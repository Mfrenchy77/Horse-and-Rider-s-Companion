/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  REVISIONS_COLLECTION,
  CHUNKS_SUBCOLLECTION,
  META_COLLECTION,
  META_DOC_ID,
  PUBLIC_COLLECTION,
  PUBLIC_ACTIVE_DOC_ID,
  computeCurriculumChecksum,
  splitIntoChunks,
  reassembleAndVerifySnapshot,
  computeCurriculumDiff,
  publishCurriculumDraftHandler,
  abortFailedPublicationHandler,
  rollbackCurriculumRevisionHandler,
} = require('../curriculum_revisions');
const {DRAFTS_COLLECTION, DEFAULT_DRAFT_ID} = require('../curriculum_drafts');

function createFakeFirestore() {
  const store = new Map();

  function applySet(path, data, opts) {
    if (opts && opts.merge && store.has(path)) {
      store.set(path, {...structuredClone(store.get(path)), ...structuredClone(data)});
    } else {
      store.set(path, structuredClone(data));
    }
  }

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
          id: path.split('/').pop(),
          exists: value !== undefined,
          data: () => (value === undefined ? undefined : structuredClone(value)),
        };
      },
      async set(data, opts) {
        applySet(path, data, opts);
      },
      async delete() {
        store.delete(path);
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
        set(ref, data, opts) {
          ops.push(() => applySet(ref.path, data, opts));
        },
        delete(ref) {
          ops.push(() => store.delete(ref.path));
        },
        async commit() {
          for (const op of ops) op();
        },
      };
    },
    async runTransaction(fn) {
      const pending = [];
      const tx = {
        async get(ref) {
          return ref.get();
        },
        set(ref, data, opts) {
          pending.push(() => applySet(ref.path, data, opts));
        },
        delete(ref) {
          pending.push(() => store.delete(ref.path));
        },
      };
      const result = await fn(tx);
      for (const op of pending) op();
      return result;
    },
  };
}

function makeFamily(overrides = {}) {
  return {
    id: 'rider.mounted.balance',
    schemaVersion: 2,
    subject: 'rider',
    realm: 'Mounted',
    name: 'Mounted Balance',
    description: 'Core rider balance in the saddle.',
    sortOrder: 10,
    ...overrides,
  };
}

function makeSkill(overrides = {}) {
  return {
    id: 'rider.mounted.neutral_pelvis',
    schemaVersion: 2,
    status: 'active',
    subject: 'rider',
    realm: 'Mounted',
    familyId: 'rider.mounted.balance',
    name: 'Neutral Pelvis',
    aliases: ['Balanced Seat'],
    summary: 'Maintains a neutral pelvis at halt and walk.',
    purpose: 'Supports independent seat and leg aids.',
    safety: ['Check girth before mounting.'],
    availableLevels: ['introductory'],
    levels: {
      introductory: {
        overview: 'Finds neutral alignment at halt and walk.',
        components: [{title: 'Seat bones', description: 'Even weight on seat bones.'}],
        learning: 'Finds alignment at halt.',
        proficient: 'Maintains alignment through walk transitions.',
        standardVersion: 1,
      },
    },
    relatedSkills: [],
    legacyIds: ['legacy_seat_1'],
    sortOrder: 10,
    ...overrides,
  };
}

const ADMIN_AUTH = {
  uid: 'admin-1',
  token: {email_verified: true, admin: true, name: 'Admin One'},
};

