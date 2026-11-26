'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {
  submitDictionarySuggestion,
  editDictionary,
  validateEntry,
  publicEntry,
  cleanupAbandonedDraftMedia,
} = require('../dictionary');
const {sharePreviewHandler} = require('../share_preview');
const seeds = require('../dictionary_seed.json');

function fakeDb() {
  const store = new Map();
  const ref = (path) => ({
    path,
    collection: (name) => collection(path + '/' + name),
    get: async () => ({exists: store.has(path), data: () => structuredClone(store.get(path))}),
  });
  const collection = (path) => ({
    doc: (id = randomUUID()) => ref(path + '/' + id),
    get: async () => ({
      docs: [...store.entries()]
          .filter(([key]) => key.startsWith(path + '/') && !key.slice(path.length + 1).includes('/'))
          .map(([, data]) => ({data: () => structuredClone(data)})),
    }),
    where: (field, op, value) => ({
      limit: (count) => ({
        get: async () => ({docs: [...store.entries()].filter(([key, data]) =>
          key.startsWith(path + '/') && Array.isArray(data[field]) && data[field].includes(value))
            .slice(0, count).map(([, data]) => ({data: () => data}))}),
      }),
    }),
  });
  return {
    store, collection,
    async runTransaction(fn) {
      const ops = [];
      const tx = {
        get: (doc) => doc.get(),
        set: (doc, data) => ops.push(() => store.set(doc.path, structuredClone(data))),
        create: (doc, data) => ops.push(() => {
          assert(!store.has(doc.path));
          store.set(doc.path, structuredClone(data));
        }),
        update: (doc, data) => ops.push(() => store.set(doc.path, {...store.get(doc.path), ...structuredClone(data)})),
      };
      await fn(tx);
      ops.forEach((op) => op());
    },
  };
}
const admin = {uid: 'editor-private-id', token: {admin: true, email_verified: true}};
const payload = (patch = {}) => ({
  submissionId: randomUUID(), term: 'A new term', proposal: 'An independently written description.',
  kind: 'missing_term', recognitionConsent: false, ...patch,
});
const request = (data, auth) => ({data, auth, app: {appId: 'test'}, rawRequest: {ip: '127.0.0.8'}});

test('guests can submit with App Check, retries are idempotent, consent defaults private', async () => {
  const db = fakeDb();
  const submit = submitDictionarySuggestion(db, {secret: 'test-secret'});
  const data = payload({publicName: 'Unconsented'});
  await submit(request(data));
  await submit(request(data));
  const stored = db.store.get('DictionarySuggestions/' + data.submissionId);
  assert.equal(stored.publicName, null);
  assert.equal(stored.contributorUid, null);
  assert.equal(stored.recognitionConsent, false);
  assert(!JSON.stringify(stored).includes('127.0.0.8'));
  await assert.rejects(submit({...request(payload()), app: null}), {code: 'unauthenticated'});
  await assert.rejects(submit(request(payload({website: 'spam'}))), {code: 'invalid-argument'});
  await assert.rejects(submit(request(payload({recognitionConsent: true, publicName: 'private@email.com'}))),
      {code: 'invalid-argument'});
});

test('guest spam limit is transactional and member identity stays private', async () => {
  const db = fakeDb();
  const submit = submitDictionarySuggestion(db, {secret: 'test-secret'});
  for (let i = 0; i < 5; i++) await submit(request(payload(), {uid: 'private-user', token: {}}));
  await assert.rejects(submit(request(payload())), {code: 'resource-exhausted'});
  const suggestion = [...db.store.entries()].find(([path]) => path.startsWith('DictionarySuggestions/'))[1];
  assert.equal(suggestion.contributorUid, 'private-user');
});

