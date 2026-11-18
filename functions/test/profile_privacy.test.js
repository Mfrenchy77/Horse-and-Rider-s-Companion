'use strict';

const assert = require('node:assert/strict');
const {test} = require('node:test');

const {buildPublicHorseProfile} = require('../public_horse_profile');
const {buildPublicRiderProfile} = require('../public_rider_profile');
const {connectionHandler} = require('../connections');
const {backfillProfilePrivacy} = require('../backfill_profile_privacy');

function createMockDb(seed = {}) {
  const store = new Map();
  for (const [k, v] of Object.entries(seed)) {
    store.set(k, structuredClone(v));
  }

  function makeRef(docPath) {
    return {
      id: docPath.split('/').pop(),
      path: docPath,
      async get() {
        const data = store.get(docPath);
        return {
          id: docPath.split('/').pop(),
          ref: makeRef(docPath),
          exists: data !== undefined,
          data: () => (data === undefined ? undefined : structuredClone(data)),
        };
      },
      async set(data) {
        store.set(docPath, structuredClone(data));
      },
      async update(patch) {
        const existing = store.get(docPath) || {};
        store.set(docPath, {...existing, ...structuredClone(patch)});
      },
      async delete() {
        store.delete(docPath);
      },
      collection(sub) {
        return makeCol(`${docPath}/${sub}`);
      },
    };
  }

  function makeCol(colPath) {
    return {
      doc(id) {
        return makeRef(`${colPath}/${id}`);
      },
      where(field, op, value) {
        return {
          async get() {
            const docs = [];
            for (const [k, v] of store.entries()) {
              if (!k.startsWith(`${colPath}/`)) continue;
              const rest = k.slice(colPath.length + 1);
              if (rest.includes('/')) continue;
              if (op === '==' && v[field] === value) {
                docs.push({
                  id: rest,
                  ref: makeRef(k),
                  exists: true,
                  data: () => structuredClone(v),
                });
              }
            }
            return {docs};
          },
        };
      },
      async get() {
        const docs = [];
        for (const [k, v] of store.entries()) {
          if (!k.startsWith(`${colPath}/`)) continue;
          const rest = k.slice(colPath.length + 1);
          if (rest.includes('/')) continue;
          docs.push({
            id: rest,
            ref: makeRef(k),
            exists: true,
            data: () => structuredClone(v),
          });
        }
        return {docs};
      },
    };
  }

  const db = {
    store,
    collection: (name) => makeCol(name),
    doc: (docPath) => makeRef(docPath),
    async runTransaction(fn) {
      const tx = {
        async get(ref) {
          return ref.get();
        },
        set(ref, data) {
          store.set(ref.path, structuredClone(data));
        },
        update(ref, patch) {
          const existing = store.get(ref.path) || {};
          store.set(ref.path, {...existing, ...structuredClone(patch)});
        },
        create(ref, data) {
          store.set(ref.path, structuredClone(data));
        },
        delete(ref) {
          store.delete(ref.path);
        },
      };
      return fn(tx);
    },
  };
  return db;
}

test('buildPublicRiderProfile strips private logbook, contacts, archive, and auth fields', () => {
  const result = buildPublicRiderProfile('riderDoc', {
    id: 'r1',
    name: 'Alex Rider',
    email: 'Alex@Example.com',
    bio: 'Trail rider',
    locationName: 'Bozeman, MT',
    zipCode: '59715',
    isTrainer: true,
    notes: [{id: 'n1', name: 'Private journal'}],
    savedProfilesList: [{id: 'friend@example.com', name: 'Friend'}],
    archivedHorses: [{id: 'old-horse', name: 'Old Horse'}],
    messagesList: ['m1'],
    savedResourcesList: ['res1'],
    ownerUid: 'uid-alex',
    instructorUids: ['uid-coach'],
    editor: true,
    ownedHorses: [{id: 'h1', name: 'Atlas', imageUrl: 'https://example.com/a.jpg', isCollapsed: false}],
  });

  assert.equal(result.name, 'Alex Rider');
  assert.equal(result.email, 'alex@example.com');
  assert.equal(result.bio, 'Trail rider');
  assert.equal(result.zipCode, '59715');
  assert.equal(result.isTrainer, true);
  assert.equal(result.ownedHorses.length, 1);
  for (const forbidden of [
    'notes',
    'savedProfilesList',
    'archivedHorses',
    'messagesList',
    'savedResourcesList',
    'ownerUid',
    'instructorUids',
    'editor',
  ]) {
    assert.equal(Object.prototype.hasOwnProperty.call(result, forbidden), false, `Must omit ${forbidden}`);
  }
});

