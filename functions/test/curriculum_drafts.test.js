'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  DRAFTS_COLLECTION,
  DEFAULT_DRAFT_ID,
  saveCurriculumDraftHandler,
  discardCurriculumDraftHandler,
} = require('../curriculum_drafts');

function createFakeFirestore() {
  const store = new Map();

  function docRef(path) {
    return {
      path,
      id: path.split('/').pop(),
      collection(subName) {
        return collectionRef(`${path}/${subName}`);
      },
      async get() {
        const value = store.get(path);
        return {
          exists: value !== undefined,
          data: () => (value === undefined ? undefined : structuredClone(value)),
        };
      },
    };
  }

  function collectionRef(colPath) {
    return {
      doc(id) {
        return docRef(`${colPath}/${id}`);
      },
    };
  }

  return {
    _store: store,
    collection: collectionRef,
    batch() {
      const ops = [];
      return {
        set(ref, data) {
          ops.push(() => store.set(ref.path, structuredClone(data)));
        },
        delete(ref) {
          ops.push(() => store.delete(ref.path));
        },
        async commit() {
          for (const op of ops) op();
        },
      };
    },
  };
}

function validDraftPayload() {
  return {
    families: [
      {
        id: 'rider.mounted.balance',
        subject: 'rider',
        realm: 'Mounted',
        name: 'Mounted Balance',
        description: 'Core rider balance in the saddle.',
        sortOrder: 1,
        schemaVersion: 2,
      },
    ],
    skills: [
      {
        id: 'rider.mounted.neutral_pelvis',
        schemaVersion: 2,
        status: 'active',
        subject: 'rider',
        realm: 'Mounted',
        familyId: 'rider.mounted.balance',
        name: 'Neutral Pelvis',
        aliases: ['Balanced Seat'],
        summary: 'Maintain a neutral pelvis at the halt and walk.',
        purpose: 'Allows independent seat and leg aids.',
        safety: ['Check girth before mounting.'],
        availableLevels: ['introductory'],
        levels: {
          introductory: {
            overview: 'Find neutral alignment at halt and walk.',
            components: [
              {
                title: 'Seat bones',
                description: 'Feel even weight on both seat bones.',
              },
            ],
            learning: 'Finds alignment at halt.',
            proficient: 'Maintains alignment through walk transitions.',
            standardVersion: 1,
          },
        },
        relatedSkills: [],
        legacyIds: ['legacy_seat_1'],
        sortOrder: 1,
      },
    ],
    note: 'Updated neutral pelvis wording',
  };
}

test('saveCurriculumDraftHandler rejects unauthenticated, unverified, user, and moderator', async () => {
  const db = createFakeFirestore();
  const handler = saveCurriculumDraftHandler(db);
  const payload = validDraftPayload();

  await assert.rejects(
    () => handler({auth: null, data: payload}),
    (err) => err.code === 'unauthenticated',
  );
  await assert.rejects(
    () => handler({auth: {uid: 'u1', token: {email_verified: false, admin: true}}, data: payload}),
    (err) => err.code === 'failed-precondition',
  );
  await assert.rejects(
    () => handler({auth: {uid: 'u2', token: {email_verified: true}}, data: payload}),
    (err) => err.code === 'permission-denied',
  );
  await assert.rejects(
    () => handler({auth: {uid: 'm1', token: {email_verified: true, moderator: true}}, data: payload}),
    (err) => err.code === 'permission-denied',
  );
});

test('discardCurriculumDraftHandler rejects moderator and ordinary user', async () => {
  const db = createFakeFirestore();
  const handler = discardCurriculumDraftHandler(db);

  await assert.rejects(
    () => handler({auth: {uid: 'm1', token: {email_verified: true, moderator: true}}, data: {}}),
    (err) => err.code === 'permission-denied',
  );
  await assert.rejects(
    () => handler({auth: {uid: 'u1', token: {email_verified: true}}, data: {}}),
    (err) => err.code === 'permission-denied',
  );
});

test('saveCurriculumDraftHandler validates V2 schema', async () => {
  const db = createFakeFirestore();
  const handler = saveCurriculumDraftHandler(db);
  const adminAuth = {uid: 'admin1', token: {email_verified: true, admin: true, name: 'Admin'}};

  const badPayload = validDraftPayload();
  badPayload.skills[0].id = 'bad id with spaces';

  await assert.rejects(
    () => handler({auth: adminAuth, data: badPayload}),
    (err) => err.code === 'invalid-argument',
  );
});

test('verified admin can save and discard draft without touching published collections', async () => {
  const db = createFakeFirestore();
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', {name: 'Published'});
  db._store.set('SkillFamilies/rider.mounted.balance', {name: 'Published Family'});

  const fixedNow = new Date('2026-11-15T06:00:00.000Z');
  let seq = 0;
  const saveHandler = saveCurriculumDraftHandler(db, {
    now: () => fixedNow,
    uuid: () => `evt_${++seq}`,
  });
  const discardHandler = discardCurriculumDraftHandler(db, {
    now: () => fixedNow,
    uuid: () => `evt_${++seq}`,
  });
  const adminAuth = {
    uid: 'admin1',
    token: {email_verified: true, admin: true, name: 'Demo Admin'},
  };

  const saved = await saveHandler({auth: adminAuth, data: validDraftPayload()});
  assert.equal(saved.draft.published, false);
  assert.equal(saved.draft.families.length, 1);
  assert.equal(saved.draft.skills.length, 1);

  const draftKey = `${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`;
  assert.ok(db._store.has(draftKey));
  assert.equal(db._store.get(`${draftKey}/AuditEvents/evt_1`).type, 'draft_saved');
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').name, 'Published');
  assert.equal(db._store.get('SkillFamilies/rider.mounted.balance').name, 'Published Family');

  const discarded = await discardHandler({auth: adminAuth, data: {}});
  assert.equal(discarded.discarded, true);
  assert.equal(db._store.has(draftKey), false);
  assert.equal(db._store.get(`${draftKey}/AuditEvents/evt_2`).type, 'draft_discarded');
});
