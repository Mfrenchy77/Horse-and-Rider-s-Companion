/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {connectionHandler} = require('../connections');

const student = 'rider@example.com';
const coach = 'coach@example.com';
const outsider = 'other@example.com';
const uid = (email) => email.split('@')[0];

function fixture() {
  const docs = new Map([
    ['Rider_Profile/rad1r9991xppl1666l', {email: student, name: 'Rider', bio: 'Keep', ownedHorses: [{id: 'atlas'}]}],
    ['Rider_Profile/lpch9991xppl1666l', {email: coach, name: 'Coach', isTrainer: true}],
    ['Horse_Profile/atlas', {currentOwnerId: student, name: 'Atlas', notes: [], height: 155}],
    ['Skills/rider-skill', {rider: true, skillName: 'Transitions'}],
    ['Skills/horse-skill', {rider: false, skillName: 'Leading'}],
  ]);
  let queue = Promise.resolve();
  const db = {
    collection: (collection) => ({
      doc: (id) => `${collection}/${id}`,
      where: (field, op, value) => ({collection, field, value}),
    }),
    runTransaction: (run) => {
      const result = queue.then(async () => {
        const writes = [];
        const tx = {
          get: async (ref) => typeof ref === 'string' ?
            {data: () => structuredClone(docs.get(ref))} :
            {docs: [...docs.entries()]
                .filter(([path, data]) => path.startsWith(`${ref.collection}/`) && data[ref.field] === ref.value)
                .map(([, data]) => ({data: () => structuredClone(data)}))},
          delete: (ref) => writes.push(() => docs.delete(ref)),
          set: (ref, data) => writes.push(() => docs.set(ref, data)),
          update: (ref, data) => writes.push(() => docs.set(ref, {...docs.get(ref), ...data})),
        };
        const output = await run(tx);
        writes.forEach((write) => write());
        return output;
      });
      queue = result.catch(() => {});
      return result;
    },
  };
  const run = connectionHandler(db, {
    getUserByEmail: async (email) => ({uid: uid(email.toLowerCase()), email: email.toLowerCase()}),
  });
  const call = (email, data, authUid = uid(email)) => run({
    auth: {uid: authUid, token: {email, email_verified: true}}, data,
  });
  const getLink = (id) => docs.get(`CoachingConnections/${id}`);
  const request = (kind) => ({action: 'send', kind, learnerEmail: student, coachEmail: coach, horseId: 'atlas'});
  return {docs, run, call, getLink, request};
}

test('crossed requests produce one pending rider connection and only the recipient can accept', async () => {
  const {call, getLink, request} = fixture();
  const [first, crossed] = await Promise.all([
    call(student, request('rider')),
    call(coach, request('rider')),
  ]);
  assert.equal(first.id, crossed.id);
  assert.equal(crossed.incoming, true);
  assert.equal(crossed.status, 'pending');
  const version = getLink(first.id).version;
  const accept = {id: first.id, version, action: 'accept'};
  await assert.rejects(call(student, accept), {code: 'permission-denied'});
  await assert.rejects(call(coach, accept, 'replacement-account'), {code: 'permission-denied'});
  assert.equal((await call(coach, accept)).status, 'accepted');
  assert.equal((await call(coach, accept)).status, 'accepted');
});

test('rider grant writes only lesson notes and matching skills until revoked', async () => {
  const {call, getLink, request, docs} = fixture();
  const {id} = await call(coach, request('rider'));
  const version = getLink(id).version;
  const record = {
    id, version, action: 'record', recordId: 'test-record',
    notes: 'Transitions', level: 'LEARNING', skillId: 'rider-skill',
  };
  await assert.rejects(call(coach, record), {code: 'permission-denied'});
  await call(student, {id, version, action: 'accept'});
  await assert.rejects(call(student, record), {code: 'permission-denied'});
  await assert.rejects(call(outsider, record), {code: 'permission-denied'});
  await assert.rejects(call(coach, {...record, skillId: 'horse-skill'}), {code: 'invalid-argument'});
  await call(coach, {...record, email: outsider, bio: 'Change'});
  await call(coach, record);
  const profile = docs.get('Rider_Profile/rad1r9991xppl1666l');
  assert.equal(profile.email, student);
  assert.equal(profile.bio, 'Keep');
  assert.equal(profile.notes, undefined);
  const history = await call(coach, {id, version, action: 'studentHistory'});
  assert.equal(history.entries.length, 1);
  assert.equal(history.entries[0].parentId, coach);
  assert.equal(history.entries[0].riderLog.authorRole, 'instructor');
  assert.equal(profile.skillLevels[0].verified, true);
  await call(student, {id, version, action: 'revoke'});
  await assert.rejects(call(coach, record), {code: 'permission-denied'});
  await assert.rejects(call(coach, {id, version, action: 'studentHistory'}), {code: 'permission-denied'});
});

