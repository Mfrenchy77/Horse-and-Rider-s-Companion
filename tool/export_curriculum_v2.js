#!/usr/bin/env node
/* eslint-disable no-console */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const admin = require(path.resolve(__dirname, '../functions/node_modules/firebase-admin'));
const {validateCurriculum} = require('../functions/curriculum_validator');
const {
  REVISIONS_COLLECTION,
  CHUNKS_SUBCOLLECTION,
  PUBLIC_COLLECTION,
  PUBLIC_ACTIVE_DOC_ID,
  computeCurriculumChecksum,
  reassembleAndVerifySnapshot,
} = require('../functions/curriculum_revisions');

const ROOT = path.resolve(__dirname, '..');
const DEFAULT_OUT_DIR = path.join(ROOT, 'curriculum', 'v2');

const SKILL_FILE_MAP = [
  {file: 'skills_rider_husbandry.json', subject: 'rider', realm: 'Husbandry'},
  {file: 'skills_rider_in_hand.json', subject: 'rider', realm: 'In_Hand'},
  {file: 'skills_rider_mounted.json', subject: 'rider', realm: 'Mounted'},
  {file: 'skills_rider_theory.json', subject: 'rider', realm: 'Other'},
  {file: 'skills_horse_in_hand.json', subject: 'horse', realm: 'In_Hand'},
  {file: 'skills_horse_mounted.json', subject: 'horse', realm: 'Mounted'},
];

function parseArgs(argv) {
  const args = {
    write: false,
    check: false,
    projectId: process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || '',
    outDir: DEFAULT_OUT_DIR,
  };
  for (let i = 2; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--write') {
      args.write = true;
    } else if (token === '--dry-run' || token === '--check') {
      args.write = false;
      args.check = token === '--check';
    } else if (token === '--project' && argv[i + 1]) {
      args.projectId = argv[i + 1];
      i += 1;
    } else if (token === '--out-dir' && argv[i + 1]) {
      args.outDir = path.resolve(argv[i + 1]);
      i += 1;
    }
  }
  return args;
}

function cleanFamilyForExport(f) {
  return {
    id: f.id,
    schemaVersion: 2,
    subject: f.subject,
    realm: f.realm,
    name: f.name,
    description: f.description || '',
    sortOrder: Number.isInteger(f.sortOrder) ? f.sortOrder : 0,
  };
}

function cleanSkillForExport(s) {
  const levels = {};
  for (const lvl of s.availableLevels || []) {
    const def = s.levels && s.levels[lvl];
    if (!def) continue;
    const entry = {
      overview: def.overview,
      components: (def.components || []).map((c) => ({
        title: c.title,
        description: c.description || '',
      })),
      learning: def.learning,
      proficient: def.proficient,
      standardVersion: Number.isInteger(def.standardVersion) && def.standardVersion >= 1 ?
        def.standardVersion :
        1,
    };
    if (def.standardUpdatedAt) {
      entry.standardUpdatedAt = typeof def.standardUpdatedAt === 'string' ?
        def.standardUpdatedAt :
        (def.standardUpdatedAt.toDate ?
          def.standardUpdatedAt.toDate().toISOString() :
          new Date(def.standardUpdatedAt).toISOString());
    }
    levels[lvl] = entry;
  }

  const out = {
    id: s.id,
    schemaVersion: 2,
    status: s.status || 'active',
    subject: s.subject,
    realm: s.realm,
    familyId: s.familyId,
    name: s.name,
    aliases: [...(s.aliases || [])],
    summary: s.summary,
    purpose: s.purpose,
    safety: [...(s.safety || [])],
    availableLevels: [...(s.availableLevels || [])],
    levels,
    relatedSkills: (s.relatedSkills || []).map((r) => {
      const item = {skillId: r.skillId, relation: r.relation};
      if (r.level) item.level = r.level;
      return item;
    }),
    legacyIds: [...(s.legacyIds || [])],
    sortOrder: Number.isInteger(s.sortOrder) ? s.sortOrder : 0,
  };
  if (s.replacedBy) out.replacedBy = s.replacedBy;
  return out;
}

function sortByOrderThenId(a, b) {
  const orderDiff = (a.sortOrder || 0) - (b.sortOrder || 0);
  if (orderDiff !== 0) return orderDiff;
  return String(a.id).localeCompare(String(b.id));
}

function buildExportFiles({families, skills}) {
  const validation = validateCurriculum({
    families,
    skills,
    requireFamilyDescription: false,
    enforceSizeLimit: false,
  });
  if (!validation.ok) {
    throw new Error(`Exported curriculum failed validation: ${validation.errors.join(' ')}`);
  }

  const cleanedFamilies = validation.families
      .map(cleanFamilyForExport)
      .sort(sortByOrderThenId);
  const cleanedSkills = validation.skills
      .map(cleanSkillForExport)
      .sort(sortByOrderThenId);

  const files = new Map();
  files.set('families.json', `${JSON.stringify(cleanedFamilies, null, 2)}\n`);

  const assigned = new Set();
  for (const spec of SKILL_FILE_MAP) {
    const matching = cleanedSkills.filter(
        (s) => s.subject === spec.subject && s.realm === spec.realm,
    );
    for (const s of matching) assigned.add(s.id);
    files.set(spec.file, `${JSON.stringify(matching, null, 2)}\n`);
  }

  const unassigned = cleanedSkills.filter((s) => !assigned.has(s.id));
  if (unassigned.length > 0) {
    throw new Error(
        `Unmapped skill subject/realm entries: ${unassigned.map((s) => s.id).join(', ')}`,
    );
  }

  const {checksum} = computeCurriculumChecksum({
    families: cleanedFamilies,
    skills: cleanedSkills,
  });

  return {
    files,
    familyCount: cleanedFamilies.length,
    skillCount: cleanedSkills.length,
    totalLevels: validation.totalLevels,
    checksum,
  };
}