test('deterministic checksum and multi-chunk snapshot integrity verification', () => {
  const f1 = makeFamily({id: 'rider.mounted.balance'});
  const f2 = makeFamily({id: 'rider.mounted.gaits', name: 'Gaits'});
  const s1 = makeSkill({id: 'rider.mounted.neutral_pelvis'});
  const s2 = makeSkill({id: 'rider.mounted.walk', familyId: 'rider.mounted.gaits', name: 'Walk', legacyIds: []});

  const c1 = computeCurriculumChecksum({families: [f1, f2], skills: [s1, s2]});
  const c2 = computeCurriculumChecksum({families: [f2, f1], skills: [s2, s1]});
  assert.equal(c1.checksum, c2.checksum);

  // Split into multiple small chunks and reassemble.
  const chunks = splitIntoChunks(c1.serialized, 1024);
  assert.ok(chunks.length >= 2);
  const header = {id: 'rev_000001', chunkCount: chunks.length, checksum: c1.checksum};
  const restored = reassembleAndVerifySnapshot(header, [...chunks].reverse());
  assert.equal(restored.checksum, c1.checksum);
  assert.equal(restored.skills.length, 2);

  // Tampering with a chunk fails checksum verification.
  const tampered = structuredClone(chunks);
  tampered[0].payload = `${tampered[0].payload} `;
  assert.throws(
      () => reassembleAndVerifySnapshot(header, tampered),
      (err) => err.code === 'data-loss',
  );
});

test('publishCurriculumDraftHandler enforces admin-only auth and publishingEnabled gate', async () => {
  const db = createFakeFirestore();
  const disabledHandler = publishCurriculumDraftHandler(db, {publishingEnabled: false});
  await assert.rejects(
      () => disabledHandler({auth: ADMIN_AUTH, data: {}}),
      (err) => err.code === 'failed-precondition' && err.message.includes('disabled'),
  );

  const handler = publishCurriculumDraftHandler(db, {publishingEnabled: true});
  await assert.rejects(
      () => handler({auth: null, data: {}}),
      (err) => err.code === 'unauthenticated',
  );
  await assert.rejects(
      () => handler({auth: {uid: 'u1', token: {email_verified: false, admin: true}}, data: {}}),
      (err) => err.code === 'failed-precondition',
  );
  await assert.rejects(
      () => handler({auth: {uid: 'm1', token: {email_verified: true, moderator: true}}, data: {}}),
      (err) => err.code === 'permission-denied',
  );
  await assert.rejects(
      () => handler({auth: {uid: 'u2', token: {email_verified: true}}, data: {}}),
      (err) => err.code === 'permission-denied',
  );
});