test('buildPublicHorseProfile includes zipCode only for active public horses and strips private fields', () => {
  const pub = buildPublicHorseProfile('h1', {
    name: 'Atlas',
    isPublic: true,
    archiveStatus: 'active',
    zipCode: '59715',
    currentOwnerId: 'owner@example.com',
    ownerUid: 'uid-owner',
    notes: [{id: 'n1', name: 'Private vet note'}],
    purchasePrice: 9500,
    instructors: [{id: 'coach@example.com'}],
    instructorUids: ['uid-coach'],
  });
  assert.equal(pub.zipCode, '59715');
  assert.equal(pub.currentOwnerId, undefined);
  assert.equal(pub.notes, undefined);
  assert.equal(pub.instructorUids, undefined);

  assert.equal(buildPublicHorseProfile('h2', {name: 'Secret', isPublic: false, zipCode: '59715'}), null);
  assert.equal(buildPublicHorseProfile('h3', {name: 'Old', isPublic: true, archiveStatus: 'archived'}), null);
});

test('connectionHandler maintains instructorUids on accept, revoke, and horse transfer', async () => {
  const ownerId = 'own1r9991xppl1666l';
  const coachId = 'lpch9991xppl1666l';
  const buyerId = 'buy1r9991xppl1666l';
  const db = createMockDb({
    [`Rider_Profile/${ownerId}`]: {email: 'owner@example.com', name: 'Owner', ownerUid: 'uid-owner', ownedHorses: [{id: 'h1', name: 'Atlas'}]},
    [`Rider_Profile/${coachId}`]: {email: 'coach@example.com', name: 'Coach', ownerUid: 'uid-coach', isTrainer: true},
    [`Rider_Profile/${buyerId}`]: {email: 'buyer@example.com', name: 'Buyer', ownerUid: 'uid-buyer'},
    'Horse_Profile/h1': {id: 'h1', name: 'Atlas', currentOwnerId: 'owner@example.com', ownerUid: 'uid-owner', instructors: []},
  });
  const auth = {
    async getUserByEmail(email) {
      const map = {
        'owner@example.com': {uid: 'uid-owner', email: 'owner@example.com', disabled: false},
        'coach@example.com': {uid: 'uid-coach', email: 'coach@example.com', disabled: false},
        'buyer@example.com': {uid: 'uid-buyer', email: 'buyer@example.com', disabled: false},
      };
      return map[email.toLowerCase()];
    },
  };
  const call = connectionHandler(db, auth);
  const asUser = (uid, email) => ({uid, token: {email, email_verified: true}});

  // Coach requests horse training -> Owner accepts -> instructorUids includes uid-coach
  const sent = await call({
    auth: asUser('uid-coach', 'coach@example.com'),
    data: {action: 'send', kind: 'horse', horseId: 'h1', coachEmail: 'coach@example.com'},
  });
  const connDoc = (await db.doc(`CoachingConnections/${sent.id}`).get()).data();
  await call({
    auth: asUser('uid-owner', 'owner@example.com'),
    data: {action: 'accept', id: sent.id, version: connDoc.version},
  });
  assert.deepEqual(db.store.get('Horse_Profile/h1').instructorUids, ['uid-coach']);

  // Revoke removes uid-coach
  await call({
    auth: asUser('uid-owner', 'owner@example.com'),
    data: {action: 'revoke', id: sent.id, version: connDoc.version},
  });
  assert.deepEqual(db.store.get('Horse_Profile/h1').instructorUids, []);

  // Re-accept then transfer -> resets instructorUids to [] and updates ownerUid
  const sent2 = await call({
    auth: asUser('uid-coach', 'coach@example.com'),
    data: {action: 'send', kind: 'horse', horseId: 'h1', coachEmail: 'coach@example.com'},
  });
  const conn2 = (await db.doc(`CoachingConnections/${sent2.id}`).get()).data();
  await call({
    auth: asUser('uid-owner', 'owner@example.com'),
    data: {action: 'accept', id: sent2.id, version: conn2.version},
  });
  assert.deepEqual(db.store.get('Horse_Profile/h1').instructorUids, ['uid-coach']);

  const transfer = await call({
    auth: asUser('uid-owner', 'owner@example.com'),
    data: {action: 'sendTransfer', horseId: 'h1', recipientEmail: 'buyer@example.com'},
  });
  const tDoc = (await db.doc(`CoachingConnections/${transfer.id}`).get()).data();
  await call({
    auth: asUser('uid-buyer', 'buyer@example.com'),
    data: {action: 'accept', id: transfer.id, version: tDoc.version},
  });
  assert.equal(db.store.get('Horse_Profile/h1').ownerUid, 'uid-buyer');
  assert.deepEqual(db.store.get('Horse_Profile/h1').instructorUids, []);
});

