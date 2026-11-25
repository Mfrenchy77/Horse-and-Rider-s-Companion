'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {submitDictionarySuggestion, editDictionary, validateEntry, publicEntry} = require('../dictionary');
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
