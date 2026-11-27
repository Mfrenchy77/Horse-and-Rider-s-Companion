/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const admin = require('firebase-admin');
const {submitSuggestionHandler, reviewSuggestionHandler} = require('../suggestions');
const {saveCurriculumDraftHandler} = require('../curriculum_drafts');
const {
  PUBLIC_COLLECTION,
  PUBLIC_ACTIVE_DOC_ID,
  META_COLLECTION,
  META_DOC_ID,
  publishCurriculumDraftHandler,
  rollbackCurriculumRevisionHandler,
} = require('../curriculum_revisions');
const {exportCurriculumFromFirestore} = require('../../tool/export_curriculum_v2');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-horse-rules';
if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();

function loadRealCurriculum() {
  const v2Dir = path.resolve(__dirname, '../../curriculum/v2');
  const families = JSON.parse(fs.readFileSync(path.join(v2Dir, 'families.json'), 'utf8'));
  const files = [
    'skills_rider_husbandry.json',
    'skills_rider_in_hand.json',
    'skills_rider_mounted.json',
    'skills_rider_theory.json',
    'skills_horse_in_hand.json',
    'skills_horse_mounted.json',
  ];
  const skills = [];
  for (const f of files) {
    skills.push(...JSON.parse(fs.readFileSync(path.join(v2Dir, f), 'utf8')));
  }
  return {families, skills};
}

