/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {createHash, randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');

const collection = 'CoachingConnections';
const journalCollection = 'SharedRidingEntries';
const key = (parts) => createHash('sha256').update(JSON.stringify(parts)).digest('hex');
const journalRef = (db, riderUid, id) => db.collection(journalCollection).doc(key([riderUid, id]));
const terminal = new Set(['declined', 'cancelled', 'revoked']);
const emailKey = (email) => email.toLowerCase();

function text(value, max, field, optional = false) {
  if (optional && (value == null || value === '')) return '';
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  return value.trim();
}

function documentId(value, field) {
  const id = text(value, 200, field);
  if (id.includes('/') || id === '.' || id === '..') {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  return id;
}

function profileId(email) {
  return email.replaceAll('.', '666').replaceAll('@', '999')
      .replaceAll('f', '5').replaceAll('e', '1').replaceAll('g', '2')
      .replaceAll('m', '').replaceAll('a', 'p').replaceAll('i', 'a')
      .replaceAll('co', 'l');
}

async function rider(tx, db, email) {
  documentId(email, 'rider email');
  if (!email.includes('@')) throw new HttpsError('invalid-argument', 'Invalid rider email.');
  const ref = db.collection('Rider_Profile').doc(profileId(email));
  const profile = (await tx.get(ref)).data();
  if (!profile || typeof profile.email !== 'string' ||
      emailKey(profile.email) !== emailKey(email)) {
    throw new HttpsError('not-found', 'The rider profile is unavailable.');
  }
  return {ref, profile};
}

async function horse(tx, db, horseId) {
  const ref = db.collection('Horse_Profile').doc(horseId);
  const profile = (await tx.get(ref)).data();
  if (!profile || typeof profile.currentOwnerId !== 'string' || !profile.currentOwnerId) {
    throw new HttpsError('not-found', 'The horse or its owner is unavailable.');
  }
  return {ref, profile};
}

function transition(link, actor, action) {
  const sender = link.sender === actor;
  const recipient = link.recipient === actor;
  const rule = {
    accept: [recipient, 'pending', 'accepted'],
    decline: [recipient, 'pending', 'declined'],
    cancel: [sender, 'pending', 'cancelled'],
    revoke: [sender || recipient, 'accepted', 'revoked'],
  }[action];
  if (!rule || !rule[0]) {
    throw new HttpsError('permission-denied', 'You cannot take that action.');
  }
  if (link.status === rule[2]) return link.status;
  if (link.status !== rule[1]) {
    throw new HttpsError('failed-precondition', 'The connection has changed.');
  }
  return rule[2];
}

async function send(tx, db, auth, data, actor, identity, now, version) {
  const kind = data.kind;
  if (kind !== 'rider' && kind !== 'horse') {
    throw new HttpsError('invalid-argument', 'Choose a connection type.');
  }
  const horseId = kind === 'horse' ? documentId(data.horseId, 'horse ID') : null;
  const targetHorse = horseId ? (await horse(tx, db, horseId)).profile : null;
  if (targetHorse && isArchived(targetHorse)) {
    throw new HttpsError('failed-precondition', 'Restore this horse to request coaching.');
  }
  const learnerEmail = targetHorse ? targetHorse.currentOwnerId : documentId(data.learnerEmail, 'rider email');
  const coachEmail = documentId(data.coachEmail, 'trainer email');
  const learner = emailKey(learnerEmail);
  const coach = emailKey(coachEmail);
  if (learner === coach || (actor !== learner && actor !== coach)) {
    throw new HttpsError('permission-denied', 'Only the two participants can request this connection.');
  }

  const otherEmail = actor === learner ? coachEmail : learnerEmail;
  let otherUser;
  try {
    otherUser = await auth.getUserByEmail(otherEmail);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    throw new HttpsError('not-found', 'The recipient has no active account.');
  }
  if (otherUser.disabled || otherUser.uid === identity.uid || !otherUser.email ||
      emailKey(otherUser.email) !== emailKey(otherEmail)) {
    throw new HttpsError('failed-precondition', 'The recipient is unavailable.');
  }

  const [learnerRecord, coachRecord] = await Promise.all([
    rider(tx, db, actor === learner ? identity.email : otherUser.email),
    rider(tx, db, actor === coach ? identity.email : otherUser.email),
  ]);
  if (coachRecord.profile.isTrainer !== true) {
    throw new HttpsError('failed-precondition', 'This rider is not listed as an instructor or trainer.');
  }

  const learnerUid = actor === learner ? identity.uid : otherUser.uid;
  const coachUid = actor === coach ? identity.uid : otherUser.uid;
  const id = key([kind, learnerUid, coachUid, horseId]);
  const ref = db.collection(collection).doc(id);
  const existing = (await tx.get(ref)).data();
  if (existing && !terminal.has(existing.status)) {
    // A crossed request remains incoming until its recipient explicitly accepts.
    return {id, status: existing.status, incoming: existing.recipient === actor};
  }
  const reason = text(data.reason, 280, 'reason', true);
  tx.set(ref, {
    kind, version, horseId,
    horseName: targetHorse?.name || null,
    learner, coach,
    learnerEmail: learnerRecord.profile.email,
    coachEmail: coachRecord.profile.email,
    learnerName: learnerRecord.profile.name || learnerEmail,
    coachName: coachRecord.profile.name || coachEmail,
    participantUids: [learnerUid, coachUid],
    learnerUid, coachUid,
    sender: actor,
    recipient: actor === learner ? coach : learner,
    reason,
    status: 'pending',
    updatedAt: now,
  });
  return {id, status: 'pending', incoming: false};
}

function isArchived(animal) {
  return ['archived', 'deceased'].includes(animal.archiveStatus);
}

async function setHorseArchive(tx, db, identity, data, now) {
  const horseId = documentId(data.horseId, 'horse ID');
  const archiveStatus = data.archiveStatus;
  if (!['active', 'archived', 'deceased'].includes(archiveStatus)) {
    throw new HttpsError('invalid-argument', 'Choose a valid horse status.');
  }
  const animal = await horse(tx, db, horseId);
  if (emailKey(animal.profile.currentOwnerId) !== emailKey(identity.email)) {
    throw new HttpsError('permission-denied', 'Only the horse owner can change its archive status.');
  }
  const owner = await rider(tx, db, identity.email);
  const owned = owner.profile.ownedHorses || [];
  const archived = owner.profile.archivedHorses || [];
  const active = archiveStatus === 'active';
  if ((animal.profile.archiveStatus || 'active') === archiveStatus &&
      hasHorse(active ? owned : archived, horseId) && !hasHorse(active ? archived : owned, horseId)) {
    return {status: archiveStatus};
  }
  const link = {
    id: horseId, name: animal.profile.name || horseId,
    ...(animal.profile.picUrl ? {imageUrl: animal.profile.picUrl} : {}), isCollapsed: false,
  };
  tx.update(owner.ref, {
    ownedHorses: [...owned.filter((item) => item.id !== horseId), ...(active ? [link] : [])],
    archivedHorses: [...archived.filter((item) => item.id !== horseId), ...(active ? [] : [link])],
  });
  tx.update(animal.ref, {
    archiveStatus,
    lastEditBy: owner.profile.name || owner.profile.email,
    lastEditDate: now,
  });
  return {status: archiveStatus};
}

async function target(tx, db, link) {
  if (link.kind === 'rider') return rider(tx, db, link.learnerEmail);
  const record = await horse(tx, db, link.horseId);
  if (emailKey(record.profile.currentOwnerId) !== link.learner) {
    throw new HttpsError('failed-precondition', 'The horse has a different owner.');
  }
  return record;
}

async function trainerGrant(tx, db, auth, record, horseId, uid, email) {
  if (!record.currentOwnerId.includes('@')) return false;
  let owner;
  try {
    owner = await auth.getUserByEmail(record.currentOwnerId);
  } catch (error) {
    if (error.code === 'auth/user-not-found') return false;
    throw error;
  }
  const ref = db.collection(collection).doc(key(['horse', owner.uid, uid, horseId]));
  const link = (await tx.get(ref)).data();
  return link?.status === 'accepted' && link.coach === emailKey(email) &&
      link.learner === emailKey(record.currentOwnerId);
}

function hasHorse(links, horseId) {
  return (links || []).some((link) => link.id === horseId);
}

async function linkedHorse(tx, db, auth, profile, uid, horseId, allowArchived = false) {
  const owned = hasHorse(profile.ownedHorses, horseId) ||
      (allowArchived && hasHorse(profile.archivedHorses, horseId));
  const student = hasHorse(profile.studentHorses, horseId);
  if (!owned && !student) {
    throw new HttpsError('permission-denied', 'Choose a horse linked to the rider profile.');
  }
  const {profile: animal} = await horse(tx, db, horseId);
  if (!allowArchived && isArchived(animal)) {
    throw new HttpsError('failed-precondition', 'Choose an active horse.');
  }
  if (owned && emailKey(animal.currentOwnerId) === emailKey(profile.email)) return animal;
  if (student &&
      ((animal.instructors || []).some((instructor) =>
        typeof instructor.id === 'string' && emailKey(instructor.id) === emailKey(profile.email)) ||
      await trainerGrant(tx, db, auth, animal, horseId, uid, profile.email))) return animal;

  throw new HttpsError('permission-denied', 'This horse link is no longer authorized.');
}

function storeJournal(tx, ref, profile, uid, authorUid, entry, animal, horseId) {
  tx.set(ref, {
    riderUid: uid,
    riderName: profile.name || profile.email,
    authorUid,
    horseId: horseId || null,
    note: {
      ...entry,
      riderLog: {
        ...entry.riderLog,
        shared: true,
        ...(animal ? {horseId, horse: animal.name || horseId} : {}),
      },
    },
  });
}

async function saveJournal(tx, db, auth, identity, data) {
  const id = documentId(data.id, 'entry ID');
  const ref = journalRef(db, identity.uid, id);
  const existing = (await tx.get(ref)).data();
  if (existing && (existing.riderUid !== identity.uid || existing.authorUid !== identity.uid)) {
    throw new HttpsError('permission-denied', 'Only the original author can change this entry.');
  }
  if (data.action === 'deleteJournal' && existing) {
    tx.delete(ref);
    return {status: 'deleted'};
  }
  if (data.shared === true && !existing) {
    if (data.action === 'deleteJournal') return {status: 'deleted'};
    throw new HttpsError('not-found', 'This entry is unavailable.');
  }
  const record = await rider(tx, db, identity.email);
  const legacy = (record.profile.notes || []).find((note) => note.id === id);
  if (legacy && (typeof legacy.parentId !== 'string' ||
      emailKey(legacy.parentId) !== emailKey(identity.email) ||
      legacy.imageUrl === 'LogTag.Edit' || legacy.riderLog?.type === 'activity')) {
    throw new HttpsError('permission-denied', 'Only the original author can change this entry.');
  }
  if (data.action === 'deleteJournal') {
    if (legacy) tx.update(record.ref, {notes: record.profile.notes.filter((note) => note.id !== id)});
    return {status: 'deleted'};
  }
  if (data.isEdit === true && !legacy && !existing) {
    throw new HttpsError('not-found', 'This entry is unavailable.');
  }

  const horseId = data.horseId == null ? null : documentId(data.horseId, 'horse ID');
  const keepingHorse = existing?.horseId === horseId || legacy?.riderLog?.horseId === horseId;
  const animal = horseId ? await linkedHorse(tx, db, auth, record.profile, identity.uid, horseId, keepingHorse) : null;
  const type = data.type;
  const tag = {lesson: 'Training', training: 'Training', show: 'Show', care: 'Health', reflection: 'Other'}[type];
  if (typeof tag !== 'string') throw new HttpsError('invalid-argument', 'Invalid entry type.');
  const date = entryDate(data.date, null);
  const details = {type};
  for (const [field, max] of Object.entries({title: 100, instructor: 200, focus: 4000, nextSteps: 4000})) {
    const value = text(data[field], max, field, true);
    if (value) details[field] = value;
  }
  if (!animal && data.horse) details.horse = text(data.horse, 200, 'horse name');
  if (type === 'show' && data.placing) details.placing = text(data.placing, 40, 'placing');
  const entry = {
    id, date, name: text(data.notes, 12000, 'notes'),
    parentId: record.profile.email, message: record.profile.name || identity.email,
    imageUrl: `LogTag.${tag}`, riderLog: details,
  };
  storeJournal(tx, ref, record.profile, identity.uid, identity.uid, entry, animal, horseId);
  if (legacy) tx.update(record.ref, {notes: record.profile.notes.filter((note) => note.id !== id)});
  return {status: 'saved'};
}

function wireNote(note, riderName) {
  const date = note.date?.toDate?.() ?? note.date;
  return {...note, date: date instanceof Date ? date.toISOString() : date || null, riderName};
}

async function horseHistory(tx, db, auth, identity, data) {
  const horseId = documentId(data.horseId, 'horse ID');
  const {profile: animal} = await horse(tx, db, horseId);
  const owner = emailKey(animal.currentOwnerId) === emailKey(identity.email);
  const trainer = !owner && await trainerGrant(tx, db, auth, animal, horseId, identity.uid, identity.email);
  if (!owner && !trainer) {
    const record = await rider(tx, db, identity.email);
    await linkedHorse(tx, db, auth, record.profile, identity.uid, horseId, true);
  }
  const query = db.collection(journalCollection).where('horseId', '==', horseId);
  const entries = (await tx.get(query)).docs.map((doc) => {
    const {note, riderName} = doc.data();
    return wireNote(note, riderName);
  });
  if (data.includeTrainingNotes === true && (owner || trainer)) {
    for (const note of animal.notes || []) {
      if (note.imageUrl === 'LogTag.Training') entries.push(wireNote(note, null));
    }
  }
  return {entries};
}

async function studentHistory(tx, db, link, actor) {
  if (link.kind !== 'rider' || link.status !== 'accepted' || link.coach !== actor) {
    throw new HttpsError('permission-denied', 'An active instructor connection is required.');
  }
  const {profile} = await target(tx, db, link);
  const shared = await tx.get(db.collection(journalCollection).where('riderUid', '==', link.learnerUid));
  const entries = [
    ...(profile.notes || []).map((note) => ({note, editable: false})),
    ...shared.docs.map((doc) => {
      const {note, authorUid} = doc.data();
      return {note, editable: authorUid === link.coachUid && note.riderLog?.type === 'lesson'};
    }),
  ].filter(({note}) => note.riderLog ?
    ['lesson', 'training'].includes(note.riderLog.type) : note.imageUrl === 'LogTag.Training');
  return {entries: entries.map(({note, editable}) => ({...wireNote(note, profile.name), editable}))};
}

function entryDate(value, fallback) {
  if (value == null) return fallback;
  if (typeof value !== 'string') throw new HttpsError('invalid-argument', 'Invalid date.');
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) throw new HttpsError('invalid-argument', 'Invalid date.');
  return date;
}

function lessonDetails(data, coachName) {
  const details = {type: 'lesson', instructor: coachName, authorRole: 'instructor'};
  for (const [field, max] of Object.entries({title: 100, horse: 200, focus: 4000, nextSteps: 4000})) {
    const value = text(data[field], max, field, true);
    if (value) details[field] = value;
  }
  return details;
}

async function changeLesson(tx, db, auth, link, actor, data) {
  if (link.kind !== 'rider' || link.status !== 'accepted' || actor !== link.coach) {
    throw new HttpsError('permission-denied', 'An active instructor connection is required.');
  }
  const id = documentId(data.entryId, 'entry ID');
  const ref = journalRef(db, link.learnerUid, id);
  const saved = (await tx.get(ref)).data();
  if (!saved || saved.authorUid !== link.coachUid || saved.note.riderLog?.type !== 'lesson') {
    throw new HttpsError('permission-denied', 'Only the original instructor can change this lesson.');
  }
  if (data.action === 'deleteLesson') {
    tx.delete(ref);
    return {status: 'deleted'};
  }
  const {profile} = await target(tx, db, link);
  const horseId = data.horseId == null ? null : documentId(data.horseId, 'horse ID');
  const animal = horseId ?
    await linkedHorse(tx, db, auth, profile, link.learnerUid, horseId, saved.horseId === horseId) : null;
  const entry = {
    ...saved.note,
    date: entryDate(data.date, null),
    name: text(data.notes, 4000, 'notes'),
    riderLog: lessonDetails(data, link.coachName),
  };
  storeJournal(tx, ref, profile, link.learnerUid, link.coachUid, entry, animal, horseId);
  return {status: 'saved'};
}

async function addRecord(tx, db, auth, link, actor, data, now, connectionId) {
  if (link.status !== 'accepted' || actor !== link.coach) {
    throw new HttpsError('permission-denied', 'An active coaching connection is required.');
  }
  const record = await target(tx, db, link);
  if (link.kind === 'horse' && isArchived(record.profile)) {
    throw new HttpsError('failed-precondition', 'This horse is archived.');
  }
  const clientId = documentId(data.recordId, 'record ID');
  const recordId = `coaching-${connectionId}-${clientId}`;
  if ((record.profile.notes || []).some((note) => note.id === recordId)) {
    return {status: link.status};
  }
  const name = text(data.notes, 4000, 'notes');
  const entry = {
    id: recordId,
    date: entryDate(data.date, now),
    name,
    parentId: link.coachEmail,
    message: link.coachName,
    imageUrl: 'LogTag.Training',
  };
  if (link.kind === 'rider') {
    entry.riderLog = lessonDetails(data, link.coachName);
  } else {
    entry.riderLog = {type: 'training', authorRole: 'trainer'};
  }
  const horseId = data.horseId == null ? null : documentId(data.horseId, 'horse ID');
  if (horseId && link.kind !== 'rider') {
    throw new HttpsError('invalid-argument', 'Choose the horse from its training connection.');
  }
  const animal = horseId ? await linkedHorse(tx, db, auth, record.profile, link.learnerUid, horseId) : null;
  const sharedRef = link.kind === 'rider' ? journalRef(db, link.learnerUid, recordId) : null;
  if (sharedRef && (await tx.get(sharedRef)).data()) return {status: link.status};
  const changes = sharedRef ? {} : {notes: [...(record.profile.notes || []), entry]};
  if (data.skillId != null) {
    const skillId = documentId(data.skillId, 'skill ID');
    const skill = (await tx.get(db.collection('Skills').doc(skillId))).data();
    if (!skill || skill.rider !== (link.kind === 'rider') ||
        !['LEARNING', 'PROFICIENT'].includes(data.level)) {
      throw new HttpsError('invalid-argument', 'Choose a matching skill and progress level.');
    }
    changes.skillLevels = [
      ...(record.profile.skillLevels || []).filter((item) => item.skillId !== skillId),
      {skillId, skillName: skill.skillName, verified: true,
        lastEditBy: link.coachEmail, lastEditDate: now, levelState: data.level},
    ];
  }
  // This write has no path for changing identity, ownership, or permissions.
  if (sharedRef) {
    storeJournal(tx, sharedRef, record.profile, link.learnerUid, link.coachUid, entry, animal, horseId);
  }
  if (Object.keys(changes).length) tx.update(record.ref, changes);
  return {status: link.status};
}

function connectionHandler(db, auth) {
  return async (request) => {
    const email = request.auth?.token?.email;
    const uid = request.auth?.uid;
    if (!uid || typeof email !== 'string' || request.auth?.token?.email_verified !== true) {
      throw new HttpsError('unauthenticated', 'Sign in with a verified email first.');
    }
    const actor = emailKey(email);
    const data = request.data || {};
    const now = new Date();
    const nonce = randomUUID();

    return db.runTransaction(async (tx) => {
      const identity = {email, uid};
      if (data.action === 'saveJournal' || data.action === 'deleteJournal') {
        return saveJournal(tx, db, auth, identity, data);
      }
      if (data.action === 'horseHistory') return horseHistory(tx, db, auth, identity, data);
      if (data.action === 'setHorseArchive') return setHorseArchive(tx, db, identity, data, now);
      if (data.action === 'send') return send(tx, db, auth, data, actor, {email, uid}, now, nonce);
      const id = documentId(data.id, 'connection ID');
      const ref = db.collection(collection).doc(id);
      const link = (await tx.get(ref)).data();
      if (!link ||
          !((link.learnerUid === uid && link.learner === actor) ||
            (link.coachUid === uid && link.coach === actor))) {
        throw new HttpsError('permission-denied', 'Connection unavailable.');
      }
      if (data.version !== link.version) {
        throw new HttpsError('failed-precondition', 'Refresh this connection and try again.');
      }
      if (data.action === 'record') return addRecord(tx, db, auth, link, actor, data, now, id);
      if (data.action === 'studentHistory') return studentHistory(tx, db, link, actor);
      if (data.action === 'editLesson' || data.action === 'deleteLesson') {
        return changeLesson(tx, db, auth, link, actor, data);
      }
      if (data.action === 'horseOptions') {
        if (link.kind !== 'rider' || link.status !== 'accepted' || link.coach !== actor) {
          throw new HttpsError('permission-denied', 'An active instructor connection is required.');
        }
        const {profile} = await target(tx, db, link);
        const links = [...(profile.ownedHorses || []), ...(profile.studentHorses || [])];
        const ids = [...new Set(links.map((item) => item.id).filter((id) => typeof id === 'string' && id))];
        const horses = await Promise.all(ids.map(async (id) => {
          try {
            const animal = await linkedHorse(tx, db, auth, profile, link.learnerUid, documentId(id, 'horse ID'));
            return {id, name: animal.name || id};
          } catch (error) {
            if (['permission-denied', 'not-found', 'failed-precondition', 'invalid-argument'].includes(error.code)) {
              return null;
            }
            throw error;
          }
        }));
        return {horses: horses.filter(Boolean)};
      }

      const status = transition(link, actor, data.action);
      if (status === 'accepted' && status !== link.status) {
        const record = await target(tx, db, link);
        if (link.kind === 'horse' && isArchived(record.profile)) {
          throw new HttpsError('failed-precondition', 'This horse is archived.');
        }
      }
      if (status !== link.status) tx.update(ref, {status, updatedAt: now});
      return {id, status};
    });
  };
}

module.exports = {connectionHandler};
