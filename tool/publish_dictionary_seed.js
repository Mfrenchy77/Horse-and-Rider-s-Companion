#!/usr/bin/env node
/* eslint-disable no-console */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const admin = require(
  path.resolve(__dirname, '../functions/node_modules/firebase-admin'),
);

const ROOT = path.resolve(__dirname, '..');
const SEED_PATH = path.join(ROOT, 'functions', 'dictionary_seed.json');

function parseArgs(argv) {
  const args = {
    apply: false,
    allowProduction: false,
    overwriteExisting: false,
    projectId: process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || '',
  };
  for (let i = 2; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--apply') {
      args.apply = true;
    } else if (token === '--allow-production') {
      args.allowProduction = true;
    } else if (token === '--overwrite-existing') {
      args.overwriteExisting = true;
    } else if (token === '--dry-run') {
      args.apply = false;
    } else if (token === '--project' && argv[i + 1]) {
      args.projectId = argv[i + 1];
      i += 1;
    }
  }
  return args;
}

function loadSeed() {
  const raw = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new Error('functions/dictionary_seed.json must be a non-empty array.');
  }
  const seenIds = new Set();
  const seenSlugs = new Set();
  for (const entry of raw) {
    if (!entry.id || !entry.slug || !entry.term || !entry.definition) {
      throw new Error(`Invalid Dictionary seed entry: ${JSON.stringify(entry)}`);
    }
    if (entry.status !== 'published') {
      throw new Error(`Seed entry ${entry.id} must have status="published".`);
    }
    if (seenIds.has(entry.id)) {
      throw new Error(`Duplicate Dictionary id: ${entry.id}`);
    }
    if (seenSlugs.has(entry.slug)) {
      throw new Error(`Duplicate Dictionary slug: ${entry.slug}`);
    }
    seenIds.add(entry.id);
    seenSlugs.add(entry.slug);
  }
  return raw;
}

async function main() {
  const args = parseArgs(process.argv);
  const entries = loadSeed();

  console.log(`Validated ${entries.length} published entries in functions/dictionary_seed.json.`);

  if (!args.apply) {
    console.log(
      `DRY RUN: Would create any missing DictionaryEntries documents (${entries.length} total in seed) ` +
        'and ensure DictionaryPublic/catalogue.initialized = true without overwriting existing live entries.',
    );
    console.log(
      'Re-run with --apply --project <id> (plus --allow-production when FIRESTORE_EMULATOR_HOST is not set) to write to Firestore.',
    );
    return;
  }

  if (!args.projectId) {
    throw new Error('Missing --project <id> (or GCLOUD_PROJECT / FIREBASE_PROJECT).');
  }

  const isEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  if (!isEmulator && !args.allowProduction) {
    throw new Error(
      'Refusing to write to production Firestore without --allow-production.',
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({projectId: args.projectId});
  }
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  let created = 0;
  let updated = 0;
  let skipped = 0;

  const batch = db.batch();
  for (const entry of entries) {
    const publicRef = db.collection('DictionaryEntries').doc(entry.slug);
    const snap = await publicRef.get();
    if (snap.exists && !args.overwriteExisting) {
      skipped += 1;
      continue;
    }
    const payload = {
      ...entry,
      publishedAt: now,
      updatedAt: now,
    };
    batch.set(publicRef, payload, {merge: false});
    if (snap.exists) {
      updated += 1;
    } else {
      created += 1;
    }
  }

  batch.set(
    db.collection('DictionaryPublic').doc('catalogue'),
    {initialized: true, updatedAt: now},
    {merge: true},
  );

  await batch.commit();
  console.log(
    `Applied Dictionary sync to ${args.projectId}: created=${created}, updated=${updated}, skippedExisting=${skipped}.`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