test('only verified admins edit, publishing is atomic, reviewed, and revision protected', async () => {
  const db = fakeDb();
  const edit = editDictionary(db);
  const entry = {...seeds[0], id: 'green', slug: 'green', contributorUid: 'leak', email: 'private@example.com'};
  const data = {action: 'publish', id: entry.id, entry, expectedRevision: 0};
  for (const auth of [null, {uid: 'member', token: {}}, {uid: 'mod', token: {moderator: true, email_verified: true}}]) {
    await assert.rejects(edit(request(data, auth)), {code: 'permission-denied'});
  }
  const proposal = payload({recognitionConsent: true, publicName: 'Community Rider'});
  await submitDictionarySuggestion(db, {secret: 'test'})(request(proposal, {uid: 'private-user'}));
  await assert.rejects(edit(request({...data, suggestionId: proposal.submissionId}, admin)),
      {code: 'failed-precondition'});
  await edit(request({action: 'review', id: proposal.submissionId, status: 'approved', note: 'Reviewed independently'}, admin));
  await edit(request({...data, action: 'save', suggestionId: proposal.submissionId}, admin));
  assert.equal(db.store.get('DictionaryDrafts/green').suggestionId, proposal.submissionId);
  await edit(request({...data, expectedRevision: 1}, admin));
  const published = db.store.get('DictionaryEntries/green');
  assert.equal(published.revision, 2);
  assert.equal(published.status, 'published');
  assert.deepEqual(published.attributions, ['Community Rider']);
  assert(!JSON.stringify(published).includes('private'));
  assert(db.store.has('DictionaryDrafts/green/Revisions/2'));
  assert.equal(db.store.get('DictionarySuggestions/' + proposal.submissionId).status, 'published');
  assert.equal([...db.store.keys()].filter((path) => path.startsWith('DictionaryEntries/')).length, 11);
  await assert.rejects(edit(request(data, admin)), {code: 'aborted'});
  await edit(request({...data, action: 'save', expectedRevision: 2, entry: {...entry, definition: 'Private draft wording.'}}, admin));
  assert.equal((await publicEntry(db, 'green')).definition, published.definition);
  await assert.rejects(edit(request({...data, expectedRevision: 3, entry: {...entry, slug: 'new-url'}}, admin)),
      {code: 'failed-precondition'});
});

test('entry validation rejects unsafe media and bounds fields, keeps distinct meanings', () => {
  assert.throws(() => validateEntry({...seeds[0], media: [{url: 'javascript:alert(1)', label: 'bad'}]}));
  assert.throws(() => validateEntry({...seeds[0], definition: 'x'.repeat(501)}));
  assert.throws(() => validateEntry({...seeds[0], explanation: 'Write to private@example.com.'}));
  assert.equal(validateEntry({...seeds[0], id: 'green-colour', slug: 'green-colour'}).slug, 'green-colour');
});

test('Dictionary crawler deep links escape metadata and keep drafts private', async () => {
  const db = fakeDb();
  db.store.set('DictionaryPublic/catalogue', {initialized: true});
  db.store.set('DictionaryEntries/canter', {...seeds[2], term: '<Canter>'});
  db.store.set('DictionaryDrafts/private', {...seeds[2], slug: 'private', status: 'draft'});
  for (const [slug, expected] of [['canter', '&lt;Canter&gt;'], ['lope', '&lt;Canter&gt;'], ['private', 'Equestrian Dictionary']]) {
    let html;
    const res = {set() {}, status() {return this;}, send(value) {html = value;}};
    await sharePreviewHandler(db, {fetchFn: async () => ({ok: false})})({
      path: '/Dictionary/' + slug, headers: {host: 'localhost:5000'}, query: {},
    }, res);
    assert(html.includes(expected));
    assert(html.includes('rel="canonical"'));
    assert(html.includes('flutter_bootstrap.js'));
    assert(!html.includes('Dictionary/private"'));
    assert(!html.includes('editor-private'));
  }
});

test('starter meanings validate, have stable unique slugs, and avoid synonym copies', () => {
  const ids = new Set();
  const slugs = new Set(seeds.map((entry) => entry.slug));
  for (const entry of seeds) {
    assert.equal(validateEntry(entry).id, entry.id);
    assert(!ids.has(entry.id));
    ids.add(entry.id);
    assert.equal(entry.status, 'published');
    for (const related of entry.relatedTerms) assert(slugs.has(related));
  }
  assert.equal(seeds.filter((entry) => entry.synonyms.includes('lope')).length, 1);
  assert(!slugs.has('lope'));
});