function diffExportFiles(filesMap, outDir) {
  const report = [];
  for (const [fileName, nextContent] of filesMap.entries()) {
    const fullPath = path.join(outDir, fileName);
    const exists = fs.existsSync(fullPath);
    const prevContent = exists ? fs.readFileSync(fullPath, 'utf8') : null;
    const changed = !exists || prevContent !== nextContent;
    report.push({
      fileName,
      fullPath,
      exists,
      changed,
      prevBytes: prevContent ? Buffer.byteLength(prevContent, 'utf8') : 0,
      nextBytes: Buffer.byteLength(nextContent, 'utf8'),
    });
  }
  return report;
}

async function loadActiveCurriculumReadOnly(db) {
  const activeSnap = await db
      .collection(PUBLIC_COLLECTION)
      .doc(PUBLIC_ACTIVE_DOC_ID)
      .get();

  if (activeSnap.exists && activeSnap.data()?.activeRevisionId) {
    const activeData = activeSnap.data();
    const revId = activeData.activeRevisionId;
    const revRef = db.collection(REVISIONS_COLLECTION).doc(revId);
    const [headerSnap, chunksSnap] = await Promise.all([
      revRef.get(),
      revRef.collection(CHUNKS_SUBCOLLECTION).get(),
    ]);
    const header = headerSnap.exists ?
      {id: revId, ...headerSnap.data()} :
      {
        id: revId,
        chunkCount: activeData.chunkCount,
        checksum: activeData.checksum,
      };
    const chunks = chunksSnap.docs.map((d) => d.data());
    const verified = reassembleAndVerifySnapshot(header, chunks);
    return {
      source: 'active_revision',
      revisionId: revId,
      revisionNumber: activeData.activeRevisionNumber || header.revisionNumber || 0,
      checksum: verified.checksum,
      families: verified.families,
      skills: verified.skills,
    };
  }

  // Fallback for pre-versioned environments (read-only).
  const [famSnap, skillSnap] = await Promise.all([
    db.collection('SkillFamilies').get(),
    db.collection('SkillsV2').get(),
  ]);
  const families = famSnap.docs.map((d) => ({id: d.id, ...d.data()}));
  const skills = skillSnap.docs
      .map((d) => ({id: d.id, ...d.data()}))
      .filter((s) => s.status === 'active' || s.status === 'retired');
  const {checksum} = computeCurriculumChecksum({families, skills});
  return {
    source: 'legacy_collections',
    revisionId: null,
    revisionNumber: 0,
    checksum,
    families,
    skills,
  };
}

async function exportCurriculumFromFirestore(db, {outDir = DEFAULT_OUT_DIR, write = false} = {}) {
  const loaded = await loadActiveCurriculumReadOnly(db);
  const built = buildExportFiles({
    families: loaded.families,
    skills: loaded.skills,
  });
  const diffs = diffExportFiles(built.files, outDir);
  const changedFiles = diffs.filter((d) => d.changed);

  if (write) {
    fs.mkdirSync(outDir, {recursive: true});
    for (const entry of changedFiles) {
      fs.writeFileSync(entry.fullPath, built.files.get(entry.fileName), 'utf8');
    }
  }

  return {
    ...loaded,
    ...built,
    diffs,
    changedCount: changedFiles.length,
    wroteFiles: write,
  };
}

async function main() {
  const args = parseArgs(process.argv);
  const appOptions = args.projectId ? {projectId: args.projectId} : {};
  if (!admin.apps.length) {
    admin.initializeApp(appOptions);
  }
  const db = admin.firestore();

  const result = await exportCurriculumFromFirestore(db, {
    outDir: args.outDir,
    write: args.write,
  });

  console.log(`Source: ${result.source}${result.revisionId ? ` (${result.revisionId})` : ''}`);
  console.log(`Families: ${result.familyCount} | Skills: ${result.skillCount} | Levels: ${result.totalLevels}`);
  console.log(`Verified Checksum: ${result.checksum}`);
  for (const item of result.diffs) {
    const status = item.changed ? (item.exists ? 'MODIFIED' : 'NEW') : 'UNCHANGED';
    console.log(`  [${status}] ${item.fileName} (${item.prevBytes} -> ${item.nextBytes} bytes)`);
  }

  if (!args.write) {
    console.log(
        result.changedCount === 0 ?
          'DRY RUN: Bundled curriculum matches active published curriculum.' :
          `DRY RUN: ${result.changedCount} file(s) differ. Re-run with --write to update ${args.outDir}.`,
    );
    if (args.check && result.changedCount > 0) {
      process.exitCode = 1;
    }
  } else {
    console.log(`EXPORTED: Updated ${result.changedCount} file(s) in ${args.outDir}.`);
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = {
  SKILL_FILE_MAP,
  cleanFamilyForExport,
  cleanSkillForExport,
  buildExportFiles,
  diffExportFiles,
  loadActiveCurriculumReadOnly,
  exportCurriculumFromFirestore,
};