test('horse invitation grants training writes and a changed owner cuts off the grant', async () => {
  const {call, getLink, request, docs} = fixture();
  const {id} = await call(student, {...request('horse'), coachEmail: coach.toUpperCase()});
  const version = getLink(id).version;
  await call(coach, {id, version, action: 'accept'});
  const record = {id, version, action: 'record', recordId: 'test-record', notes: 'Groundwork', currentOwnerId: coach};
  await call(coach, record);
  const horse = docs.get('Horse_Profile/atlas');
  assert.equal(horse.currentOwnerId, student);
  assert.equal(horse.height, 155);
  assert.equal(horse.notes[0].riderLog.authorRole, 'trainer');
  const history = {action: 'horseHistory', horseId: 'atlas', includeTrainingNotes: true};
  assert.equal((await call(coach, history)).entries[0].name, 'Groundwork');
  horse.currentOwnerId = outsider;
  assert.equal((await call(outsider, history)).entries[0].name, 'Groundwork');
  await assert.rejects(call(coach, history), {code: 'permission-denied'});
  await assert.rejects(call(coach, record), {code: 'failed-precondition'});
});

test('decline and cancellation resolve pending requests and stale actions are rejected', async () => {
  const {call, run, getLink, request} = fixture();
  await assert.rejects(run({data: request('rider')}), {code: 'unauthenticated'});
  const {id} = await call(coach, request('horse'));
  const version = getLink(id).version;
  await call(student, {id, version, action: 'decline'});
  assert.equal(getLink(id).status, 'declined');
  await call(coach, request('horse'));
  const nextVersion = getLink(id).version;
  await assert.rejects(call(student, {id, version, action: 'accept'}), {code: 'failed-precondition'});
  await call(coach, {id, version: nextVersion, action: 'cancel'});
  assert.equal(getLink(id).status, 'cancelled');
});

test('one linked journal record follows the horse and edits or deletes in both views', async () => {
  const {call, docs} = fixture();
  const action = {
    action: 'saveJournal', id: 'ride', horseId: 'atlas', type: 'show',
    notes: 'Show results', placing: '1st', date: '2025-01-01T00:00:00.000Z',
  };
  await call(student, action);
  const entries = await call(student, {action: 'horseHistory', horseId: 'atlas'});
  assert.equal(entries.entries[0].riderLog.placing, '1st');
  assert.equal(entries.entries[0].date, action.date);
  assert.equal(entries.entries[0].riderName, 'Rider');
  assert.equal(entries.entries[0].riderLog.horse, 'Atlas');
  assert.equal(docs.get('Rider_Profile/rad1r9991xppl1666l').notes, undefined);
  assert.equal([...docs.keys()].filter((path) => path.startsWith('SharedRidingEntries/')).length, 1);
  await assert.rejects(call(coach, action), {code: 'permission-denied'});
  await call(student, {...action, shared: true, isEdit: true, notes: 'Corrected'});
  assert.equal((await call(student, {action: 'horseHistory', horseId: 'atlas'})).entries[0].name, 'Corrected');
  docs.get('Horse_Profile/atlas').currentOwnerId = outsider;
  const history = {action: 'horseHistory', horseId: 'atlas'};
  await assert.rejects(call(student, history), {code: 'permission-denied'});
  assert.equal((await call(outsider, history)).entries[0].name, 'Corrected');
  await call(student, {action: 'deleteJournal', id: 'ride', shared: true});
  assert.deepEqual((await call(outsider, {action: 'horseHistory', horseId: 'atlas'})).entries, []);
});

