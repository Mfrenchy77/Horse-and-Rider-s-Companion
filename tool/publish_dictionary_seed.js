#!/usr/bin/env node
/* eslint-disable no-console */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const admin = require(
  path.resolve(__dirname, '../functions/node_modules/firebase-admin'),
);
const {validateEntry} = require(
  path.resolve(__dirname, '../functions/dictionary'),
);

const ROOT = path.resolve(__dirname, '..');
const SEED_PATH = path.join(ROOT, 'functions', 'dictionary_seed.json');
const BATCH_LIMIT = 400;

const EDITORIAL_FIELDS = [
  'id',
  'slug',
  'schemaVersion',
  'status',
  'term',
  'definition',
  'explanation',
  'synonyms',
  'categories',
  'usage',
  'regionalUsage',
  'examples',
  'relatedTerms',
  'skillIds',
  'contextual',
];

function parseArgs(argv) {
  const args = {
    apply: false,
    allowProduction: false,
    overwriteExisting: false,
    syncEditorial: false,
    backupPath: '',
    restorePath: '',
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
    } else if (token === '--sync-editorial') {
      args.syncEditorial = true;
    } else if (token === '--dry-run') {
      args.apply = false;
    } else if (token === '--backup' && argv[i + 1]) {
      args.backupPath = path.resolve(argv[i + 1]);
      i += 1;
    } else if (token === '--restore' && argv[i + 1]) {
      args.restorePath = path.resolve(argv[i + 1]);
      i += 1;
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
  const nameOwners = new Map();
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
    validateEntry(entry);
    for (const rawName of [entry.term, ...(entry.synonyms || [])]) {
      const key = String(rawName || '').trim().toLowerCase();
      if (!key) continue;
      if (!nameOwners.has(key)) nameOwners.set(key, new Set());
      nameOwners.get(key).add(entry.id);
    }
  }
  for (const [key, owners] of nameOwners.entries()) {
    if (owners.size > 1) {
      throw new Error(
        `Colliding Dictionary alias "${key}" across entries: ${[...owners].join(', ')}`,
      );
    }
  }
  return raw;
}

function getDb(projectId) {
  if (!projectId) {
    throw new Error(
      'Missing --project <id> (or GCLOUD_PROJECT / FIREBASE_PROJECT).',
    );
  }
  if (!admin.apps.length) {
    admin.initializeApp({projectId});
  }
  return admin.firestore();
}

function assertWriteAllowed(args) {
  const isEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  if (!isEmulator && !args.allowProduction) {
    throw new Error(
      'Refusing to write to production Firestore without --allow-production.',
    );
  }
  if (isEmulator && args.projectId === 'horse-and-riders-compani-d2bd4') {
    throw new Error(
      'Refusing to run against FIRESTORE_EMULATOR_HOST with production project ID.',
    );
  }
}

function serializeFirestoreValue(value) {
  if (value === null || value === undefined) return value;
  if (typeof value.toDate === 'function') {
    return {__firestoreTimestamp: value.toDate().toISOString()};
  }
  if (Array.isArray(value)) {
    return value.map(serializeFirestoreValue);
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = serializeFirestoreValue(v);
    }
    return out;
  }
  return value;
}

function rehydrateFirestoreValue(value) {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) {
    return value.map(rehydrateFirestoreValue);
  }
  if (typeof value === 'object') {
    if (
      Object.keys(value).length === 1 &&
      typeof value.__firestoreTimestamp === 'string'
    ) {
      return admin.firestore.Timestamp.fromDate(
        new Date(value.__firestoreTimestamp),
      );
    }
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = rehydrateFirestoreValue(v);
    }
    return out;
  }
  return value;
}

function editorialChanged(existingDoc, seedEntry) {
  for (const key of EDITORIAL_FIELDS) {
    const a = existingDoc[key] === undefined ? null : existingDoc[key];
    const b = seedEntry[key] === undefined ? null : seedEntry[key];
    if (JSON.stringify(a) !== JSON.stringify(b)) {
      return true;
    }
  }
  return false;
}

