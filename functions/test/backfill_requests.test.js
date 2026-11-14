/* eslint-env node */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {
  backfillRequests,
  mapLegacyMessageToRequest,
  parseCliArgs,
  validateBackfillEnvironment,
} = require('../backfill_requests');

function createInMemoryFirestore(seed = {}) {
  const store = {
    Conversations: new Map(),
    Requests: new Map(),
  };

  for (const [convId, conv] of Object.entries(seed.Conversations || {})) {
    const messages = new Map(Object.entries(conv.messages || {}));
    const data = {...conv};
    delete data.messages;
    store.Conversations.set(convId, {data, messages});
  }
  for (const [reqId, req] of Object.entries(seed.Requests || {})) {
    store.Requests.set(reqId, {...req});
  }

  function makeMsgRef(convId, msgId) {
    return {
      id: msgId,
      path: `Conversations/${convId}/Messages/${msgId}`,
      async get() {
        const msg = store.Conversations.get(convId)?.messages.get(msgId);
        return {exists: Boolean(msg), id: msgId, data: () => (msg ? {...msg} : undefined)};
      },
      _read() {
        const msg = store.Conversations.get(convId)?.messages.get(msgId);
        return {exists: Boolean(msg), id: msgId, data: () => (msg ? {...msg} : undefined)};
      },
      _set(val) {
        store.Conversations.get(convId).messages.set(msgId, {...val});
      },
    };
  }

  function makeReqRef(reqId) {
    return {
      id: reqId,
      path: `Requests/${reqId}`,
      async get() {
        const doc = store.Requests.get(reqId);
        return {exists: Boolean(doc), id: reqId, data: () => (doc ? {...doc} : undefined)};
      },
      _read() {
        const doc = store.Requests.get(reqId);
        return {exists: Boolean(doc), id: reqId, data: () => (doc ? {...doc} : undefined)};
      },
      _set(val) {
        store.Requests.set(reqId, {...val});
      },
    };
  }

  return {
    _store: store,
    collection(name) {
      if (name === 'Requests') {
        return {
          doc: (id) => makeReqRef(id),
          async get() {
            const docs = Array.from(store.Requests.entries()).map(([id, data]) => ({
              id,
              data: () => ({...data}),
            }));
            return {empty: docs.length === 0, docs};
          },
        };
      }
      if (name === 'Conversations') {
        let startAfterId = null;
        let limitN = Infinity;
        const query = {
          orderBy() { return query; },
          startAfter(id) { startAfterId = id; return query; },
          limit(n) { limitN = n; return query; },
          async get() {
            let ids = Array.from(store.Conversations.keys()).sort();
            if (startAfterId) {
              ids = ids.filter((id) => id > startAfterId);
            }
            ids = ids.slice(0, limitN);
            const docs = ids.map((convId) => {
              const entry = store.Conversations.get(convId);
              return {
                id: convId,
                data: () => ({...entry.data}),
                ref: {
                  collection(sub) {
                    assert.equal(sub, 'Messages');
                    return {
                      async get() {
                        const msgDocs = Array.from(entry.messages.keys()).sort().map((msgId) => ({
                          id: msgId,
                          ref: makeMsgRef(convId, msgId),
                          data: () => ({...entry.messages.get(msgId)}),
                        }));
                        return {empty: msgDocs.length === 0, docs: msgDocs};
                      },
                    };
                  },
                },
              };
            });
            return {empty: docs.length === 0, docs};
          },
        };
        return query;
      }
      throw new Error(`Unexpected collection ${name}`);
    },
    async runTransaction(fn) {
      const tx = {
        async get(ref) { return ref._read(); },
        set(ref, data) { ref._set(data); },
      };
      return fn(tx);
    },
  };
}

test('validateBackfillEnvironment defaults to dryRun and blocks unauthorized non-emulator writes', () => {
  assert.deepEqual(parseCliArgs(['--project', 'demo-hrc']), {
    dryRun: true,
    projectId: 'demo-hrc',
    confirmProduction: false,
    startAfterConvId: null,
    batchSize: 100,
  });

  assert.throws(
      () => validateBackfillEnvironment({dryRun: true, projectId: ''}),
      /Explicit projectId is required/,
  );
  assert.throws(
      () => validateBackfillEnvironment({
        dryRun: false,
        projectId: 'prod-hrc',
        emulatorHost: '',
        confirmProduction: false,
      }),
      /Refusing non-emulator writes/,
  );
  assert.equal(
      validateBackfillEnvironment({
        dryRun: false,
        projectId: 'demo-hrc',
        emulatorHost: '127.0.0.1:8089',
      }).isEmulator,
      true,
  );
});

