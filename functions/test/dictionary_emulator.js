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
  const memberAuth = {uid: 'emulator-member-' + suffix, token: {email_verified: true}};
  const requests = Array.from({length: 6}, (_, index) => ({
    auth: memberAuth,
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

  // Verify structured improvement + concurrent revision mismatch protection on real Firestore transactions.
  const structuredId = 'dictionary-structured-' + suffix;
  const secondMemberAuth = {uid: 'emulator-member-2-' + suffix, token: {email_verified: true}};
  await submit({
    auth: secondMemberAuth,
    rawRequest: {ip: 'dictionary-emulator-2-' + suffix},
    data: {
      submissionId: structuredId,
      term: entry.term,
      termId: entry.id,
      kind: 'correction',
      baseRevision: 1,
      reason: 'Emulator structured revision check.',
      proposedFields: {
        definition: 'Updated emulator definition from contributor.',
        explanation: entry.explanation,
        usage: entry.usage,
        regionalUsage: entry.regionalUsage,
        examples: entry.examples,
        synonyms: entry.synonyms,
      },
      recognitionConsent: false,
    },
  });
  await edit({
    auth: actor,
    data: {
      action: 'review',
      id: structuredId,
      status: 'approved',
      note: 'Refined by admin.',
      editedFields: {
        definition: 'Admin-refined emulator definition.',
        explanation: entry.explanation,
        usage: entry.usage,
        regionalUsage: entry.regionalUsage,
        examples: entry.examples,
        synonyms: entry.synonyms,
      },
    },
  });
  // Advance published entry to revision 2 before applying the suggestion.
  await edit({
    auth: actor,
    data: {
      action: 'publish',
      id: entry.id,
      expectedRevision: 1,
      entry: {...entry, regionalUsage: 'Concurrent emulator regional note.'},
    },
  });
  // Must reject without explicit acknowledgeRevisionMismatch!
  await assert.rejects(
      edit({
        auth: actor,
        data: {
          action: 'publish',
          id: entry.id,
          expectedRevision: 2,
          suggestionId: structuredId,
          entry: {
            ...entry,
            definition: 'Admin-refined emulator definition.',
            regionalUsage: 'Concurrent emulator regional note.',
          },
        },
      }),
      {code: 'failed-precondition'},
  );
  // Succeeds when explicitly acknowledged and preserves prior revisions.
  await edit({
    auth: actor,
    data: {
      action: 'publish',
      id: entry.id,
      expectedRevision: 2,
      suggestionId: structuredId,
      acknowledgeRevisionMismatch: true,
      entry: {
        ...entry,
        definition: 'Admin-refined emulator definition.',
        regionalUsage: 'Concurrent emulator regional note.',
      },
    },
  });
  const rev3 = (await db.collection('DictionaryEntries').doc(entry.slug).get()).data();
  assert.equal(rev3.revision, 3);
  assert.equal(rev3.definition, 'Admin-refined emulator definition.');
  assert.equal(rev3.regionalUsage, 'Concurrent emulator regional note.');
  assert((await db.collection('DictionaryDrafts').doc(entry.id).collection('Revisions').doc('2').get()).exists);
  assert((await db.collection('DictionaryDrafts').doc(entry.id).collection('Revisions').doc('3').get()).exists);

  console.log('Dictionary emulator concurrency, rate limiting, structured edits, revision safety, and privacy passed.');
}
main().then(() => db.terminate()).catch((error) => {console.error(error); process.exitCode = 1;});
