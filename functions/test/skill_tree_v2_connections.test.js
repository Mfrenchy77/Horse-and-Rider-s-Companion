'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {connectionHandler} = require('../connections');
const {backfillOwnerUids} = require('../../tool/backfill_profile_owner_uid');

function clone(value) {
  return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

function createMockDb(initial = {}) {
  const store = new Map();
  for (const [k, v] of Object.entries(initial)) store.set(k, clone(v));

  function makeRef(path) {
    return {
      id: path.split('/').pop(),
      path,
      collection(name) {
        return makeCol(`${path}/${name}`);
      },
      async update(patch) {
        const cur = store.get(path);
        if (!cur) throw new Error(`Missing: ${path}`);
        store.set(path, {...cur, ...clone(patch)});
      },
    };
  }

  function makeCol(prefix) {
    return {
      doc(id) {
        return makeRef(`${prefix}/${id}`);
      },
      async get() {
        const docs = [];
        for (const [k, v] of store.entries()) {
          if (k.startsWith(`${prefix}/`) && !k.slice(prefix.length + 1).includes('/')) {
            docs.push({id: k.split('/').pop(), ref: makeRef(k), data: () => clone(v)});
          }
        }
        return {docs};
      },
    };
  }

  return {
    store,
    collection: makeCol,
    async runTransaction(fn) {
      const tx = {
        async get(ref) {
          const data = store.get(ref.path);
          return {exists: data !== undefined, id: ref.id, ref, data: () => clone(data)};
        },
        set(ref, data) {
          store.set(ref.path, clone(data));
        },
        create(ref, data) {
          if (store.has(ref.path)) throw new Error(`Already exists: ${ref.path}`);
          store.set(ref.path, clone(data));
        },
        update(ref, patch) {
          const cur = store.get(ref.path);
          if (!cur) throw new Error(`Missing: ${ref.path}`);
          store.set(ref.path, {...cur, ...clone(patch)});
        },
      };
      return fn(tx);
    },
  };
}

function profileId(email) {
  return email.replaceAll('.', '666').replaceAll('@', '999')
      .replaceAll('f', '5').replaceAll('e', '1').replaceAll('g', '2')
      .replaceAll('m', '').replaceAll('a', 'p').replaceAll('i', 'a')
      .replaceAll('co', 'l');
}

const RIDER_DOC_ID = profileId('rider@example.com');
const RIDER_DOC = `Rider_Profile/${RIDER_DOC_ID}`;

function mockAuth() {
  return {
    async getUserByEmail(email) {
      if (email === 'rider@example.com') return {uid: 'uid-rider', email, emailVerified: true};
      if (email === 'coach1@example.com') return {uid: 'uid-coach-1', email, emailVerified: true};
      if (email === 'coach2@example.com') return {uid: 'uid-coach-2', email, emailVerified: true};
      throw new Error('not-found');
    },
  };
}

function baseDb() {
  return createMockDb({
    [RIDER_DOC]: {
      email: 'rider@example.com',
      ownerUid: 'uid-rider',
      name: 'Rider',
      notes: [],
    },
    [`Rider_Profile/${profileId('coach1@example.com')}`]: {
      email: 'coach1@example.com',
      ownerUid: 'uid-coach-1',
      name: 'Coach One',
    },
    [`Rider_Profile/${profileId('coach2@example.com')}`]: {
      email: 'coach2@example.com',
      ownerUid: 'uid-coach-2',
      name: 'Coach Two',
    },
    'Horse_Profile/horse-1': {
      id: 'horse-1',
      name: 'Apollo',
      currentOwnerId: 'rider@example.com',
      ownerUid: 'uid-rider',
      ownershipVersion: 'v1',
      archiveStatus: 'active',
      notes: [],
    },
    'CoachingConnections/conn-rider-1': {
      kind: 'rider',
      status: 'accepted',
      version: 'cv1',
      learner: 'rider@example.com',
      learnerEmail: 'rider@example.com',
      learnerUid: 'uid-rider',
      coach: 'coach1@example.com',
      coachEmail: 'coach1@example.com',
      coachUid: 'uid-coach-1',
      coachName: 'Coach One',
    },
    'CoachingConnections/conn-rider-2': {
      kind: 'rider',
      status: 'accepted',
      version: 'cv2',
      learner: 'rider@example.com',
      learnerEmail: 'rider@example.com',
      learnerUid: 'uid-rider',
      coach: 'coach2@example.com',
      coachEmail: 'coach2@example.com',
      coachUid: 'uid-coach-2',
      coachName: 'Coach Two',
    },
    'CoachingConnections/conn-horse-1': {
      kind: 'horse',
      status: 'accepted',
      version: 'hv1',
      horseId: 'horse-1',
      ownershipVersion: 'v1',
      learner: 'rider@example.com',
      learnerEmail: 'rider@example.com',
      learnerUid: 'uid-rider',
      coach: 'coach1@example.com',
      coachEmail: 'coach1@example.com',
      coachUid: 'uid-coach-1',
      coachName: 'Coach One',
    },
    'SkillsV2/rider.mounted.shoulder_in': {
      id: 'rider.mounted.shoulder_in',
      name: 'Shoulder-In',
      subject: 'rider',
      status: 'active',
      availableLevels: ['intermediate', 'advanced'],
      levels: {
        intermediate: {standardVersion: 1},
        advanced: {standardVersion: 2},
      },
    },
    'SkillsV2/horse.mounted.shoulder_in': {
      id: 'horse.mounted.shoulder_in',
      name: 'Shoulder-In (Under Saddle)',
      subject: 'horse',
      status: 'active',
      availableLevels: ['intermediate', 'advanced'],
      levels: {
        intermediate: {standardVersion: 1},
        advanced: {standardVersion: 1},
      },
    },
    [`${RIDER_DOC}/SkillProgress/rider.mounted.shoulder_in`]: {
      skillId: 'rider.mounted.shoulder_in',
      subject: 'rider',
      schemaVersion: 2,
      levels: {
        intermediate: {state: 'PROFICIENT', updatedByUid: 'uid-rider'},
      },
    },
  });
}

test('verifySkillLevel verifies valid level idempotently, preserves progress, and rejects unavailable levels', async () => {
  const db = baseDb();
  const handler = connectionHandler(db, mockAuth());
  const coach1Auth = {uid: 'uid-coach-1', token: {email: 'coach1@example.com', email_verified: true}};

  // Unavailable level (Introductory not offered on Shoulder-In) must fail
  await assert.rejects(
    () => handler({
      auth: coach1Auth,
      data: {
        action: 'verifySkillLevel',
        id: 'conn-rider-1',
        version: 'cv1',
        recordId: 'rec-bad',
        skillId: 'rider.mounted.shoulder_in',
        level: 'introductory',
      },
    }),
    /available difficulty level/i,
  );

  // Verify Intermediate
  const res1 = await handler({
    auth: coach1Auth,
    data: {
      action: 'verifySkillLevel',
      id: 'conn-rider-1',
      version: 'cv1',
      recordId: 'rec-1',
      skillId: 'rider.mounted.shoulder_in',
      level: 'intermediate',
    },
  });
  assert.equal(res1.verified, true);
  assert.equal(res1.level, 'intermediate');

  // Idempotent retry with same recordId does not duplicate events
  const resRetry = await handler({
    auth: coach1Auth,
    data: {
      action: 'verifySkillLevel',
      id: 'conn-rider-1',
      version: 'cv1',
      recordId: 'rec-1',
      skillId: 'rider.mounted.shoulder_in',
      level: 'intermediate',
    },
  });
  assert.equal(resRetry.eventId, res1.eventId);

  const verif = db.store.get(
    `${RIDER_DOC}/SkillVerifications/rider.mounted.shoulder_in`,
  );
  assert.equal(verif.levels.intermediate.verifiedState, 'PROFICIENT');
  assert.equal(verif.levels.intermediate.verifiedByName, 'Coach One');
  assert.equal(verif.levels.intermediate.verifiedByUid, undefined);
  assert.equal(verif.levels.intermediate.connectionId, undefined);
  assert.equal(verif.levels.intermediate.standardVersion, 1);

  // Event recorded with UIDs
  const evt = db.store.get(
    `${RIDER_DOC}/SkillVerificationEvents/${res1.eventId}`,
  );
  assert.equal(evt.type, 'verified');
  assert.equal(evt.actorUid, 'uid-coach-1');

  // Any active accepted coach (coach2) can revoke, preserving SkillProgress
  const coach2Auth = {uid: 'uid-coach-2', token: {email: 'coach2@example.com', email_verified: true}};
  const rev = await handler({
    auth: coach2Auth,
    data: {
      action: 'revokeSkillLevel',
      id: 'conn-rider-2',
      version: 'cv2',
      recordId: 'rec-2',
      skillId: 'rider.mounted.shoulder_in',
      level: 'intermediate',
      reason: 'Re-assessing after winter break',
    },
  });
  assert.equal(rev.verified, false);

  const afterVerif = db.store.get(
    `${RIDER_DOC}/SkillVerifications/rider.mounted.shoulder_in`,
  );
  assert.equal(afterVerif.levels.intermediate, undefined);

  const progress = db.store.get(
    `${RIDER_DOC}/SkillProgress/rider.mounted.shoulder_in`,
  );
  assert.equal(progress.levels.intermediate.state, 'PROFICIENT');

  const revEvt = db.store.get(
    `${RIDER_DOC}/SkillVerificationEvents/${rev.eventId}`,
  );
  assert.equal(revEvt.type, 'revoked');
  assert.equal(revEvt.actorUid, 'uid-coach-2');
  assert.equal(revEvt.previousVerification.verifiedByName, 'Coach One');
  assert.equal(revEvt.reason, 'Re-assessing after winter break');
});

test('horse verification rejects subject mismatch and stale ownership version after transfer', async () => {
  const db = baseDb();
  const handler = connectionHandler(db, mockAuth());
  const coach1Auth = {uid: 'uid-coach-1', token: {email: 'coach1@example.com', email_verified: true}};

  // Rider skill on a horse connection must fail
  await assert.rejects(
    () => handler({
      auth: coach1Auth,
      data: {
        action: 'verifySkillLevel',
        id: 'conn-horse-1',
        version: 'hv1',
        recordId: 'hrec-bad',
        skillId: 'rider.mounted.shoulder_in',
        level: 'intermediate',
      },
    }),
    /matching skill/i,
  );

  // Valid horse verification
  const ok = await handler({
    auth: coach1Auth,
    data: {
      action: 'verifySkillLevel',
      id: 'conn-horse-1',
      version: 'hv1',
      recordId: 'hrec-1',
      skillId: 'horse.mounted.shoulder_in',
      level: 'intermediate',
    },
  });
  assert.equal(ok.verified, true);

  // Simulate horse ownership transfer
  db.store.set('Horse_Profile/horse-1', {
    ...db.store.get('Horse_Profile/horse-1'),
    currentOwnerId: 'newowner@example.com',
    ownerUid: 'uid-new-owner',
    ownershipVersion: 'v2',
  });

  await assert.rejects(
    () => handler({
      auth: coach1Auth,
      data: {
        action: 'revokeSkillLevel',
        id: 'conn-horse-1',
        version: 'hv1',
        recordId: 'hrec-2',
        skillId: 'horse.mounted.shoulder_in',
        level: 'intermediate',
      },
    }),
    /different owner/i,
  );
});

test('backfillOwnerUids resolves authoritative UIDs from Auth without trusting client claims', async () => {
  const db = createMockDb({
    'Rider_Profile/a@example.com': {email: 'a@example.com', name: 'A'},
    'Rider_Profile/b@example.com': {email: 'b@example.com', ownerUid: 'uid-b'},
    'Horse_Profile/h1': {currentOwnerId: 'a@example.com', name: 'H1'},
    'Horse_Profile/h2': {currentOwnerId: 'missing@example.com', name: 'H2'},
  });
  const auth = {
    async getUserByEmail(email) {
      if (email === 'a@example.com') return {uid: 'uid-a'};
      throw new Error('not-found');
    },
  };

  const dry = await backfillOwnerUids({db, auth, dryRun: true});
  assert.equal(dry.ridersUpdated, 1);
  assert.equal(dry.ridersAlreadySet, 1);
  assert.equal(dry.horsesUpdated, 1);
  assert.equal(dry.horsesUnresolved.length, 1);
  assert.equal(db.store.get('Rider_Profile/a@example.com').ownerUid, undefined);

  const committed = await backfillOwnerUids({db, auth, dryRun: false});
  assert.equal(committed.ridersUpdated, 1);
  assert.equal(db.store.get('Rider_Profile/a@example.com').ownerUid, 'uid-a');
  assert.equal(db.store.get('Horse_Profile/h1').ownerUid, 'uid-a');
});