test('publish creates immutable chunked revision, preserves user progress, and blocks duplicate/no-op publishes', async () => {
  const db = createFakeFirestore();
  const baseFamily = makeFamily();
  const baseSkill = makeSkill();
  db._store.set('SkillFamilies/rider.mounted.balance', baseFamily);
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', baseSkill);
  // Existing rider progress and instructor verification must remain untouched.
  const progressKey = 'Rider_Profile/rider@example.com/SkillProgress/rider.mounted.neutral_pelvis';
  const verifKey = 'Rider_Profile/rider@example.com/SkillVerifications/rider.mounted.neutral_pelvis';
  db._store.set(progressKey, {skillId: 'rider.mounted.neutral_pelvis', levels: {introductory: {state: 'PROFICIENT'}}});
  db._store.set(verifKey, {skillId: 'rider.mounted.neutral_pelvis', levels: {introductory: {standardVersion: 1}}});

  const revisedSkill = makeSkill({
    name: 'Neutral Pelvis & Seat Alignment',
    levels: {
      introductory: {
        ...baseSkill.levels.introductory,
        proficient: 'Independently maintains neutral alignment through walk transitions.',
        standardVersion: 2,
      },
    },
  });
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [revisedSkill],
    published: false,
  });

  const fixedNow = new Date('2026-11-24T18:00:00.000Z');
  const handler = publishCurriculumDraftHandler(db, {
    now: () => fixedNow,
    publishingEnabled: true,
    chunkByteLimit: 1024,
  });

  const res = await handler({auth: ADMIN_AUTH, data: {notes: 'Clarified neutral pelvis standard'}});
  assert.equal(res.revision.id, 'rev_000001');
  assert.equal(res.revision.revisionNumber, 1);
  assert.equal(res.revision.status, 'completed');
  assert.equal(res.revision.immutable, true);
  assert.equal(res.revision.notes, 'Clarified neutral pelvis standard');
  assert.deepEqual(res.revision.summary.modifiedSkillIds, ['rider.mounted.neutral_pelvis']);
  assert.equal(res.revision.summary.revisedStandards[0].toVersion, 2);

  // Live SkillsV2 updated, draft cleared, progress/verifications untouched.
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').name, 'Neutral Pelvis & Seat Alignment');
  assert.equal(db._store.has(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`), false);
  assert.equal(db._store.get(progressKey).levels.introductory.state, 'PROFICIENT');
  assert.equal(db._store.get(verifKey).levels.introductory.standardVersion, 1);
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).currentRevisionId, 'rev_000001');

  // Re-publishing identical content as a draft is rejected as a no-op.
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [revisedSkill],
    published: false,
  });
  await assert.rejects(
      () => handler({auth: ADMIN_AUTH, data: {}}),
      (err) => err.code === 'failed-precondition' && err.message.includes('No curriculum changes'),
  );
});

test('concurrent admin lock collision and invalid draft release lock safely', async () => {
  const db = createFakeFirestore();
  const baseFamily = makeFamily();
  const baseSkill = makeSkill();
  db._store.set('SkillFamilies/rider.mounted.balance', baseFamily);
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', baseSkill);

  // Active lock held by admin-1 blocks admin-2.
  const now = new Date('2026-11-24T18:00:00.000Z');
  db._store.set(`${META_COLLECTION}/${META_DOC_ID}`, {
    publicationState: 'applying',
    activePublicationId: 'rev_000001',
    lockOwnerUid: 'admin-1',
    lockOwnerName: 'Admin One',
    lockExpiresAt: new Date(now.getTime() + 60000),
    currentRevisionNumber: 0,
  });
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [makeSkill({name: 'Edited'})],
  });

  const handler = publishCurriculumDraftHandler(db, {now: () => now, publishingEnabled: true});
  const admin2 = {uid: 'admin-2', token: {email_verified: true, admin: true, name: 'Admin Two'}};
  await assert.rejects(
      () => handler({auth: admin2, data: {}}),
      (err) => err.code === 'aborted' && err.message.includes('already in progress'),
  );

  // Clear lock and attempt to publish an invalid draft (deletes published skill ID).
  db._store.set(`${META_COLLECTION}/${META_DOC_ID}`, {
    publicationState: 'idle',
    currentRevisionNumber: 0,
  });
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [],
  });
  await assert.rejects(
      () => handler({auth: ADMIN_AUTH, data: {}}),
      (err) => err.code === 'invalid-argument' && err.message.includes('cannot be deleted'),
  );
  // Lock is cleanly released back to idle and no revision was marked completed.
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).publicationState, 'idle');
  assert.equal(db._store.has(`${REVISIONS_COLLECTION}/rev_000001`), false);
});

test('atomic pointer stays on previous revision on staging/pre-activation failure and supports resume or abort', async () => {
  const db = createFakeFirestore();
  const baseFamily = makeFamily();
  const baseSkill = makeSkill();
  db._store.set('SkillFamilies/rider.mounted.balance', baseFamily);
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', baseSkill);

  // Publish baseline rev_000001 first so SkillTreeCurriculumPublic/active points to rev_000001.
  const now = new Date('2026-11-24T18:05:00.000Z');
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [makeSkill({name: 'Baseline Published'})],
  });
  const normalHandler = publishCurriculumDraftHandler(db, {now: () => now, publishingEnabled: true});
  const rev1 = await normalHandler({auth: ADMIN_AUTH, data: {notes: 'Baseline', requestId: 'req-rev-1'}});
  assert.equal(rev1.revision.id, 'rev_000001');
  assert.equal(db._store.get(`${PUBLIC_COLLECTION}/${PUBLIC_ACTIVE_DOC_ID}`).activeRevisionId, 'rev_000001');

  // Duplicate requestId returns idempotent replay without creating rev_000002.
  const replay = await normalHandler({auth: ADMIN_AUTH, data: {notes: 'Baseline', requestId: 'req-rev-1'}});
  assert.equal(replay.idempotentReplay, true);
  assert.equal(replay.revision.id, 'rev_000001');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).currentRevisionNumber, 1);

  // Stage 2 failure (staging chunk write fails) leaves rev_000001 active and allows clean abort.
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [makeSkill({name: 'Staged Failure'})],
  });
  const stagingFailHandler = publishCurriculumDraftHandler(db, {
    now: () => now,
    publishingEnabled: true,
    commitBatch: async (_batch, _idx, _count, stage) => {
      if (stage === 'staging') {
        throw new Error('Simulated staging write failure');
      }
      await _batch.commit();
    },
  });
  await assert.rejects(
      () => stagingFailHandler({auth: ADMIN_AUTH, data: {notes: 'Will fail staging'}}),
      (err) => err.code === 'internal' && err.message.includes('staging'),
  );
  assert.equal(db._store.get(`${PUBLIC_COLLECTION}/${PUBLIC_ACTIVE_DOC_ID}`).activeRevisionId, 'rev_000001');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).failedStage, 'staging');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).publicationState, 'failed');

  // Abort unpublished failed attempt -> deletes staged rev_000002 and keeps rev_000001 active.
  const abortHandler = abortFailedPublicationHandler(db, {now: () => now, publishingEnabled: true});
  const abortRes = await abortHandler({auth: ADMIN_AUTH, data: {}});
  assert.equal(abortRes.aborted, true);
  assert.equal(abortRes.revisionId, 'rev_000002');
  assert.equal(db._store.has(`${REVISIONS_COLLECTION}/rev_000002`), false);
  assert.equal(db._store.get(`${PUBLIC_COLLECTION}/${PUBLIC_ACTIVE_DOC_ID}`).activeRevisionId, 'rev_000001');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).publicationState, 'idle');

  // Pre-activation interruption (after chunks are written & verified, before pointer flip).
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [makeSkill({name: 'Updated After Recovery'})],
  });
  const preActivateFailHandler = publishCurriculumDraftHandler(db, {
    now: () => now,
    publishingEnabled: true,
    onBeforeActivate: async () => {
      throw new Error('Simulated crash before atomic activation');
    },
  });
  await assert.rejects(
      () => preActivateFailHandler({auth: ADMIN_AUTH, data: {notes: 'Interrupted before activation'}}),
      (err) => err.code === 'internal',
  );
  assert.equal(db._store.get(`${PUBLIC_COLLECTION}/${PUBLIC_ACTIVE_DOC_ID}`).activeRevisionId, 'rev_000001');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).failedStage, 'activating');

  // Starting a brand-new publish without recovery is refused.
  await assert.rejects(
      () => normalHandler({auth: ADMIN_AUTH, data: {}}),
      (err) => err.code === 'failed-precondition' && err.message.includes('interrupted'),
  );

  // Resuming from the verified snapshot activates rev_000002 atomically!
  const recovered = await normalHandler({
    auth: ADMIN_AUTH,
    data: {resumeFailedPublication: true},
  });
  assert.equal(recovered.resumed, true);
  assert.equal(recovered.revision.id, 'rev_000002');
  assert.equal(recovered.revision.status, 'completed');
  assert.equal(recovered.revision.immutable, true);
  assert.equal(db._store.get(`${PUBLIC_COLLECTION}/${PUBLIC_ACTIVE_DOC_ID}`).activeRevisionId, 'rev_000002');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).publicationState, 'idle');
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').name, 'Updated After Recovery');
});

test('syncing_legacy interruption refuses discard (already active) and completes idempotently on resume', async () => {
  const db = createFakeFirestore();
  const baseFamily = makeFamily();
  const baseSkill = makeSkill();
  db._store.set('SkillFamilies/rider.mounted.balance', baseFamily);
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', baseSkill);
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [makeSkill({name: 'Live After Legacy Resume'})],
  });

  const now = new Date('2026-11-24T18:10:00.000Z');
  const legacyFailHandler = publishCurriculumDraftHandler(db, {
    now: () => now,
    publishingEnabled: true,
    commitBatch: async (batch, _idx, _count, stage) => {
      if (stage === 'syncing_legacy') {
        throw new Error('Simulated legacy mirror timeout');
      }
      await batch.commit();
    },
  });

  await assert.rejects(
      () => legacyFailHandler({auth: ADMIN_AUTH, data: {notes: 'Legacy sync hiccup'}}),
      (err) => err.code === 'internal' && err.message.includes('already') || err.message.includes('active'),
  );

  // Public pointer IS already active on rev_000001!
  assert.equal(db._store.get(`${PUBLIC_COLLECTION}/${PUBLIC_ACTIVE_DOC_ID}`).activeRevisionId, 'rev_000001');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).failedStage, 'syncing_legacy');

  // Discarding an already-active revision MUST be refused!
  const abortHandler = abortFailedPublicationHandler(db, {now: () => now, publishingEnabled: true});
  await assert.rejects(
      () => abortHandler({auth: ADMIN_AUTH, data: {}}),
      (err) => err.code === 'failed-precondition' && err.message.includes('already active'),
  );

  // Resuming finishes legacy mirror without creating rev_000002.
  const normalHandler = publishCurriculumDraftHandler(db, {now: () => now, publishingEnabled: true});
  const resumed = await normalHandler({auth: ADMIN_AUTH, data: {resumeFailedPublication: true}});
  assert.equal(resumed.resumed, true);
  assert.equal(resumed.revision.id, 'rev_000001');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).publicationState, 'idle');
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).currentRevisionNumber, 1);
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').name, 'Live After Legacy Resume');
});

test('expired lease allows recovery and active lock blocks concurrent rollback', async () => {
  const db = createFakeFirestore();
  const baseFamily = makeFamily();
  const baseSkill = makeSkill();
  db._store.set('SkillFamilies/rider.mounted.balance', baseFamily);
  db._store.set('SkillsV2/rider.mounted.neutral_pelvis', baseSkill);
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [makeSkill({name: 'Rev 1'})],
  });

  const now = new Date('2026-11-24T18:20:00.000Z');
  const publish = publishCurriculumDraftHandler(db, {now: () => now, publishingEnabled: true});
  await publish({auth: ADMIN_AUTH, data: {}});

  // Simulate an active lock blocking concurrent rollback.
  db._store.set(`${META_COLLECTION}/${META_DOC_ID}`, {
    ...db._store.get(`${META_COLLECTION}/${META_DOC_ID}`),
    publicationState: 'staging',
    activePublicationId: 'rev_000002',
    lockOwnerUid: 'admin-1',
    lockOwnerName: 'Admin One',
    lockExpiresAt: new Date(now.getTime() + 60000),
  });
  const rollback = rollbackCurriculumRevisionHandler(db, {now: () => now, publishingEnabled: true});
  await assert.rejects(
      () => rollback({auth: ADMIN_AUTH, data: {targetRevisionId: 'rev_000001'}}),
      (err) => err.code === 'aborted' && err.message.includes('already in progress'),
  );

  // Once the lease expires, abortFailedPublicationHandler can safely clear it.
  const afterExpiry = new Date(now.getTime() + 10 * 60 * 1000);
  const abortHandler = abortFailedPublicationHandler(db, {now: () => afterExpiry, publishingEnabled: true});
  const aborted = await abortHandler({auth: ADMIN_AUTH, data: {}});
  assert.equal(aborted.aborted, true);
  assert.equal(db._store.get(`${META_COLLECTION}/${META_DOC_ID}`).publicationState, 'idle');
});

test('rollback creates a new forward revision, bumps standardVersion, and refuses incompatible rollbacks', async () => {
  const db = createFakeFirestore();
  const baseFamily = makeFamily();
  const v1Skill = makeSkill({
    name: 'Neutral Pelvis v1',
    levels: {
      introductory: {
        overview: 'Overview v1.',
        components: [],
        learning: 'Learning v1.',
        proficient: 'Proficient v1.',
        standardVersion: 1,
      },
    },
  });

  // Publish revision 1 (baseline v1).
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [v1Skill],
  });
  const publish = publishCurriculumDraftHandler(db, {publishingEnabled: true});
  const rev1 = await publish({auth: ADMIN_AUTH, data: {notes: 'Initial publish'}});
  assert.equal(rev1.revision.id, 'rev_000001');

  // Publish revision 2 (changes name and proficient criteria to v2).
  const v2Skill = makeSkill({
    name: 'Neutral Pelvis v2',
    levels: {
      introductory: {
        overview: 'Overview v2.',
        components: [],
        learning: 'Learning v2.',
        proficient: 'Proficient v2.',
        standardVersion: 2,
      },
    },
  });
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [v2Skill],
  });
  const rev2 = await publish({auth: ADMIN_AUTH, data: {notes: 'v2 edit'}});
  assert.equal(rev2.revision.id, 'rev_000002');

  // Dry-run rollback to rev_000001 shows exact diff without mutating live data.
  const rollback = rollbackCurriculumRevisionHandler(db, {publishingEnabled: true});
  const dryRes = await rollback({
    auth: ADMIN_AUTH,
    data: {targetRevisionId: 'rev_000001', dryRun: true},
  });
  assert.equal(dryRes.dryRun, true);
  assert.deepEqual(dryRes.diff.modifiedSkillIds, ['rider.mounted.neutral_pelvis']);
  assert.equal(dryRes.diff.revisedStandards[0].fromVersion, 2);
  assert.equal(dryRes.diff.revisedStandards[0].toVersion, 3);
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').name, 'Neutral Pelvis v2');

  // Execute rollback -> creates rev_000003 (rev_000001 and rev_000002 remain immutable).
  const rev3 = await rollback({
    auth: ADMIN_AUTH,
    data: {targetRevisionId: 'rev_000001', notes: 'Revert wording to v1'},
  });
  assert.equal(rev3.revision.id, 'rev_000003');
  assert.equal(rev3.revision.kind, 'rollback');
  assert.equal(rev3.revision.rollbackOfRevisionId, 'rev_000001');
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').name, 'Neutral Pelvis v1');
  assert.equal(db._store.get('SkillsV2/rider.mounted.neutral_pelvis').levels.introductory.standardVersion, 3);
  assert.equal(db._store.get(`${REVISIONS_COLLECTION}/rev_000001`).immutable, true);
  assert.equal(db._store.get(`${REVISIONS_COLLECTION}/rev_000002`).immutable, true);

  // Now publish rev_000004 adding a new skill; rolling back to rev_000001 would delete that published skill
  // and MUST be refused!
  const newSkill = makeSkill({id: 'rider.mounted.second_skill', name: 'Second Skill', legacyIds: []});
  db._store.set(`${DRAFTS_COLLECTION}/${DEFAULT_DRAFT_ID}`, {
    families: [baseFamily],
    skills: [
      db._store.get('SkillsV2/rider.mounted.neutral_pelvis'),
      newSkill,
    ],
  });
  await publish({auth: ADMIN_AUTH, data: {notes: 'Added second skill'}});

  await assert.rejects(
      () => rollback({auth: ADMIN_AUTH, data: {targetRevisionId: 'rev_000001'}}),
      (err) => err.code === 'failed-precondition' && err.message.includes('cannot be deleted'),
  );

  // Verify revision chunks subcollection exists for all completed revisions.
  assert.ok(db._store.has(`${REVISIONS_COLLECTION}/rev_000001/${CHUNKS_SUBCOLLECTION}/0000`));
  assert.ok(db._store.has(`${REVISIONS_COLLECTION}/rev_000003/${CHUNKS_SUBCOLLECTION}/0000`));
  const diffCheck = computeCurriculumDiff(
      {families: [baseFamily], skills: [v1Skill]},
      {families: [baseFamily], skills: [v2Skill]},
  );
  assert.equal(diffCheck.hasChanges, true);
});
