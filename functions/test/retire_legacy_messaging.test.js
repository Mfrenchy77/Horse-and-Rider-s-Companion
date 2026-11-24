/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {
  RETIRED_BODY,
  RETIRED_USER,
  retireLegacyMessaging,
  validateRetirementEnvironment,
} = require('../retire_legacy_messaging');

function createMockDb(initial = []) {
  const docs = new Map(initial);
  const makeDocRef = (path) => ({
    path,
    id: path.split('/').pop(),
    collection: (sub) => makeCollectionRef(`${path}/${sub}`),
    get: async () => ({
      exists: docs.has(path),
      id: path.split('/').pop(),
      ref: makeDocRef(path),
      data: () => structuredClone(docs.get(path)),
    }),
    update: async (patch) => {
      const prev = docs.get(path) || {};
      docs.set(path, {...prev, ...structuredClone(patch)});
    },
    delete: async () => {
      docs.delete(path);
    },
  });
  const makeCollectionRef = (prefix) => {
    const depth = prefix.split('/').length + 1;
    const listDirect = () => [...docs.entries()]
        .filter(([p]) => p.startsWith(`${prefix}/`) && p.split('/').length === depth);
    return {
      doc: (id) => makeDocRef(`${prefix}/${id}`),
      get: async () => ({
        docs: listDirect().map(([p, d]) => ({
          id: p.split('/').pop(),
          ref: makeDocRef(p),
          exists: true,
          data: () => structuredClone(d),
        })),
      }),
    };
  };
  return {docs, collection: (name) => makeCollectionRef(name)};
}

test('validateRetirementEnvironment refuses production execution without explicit confirmation', () => {
  assert.throws(
      () => validateRetirementEnvironment({dryRun: false, projectId: 'prod-proj', emulatorHost: ''}),
      /Refusing non-emulator writes/,
  );
  const prodDry = validateRetirementEnvironment({dryRun: true, projectId: 'prod-proj', emulatorHost: ''});
  assert.equal(prodDry.dryRun, true);
  assert.equal(prodDry.isEmulator, false);
});

test('retireLegacyMessaging defaults to dry-run and anonymizes Conversations/Messages on execute', async () => {
  const db = createMockDb([
    ['Conversations/c1', {
      partiesIds: ['alice@example.com', 'bob@example.com'],
      parties: ['Alice', 'Bob'],
      createdBy: 'Alice',
      lastEditBy: 'Bob',
      recentMessage: {
        sender: 'Alice',
        senderId: 'alice@example.com',
        senderProfilePicUrl: 'https://example.com/a.jpg',
        message: 'Hello Bob',
        recipients: ['Bob'],
      },
    }],
    ['Conversations/c1/Messages/m1', {
      sender: 'Alice',
      senderId: 'alice@example.com',
      senderProfilePicUrl: 'https://example.com/a.jpg',
      message: 'Hello Bob',
      messageType: 'CHAT',
      recipients: ['Bob'],
    }],
  ]);

  const dry = await retireLegacyMessaging(db, {projectId: 'demo-test'});
  assert.equal(dry.dryRun, true);
  assert.equal(dry.wouldAnonymizeConversations, 1);
  assert.equal(dry.wouldAnonymizeMessages, 1);
  assert.equal(db.docs.get('Conversations/c1').createdBy, 'Alice');

  const exec = await retireLegacyMessaging(db, {
    projectId: 'demo-test',
    dryRun: false,
    confirmProduction: true,
  });
  assert.equal(exec.anonymizedConversations, 1);
  assert.equal(exec.anonymizedMessages, 1);
  const conv = db.docs.get('Conversations/c1');
  assert.equal(conv.createdBy, RETIRED_USER);
  assert.deepEqual(conv.parties, [RETIRED_USER, RETIRED_USER]);
  assert.equal(conv.recentMessage.message, RETIRED_BODY);
  const msg = db.docs.get('Conversations/c1/Messages/m1');
  assert.equal(msg.sender, RETIRED_USER);
  assert.equal(msg.message, RETIRED_BODY);
});

test('purge mode blocks when unmigrated pending request exists and deletes cleanly once migrated', async () => {
  const db = createMockDb([
    ['Conversations/c2', {partiesIds: ['a@example.com', 'b@example.com']}],
    ['Conversations/c2/Messages/m-req', {
      messageId: 'm-req',
      messageType: 'INSTRUCTOR_REQUEST',
      senderId: 'a@example.com',
      requestItem: {isSelected: false},
    }],
  ]);

  await assert.rejects(
      () => retireLegacyMessaging(db, {
        projectId: 'demo-test',
        dryRun: true,
        mode: 'purge',
      }),
      /unmigrated pending request/,
  );

  await db.collection('Requests').doc('legacy_c2_m-req').set?.({status: 'pending'});
  // Insert migrated doc directly into mock Map
  db.docs.set('Requests/legacy_c2_m-req', {status: 'pending'});

  const exec = await retireLegacyMessaging(db, {
    projectId: 'demo-test',
    dryRun: false,
    mode: 'purge',
    confirmProduction: true,
  });
  assert.equal(exec.deletedConversations, 1);
  assert.equal(exec.deletedMessages, 1);
  assert.equal(db.docs.has('Conversations/c2'), false);
  assert.equal(db.docs.has('Conversations/c2/Messages/m-req'), false);
});