test('structured improvements record base revision, validate changes, allow admin proposal edits, and enforce mismatch acknowledgement', async () => {
  const db = fakeDb();
  const submit = submitDictionarySuggestion(db, {secret: 'test-secret'});
  const edit = editDictionary(db);
  const canterSeed = seeds.find((item) => item.id === 'canter');

  // Unchanged structured fields must be rejected.
  await assert.rejects(
      submit(request({
        submissionId: randomUUID(),
        term: canterSeed.term,
        kind: 'correction',
        termId: canterSeed.id,
        baseRevision: 0,
        proposedFields: {
          definition: canterSeed.definition,
          explanation: canterSeed.explanation,
          usage: canterSeed.usage,
          regionalUsage: canterSeed.regionalUsage,
          examples: canterSeed.examples,
          synonyms: canterSeed.synonyms,
        },
        recognitionConsent: false,
      })),
      {code: 'invalid-argument'},
  );

  // Email in proposedFields must be rejected.
  await assert.rejects(
      submit(request({
        submissionId: randomUUID(),
        term: canterSeed.term,
        kind: 'improvement',
        termId: canterSeed.id,
        proposedFields: {
          definition: 'Contact rider@example.com for lope details.',
        },
        recognitionConsent: false,
      })),
      {code: 'invalid-argument'},
  );

  // Guest submits a structured improvement against bundled rev 0.
  const sugId = randomUUID();
  await submit(request({
    submissionId: sugId,
    term: canterSeed.term,
    kind: 'correction',
    termId: canterSeed.id,
    baseRevision: 0,
    reason: 'Clarify Western trail rhythm.',
    proposedFields: {
      definition: 'A controlled three-beat gait with a moment of suspension.',
      explanation: canterSeed.explanation,
      usage: canterSeed.usage,
      regionalUsage: canterSeed.regionalUsage,
      examples: [...canterSeed.examples, 'Ask for a calm lope departing from a balanced walk.'],
      synonyms: canterSeed.synonyms,
    },
    recognitionConsent: false,
  }));

  const stored = db.store.get('DictionarySuggestions/' + sugId);
  assert.equal(stored.baseRevision, 0);
  assert.equal(stored.reason, 'Clarify Western trail rhythm.');
  assert.deepEqual(stored.changedFields, ['definition', 'examples']);
  assert.equal(stored.baseFields.definition, canterSeed.definition);

  // Administrator edits the proposal before approving, preserving originalProposedFields.
  await edit(request({
    action: 'review',
    id: sugId,
    status: 'approved',
    note: 'Tightened wording before publication.',
    editedFields: {
      ...stored.proposedFields,
      definition: 'A balanced, cadenced three-beat gait with a moment of suspension.',
    },
  }, admin));

  const afterReview = db.store.get('DictionarySuggestions/' + sugId);
  assert.equal(afterReview.status, 'approved');
  assert.equal(
      afterReview.originalProposedFields.definition,
      'A controlled three-beat gait with a moment of suspension.',
  );
  assert.equal(
      afterReview.proposedFields.definition,
      'A balanced, cadenced three-beat gait with a moment of suspension.',
  );

  // Simulate another administrator publishing an independent edit to 'canter' first (rev -> 1).
  await edit(request({
    action: 'publish',
    id: 'canter',
    expectedRevision: 0,
    entry: {
      ...canterSeed,
      regionalUsage: 'Called lope in Western disciplines and canter in English and general riding.',
    },
  }, admin));
  assert.equal(db.store.get('DictionaryEntries/canter').revision, 1);

  // Applying the older suggestion without acknowledgeRevisionMismatch must fail!
  const mergedEntry = {
    ...db.store.get('DictionaryEntries/canter'),
    definition: afterReview.proposedFields.definition,
    examples: afterReview.proposedFields.examples,
  };
  await assert.rejects(
      edit(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 1,
        suggestionId: sugId,
        entry: mergedEntry,
      }, admin)),
      {code: 'failed-precondition'},
  );

  // Once the administrator explicitly acknowledges the revision mismatch, publication succeeds
  // and preserves both revision 1 and revision 2!
  await edit(request({
    action: 'publish',
    id: 'canter',
    expectedRevision: 1,
    suggestionId: sugId,
    acknowledgeRevisionMismatch: true,
    entry: mergedEntry,
  }, admin));

  const finalPublished = db.store.get('DictionaryEntries/canter');
  assert.equal(finalPublished.revision, 2);
  assert.equal(
      finalPublished.definition,
      'A balanced, cadenced three-beat gait with a moment of suspension.',
  );
  assert.equal(
      finalPublished.regionalUsage,
      'Called lope in Western disciplines and canter in English and general riding.',
  );
  assert(db.store.has('DictionaryDrafts/canter/Revisions/1'));
  assert(db.store.has('DictionaryDrafts/canter/Revisions/2'));
});

