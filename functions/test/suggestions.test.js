'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  submitSuggestionHandler,
  reviewSuggestionHandler,
  MAX_SUBMISSIONS_PER_24H,
} = require('../suggestions');

function createFakeFirestore() {
  const store = new Map();

  function docRef(path) {
    return {
      path,
      collection(subName) {
        return collectionRef(`${path}/${subName}`);
      },
      async get() {
        const value = store.get(path);
        return {
          exists: value !== undefined,
          data: () => (value === undefined ? undefined : structuredClone(value)),
        };
      },
    };
  }

  function collectionRef(colPath) {
    return {
      doc(id) {
        return docRef(`${colPath}/${id}`);
      },
      where(field, op, value) {
        assert.equal(op, '==');
        return {
          async get() {
            const docs = [];
            const prefix = `${colPath}/`;
            for (const [docPath, data] of store.entries()) {
              if (!docPath.startsWith(prefix)) continue;
              const rest = docPath.slice(prefix.length);
              if (rest.includes('/')) continue;
              if (data[field] === value) {
                docs.push({
                  id: rest,
                  data: () => structuredClone(data),
                });
              }
            }
            return {docs};
          },
        };
      },
    };
  }

  return {
    _store: store,
    collection: collectionRef,
    batch() {
      const ops = [];
      return {
        set(ref, data) {
          ops.push(() => store.set(ref.path, structuredClone(data)));
        },
        async commit() {
          for (const op of ops) op();
        },
      };
    },
    async runTransaction(fn) {
      const ops = [];
      const tx = {
        async get(ref) {
          return ref.get();
        },
        set(ref, data) {
          ops.push(() => store.set(ref.path, structuredClone(data)));
        },
        update(ref, patch) {
          ops.push(() => {
            const current = store.get(ref.path) || {};
            store.set(ref.path, {...current, ...structuredClone(patch)});
          });
        },
      };
      const result = await fn(tx);
      for (const op of ops) op();
      return result;
    },
  };
}

function validPayload(overrides = {}) {
  return {
    contributionCategory: 'component_or_example',
    subject: 'horse',
    realm: 'In_Hand',
    familyId: 'horse.in_hand.handling_care',
    targetSkillId: 'horse.in_hand.grooming',
    targetSkillName: 'Grooming',
    targetLevel: 'introductory',
    title: 'Add hoof pick safety cue',
    description: 'Mention standing beside the shoulder rather than directly behind the hind leg.',
    rationale: 'Improves safety for beginners.',
    ...overrides,
  };
}

test('submitSuggestionHandler rejects unauthenticated, guest, and unverified callers', async () => {
  const db = createFakeFirestore();
  const submit = submitSuggestionHandler(db);

  await assert.rejects(
      () => submit({data: validPayload()}),
      (err) => err.code === 'unauthenticated',
  );
  await assert.rejects(
      () => submit({
        auth: {uid: 'g1', token: {firebase: {sign_in_provider: 'anonymous'}}},
        data: validPayload(),
      }),
      (err) => err.code === 'permission-denied',
  );
  await assert.rejects(
      () => submit({
        auth: {uid: 'u1', token: {email: 'u1@example.com', email_verified: false}},
        data: validPayload(),
      }),
      (err) => err.code === 'failed-precondition',
  );
});

test('submitSuggestionHandler validates enums, lengths, and document IDs', async () => {
  const db = createFakeFirestore();
  const submit = submitSuggestionHandler(db);
  const auth = {uid: 'u1', token: {email: 'u1@example.com', email_verified: true}};

  await assert.rejects(
      () => submit({auth, data: validPayload({contributionCategory: 'invalid'})}),
      (err) => err.code === 'invalid-argument',
  );
  await assert.rejects(
      () => submit({auth, data: validPayload({title: 'Hi'})}),
      (err) => err.code === 'invalid-argument',
  );
  await assert.rejects(
      () => submit({auth, data: validPayload({targetSkillId: 'bad/path'})}),
      (err) => err.code === 'invalid-argument',
  );
});

