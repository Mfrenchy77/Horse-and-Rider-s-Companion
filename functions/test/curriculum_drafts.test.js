/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
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
      async get() {
        const prefix = `${colPath}/`;
        const docs = [];
        for (const [docPath, value] of store.entries()) {
          if (!docPath.startsWith(prefix)) continue;
          const rest = docPath.slice(prefix.length);
          if (rest.includes('/')) continue;
          docs.push({
            id: rest,
            data: () => structuredClone(value),
          });
        }
        return {docs};
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

test('saveCurriculumDraftHandler validates V2 schema and references', async () => {
  const db = createFakeFirestore();
  const handler = saveCurriculumDraftHandler(db);
  const adminAuth = {uid: 'admin1', token: {email_verified: true, admin: true, name: 'Admin'}};

  const badIdPayload = validDraftPayload();
  badIdPayload.skills[0].id = 'bad id with spaces';
  await assert.rejects(
      () => handler({auth: adminAuth, data: badIdPayload}),
      (err) => err.code === 'invalid-argument',
  );

  const missingFamilyPayload = validDraftPayload();
  missingFamilyPayload.skills[0].familyId = 'rider.mounted.does_not_exist';
  await assert.rejects(
      () => handler({auth: adminAuth, data: missingFamilyPayload}),
      (err) => err.code === 'invalid-argument' && err.message.includes('unknown familyId'),
  );
});

test('invalid draft never overwrites an existing valid saved draft', async () => {
  const db = createFakeFirestore();
  const fixedNow = new Date('2026-11-23T06:00:00.000Z');
  let seq = 0;
  const saveHandler = saveCurriculumDraftHandler(db, {
    now: () => fixedNow,
    uuid: () => `evt_${++seq}`,
  });
  const adminAuth = {uid: 'admin1', token: {email_verified: true, admin: true, name: 'Admin'}};

  await saveHandler({auth: adminAuth, data: validDraftPayload()});
  const draftKey = `${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`;
  const savedBefore = structuredClone(db._store.get(draftKey));

  const invalidPayload = validDraftPayload();
  invalidPayload.skills[0].relatedSkills = [{skillId: 'nonexistent.skill', relation: 'foundation'}];

  await assert.rejects(
      () => saveHandler({auth: adminAuth, data: invalidPayload}),
      (err) => err.code === 'invalid-argument',
  );

  assert.deepEqual(db._store.get(draftKey), savedBefore);
  assert.equal(db._store.has(`${draftKey}/AuditEvents/evt_2`), false);
});

test('saveCurriculumDraftHandler enforces published skill and level preservation and preserves metadata', async () => {
  const db = createFakeFirestore();
  const publishedSkill = structuredClone(validDraftPayload().skills[0]);
  publishedSkill.availableLevels = ['introductory', 'intermediate'];
  publishedSkill.levels.intermediate = {
    overview: 'Int overview.',
    components: [],
    learning: 'Int learning.',
    proficient: 'Int proficient.',
    standardVersion: 1,
  };
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', publishedSkill);
  db._store.set('SkillFamilies/rider.mounted.balance', validDraftPayload().families[0]);

  const saveHandler = saveCurriculumDraftHandler(db);
  const adminAuth = {uid: 'admin1', token: {email_verified: true, admin: true, name: 'Admin'}};

  // Deleting a published difficulty level is rejected.
  const dropLevelPayload = validDraftPayload();
  await assert.rejects(
      () => saveHandler({auth: adminAuth, data: dropLevelPayload}),
      (err) => err.code === 'invalid-argument' && err.message.includes('cannot be deleted'),
  );

  // Deleting a published skill ID is rejected.
  const dropSkillPayload = validDraftPayload();
  dropSkillPayload.skills = [];
  await assert.rejects(
      () => saveHandler({auth: adminAuth, data: dropSkillPayload}),
      (err) => err.code === 'invalid-argument' && err.message.includes('cannot be deleted'),
  );

  // Valid retirement with replacedBy and metadata preserved succeeds.
  const retirePayload = {
    families: validDraftPayload().families,
    skills: [
      {
        ...publishedSkill,
        status: 'retired',
        replacedBy: 'rider.mounted.replacement_skill',
        updatedBy: 'admin1',
        levels: {
          ...publishedSkill.levels,
          introductory: {
            ...publishedSkill.levels.introductory,
            standardVersion: 2,
            standardUpdatedAt: '2026-11-23T05:00:00.000Z',
          },
        },
      },
      {
        ...validDraftPayload().skills[0],
        id: 'rider.mounted.replacement_skill',
        name: 'Replacement Pelvis Skill',
        legacyIds: [],
      },
    ],
  };

  const saved = await saveHandler({auth: adminAuth, data: retirePayload});
  const retired = saved.draft.skills.find((s) => s.id === 'rider.mounted.neutral_pelvis');
  assert.equal(retired.replacedBy, 'rider.mounted.replacement_skill');
  assert.equal(retired.updatedBy, 'admin1');
  assert.equal(retired.levels.introductory.standardVersion, 2);
  assert.equal(retired.levels.introductory.standardUpdatedAt, '2026-11-23T05:00:00.000Z');
});

test('verified admin can save and discard draft without touching published collections', async () => {
  const db = createFakeFirestore();
  const publishedSkill = structuredClone(validDraftPayload().skills[0]);
  publishedSkill.name = 'Published';
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', publishedSkill);
  db._store.set('SkillFamilies/rider.mounted.balance', {
    ...validDraftPayload().families[0],
    name: 'Published Family',
  });

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
