/* eslint-disable require-jsdoc */
'use strict';

const assert = require('node:assert/strict');
const {execFileSync} = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const admin = require('firebase-admin');
const seed = require('../dictionary_seed.json');

const ROOT = path.resolve(__dirname, '../..');
const SCRIPT = path.join(ROOT, 'tool', 'publish_dictionary_seed.js');
const PROJECT_ID = 'demo-horse-rules';

function runCli(cliArgs) {
  return execFileSync(process.execPath, [SCRIPT, ...cliArgs], {
    cwd: ROOT,
    env: {...process.env, GCLOUD_PROJECT: PROJECT_ID},
    encoding: 'utf8',
  });
}

async function run() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('FIRESTORE_EMULATOR_HOST is required for emulator tests.');
  }
  if (!admin.apps.length) {
    admin.initializeApp({projectId: PROJECT_ID});
  }
  const db = admin.firestore();

  // Clear prior emulator state (so running after dictionary_emulator.js stays isolated).
  for (const colName of ['DictionaryEntries', 'DictionaryPublic']) {
    const existing = await db.collection(colName).get();
    for (let i = 0; i < existing.docs.length; i += 400) {
      const delBatch = db.batch();
      for (const doc of existing.docs.slice(i, i + 400)) {
        delBatch.delete(doc.ref);
      }
      await delBatch.commit();
    }
  }

  // Seed 28 pre-release live entries with live media, attributions, and revision 2 on sample docs.
  const first28 = seed.slice(0, 28);
  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();
  for (const entry of first28) {
    const isMediaDoc =
      entry.slug === 'canter' || entry.slug === 'positive-reinforcement';
    batch.set(db.collection('DictionaryEntries').doc(entry.slug), {
      ...entry,
      definition:
        entry.slug === 'canter-lead'
          ? 'Old pre-release lead definition.'
          : entry.definition,
      media: isMediaDoc
        ? [
            {
              url: `https://example.com/${entry.slug}.png`,
              label: `Live ${entry.term} media`,
            },
          ]
        : [],
      attributions:
        entry.slug === 'positive-reinforcement' ? ['Alex Rider'] : [],
      revision: isMediaDoc ? 2 : 1,
      publishedAt: now,
      updatedAt: now,
    });
  }
  batch.set(db.collection('DictionaryPublic').doc('catalogue'), {
    initialized: true,
    version: 1,
    updatedAt: now,
  });
  await batch.commit();

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'dict-sync-test-'));
  const backupFile = path.join(tmpDir, 'dict_backup.json');

  try {
    // 1. Capture backup before editorial sync.
    const backupOut = runCli([
      '--backup',
      backupFile,
      '--project',
      PROJECT_ID,
    ]);
    assert.match(backupOut, /entries=28/);
    const backupJson = JSON.parse(fs.readFileSync(backupFile, 'utf8'));
    assert.equal(backupJson.entryCount, 28);
    assert.equal(backupJson.catalogue.version, 1);

    // 2. Dry-run sync reports exact counts without modifying Firestore.
    const drySyncOut = runCli([
      '--sync-editorial',
      '--project',
      PROJECT_ID,
    ]);
    assert.match(drySyncOut, /would create=56/);
    assert.match(drySyncOut, /preservedLiveMedia=2/);
    assert.match(drySyncOut, /preservedLiveAttributions=1/);
    const beforeCount = (await db.collection('DictionaryEntries').get()).size;
    assert.equal(beforeCount, 28);

    // 3. Apply editorial sync -> creates 56, updates changed existing while preserving live media/attributions.
    const applyOut = runCli([
      '--sync-editorial',
      '--apply',
      '--project',
      PROJECT_ID,
    ]);
    assert.match(applyOut, /created=56/);
    assert.match(applyOut, /preservedLiveMedia=2/);
    assert.match(applyOut, /preservedLiveAttributions=1/);

    const afterSnap = await db.collection('DictionaryEntries').get();
    assert.equal(afterSnap.size, 84);

    const leadSnap = await db
      .collection('DictionaryEntries')
      .doc('canter-lead')
      .get();
    assert.equal(
      leadSnap.data().definition,
      seed.find((e) => e.slug === 'canter-lead').definition,
    );
    assert.equal(leadSnap.data().revision, 2);

    const posReinfSnap = await db
      .collection('DictionaryEntries')
      .doc('positive-reinforcement')
      .get();
    assert.deepEqual(posReinfSnap.data().attributions, ['Alex Rider']);
    assert.equal(posReinfSnap.data().media.length, 1);

    const catAfterSync = (
      await db.collection('DictionaryPublic').doc('catalogue').get()
    ).data();
    assert.equal(catAfterSync.version, 2);

    // 4. Restore from backup -> removes 56 added entries, restores 28 original docs, bumps catalogue version.
    const restoreOut = runCli([
      '--restore',
      backupFile,
      '--apply',
      '--project',
      PROJECT_ID,
    ]);
    assert.match(restoreOut, /RESTORED: 28 DictionaryEntries/);
    assert.match(restoreOut, /deleted 56 extra/);

    const restoredSnap = await db.collection('DictionaryEntries').get();
    assert.equal(restoredSnap.size, 28);

    const restoredLead = (
      await db.collection('DictionaryEntries').doc('canter-lead').get()
    ).data();
    assert.equal(restoredLead.definition, 'Old pre-release lead definition.');

    const restoredPos = (
      await db
        .collection('DictionaryEntries')
        .doc('positive-reinforcement')
        .get()
    ).data();
    assert.deepEqual(restoredPos.attributions, ['Alex Rider']);
    assert.equal(restoredPos.revision, 2);

    const catAfterRestore = (
      await db.collection('DictionaryPublic').doc('catalogue').get()
    ).data();
    assert.equal(catAfterRestore.version, 3);

    console.log(
      'Dictionary seed sync, live-media preservation, backup, and restore emulator test passed.',
    );
  } finally {
    fs.rmSync(tmpDir, {recursive: true, force: true});
  }
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