test('backfillProfilePrivacy is dry-run by default and idempotent on apply', async () => {
  const db = createMockDb({
    'Rider_Profile/r_owner': {
      email: 'owner@example.com',
      name: 'Owner',
      notes: [{id: 'n1', name: 'Private'}],
    },
    'Horse_Profile/h_pub': {
      id: 'h_pub',
      name: 'Public Horse',
      currentOwnerId: 'owner@example.com',
      isPublic: true,
      archiveStatus: 'active',
      notes: [{id: 'hn1', name: 'Private horse note'}],
    },
    'Horse_Profile/h_priv': {
      id: 'h_priv',
      name: 'Private Horse',
      currentOwnerId: 'owner@example.com',
      isPublic: false,
      instructors: [{id: 'legacy-trainer@example.com', name: 'Legacy Trainer'}],
    },
    'Public_Horse_Profile/h_stale': {id: 'h_stale', name: 'Stale'},
    'CoachingConnections/c1': {
      kind: 'horse',
      horseId: 'h_pub',
      learner: 'owner@example.com',
      coachUid: 'uid-coach',
      status: 'accepted',
    },
    'CoachingConnections/c2': {
      kind: 'rider',
      learner: 'owner@example.com',
      coachUid: 'uid-coach',
      status: 'accepted',
    },
  });
  const auth = {
    async getUserByEmail(email) {
      if (email === 'owner@example.com') return {uid: 'uid-owner'};
      if (email === 'legacy-trainer@example.com') return {uid: 'uid-legacy'};
      return null;
    },
  };

  // Dry run does not write
  const dry = await backfillProfilePrivacy(db, {apply: false, auth});
  assert.equal(dry.apply, false);
  assert.equal(dry.ridersUpdated, 1);
  assert.equal(dry.horsesUpdated, 2);
  assert.equal(dry.publicHorsesDeleted, 1);
  assert.equal(db.store.has('Public_Rider_Profile/r_owner'), false);

  // Apply writes projections and authorization fields
  const applied = await backfillProfilePrivacy(db, {apply: true, auth});
  assert.equal(applied.apply, true);
  assert.equal(db.store.get('Rider_Profile/r_owner').ownerUid, 'uid-owner');
  assert.deepEqual(db.store.get('Rider_Profile/r_owner').instructorUids, ['uid-coach']);
  assert.deepEqual(db.store.get('Horse_Profile/h_pub').instructorUids, ['uid-coach']);
  assert.deepEqual(db.store.get('Horse_Profile/h_priv').instructorUids, ['uid-legacy']);
  assert.equal(applied.legacyInstructorsResolved, 1);
  assert.equal(db.store.get('Public_Rider_Profile/r_owner').notes, undefined);
  assert.equal(db.store.get('Public_Horse_Profile/h_pub').notes, undefined);
  assert.equal(db.store.has('Public_Horse_Profile/h_priv'), false);
  assert.equal(db.store.has('Public_Horse_Profile/h_stale'), false);

  // Second run is idempotent (0 doc updates, 0 deletes)
  const second = await backfillProfilePrivacy(db, {apply: true, auth});
  assert.equal(second.ridersUpdated, 0);
  assert.equal(second.horsesUpdated, 0);
  assert.equal(second.publicHorsesDeleted, 0);
});
