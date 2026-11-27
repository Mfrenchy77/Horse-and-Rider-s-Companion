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
        get: async () => ({
          docs: [...store.entries()].filter(([key, data]) => {
            if (!key.startsWith(path + '/') || key.slice(path.length + 1).includes('/')) {
              return false;
            }
            if (op === '==') return data[field] === value;
            if (op === 'array-contains') {
              return Array.isArray(data[field]) && data[field].includes(value);
            }
            return false;
          }).slice(0, count).map(([, data]) => ({data: () => structuredClone(data)})),
        }),
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
const member = {uid: 'private-user', token: {email_verified: true}};
const payload = (patch = {}) => ({
  submissionId: randomUUID(), term: 'A new term', proposal: 'An independently written description.',
  kind: 'missing_term', recognitionConsent: false, ...patch,
});
const request = (data, auth = member) => ({data, auth, app: {appId: 'test'}, rawRequest: {ip: '127.0.0.8'}});

test('signed-in verified contributors can submit with App Check, retries are idempotent, consent defaults private, and signed-out/unverified requests fail', async () => {
  const db = fakeDb();
  const submit = submitDictionarySuggestion(db, {secret: 'test-secret'});
  await assert.rejects(submit(request(payload(), null)), {code: 'unauthenticated'});
  await assert.rejects(
      submit(request(payload(), {uid: 'unverified', token: {email_verified: false}})),
      {code: 'unauthenticated'},
  );
  const data = payload({publicName: 'Unconsented'});
  await submit(request(data, member));
  await submit(request(data, member));
  const stored = db.store.get('DictionarySuggestions/' + data.submissionId);
  assert.equal(stored.publicName, null);
  assert.equal(stored.contributorUid, member.uid);
  assert.equal(stored.recognitionConsent, false);
  assert(!JSON.stringify(stored).includes('127.0.0.8'));
  await assert.rejects(submit({...request(payload(), member), app: null}), {code: 'unauthenticated'});
  await assert.rejects(submit(request(payload({website: 'spam'}), member)), {code: 'invalid-argument'});
  await assert.rejects(submit(request(payload({recognitionConsent: true, publicName: 'private@email.com'}), member)),
      {code: 'invalid-argument'});
});