test('submitSuggestionHandler creates suggestion + audit event and enforces 10/24h limit', async () => {
  const db = createFakeFirestore();
  let counter = 0;
  let currentMs = Date.UTC(2026, 10, 14, 12, 0, 0);
  const submit = submitSuggestionHandler(db, {
    now: () => new Date(currentMs),
    uuid: () => `id-${++counter}`,
  });
  const auth = {
    uid: 'rider-1',
    token: {email: 'Rider1@Example.com', name: 'Rider One', email_verified: true},
  };

  for (let i = 0; i < MAX_SUBMISSIONS_PER_24H; i += 1) {
    const res = await submit({auth, data: validPayload({title: `Suggestion #${i + 1}`})});
    assert.equal(res.suggestion.status, 'submitted');
    assert.equal(res.suggestion.submittedByUid, 'rider-1');
    assert.equal(res.suggestion.submitterEmail, 'rider1@example.com');
  }

  // 11th submission within 24h is rejected.
  await assert.rejects(
      () => submit({auth, data: validPayload({title: 'Suggestion #11'})}),
      (err) => err.code === 'resource-exhausted',
  );

  // Advance clock past 24 hours: next submission succeeds.
  currentMs += 24 * 60 * 60 * 1000 + 1000;
  const afterWindow = await submit({auth, data: validPayload({title: 'After 24h window'})});
  assert.equal(afterWindow.suggestion.status, 'submitted');

  // Verify initial audit event exists.
  const firstAudit = db._store.get('SkillTreeSuggestions/id-1/AuditEvents/id-2');
  assert.equal(firstAudit.type, 'submitted');
  assert.equal(firstAudit.actorRole, 'submitter');
});

test('reviewSuggestionHandler enforces moderator vs admin permissions and records audit events', async () => {
  const db = createFakeFirestore();
  let counter = 0;
  const now = () => new Date(Date.UTC(2026, 10, 14, 13, 0, 0));
  const submit = submitSuggestionHandler(db, {now, uuid: () => `id-${++counter}`});
  const review = reviewSuggestionHandler(db, {now, uuid: () => `id-${++counter}`});

  const {suggestion} = await submit({
    auth: {uid: 'u1', token: {email: 'u1@example.com', name: 'User 1', email_verified: true}},
    data: validPayload(),
  });

  // Ordinary user cannot review.
  await assert.rejects(
      () => review({
        auth: {uid: 'u1', token: {email: 'u1@example.com', email_verified: true}},
        data: {suggestionId: suggestion.id, status: 'under_review'},
      }),
      (err) => err.code === 'permission-denied',
  );

  // Moderator cannot approve, decline, or publish.
  const modAuth = {
    uid: 'mod-1',
    token: {email: 'mod@example.com', name: 'Mod', email_verified: true, moderator: true},
  };
  for (const forbiddenStatus of [
    'approved_as_alias_or_component',
    'approved_as_level',
    'approved_as_new_skill',
    'published',
    'declined_already_covered',
    'declined_out_of_scope',
  ]) {
    await assert.rejects(
        () => review({
          auth: modAuth,
          data: {suggestionId: suggestion.id, status: forbiddenStatus},
        }),
        (err) => err.code === 'permission-denied',
    );
  }

  // Moderator can triage, assign, add privateNote, and request clarification.
  const modResult = await review({
    auth: modAuth,
    data: {
      suggestionId: suggestion.id,
      status: 'needs_clarification',
      assignedToUid: 'mod-1',
      privateNote: 'Ask submitter for horse size context.',
      publicResolutionNote: 'Could you clarify which grooming step this applies to?',
    },
  });
  assert.equal(modResult.suggestion.status, 'needs_clarification');
  assert.equal(modResult.suggestion.assignedToUid, 'mod-1');

  // Admin can approve with public resolution note + private note.
  const adminAuth = {
    uid: 'admin-1',
    token: {email: 'admin@example.com', name: 'Admin', email_verified: true, admin: true},
  };
  const adminResult = await review({
    auth: adminAuth,
    data: {
      suggestionId: suggestion.id,
      status: 'approved_as_alias_or_component',
      publicResolutionNote: 'Accepted for the next curriculum update.',
      privateNote: 'Queued for v2.1 JSON batch.',
    },
  });
  assert.equal(adminResult.suggestion.status, 'approved_as_alias_or_component');
  assert.equal(adminResult.suggestion.reviewedByUid, 'admin-1');

  // Verify audit trail captured both reviews without leaking into SkillsV2.
  const keys = [...db._store.keys()].filter((k) =>
    k.startsWith(`SkillTreeSuggestions/${suggestion.id}/AuditEvents/`),
  );
  assert.equal(keys.length, 3);
  assert.equal(
      [...db._store.keys()].some((k) => k.startsWith('SkillsV2/')),
      false,
  );
});