async function main() {
  const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const clearRes = await fetch(
      `http://${firestoreHost}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
      {method: 'DELETE'},
  );
  assert.equal(clearRes.status, 200, 'Emulator Firestore reset must succeed');

  const {families, skills} = loadRealCurriculum();
  const riderAuth = {
    uid: 'e2e-rider-1',
    token: {email: 'jane@example.com', name: 'Jane Smith', email_verified: true},
  };
  const noConsentRiderAuth = {
    uid: 'e2e-rider-2',
    token: {email: 'anon@example.com', name: 'Anon Rider', email_verified: true},
  };
  const adminAuth = {
    uid: 'e2e-admin-1',
    token: {email: 'admin@example.com', name: 'App Admin', email_verified: true, admin: true},
  };

  // Seed existing rider progress and instructor verification to prove preservation end-to-end.
  const progressRef = db.doc('Rider_Profile/jane@example.com/SkillProgress/rider.mounted.shoulder_in');
  const verifRef = db.doc('Rider_Profile/jane@example.com/SkillVerifications/rider.mounted.shoulder_in');
  await progressRef.set({
    skillId: 'rider.mounted.shoulder_in',
    subject: 'rider',
    schemaVersion: 2,
    levels: {intermediate: {state: 'PROFICIENT', updatedByUid: 'e2e-rider-1'}},
  });
  await verifRef.set({
    skillId: 'rider.mounted.shoulder_in',
    levels: {intermediate: {verifiedState: 'PROFICIENT', verifiedByName: 'Coach', standardVersion: 1}},
  });

  const submitSuggestion = submitSuggestionHandler(db);
  const reviewSuggestion = reviewSuggestionHandler(db);
  const saveDraft = saveCurriculumDraftHandler(db);
  const publish = publishCurriculumDraftHandler(db, {publishingEnabled: true, chunkByteLimit: 64 * 1024});
  const rollback = rollbackCurriculumRevisionHandler(db, {publishingEnabled: true, chunkByteLimit: 64 * 1024});

  // Seed production-like baseline: ONLY SkillFamilies (33) and SkillsV2 (79),
  // with NO SkillTreeCurriculumPublic/active and NO SkillTreeCurriculumMeta/current.
  const seedBatch = db.batch();
  for (const f of families) {
    seedBatch.set(db.collection('SkillFamilies').doc(f.id), f);
  }
  for (const s of skills) {
    seedBatch.set(db.collection('SkillsV2').doc(s.id), s);
  }
  await seedBatch.commit();

  // Verify pre-activation read compatibility (legacy fallback when active pointer absent).
  const preActiveDoc = await db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID).get();
  assert.equal(preActiveDoc.exists, false);
  const preExport = await exportCurriculumFromFirestore(db, {
    outDir: os.tmpdir(),
    write: false,
  });
  assert.equal(preExport.source, 'legacy_collections');
  assert.equal(preExport.familyCount, 33);
  assert.equal(preExport.skillCount, 79);

  // Initial revision creation from pre-versioned production baseline:
  // First simulate interruption before activation -> SkillTreeCurriculumPublic/active MUST stay absent!
  const initSkills = structuredClone(skills);
  initSkills[0].summary = `${initSkills[0].summary} (Initial revision baseline)`;
  await saveDraft({auth: adminAuth, data: {families, skills: initSkills, note: 'Initial revision'}});
  const interruptedInit = publishCurriculumDraftHandler(db, {
    publishingEnabled: true,
    chunkByteLimit: 64 * 1024,
    onBeforeActivate: async () => {
      throw new Error('Simulated pre-activation interruption on initial revision');
    },
  });
  await assert.rejects(() => interruptedInit({auth: adminAuth, data: {notes: 'Initial rev 1'}}));
  assert.equal(
      (await db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID).get()).exists,
      false,
      'No partial initial revision may become publicly visible',
  );

  // Resume initial revision -> atomically creates rev_000001 preserving all 33 families, 79 skills, and progress.
  const rev1 = await publish({auth: adminAuth, data: {resumeFailedPublication: true}});
  assert.equal(rev1.resumed, true);
  assert.equal(rev1.revision.id, 'rev_000001');
  assert.equal(rev1.revision.familyCount, 33);
  assert.equal(rev1.revision.skillCount, 79);
  assert.equal((await progressRef.get()).data().levels.intermediate.state, 'PROFICIENT');
  assert.equal((await verifRef.get()).data().levels.intermediate.standardVersion, 1);

  // 1. Community member submits suggestion with creditConsent: true (and another without consent).
  const {suggestion} = await submitSuggestion({
    auth: riderAuth,
    data: {
      contributionCategory: 'component_or_example',
      subject: 'rider',
      realm: 'Mounted',
      targetSkillId: 'rider.mounted.shoulder_in',
      targetSkillName: 'Shoulder-In',
      targetLevel: 'intermediate',
      title: 'Add clear outside rein half-halt cue',
      description: 'Clarify supporting the outside shoulder before asking for angle.',
      creditConsent: true,
    },
  });
  assert.equal(suggestion.creditConsent, true);

  const {suggestion: noConsentSug} = await submitSuggestion({
    auth: noConsentRiderAuth,
    data: {
      contributionCategory: 'safety_or_wording_correction',
      subject: 'rider',
      realm: 'Mounted',
      targetSkillId: 'rider.mounted.shoulder_in',
      title: 'Private suggestion without credit',
      description: 'Helpful wording tweak without public recognition.',
    },
  });
  assert.equal(noConsentSug.creditConsent, false);

  // 2. Unauthorized publish is rejected; missing attribution consent is rejected.
  await assert.rejects(
      () => publish({auth: riderAuth, data: {}}),
      (err) => err.code === 'permission-denied',
  );
  await assert.rejects(
      () => reviewSuggestion({
        auth: adminAuth,
        data: {suggestionId: noConsentSug.id, status: 'incorporated', grantPublicCredit: true},
      }),
      (err) => err.code === 'failed-precondition',
  );

  // 3. Administrator incorporates suggestion into draft (never auto-published) & marks incorporated + credit.
  const draftSkills = structuredClone(skills);
  const target = draftSkills.find((s) => s.id === 'rider.mounted.shoulder_in');
  target.levels.intermediate.proficient =
    `${target.levels.intermediate.proficient} Supports outside shoulder before asking for angle.`;
  target.levels.intermediate.standardVersion = 2;

  await saveDraft({
    auth: adminAuth,
    data: {families, skills: draftSkills, note: `Incorporated ${suggestion.id}`},
  });
  // Active revision is STILL rev_000001 before explicit publish!
  assert.equal(
      (await db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID).get()).data().activeRevisionId,
      'rev_000001',
  );

  const reviewed = await reviewSuggestion({
    auth: adminAuth,
    data: {
      suggestionId: suggestion.id,
      status: 'incorporated',
      grantPublicCredit: true,
      publicResolutionNote: 'Thank you! Incorporated into the upcoming curriculum update.',
    },
  });
  assert.equal(reviewed.suggestion.status, 'incorporated');
  assert.equal(reviewed.suggestion.creditGranted, true);

  // Public contributors doc has ONLY display name — never email, UID, or suggestion text.
  const contribDoc = (await db.collection(PUBLIC_COLLECTION).doc('contributors').get()).data();
  assert.deepEqual(contribDoc.names, ['Jane Smith']);
  assert.equal(JSON.stringify(contribDoc).includes('jane@example.com'), false);
  assert.equal(JSON.stringify(contribDoc).includes('e2e-rider-1'), false);

  // 4-8. Publish rev_000002 -> atomic active pointer switches to rev_000002.
  const rev2 = await publish({auth: adminAuth, data: {notes: 'Published community shoulder-in update'}});
  assert.equal(rev2.revision.id, 'rev_000002');
  assert.equal(
      (await db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID).get()).data().activeRevisionId,
      'rev_000002',
  );

  // 9. Existing progress and instructor verifications remain intact.
  assert.equal((await progressRef.get()).data().levels.intermediate.state, 'PROFICIENT');
  assert.equal((await verifRef.get()).data().levels.intermediate.standardVersion, 1);

  // 10. CLI Export produces verified, deterministic files matching curriculum/v2/*.json structure.
  const tmpExportDir = fs.mkdtempSync(path.join(os.tmpdir(), 'hrc-e2e-export-'));
  try {
    const exported = await exportCurriculumFromFirestore(db, {
      outDir: tmpExportDir,
      write: true,
    });
    assert.equal(exported.source, 'active_revision');
    assert.equal(exported.revisionId, 'rev_000002');
    assert.equal(exported.familyCount, 33);
    assert.equal(exported.skillCount, 79);
    assert.equal(exported.changedCount, 7);
    const exportedMounted = JSON.parse(
        fs.readFileSync(path.join(tmpExportDir, 'skills_rider_mounted.json'), 'utf8'),
    );
    const exportedShoulderIn = exportedMounted.find((s) => s.id === 'rider.mounted.shoulder_in');
    assert.equal(exportedShoulderIn.levels.intermediate.standardVersion, 2);
  } finally {
    fs.rmSync(tmpExportDir, {recursive: true, force: true});
  }

  // 11-12. Rollback to rev_000001 creates forward rev_000003 and preserves history + progress.
  const rev3 = await rollback({
    auth: adminAuth,
    data: {targetRevisionId: 'rev_000001', notes: 'E2E rollback verification'},
  });
  assert.equal(rev3.revision.id, 'rev_000003');
  assert.equal(rev3.revision.kind, 'rollback');
  assert.equal(
      (await db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID).get()).data().activeRevisionId,
      'rev_000003',
  );
  assert.equal((await db.collection(META_COLLECTION).doc(META_DOC_ID).get()).data().publicationState, 'idle');
  assert.equal((await progressRef.get()).data().levels.intermediate.state, 'PROFICIENT');
  assert.equal((await verifRef.get()).data().levels.intermediate.standardVersion, 1);

  console.log('ALL PHASE 2C E2E EMULATOR ASSERTIONS PASSED');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