test('publishing promotes private draft images to immutable dictionary_public paths, verifies ownership, cleans up failed publishes, and preserves saved drafts', async () => {
  const db = fakeDb();
  const canterSeed = seeds.find((item) => item.id === 'canter');
  const draftPath = 'dictionary_drafts/canter/abc123_diagram.png';
  const draftUrl =
    'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
    encodeURIComponent(draftPath) +
    '?alt=media&token=draft-tok';

  // Without a storage bucket, publishing a draft-storage URL must fail rather than leaking a draft path.
  const editNoBucket = editDictionary(db);
  await assert.rejects(
      editNoBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {...canterSeed, media: [{url: draftUrl, label: 'Canter footfalls'}]},
      }, admin)),
      {code: 'failed-precondition'},
  );

  // Stateful mock bucket tracking existing objects, copies, metadata, and deletions.
  const objects = new Map([
    [draftPath, {contentType: 'image/png', timeCreated: '2026-11-01T00:00:00Z'}],
    ['dictionary_drafts/withers/other.png', {contentType: 'image/png', timeCreated: '2026-11-01T00:00:00Z'}],
    ['dictionary_drafts/canter/bad.gif', {contentType: 'image/gif', timeCreated: '2026-11-01T00:00:00Z'}],
  ]);
  const fakeBucket = {
    name: 'test-bucket',
    file(path) {
      return {
        name: path,
        path,
        async exists() {
          return [objects.has(path)];
        },
        async copy(dest) {
          assert(objects.has(path), 'Source must exist: ' + path);
          objects.set(dest.path, {...objects.get(path)});
        },
        async getMetadata() {
          assert(objects.has(path), 'Missing metadata for: ' + path);
          return [objects.get(path)];
        },
        async setMetadata(meta) {
          objects.set(path, {...objects.get(path), ...meta});
        },
        async delete() {
          objects.delete(path);
        },
      };
    },
    async getFiles({prefix} = {}) {
      const matched = [...objects.entries()]
          .filter(([path]) => !prefix || path.startsWith(prefix))
          .map(([path, metadata]) => ({
            name: path,
            metadata,
            async delete() {
              objects.delete(path);
            },
          }));
      return [matched];
    },
  };

  const editWithBucket = editDictionary(db, {bucket: fakeBucket});

  // Reject wrong bucket, wrong entry ownership, unrelated folder, missing draft, and bad content-type.
  await assert.rejects(
      editWithBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {
          ...canterSeed,
          media: [{
            url: 'https://firebasestorage.googleapis.com/v0/b/wrong-bucket/o/' + encodeURIComponent(draftPath),
            label: 'Wrong bucket',
          }],
        },
      }, admin)),
      {code: 'invalid-argument'},
  );
  await assert.rejects(
      editWithBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {
          ...canterSeed,
          media: [{
            url: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
              encodeURIComponent('dictionary_drafts/withers/other.png'),
            label: 'Other entry image',
          }],
        },
      }, admin)),
      {code: 'invalid-argument'},
  );
  await assert.rejects(
      editWithBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {
          ...canterSeed,
          media: [{
            url: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
              encodeURIComponent('Riders_Photo/rider-1.png'),
            label: 'Unrelated folder',
          }],
        },
      }, admin)),
      {code: 'invalid-argument'},
  );
  await assert.rejects(
      editWithBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {
          ...canterSeed,
          media: [{
            url: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
              encodeURIComponent('dictionary_drafts/canter/missing.png'),
            label: 'Missing file',
          }],
        },
      }, admin)),
      {code: 'failed-precondition'},
  );
  await assert.rejects(
      editWithBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {
          ...canterSeed,
          media: [{
            url: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
              encodeURIComponent('dictionary_drafts/canter/bad.gif'),
            label: 'Disallowed GIF',
          }],
        },
      }, admin)),
      {code: 'invalid-argument'},
  );

  // Successful publish creates an immutable UUID public path and cleans up the entry's draft file.
  await editWithBucket(request({
    action: 'publish',
    id: 'canter',
    expectedRevision: 0,
    entry: {...canterSeed, media: [{url: draftUrl, label: 'Canter footfalls'}]},
  }, admin));

  const published = db.store.get('DictionaryEntries/canter');
  assert.equal(published.media.length, 1);
  assert.equal(published.media[0].label, 'Canter footfalls');
  assert.match(
      published.media[0].url,
      /dictionary_public%2Fcanter%2F[0-9a-f-]{36}\.png\?alt=media&token=/,
  );
  const firstPublicPath = decodeURIComponent(
      new URL(published.media[0].url).pathname.split('/o/')[1],
  );
  assert(objects.has(firstPublicPath));
  assert(!objects.has(draftPath), 'Published draft image should be cleaned up');

  // Re-seed draft image and attempt a stale publish (expectedRevision: 0 instead of 1).
  // Must fail with 'aborted', keep firstPublicPath intact, and leave zero orphaned dictionary_public files!
  objects.set(draftPath, {contentType: 'image/png', timeCreated: '2026-11-01T00:00:00Z'});
  await assert.rejects(
      editWithBucket(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        entry: {...canterSeed, media: [{url: draftUrl, label: 'Stale overwrite attempt'}]},
      }, admin)),
      {code: 'aborted'},
  );
  const publicCanterFiles = [...objects.keys()].filter((p) => p.startsWith('dictionary_public/canter/'));
  assert.deepEqual(publicCanterFiles, [firstPublicPath]);

  // Verify cleanupAbandonedDraftMedia deletes only unreferenced expired draft files
  // and NEVER deletes files referenced by saved drafts or recent uploads.
  const savedDraftImg = 'dictionary_drafts/green/saved.png';
  const expiredOrphanImg = 'dictionary_drafts/green/abandoned.png';
  const recentOrphanImg = 'dictionary_drafts/green/recent.png';
  objects.set(savedDraftImg, {contentType: 'image/png', timeCreated: '2026-11-01T00:00:00Z'});
  objects.set(expiredOrphanImg, {contentType: 'image/png', timeCreated: '2026-11-01T00:00:00Z'});
  objects.set(recentOrphanImg, {contentType: 'image/png', timeCreated: '2026-11-25T10:00:00Z'});
  db.store.set('DictionaryDrafts/green', {
    ...seeds[0],
    media: [{
      url: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
        encodeURIComponent(savedDraftImg) + '?alt=media&token=s1',
      label: 'Saved draft illustration',
    }],
  });

  const cleanupResult = await cleanupAbandonedDraftMedia(db, fakeBucket, {
    now: () => Date.parse('2026-11-25T16:00:00Z'),
  });
  assert(cleanupResult.deleted.includes(expiredOrphanImg));
  assert(objects.has(savedDraftImg), 'Saved draft image must never be deleted');
  assert(objects.has(recentOrphanImg), 'Recent upload within retention window must be kept');
  assert(!objects.has(expiredOrphanImg), 'Expired unreferenced draft image must be deleted');
});
