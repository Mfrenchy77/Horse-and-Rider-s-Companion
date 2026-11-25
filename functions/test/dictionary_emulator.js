'use strict';

const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const {submitDictionarySuggestion, editDictionary} = require('../dictionary');
const seed = require('../dictionary_seed.json');
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Firestore emulator required.');
admin.initializeApp({projectId: 'demo-horse-rules'});
const db = admin.firestore();
const actor = {uid: 'dictionary-emulator-admin', token: {admin: true, email_verified: true}};
async function main() {
  const suffix = Date.now().toString(36);
  const submit = submitDictionarySuggestion(db, {secret: 'emulator-only', requireAppCheck: false});
  const requests = Array.from({length: 6}, (_, index) => ({
    rawRequest: {ip: 'dictionary-emulator-' + suffix},
    data: {
      submissionId: 'dictionary-' + suffix + '-' + index,
      term: 'Emulator meaning', proposal: 'An independently reviewed example.',
      kind: 'missing_term', recognitionConsent: index === 0, publicName: 'Community Rider',
    },
  }));
  const outcomes = await Promise.allSettled(requests.map((request) => submit(request)));
  assert.equal(outcomes.filter((item) => item.status === 'fulfilled').length, 5);
  assert(outcomes.some((item) => item.reason?.code === 'resource-exhausted'));
  const accepted = requests[outcomes.findIndex((item) => item.status === 'fulfilled')];
  const edit = editDictionary(db);
  const suggestionId = accepted.data.submissionId;
  await edit({auth: actor, data: {action: 'review', id: suggestionId, status: 'approved', note: 'Reviewed.'}});
  const entry = {...seed[0], id: 'emulator-' + suffix, slug: 'emulator-' + suffix, term: 'Emulator meaning'};
  const request = {auth: actor, data: {
    action: 'publish', id: entry.id, entry, suggestionId, expectedRevision: 0,
  }};
  const publishes = await Promise.allSettled([edit(request), edit(request)]);
  assert.equal(publishes.filter((item) => item.status === 'fulfilled').length, 1);
  assert(publishes.some((item) => item.reason?.code === 'aborted'));
  const published = (await db.collection('DictionaryEntries').doc(entry.slug).get()).data();
  assert.equal(published.revision, 1);
  assert(!JSON.stringify(published).includes(actor.uid));
  assert((await db.collection('DictionaryDrafts').doc(entry.id).collection('Revisions').doc('1').get()).exists);
  console.log('Dictionary emulator concurrency, rate limiting, publication, and privacy passed.');
}
main().then(() => db.terminate()).catch((error) => {console.error(error); process.exitCode = 1;});