test('per-member rate limit is transactional and member identity stays private', async () => {
  const db = fakeDb();
  const submit = submitDictionarySuggestion(db, {secret: 'test-secret'});
  for (let i = 0; i < 5; i++) await submit(request(payload(), member));
  await assert.rejects(submit(request(payload(), member)), {code: 'resource-exhausted'});
  const suggestion = [...db.store.entries()].find(([path]) => path.startsWith('DictionarySuggestions/'))[1];
  assert.equal(suggestion.contributorUid, member.uid);
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
  await submitDictionarySuggestion(db, {secret: 'test'})(request(proposal, member));
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
  assert.equal([...db.store.keys()].filter((path) => path.startsWith('DictionaryEntries/')).length, seeds.length);
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

test('community new_term & image_contribution enforce ownership, limits, rights, partial approval, cleanup, and public metadata', async () => {
  const db = fakeDb();
  const objects = new Map();
  const subBucket = {
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

  const urlFor = (objectPath) =>
    'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
    encodeURIComponent(objectPath) +
    '?alt=media&token=tok';

  const submit = submitDictionarySuggestion(db, {secret: 'test-secret', bucket: subBucket});
  const edit = editDictionary(db, {bucket: subBucket});

  const subId = randomUUID();
  const p1 = `dictionary_submissions/${member.uid}/${subId}/good_diagram.png`;
  const p2 = `dictionary_submissions/${member.uid}/${subId}/blurry_photo.jpg`;
  const foreignPath = `dictionary_submissions/other-user/${subId}/stolen.png`;
  objects.set(p1, {contentType: 'image/png', size: 2048, timeCreated: '2026-11-25T10:00:00Z'});
  objects.set(p2, {contentType: 'image/jpeg', size: 4096, timeCreated: '2026-11-25T10:00:00Z'});
  objects.set(foreignPath, {contentType: 'image/png', size: 2048, timeCreated: '2026-11-25T10:00:00Z'});

  // Reject missing rights confirmation
  await assert.rejects(
      submit(request({
        submissionId: subId,
        term: 'Canter',
        termId: 'canter',
        kind: 'image_contribution',
        rightsConfirmed: false,
        submittedImages: [{id: 'img_1', url: urlFor(p1), imageType: 'diagram'}],
      }, member)),
      {code: 'invalid-argument'},
  );

  // Reject attaching another user's upload
  await assert.rejects(
      submit(request({
        submissionId: subId,
        term: 'Canter',
        termId: 'canter',
        kind: 'image_contribution',
        rightsConfirmed: true,
        submittedImages: [{id: 'img_f', url: urlFor(foreignPath)}],
      }, member)),
      {code: 'invalid-argument'},
  );

  // Reject > 3 images
  await assert.rejects(
      submit(request({
        submissionId: subId,
        term: 'Canter',
        termId: 'canter',
        kind: 'image_contribution',
        rightsConfirmed: true,
        submittedImages: [
          {id: 'img_1', url: urlFor(p1)},
          {id: 'img_2', url: urlFor(p2)},
          {id: 'img_3', url: urlFor(p1)},
          {id: 'img_4', url: urlFor(p2)},
        ],
      }, member)),
      {code: 'invalid-argument'},
  );

  // Submit image contribution with deduplicated duplicate SHA-256 and opt-in recognition
  const dupHash = 'a'.repeat(64);
  const imgSub = await submit(request({
    submissionId: subId,
    term: 'Canter',
    termId: 'canter',
    kind: 'image_contribution',
    rightsConfirmed: true,
    recognitionConsent: true,
    publicName: 'Morgan Trail',
    submittedImages: [
      {
        id: 'img_1',
        url: urlFor(p1),
        sha256: dupHash,
        caption: 'Lead leg placement',
        explanation: 'Shows three-beat sequence.',
        imageType: 'diagram',
      },
      {
        id: 'img_dup',
        url: urlFor(p2),
        sha256: dupHash,
        caption: 'Duplicate hash ignored',
      },
      {
        id: 'img_2',
        url: urlFor(p2),
        sha256: 'b'.repeat(64),
        caption: 'Blurry arena shot',
      },
    ],
  }, member));
  assert.equal(imgSub.imageCount, 2);

  // Admin partially approves img_1 (editing caption/imageType) and rejects img_2
  const reviewRes = await edit(request({
    action: 'review',
    id: subId,
    textDecision: 'rejected',
    imageDecisions: [
      {
        id: 'img_1',
        status: 'approved',
        caption: 'Inside lead footfall diagram',
        explanation: 'Illustrates three-beat canter sequence with suspension.',
        imageType: 'diagram',
      },
      {id: 'img_2', status: 'rejected'},
    ],
    note: 'Diagram is clear; second image blurry.',
  }, admin));
  assert.equal(reviewRes.status, 'partially_approved');
  // Rejected image was deleted from private Storage immediately on review!
  assert(!objects.has(p2));
  assert(objects.has(p1));

  // Unapproved submission URL cannot be published directly without approval
  const canterSeed = seeds.find((item) => item.id === 'canter');
  await assert.rejects(
      edit(request({
        action: 'publish',
        id: 'canter',
        expectedRevision: 0,
        suggestionId: subId,
        entry: {
          ...canterSeed,
          media: [{url: urlFor(p2), label: 'Rejected image'}],
        },
      }, admin)),
      {code: 'failed-precondition'},
  );

  // Publish approved community diagram alongside an existing published image
  await edit(request({
    action: 'publish',
    id: 'canter',
    expectedRevision: 0,
    suggestionId: subId,
    entry: {
      ...canterSeed,
      media: [
        {url: urlFor(p1), label: 'Inside lead footfall diagram', explanation: 'Illustrates three-beat canter sequence with suspension.', imageType: 'diagram', attribution: 'Morgan Trail'},
      ],
    },
  }, admin));

  const updatedCanter = db.store.get('DictionaryEntries/canter');
  assert.equal(updatedCanter.media.length, 1);
  assert.match(updatedCanter.media[0].url, /dictionary_public%2Fcanter%2F/);
  assert.equal(updatedCanter.media[0].imageType, 'diagram');
  assert.equal(updatedCanter.media[0].attribution, 'Morgan Trail');
  // Private submission file is cleaned up once promoted to dictionary_public/
  assert(!objects.has(p1));

  // New term with categories and no images
  const newTermId = randomUUID();
  await submit(request({
    submissionId: newTermId,
    term: 'Cavaletti',
    kind: 'new_term',
    categories: ['Groundwork', 'Gymnastics'],
    proposedFields: {
      definition: 'Low adjustable poles used at walk, trot, or canter to build cadence.',
      explanation: 'Used across English and Western programs.',
      usage: '',
      regionalUsage: '',
      examples: ['Space trot rails to match natural stride length.'],
      synonyms: ['ground poles'],
    },
    recognitionConsent: false,
  }, member));
  const storedNew = db.store.get('DictionarySuggestions/' + newTermId);
  assert.deepEqual(storedNew.categories, ['Groundwork', 'Gymnastics']);
  assert.equal(storedNew.kind, 'new_term');
});

test('approve_and_publish enforces admin permissions, hero/gallery selection, partial approval, duplicate protection, rollback, and audit history', async () => {
  const db = fakeDb();
  const objects = new Map();
  const bucket = {
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

  const urlFor = (objectPath) =>
    'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/' +
    encodeURIComponent(objectPath) +
    '?alt=media&token=tok';

  const submit = submitDictionarySuggestion(db, {secret: 'test-secret', bucket});
  const edit = editDictionary(db, {bucket});

  // Seed initial published Canter entry with one existing image.
  const canterSeed = seeds.find((item) => item.id === 'canter');
  const existingPublicPath = 'dictionary_public/canter/existing-1.png';
  objects.set(existingPublicPath, {contentType: 'image/png', size: 1024, timeCreated: '2026-11-20T00:00:00Z'});
  await edit(request({
    action: 'publish',
    id: 'canter',
    expectedRevision: 0,
    entry: {
      ...canterSeed,
      media: [{url: urlFor(existingPublicPath), label: 'Existing stride diagram'}],
    },
  }, admin));
  assert.equal(db.store.get('DictionaryEntries/canter').revision, 1);

  const subId = randomUUID();
  const pHero = `dictionary_submissions/${member.uid}/${subId}/hero_lead.png`;
  const pGallery = `dictionary_submissions/${member.uid}/${subId}/gallery_cadence.jpg`;
  const pReject = `dictionary_submissions/${member.uid}/${subId}/blurry_skip.jpg`;
  objects.set(pHero, {contentType: 'image/png', size: 2048, timeCreated: '2026-11-25T10:00:00Z'});
  objects.set(pGallery, {contentType: 'image/jpeg', size: 2048, timeCreated: '2026-11-25T10:00:00Z'});
  objects.set(pReject, {contentType: 'image/jpeg', size: 2048, timeCreated: '2026-11-25T10:00:00Z'});

  await submit(request({
    submissionId: subId,
    term: 'Canter',
    termId: 'canter',
    kind: 'image_contribution',
    rightsConfirmed: true,
    recognitionConsent: true,
    publicName: 'Elena Ranch',
    submittedImages: [
      {id: 'img_gallery', url: urlFor(pGallery), sha256: '1'.repeat(64), caption: 'Balanced cadence', imageType: 'photograph'},
      {id: 'img_hero', url: urlFor(pHero), sha256: '2'.repeat(64), caption: 'Right lead footfalls', explanation: 'Three-beat sequence.', imageType: 'diagram'},
      {id: 'img_reject', url: urlFor(pReject), sha256: '3'.repeat(64), caption: 'Blurry shot', imageType: 'photograph'},
    ],
  }, member));

  const publishReq = (overrides = {}) => ({
    action: 'approve_and_publish',
    id: subId,
    expectedRevision: 1,
    heroImageId: 'submitted:img_hero',
    note: 'Approved clear lead diagram and cadence photo; rejected blurry shot.',
    imageDecisions: [
      {id: 'img_gallery', status: 'approved', caption: 'Balanced arena cadence', imageType: 'photograph'},
      {id: 'img_hero', status: 'approved', caption: 'Right lead footfalls', explanation: 'Three-beat sequence.', imageType: 'diagram'},
      {id: 'img_reject', status: 'rejected'},
    ],
    ...overrides,
  });

  // 1. Permission enforcement: non-admins and unverified admins cannot approve_and_publish.
  for (const auth of [null, member, {uid: 'mod', token: {moderator: true, email_verified: true}}, {uid: 'unv', token: {admin: true, email_verified: false}}]) {
    await assert.rejects(edit(request(publishReq(), auth)), {code: 'permission-denied'});
  }

  // 2. Validation failure: approving 0 images must reject without mutating public entry or promoted files.
  await assert.rejects(
      edit(request(publishReq({
        heroImageId: 'existing:0',
        imageDecisions: [
          {id: 'img_gallery', status: 'rejected'},
          {id: 'img_hero', status: 'rejected'},
          {id: 'img_reject', status: 'rejected'},
        ],
      }), admin)),
      {code: 'invalid-argument'},
  );
  assert.equal(db.store.get('DictionaryEntries/canter').media.length, 1);

  // 3. Stale expectedRevision must abort and roll back any promoted public files.
  const publicBeforeStale = [...objects.keys()].filter((p) => p.startsWith('dictionary_public/canter/'));
  await assert.rejects(
      edit(request(publishReq({expectedRevision: 0}), admin)),
      {code: 'aborted'},
  );
  assert.deepEqual(
      [...objects.keys()].filter((p) => p.startsWith('dictionary_public/canter/')),
      publicBeforeStale,
  );

  // 4. Successful single-action approve_and_publish with hero selection and partial image rejection.
  const result = await edit(request(publishReq(), admin));
  assert.equal(result.status, 'published');
  assert.equal(result.publishedImageCount, 2);
  assert.equal(result.rejectedImageCount, 1);
  assert.equal(result.revision, 2);

  const publishedEntry = db.store.get('DictionaryEntries/canter');
  assert.equal(publishedEntry.revision, 2);
  assert.equal(publishedEntry.media.length, 3);
  assert.equal(publishedEntry.media[0].label, 'Right lead footfalls');
  assert.equal(publishedEntry.media[0].imageType, 'diagram');
  assert.equal(publishedEntry.media[0].attribution, 'Elena Ranch');
  assert.equal(publishedEntry.media[1].label, 'Existing stride diagram');
  assert.equal(publishedEntry.media[2].label, 'Balanced arena cadence');
  assert.deepEqual(publishedEntry.attributions, ['Elena Ranch']);

  // Temp submission files cleaned up after promotion/rejection.
  assert(!objects.has(pHero));
  assert(!objects.has(pGallery));
  assert(!objects.has(pReject));

  // Audit history preserves both review decision and publication events.
  const auditEvents = [...db.store.entries()]
      .filter(([key]) => key.startsWith(`DictionarySuggestions/${subId}/AuditEvents/`))
      .map(([, val]) => val);
  assert.equal(auditEvents.length, 2);
  assert(auditEvents.some((e) => e.status === 'partially_approved'));
  assert(auditEvents.some((e) => e.status === 'published' && e.publishedImageCount === 2));

  // 5. Duplicate publication protection: second approve_and_publish is rejected cleanly.
  await assert.rejects(
      edit(request(publishReq({expectedRevision: 2}), admin)),
      {code: 'failed-precondition'},
  );
});

test('server resolves contributor profile/Auth identity automatically, rejects spoofing, handles missing names safely, and resolves legacy UIDs for admins only', async () => {
  const db = fakeDb();
  const riderEmail = 'sierra.rider@example.com';
  const encodedId = riderEmail
      .replaceAll('.', '666')
      .replaceAll('@', '999')
      .replaceAll('f', '5')
      .replaceAll('e', '1')
      .replaceAll('g', '2')
      .replaceAll('m', '')
      .replaceAll('a', 'p')
      .replaceAll('i', 'a')
      .replaceAll('co', 'l');
  db.store.set(`Rider_Profile/${encodedId}`, {
    id: encodedId,
    name: 'Sierra Profile',
    email: riderEmail,
    ownerUid: 'uid-sierra',
    bio: 'Private full bio that must not be duplicated.',
    notes: [{title: 'Private training note'}],
  });

  const authStub = {
    async getUser(uid) {
      if (uid === 'uid-auth-only') {
        return {uid, email: 'auth.only@example.com', displayName: 'Auth Fallback Name'};
      }
      if (uid === 'uid-no-name') {
        return {uid, email: 'anon@example.com', displayName: ''};
      }
      if (uid === 'uid-legacy-2') {
        return {uid, email: 'legacy2@example.com', displayName: 'Legacy Auth Name'};
      }
      throw Object.assign(new Error('not found'), {code: 'auth/user-not-found'});
    },
    async getUsers(ids) {
      const users = [];
      for (const item of ids) {
        try {
          users.push(await authStub.getUser(item.uid));
        } catch (_) {
          // Ignore missing users in batch response.
        }
      }
      return {users};
    },
  };

  const fixedNow = Date.parse('2026-11-26T22:00:00Z');
  const submit = submitDictionarySuggestion(db, {
    secret: 'test-secret',
    now: () => fixedNow,
    auth: authStub,
  });
  const edit = editDictionary(db, {now: () => new Date(fixedNow + 60000), auth: authStub});

  // 1. Suggestion captures server-verified profile identity and ignores spoofed client identity fields.
  const subProfileId = randomUUID();
  await submit(request({
    submissionId: subProfileId,
    term: 'Collected Trot',
    proposal: 'Engaged, expressive two-beat diagonal gait.',
    kind: 'missing_term',
    contributorUid: 'spoofed-uid',
    contributorEmail: 'spoof@example.com',
    contributorSnapshot: {displayName: 'Spoofed Name'},
    recognitionConsent: true,
    publicName: 'Spoofed Public Name',
  }, {
    uid: 'uid-sierra',
    token: {email: riderEmail, email_verified: true, name: 'Token Name'},
  }));

  const storedProfileSub = db.store.get(`DictionarySuggestions/${subProfileId}`);
  assert.equal(storedProfileSub.contributorUid, 'uid-sierra');
  assert.equal(storedProfileSub.publicName, 'Sierra Profile');
  assert.equal(storedProfileSub.contributorSnapshot.displayName, 'Sierra Profile');
  assert.equal(storedProfileSub.contributorSnapshot.email, riderEmail);
  assert.equal(storedProfileSub.contributorSnapshot.source, 'profile');
  assert(!JSON.stringify(storedProfileSub).includes('Private full bio'));
  assert(!JSON.stringify(storedProfileSub).includes('Private training note'));

  // 2. Fallback to Firebase Auth displayName when profile record is missing.
  const subAuthId = randomUUID();
  await submit(request({
    submissionId: subAuthId,
    term: 'Canter',
    termId: 'canter',
    kind: 'correction',
    proposedFields: {
      definition: 'A three-beat gait with a moment of suspension.',
      explanation: 'Clear explanation across disciplines.',
      usage: '',
      regionalUsage: '',
      examples: [],
      synonyms: [],
    },
    recognitionConsent: true,
  }, {
    uid: 'uid-auth-only',
    token: {email_verified: true},
  }));
  const storedAuthSub = db.store.get(`DictionarySuggestions/${subAuthId}`);
  assert.equal(storedAuthSub.publicName, 'Auth Fallback Name');
  assert.equal(storedAuthSub.contributorSnapshot.displayName, 'Auth Fallback Name');
  assert.equal(storedAuthSub.contributorSnapshot.email, 'auth.only@example.com');
  assert.equal(storedAuthSub.contributorSnapshot.source, 'auth');

  // 3. Missing profile & Auth name: blank optional fallback succeeds cleanly without leaking identity.
  const subNoNameBlank = randomUUID();
  await submit(request({
    submissionId: subNoNameBlank,
    term: 'Half-Pass',
    proposal: 'Diagonal lateral movement.',
    kind: 'missing_term',
    recognitionConsent: true,
    publicName: '',
  }, {
    uid: 'uid-no-name',
    token: {email: 'anon@example.com', email_verified: true},
  }));
  const storedNoNameBlank = db.store.get(`DictionarySuggestions/${subNoNameBlank}`);
  assert.equal(storedNoNameBlank.recognitionConsent, true);
  assert.equal(storedNoNameBlank.publicName, null);
  assert.equal(storedNoNameBlank.contributorSnapshot.email, 'anon@example.com');
  assert.equal(storedNoNameBlank.contributorSnapshot.source, 'none');

  // Rejects UID spoofed as optional publicName.
  await assert.rejects(
      submit(request({
        submissionId: randomUUID(),
        term: 'Volte',
        proposal: 'Small balanced circle.',
        kind: 'missing_term',
        recognitionConsent: true,
        publicName: 'uid-no-name',
      }, {uid: 'uid-no-name', token: {email: 'anon@example.com', email_verified: true}})),
      {code: 'invalid-argument'},
  );

  // 4. Changing public attribution during admin review preserves private contributorSnapshot and audit trail.
  await edit(request({
    action: 'review',
    id: subProfileId,
    status: 'approved',
    recognitionConsent: false,
    note: 'Contributor withdrew public credit.',
  }, admin));
  const updatedSub = db.store.get(`DictionarySuggestions/${subProfileId}`);
  assert.equal(updatedSub.recognitionConsent, false);
  assert.equal(updatedSub.publicName, null);
  assert.equal(updatedSub.contributorUid, 'uid-sierra');
  assert.equal(updatedSub.contributorSnapshot.displayName, 'Sierra Profile');
  assert.equal(updatedSub.contributorSnapshot.email, riderEmail);

  // 5. Admin-only resolve_contributors handles legacy UID-only submissions and rejects non-admins.
  await assert.rejects(
      edit(request({action: 'resolve_contributors', uids: ['uid-sierra']}, member)),
      {code: 'permission-denied'},
  );
  const resolvedRes = await edit(request({
    action: 'resolve_contributors',
    uids: ['uid-sierra', 'uid-legacy-2', 'uid-sierra'],
  }, admin));
  assert.equal(resolvedRes.contributors['uid-sierra'].email, riderEmail);
  assert.equal(resolvedRes.contributors['uid-sierra'].displayName, 'Sierra Profile');
  assert.equal(resolvedRes.contributors['uid-legacy-2'].email, 'legacy2@example.com');
  assert.equal(resolvedRes.contributors['uid-legacy-2'].displayName, 'Legacy Auth Name');
});