async function commitOps(db, ops) {
  for (let i = 0; i < ops.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    const slice = ops.slice(i, i + BATCH_LIMIT);
    for (const op of slice) {
      if (op.type === 'delete') {
        batch.delete(op.ref);
      } else {
        batch.set(op.ref, op.data, op.options || {});
      }
    }
    await batch.commit();
  }
}

async function runBackup({projectId, backupPath}) {
  const db = getDb(projectId);
  const [catalogueSnap, entriesSnap] = await Promise.all([
    db.collection('DictionaryPublic').doc('catalogue').get(),
    db.collection('DictionaryEntries').get(),
  ]);
  const entries = entriesSnap.docs
    .slice()
    .sort((a, b) => a.id.localeCompare(b.id))
    .map((doc) => ({
      docId: doc.id,
      data: serializeFirestoreValue(doc.data()),
    }));
  const payload = {
    backedUpAt: new Date().toISOString(),
    projectId,
    catalogue: catalogueSnap.exists
      ? serializeFirestoreValue(catalogueSnap.data())
      : null,
    entryCount: entries.length,
    entries,
  };
  fs.mkdirSync(path.dirname(backupPath), {recursive: true});
  fs.writeFileSync(backupPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
  console.log(
    `BACKUP WRITTEN: ${backupPath} (project=${projectId}, entries=${entries.length}, catalogueVersion=${payload.catalogue?.version ?? 'none'})`,
  );
  return payload;
}

async function runRestore({args}) {
  const raw = JSON.parse(fs.readFileSync(args.restorePath, 'utf8'));
  if (!Array.isArray(raw.entries)) {
    throw new Error(`Invalid Dictionary backup file: ${args.restorePath}`);
  }
  const db = getDb(args.projectId);
  const [liveSnap, catalogueSnap] = await Promise.all([
    db.collection('DictionaryEntries').get(),
    db.collection('DictionaryPublic').doc('catalogue').get(),
  ]);
  const backupIds = new Set(raw.entries.map((item) => item.docId));
  const toDelete = liveSnap.docs.filter((doc) => !backupIds.has(doc.id));
  const currentVersion =
    typeof catalogueSnap.data()?.version === 'number'
      ? catalogueSnap.data().version
      : 0;
  const restoredVersion = Math.max(
    currentVersion + 1,
    typeof raw.catalogue?.version === 'number' ? raw.catalogue.version : 1,
  );

  if (!args.apply) {
    console.log(
      `DRY RUN RESTORE: Would restore ${raw.entries.length} DictionaryEntries docs, delete ${toDelete.length} non-backup doc(s), and set DictionaryPublic/catalogue.version=${restoredVersion}.`,
    );
    return;
  }

  assertWriteAllowed(args);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const ops = [
    ...raw.entries.map((item) => ({
      type: 'set',
      ref: db.collection('DictionaryEntries').doc(item.docId),
      data: rehydrateFirestoreValue(item.data),
      options: {merge: false},
    })),
    ...toDelete.map((doc) => ({
      type: 'delete',
      ref: doc.ref,
    })),
    {
      type: 'set',
      ref: db.collection('DictionaryPublic').doc('catalogue'),
      data: {
        ...(raw.catalogue ? rehydrateFirestoreValue(raw.catalogue) : {}),
        initialized: true,
        version: restoredVersion,
        updatedAt: now,
      },
      options: {merge: false},
    },
  ];
  await commitOps(db, ops);
  console.log(
    `RESTORED: ${raw.entries.length} DictionaryEntries doc(s), deleted ${toDelete.length} extra doc(s), catalogueVersion=${restoredVersion}.`,
  );
}

async function runSync({args, entries}) {
  if (!args.apply && !args.syncEditorial) {
    console.log(
      `DRY RUN: Would create any missing DictionaryEntries documents (${entries.length} total in seed) ` +
        'and ensure DictionaryPublic/catalogue.initialized = true without overwriting existing live entries.',
    );
    console.log(
      'Re-run with --sync-editorial --apply --project <id> (plus --allow-production when FIRESTORE_EMULATOR_HOST is not set) to sync editorial fields safely while preserving live media/attributions.',
    );
    return;
  }

  const db = getDb(args.projectId);
  const existingSnap = await db.collection('DictionaryEntries').get();
  const existingById = new Map(existingSnap.docs.map((doc) => [doc.id, doc.data()]));

  let created = 0;
  let updated = 0;
  let unchanged = 0;
  let preservedLiveMedia = 0;
  let preservedLiveAttributions = 0;

  const ops = [];
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const entry of entries) {
    const ref = db.collection('DictionaryEntries').doc(entry.slug);
    const existing = existingById.get(entry.slug);
    if (!existing) {
      created += 1;
      ops.push({
        type: 'set',
        ref,
        data: {
          ...entry,
          publishedAt: now,
          updatedAt: now,
        },
        options: {merge: false},
      });
      continue;
    }

    if (args.syncEditorial) {
      if (Array.isArray(existing.media) && existing.media.length > 0) {
        preservedLiveMedia += 1;
      }
      if (
        Array.isArray(existing.attributions) &&
        existing.attributions.length > 0
      ) {
        preservedLiveAttributions += 1;
      }
      if (!editorialChanged(existing, entry)) {
        unchanged += 1;
        continue;
      }
      updated += 1;
      const editorialPatch = {};
      for (const key of EDITORIAL_FIELDS) {
        editorialPatch[key] = entry[key];
      }
      const nextRevision =
        (typeof existing.revision === 'number' && existing.revision >= 1
          ? existing.revision
          : 1) + 1;
      ops.push({
        type: 'set',
        ref,
        data: {
          ...editorialPatch,
          revision: nextRevision,
          updatedAt: now,
        },
        options: {merge: true},
      });
      continue;
    }

    if (!args.overwriteExisting) {
      unchanged += 1;
      continue;
    }
    updated += 1;
    ops.push({
      type: 'set',
      ref,
      data: {
        ...entry,
        publishedAt: now,
        updatedAt: now,
      },
      options: {merge: false},
    });
  }

  if (!args.apply) {
    console.log(
      `DRY RUN (${args.syncEditorial ? 'sync-editorial' : 'seed'}): ` +
        `would create=${created}, update=${updated}, unchanged=${unchanged}, ` +
        `preservedLiveMedia=${preservedLiveMedia}, preservedLiveAttributions=${preservedLiveAttributions}, ` +
        `bumpCatalogueVersion=${created + updated > 0}.`,
    );
    return;
  }

  assertWriteAllowed(args);
  const catalogueUpdate = {
    initialized: true,
    updatedAt: now,
  };
  if (created + updated > 0) {
    catalogueUpdate.version = admin.firestore.FieldValue.increment(1);
  }
  ops.push({
    type: 'set',
    ref: db.collection('DictionaryPublic').doc('catalogue'),
    data: catalogueUpdate,
    options: {merge: true},
  });
  await commitOps(db, ops);
  console.log(
    `Applied Dictionary sync to ${args.projectId}: created=${created}, updated=${updated}, ` +
      `unchanged=${unchanged}, preservedLiveMedia=${preservedLiveMedia}, ` +
      `preservedLiveAttributions=${preservedLiveAttributions}, catalogueVersionBumped=${created + updated > 0}.`,
  );
}

async function main() {
  const args = parseArgs(process.argv);
  if (args.backupPath) {
    await runBackup({projectId: args.projectId, backupPath: args.backupPath});
    return;
  }
  if (args.restorePath) {
    await runRestore({args});
    return;
  }
  const entries = loadSeed();
  console.log(
    `Validated ${entries.length} published entries in functions/dictionary_seed.json.`,
  );
  await runSync({args, entries});
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = {
  loadSeed,
  editorialChanged,
  serializeFirestoreValue,
  rehydrateFirestoreValue,
};