test('accepted instructor can save a lesson on a reciprocal student horse link', async () => {
  const {call, getLink, request, docs} = fixture();
  const profile = docs.get('Rider_Profile/rad1r9991xppl1666l');
  profile.ownedHorses = [];
  profile.studentHorses = [{id: 'atlas', name: 'Atlas'}];
  const horse = docs.get('Horse_Profile/atlas');
  horse.currentOwnerId = outsider;
  const {id} = await call(coach, request('rider'));
  const version = getLink(id).version;
  const lesson = {id, version, action: 'record', recordId: 'lesson', horseId: 'atlas', notes: 'Lesson'};
  await assert.rejects(call(coach, lesson), {code: 'permission-denied'});
  await call(student, {id, version, action: 'accept'});
  await assert.rejects(call(coach, lesson), {code: 'permission-denied'});
  horse.instructors = [{id: student}];
  await assert.rejects(call(outsider, lesson), {code: 'permission-denied'});
  await call(coach, lesson);
  await call(coach, lesson);
  const ownerHistory = await call(outsider, {action: 'horseHistory', horseId: 'atlas'});
  const [entry] = ownerHistory.entries;
  assert.equal(ownerHistory.entries.length, 1);
  assert.equal(entry.parentId, coach);
  assert.equal(entry.riderName, 'Rider');
  assert.equal((await call(coach, {id, version, action: 'studentHistory'})).entries[0].id, entry.id);
  const edit = {...lesson, action: 'editLesson', entryId: entry.id, notes: 'Updated'};
  await call(coach, edit);
  assert.equal((await call(outsider, {action: 'horseHistory', horseId: 'atlas'})).entries[0].name, 'Updated');
  await assert.rejects(call(student, {action: 'deleteJournal', id: entry.id, shared: true}),
      {code: 'permission-denied'});
  await call(coach, {...edit, action: 'deleteLesson'});
  assert.deepEqual((await call(outsider, {action: 'horseHistory', horseId: 'atlas'})).entries, []);
});

test('new instructor sees existing lesson history while private reflections remain private', async () => {
  const {call, getLink, request, docs} = fixture();
  const profile = docs.get('Rider_Profile/rad1r9991xppl1666l');
  profile.notes = [
    {id: 'old-lesson', name: 'Past lesson', imageUrl: 'LogTag.Training', parentId: outsider},
    {id: 'reflection', name: 'Private reflection', imageUrl: 'LogTag.Other', parentId: student},
  ];
  const {id} = await call(student, request('rider'));
  const version = getLink(id).version;
  const history = {id, version, action: 'studentHistory'};
  await assert.rejects(call(coach, history), {code: 'permission-denied'});
  await call(coach, {id, version, action: 'accept'});
  const {entries} = await call(coach, history);
  assert.deepEqual(entries.map((entry) => [entry.id, entry.editable]), [['old-lesson', false]]);
});

test('archive and restore retain ownership and shared history while hiding the horse from lesson options', async () => {
  const {call, getLink, request, docs} = fixture();
  const {id} = await call(coach, request('rider'));
  const version = getLink(id).version;
  await call(student, {id, version, action: 'accept'});
  const horseRequest = await call(coach, request('horse'));
  const horseVersion = getLink(horseRequest.id).version;
  await call(student, {id: horseRequest.id, version: horseVersion, action: 'accept'});
  const training = {
    id: horseRequest.id, version: horseVersion, action: 'record', recordId: 'training', notes: 'Groundwork',
  };
  const options = {id, version, action: 'horseOptions'};
  assert.deepEqual((await call(coach, options)).horses, [{id: 'atlas', name: 'Atlas'}]);
  const action = {action: 'setHorseArchive', horseId: 'atlas', archiveStatus: 'deceased'};
  const journal = {action: 'saveJournal', id: 'ride', type: 'training', horseId: 'atlas', notes: 'Practice'};
  await call(student, journal);
  await assert.rejects(call(coach, action), {code: 'permission-denied'});
  await assert.rejects(call(student, {...action, archiveStatus: 'unknown'}), {code: 'invalid-argument'});
  await call(student, action);
  await call(student, action);
  const animal = docs.get('Horse_Profile/atlas');
  const owner = docs.get('Rider_Profile/rad1r9991xppl1666l');
  assert.equal(animal.currentOwnerId, student);
  assert.equal(animal.archiveStatus, 'deceased');
  assert.equal(animal.height, 155);
  assert.deepEqual(owner.ownedHorses, []);
  assert.deepEqual(owner.archivedHorses.map((item) => item.id), ['atlas']);
  assert.deepEqual((await call(coach, options)).horses, []);
  await assert.rejects(call(coach, request('horse')), {code: 'failed-precondition'});
  await assert.rejects(call(coach, training), {code: 'failed-precondition'});
  await assert.rejects(call(student, {...journal, id: 'new-ride'}), {code: 'permission-denied'});
  await call(student, {...journal, shared: true, isEdit: true, notes: 'Practice corrected'});
  const history = await call(student, {action: 'horseHistory', horseId: 'atlas'});
  assert.equal(history.entries[0].name, 'Practice corrected');
  await call(student, {...action, archiveStatus: 'active'});
  const restored = docs.get('Rider_Profile/rad1r9991xppl1666l');
  assert.deepEqual(restored.archivedHorses, []);
  assert.deepEqual(restored.ownedHorses.map((item) => item.id), ['atlas']);
  await call(coach, training);
  assert.deepEqual((await call(coach, options)).horses, [{id: 'atlas', name: 'Atlas'}]);
});