test('mapLegacyMessageToRequest maps all four request kinds and statuses accurately', () => {
  const conv = {
    parties: ['Alice', 'Bob'],
    partiesIds: ['alice@example.com', 'bob@example.com'],
  };
  const date = new Date('2026-01-10T00:00:00Z');

  assert.equal(
      mapLegacyMessageToRequest({convId: 'c1', conv, messageId: 'm0', message: {messageType: 'CHAT'}}),
      null,
  );

  const inst = mapLegacyMessageToRequest({
    convId: 'c1',
    conv,
    messageId: 'm1',
    message: {
      messageType: 'INSTRUCTOR_REQUEST',
      sender: 'Alice',
      senderId: 'Alice@Example.com',
      subject: 'Coach me',
      message: 'Please',
      date,
    },
  });
  assert.equal(inst.id, 'legacy_c1_m1');
  assert.equal(inst.kind, 'instructor');
  assert.equal(inst.senderEmail, 'alice@example.com');
  assert.equal(inst.recipientEmail, 'bob@example.com');
  assert.equal(inst.status, 'pending');
  assert.equal(inst.migratedFromLegacy, true);

  const stud = mapLegacyMessageToRequest({
    convId: 'c1',
    conv,
    messageId: 'm2',
    message: {
      messageType: 'STUDENT_REQUEST',
      senderId: 'bob@example.com',
      requestItem: {isSelected: true},
    },
  });
  assert.equal(stud.kind, 'student');
  assert.equal(stud.status, 'accepted');
  assert.equal(stud.isAccepted, true);

  const sh = mapLegacyMessageToRequest({
    convId: 'c1',
    conv,
    messageId: 'm3',
    message: {
      messageType: 'STUDENT_HORSE_REQUEST',
      senderId: 'alice@example.com',
      status: 'declined',
      requestItem: {id: 'h1', name: 'Apollo', parentId: 'bob@example.com'},
    },
  });
  assert.equal(sh.kind, 'studentHorse');
  assert.equal(sh.status, 'declined');
  assert.equal(sh.horseId, 'h1');
  assert.equal(sh.horseOwnerId, 'bob@example.com');

  const xfer = mapLegacyMessageToRequest({
    convId: 'c1',
    conv,
    messageId: 'm4',
    message: {
      messageType: 'TRANSFER_HORSE_REQUEST',
      senderId: 'alice@example.com',
      status: 'cancelled',
      requestItem: {id: 'h2', name: 'Starlight'},
    },
  });
  assert.equal(xfer.kind, 'transferHorse');
  assert.equal(xfer.status, 'cancelled');
  assert.equal(xfer.horseId, 'h2');
});

