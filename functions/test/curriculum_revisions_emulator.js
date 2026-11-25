/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');
const {saveCurriculumDraftHandler} = require('../curriculum_drafts');
const {
  REVISIONS_COLLECTION,
  CHUNKS_SUBCOLLECTION,
  META_COLLECTION,
  META_DOC_ID,
  publishCurriculumDraftHandler,
  rollbackCurriculumRevisionHandler,
} = require('../curriculum_revisions');

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
  const adminAuth = {
    uid: 'emu-admin-1',
    token: {email: 'admin@example.com', email_verified: true, admin: true, name: 'Emulator Admin'},
  };

  // Seed existing rider progress and verification to prove publishing never touches them.
  const progressRef = db.doc('Rider_Profile/emu-rider@example.com/SkillProgress/rider.mounted.shoulder_in');
  const verifRef = db.doc('Rider_Profile/emu-rider@example.com/SkillVerifications/rider.mounted.shoulder_in');
  await progressRef.set({
    skillId: 'rider.mounted.shoulder_in',
    subject: 'rider',
    schemaVersion: 2,
    levels: {intermediate: {state: 'PROFICIENT', updatedByUid: 'emu-rider'}},
  });
  await verifRef.set({
    skillId: 'rider.mounted.shoulder_in',
    levels: {intermediate: {verifiedState: 'PROFICIENT', verifiedByName: 'Coach', standardVersion: 1}},
  });

  const saveDraft = saveCurriculumDraftHandler(db);
  const publish = publishCurriculumDraftHandler(db, {
    publishingEnabled: true,
    chunkByteLimit: 64 * 1024, // Force multi-chunk snapshot (~175 KB -> 3 chunks)
  });
  const rollback = rollbackCurriculumRevisionHandler(db, {
    publishingEnabled: true,
    chunkByteLimit: 64 * 1024,
  });

  // 1. Save and publish full 32-family / 72-skill baseline as rev_000001.
  await saveDraft({auth: adminAuth, data: {families, skills, note: 'Baseline import'}});
  const rev1 = await publish({auth: adminAuth, data: {notes: 'Baseline 72-skill publish'}});
  assert.equal(rev1.revision.id, 'rev_000001');
  assert.equal(rev1.revision.skillCount, 72);
  assert.ok(rev1.revision.chunkCount >= 2, 'Expected multi-chunk snapshot');

  const chunksSnap = await db
      .collection(REVISIONS_COLLECTION)
      .doc('rev_000001')
      .collection(CHUNKS_SUBCOLLECTION)
      .get();
  assert.equal(chunksSnap.size, rev1.revision.chunkCount);

  // 2. Edit a published skill's proficient standard (with standardVersion bump) and publish rev_000002.
  const editedSkills = structuredClone(skills);
  const target = editedSkills.find((s) => s.id === 'rider.mounted.shoulder_in');
  target.levels.intermediate.proficient = `${target.levels.intermediate.proficient} (Updated in rev 2)`;
  target.levels.intermediate.standardVersion = 2;

  await saveDraft({auth: adminAuth, data: {families, skills: editedSkills, note: 'Update shoulder-in'}});
  const rev2 = await publish({auth: adminAuth, data: {notes: 'Updated shoulder-in intermediate standard'}});
  assert.equal(rev2.revision.id, 'rev_000002');
  assert.deepEqual(rev2.revision.summary.modifiedSkillIds, ['rider.mounted.shoulder_in']);

  // 3. Roll back to rev_000001 -> creates rev_000003 with standardVersion bumped to 3.
  const rev3 = await rollback({
    auth: adminAuth,
    data: {targetRevisionId: 'rev_000001', notes: 'Restore rev 1 wording'},
  });
  assert.equal(rev3.revision.id, 'rev_000003');
  assert.equal(rev3.revision.kind, 'rollback');
  assert.equal(rev3.revision.rollbackOfRevisionId, 'rev_000001');

  const liveShoulderIn = (await db.doc('SkillsV2/rider.mounted.shoulder_in').get()).data();
  assert.equal(liveShoulderIn.levels.intermediate.standardVersion, 3);

  // 4. Verify meta pointer, immutable revisions, and untouched user progress/verifications.
  const meta = (await db.collection(META_COLLECTION).doc(META_DOC_ID).get()).data();
  assert.equal(meta.currentRevisionId, 'rev_000003');
  assert.equal(meta.publicationState, 'idle');
  assert.equal((await progressRef.get()).data().levels.intermediate.state, 'PROFICIENT');
  assert.equal((await verifRef.get()).data().levels.intermediate.standardVersion, 1);

  console.log('ALL CURRICULUM REVISIONS EMULATOR ASSERTIONS PASSED');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
