#!/usr/bin/env node
/* eslint-disable no-console */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const admin = require(path.resolve(__dirname, '../functions/node_modules/firebase-admin'));

const ROOT = path.resolve(__dirname, '..');
const V2_DIR = path.join(ROOT, 'curriculum', 'v2');
const SKILL_FILES = [
  'skills_rider_husbandry.json',
  'skills_rider_in_hand.json',
  'skills_rider_mounted.json',
  'skills_horse_in_hand.json',
  'skills_horse_mounted.json',
];

function parseArgs(argv) {
  const args = {
    apply: false,
    projectId: process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || '',
  };
  for (let i = 2; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--apply') {
      args.apply = true;
    } else if (token === '--dry-run') {
      args.apply = false;
    } else if (token === '--project' && argv[i + 1]) {
      args.projectId = argv[i + 1];
      i += 1;
    }
  }
  return args;
}

function loadCurriculum() {
  const families = JSON.parse(
    fs.readFileSync(path.join(V2_DIR, 'families.json'), 'utf8'),
  );
  const skills = [];
  for (const file of SKILL_FILES) {
    const list = JSON.parse(fs.readFileSync(path.join(V2_DIR, file), 'utf8'));
    skills.push(...list);
  }
  return {families, skills};
}

async function main() {
  const args = parseArgs(process.argv);

  // Always run canonical schema & legacy mapping validation first.
  const validatorOutput = execFileSync(
    process.execPath,
    [path.join(__dirname, 'validate_curriculum_v2.js')],
    {encoding: 'utf8'},
  );
  process.stdout.write(validatorOutput);

  const {families, skills} = loadCurriculum();
  const totalStandards = skills.reduce(
    (sum, s) => sum + (Array.isArray(s.availableLevels) ? s.availableLevels.length : 0),
    0,
  );

  if (!args.apply) {
    console.log(
      `DRY RUN: Would upsert ${families.length} SkillFamilies and ${skills.length} SkillsV2 (${totalStandards} standards).`,
    );
    console.log('Re-run with --apply (and --project <id> or FIRESTORE_EMULATOR_HOST) to write to Firestore.');
    return;
  }

  const appOptions = args.projectId ? {projectId: args.projectId} : {};
  admin.initializeApp(appOptions);
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const ops = [
    ...families.map((family) => ({
      ref: db.collection('SkillFamilies').doc(family.id),
      data: {...family, updatedAt: now},
    })),
    ...skills.map((skill) => ({
      ref: db.collection('SkillsV2').doc(skill.id),
      data: {...skill, updatedAt: now},
    })),
  ];

  const BATCH_LIMIT = 400;
  let committed = 0;
  for (let i = 0; i < ops.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    const slice = ops.slice(i, i + BATCH_LIMIT);
    for (const op of slice) {
      batch.set(op.ref, op.data, {merge: true});
    }
    await batch.commit();
    committed += slice.length;
  }

  console.log(
    `PUBLISHED: Upserted ${families.length} SkillFamilies and ${skills.length} SkillsV2 (${committed} total documents). Legacy Skills, Profiles, SkillProgress, SkillVerifications, and Resources were not modified.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