test('backfillRequests supports dry-run, idempotent execution, resumability, and reconciliation', async () => {
  const db = createInMemoryFirestore({
    Conversations: {
      conv_a: {
        parties: ['Alice', 'Bob'],
        partiesIds: ['alice@example.com', 'bob@example.com'],
        messages: {
          m1: {messageType: 'INSTRUCTOR_REQUEST', senderId: 'alice@example.com', sender: 'Alice'},
          m2: {messageType: 'CHAT', senderId: 'alice@example.com'},
        },
      },
      conv_b: {
        parties: ['Bob', 'Cara'],
        partiesIds: ['bob@example.com', 'cara@example.com'],
        messages: {
          m3: {
            messageType: 'TRANSFER_HORSE_REQUEST',
            senderId: 'bob@example.com',
            sender: 'Bob',
            requestItem: {id: 'horse-1', name: 'Apollo'},
          },
        },
      },
    },
  });

  // 1. Default dry-run writes nothing.
  const dry = await backfillRequests(db, {projectId: 'demo-hrc'});
  assert.equal(dry.dryRun, true);
  assert.equal(dry.wouldCreate, 2);
  assert.equal(dry.created, 0);
  assert.equal(db._store.Requests.size, 0);

  // 2. Resumable execution with batchSize = 1.
  const page1 = await backfillRequests(db, {
    dryRun: false,
    projectId: 'demo-hrc',
    emulatorHost: '127.0.0.1:8089',
    batchSize: 1,
    maxConversations: 1,
  });
  assert.equal(page1.created, 1);
  assert.equal(page1.lastConvId, 'conv_a');

  const page2 = await backfillRequests(db, {
    dryRun: false,
    projectId: 'demo-hrc',
    emulatorHost: '127.0.0.1:8089',
    batchSize: 1,
    startAfterConvId: page1.lastConvId,
  });
  assert.equal(page2.created, 1);
  assert.equal(db._store.Requests.size, 2);

  // 3. Re-running is idempotent and reconciles with 0 mismatches.
  const rerun = await backfillRequests(db, {
    dryRun: false,
    projectId: 'demo-hrc',
    emulatorHost: '127.0.0.1:8089',
  });
  assert.equal(rerun.created, 0);
  assert.equal(rerun.skippedExisting, 2);
  assert.equal(rerun.reconciliation.legacyPendingTotal, 2);
  assert.equal(rerun.reconciliation.requestsPendingTotal, 2);
  assert.deepEqual(rerun.reconciliation.mismatchedUsers, []);
});

test('NEW-LOW-1: backfill skips canonical Requests/{messageId} for mirrored transferHorse while backfilling legacy-only requests', async () => {
  const canonicalConnectionId =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  const db = createInMemoryFirestore({
    Requests: {
      [canonicalConnectionId]: {
        id: canonicalConnectionId,
        messageId: canonicalConnectionId,
        kind: 'transferHorse',
        senderEmail: 'alice@example.com',
        recipientEmail: 'bob@example.com',
        partiesIds: ['alice@example.com', 'bob@example.com'],
        status: 'pending',
        isAccepted: false,
        horseId: 'horse-1',
        connectionId: canonicalConnectionId,
      },
    },
    Conversations: {
      conv_mirrored: {
        parties: ['Alice', 'Bob'],
        partiesIds: ['alice@example.com', 'bob@example.com'],
        messages: {
          [canonicalConnectionId]: {
            messageId: canonicalConnectionId,
            messageType: 'TRANSFER_HORSE_REQUEST',
            senderId: 'alice@example.com',
            sender: 'Alice',
            requestItem: {id: 'horse-1', name: 'Apollo'},
          },
          legacy_only_1: {
            messageId: 'legacy_only_1',
            messageType: 'INSTRUCTOR_REQUEST',
            senderId: 'alice@example.com',
            sender: 'Alice',
          },
        },
      },
    },
  });

  // 1. Dry-run skips the mirrored transferHorse (canonical doc exists) and counts only legacy_only_1.
  const dry = await backfillRequests(db, {projectId: 'demo-hrc'});
  assert.equal(dry.wouldCreate, 1);
  assert.equal(dry.skippedExisting, 1);
  assert.equal(db._store.Requests.size, 1);

  // 2. First execute creates only legacy_conv_mirrored_legacy_only_1, leaving canonical transfer untouched.
  const firstRun = await backfillRequests(db, {
    dryRun: false,
    projectId: 'demo-hrc',
    emulatorHost: '127.0.0.1:8089',
  });
  assert.equal(firstRun.created, 1);
  assert.equal(firstRun.skippedExisting, 1);
  assert.equal(db._store.Requests.size, 2);
  assert.equal(db._store.Requests.has(`legacy_conv_mirrored_${canonicalConnectionId}`), false);
  assert.equal(db._store.Requests.has('legacy_conv_mirrored_legacy_only_1'), true);
  assert.deepEqual(firstRun.reconciliation.mismatchedUsers, []);

  // 3. Repeated run is idempotent: 0 created, both skipped.
  const secondRun = await backfillRequests(db, {
    dryRun: false,
    projectId: 'demo-hrc',
    emulatorHost: '127.0.0.1:8089',
  });
  assert.equal(secondRun.created, 0);
  assert.equal(secondRun.skippedExisting, 2);
  assert.equal(db._store.Requests.size, 2);
  assert.deepEqual(secondRun.reconciliation.mismatchedUsers, []);
});
