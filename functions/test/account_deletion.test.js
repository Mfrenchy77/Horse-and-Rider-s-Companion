/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {accountDeletionHandler, DELETED_NAME, profileId} = require('../account_deletion');

function createFirestoreMock(initial = []) {
  const docs = new Map(initial);

  function makeDocRef(path) {
    return {
      path,
      id: path.split('/').pop(),
      collection: (sub) => makeCollectionRef(`${path}/${sub}`),
      get: async () => ({
        exists: docs.has(path),
        id: path.split('/').pop(),
        ref: makeDocRef(path),
        data: () => structuredClone(docs.get(path)),
      }),
      set: async (data, opts) => {
        if (opts && opts.merge && docs.has(path)) {
          const prev = docs.get(path);
          const next = {...prev, ...structuredClone(data)};
          if (data.steps && prev.steps) {
            next.steps = {...prev.steps, ...data.steps};
          }
          docs.set(path, next);
        } else {
          docs.set(path, structuredClone(data));
        }
      },
      update: async (patch) => {
        const prev = docs.get(path) || {};
        docs.set(path, {...prev, ...structuredClone(patch)});
      },
      delete: async () => {
        docs.delete(path);
      },
    };
  }

  function makeCollectionRef(prefix) {
    const depth = prefix.split('/').length + 1;
    const listDirectDocs = () => [...docs.entries()]
        .filter(([p]) => p.startsWith(`${prefix}/`) && p.split('/').length === depth);

    return {
      doc: (id) => makeDocRef(`${prefix}/${id}`),
      get: async () => ({
        docs: listDirectDocs().map(([p, d]) => ({
          id: p.split('/').pop(),
          ref: makeDocRef(p),
          exists: true,
          data: () => structuredClone(d),
        })),
      }),
      where: (field, op, value) => ({
        get: async () => ({
          docs: listDirectDocs()
              .filter(([, d]) => {
                if (op === '==') return d[field] === value;
                if (op === 'array-contains') {
                  return Array.isArray(d[field]) && d[field].includes(value);
                }
                return false;
              })
              .map(([p, d]) => ({
                id: p.split('/').pop(),
                ref: makeDocRef(p),
                exists: true,
                data: () => structuredClone(d),
              })),
        }),
      }),
    };
  }

  return {
    docs,
    collection: (name) => makeCollectionRef(name),
  };
}

test('rejects unauthenticated and stale-login account deletion requests', async () => {
  const db = createFirestoreMock();
  const auth = {deleteUser: async () => {}, revokeRefreshTokens: async () => {}};
  const handler = accountDeletionHandler(db, auth, null, {
    maxAuthAgeSeconds: 300,
    nowSeconds: () => 1000,
  });

  await assert.rejects(
      () => handler({auth: null}),
      (err) => err.code === 'unauthenticated',
  );

  await assert.rejects(
      () => handler({
        auth: {
          uid: 'u1',
          token: {email: 'rider@example.com', auth_time: 500, firebase: {sign_in_provider: 'password'}},
        },
      }),
      (err) => err.code === 'failed-precondition' && err.details?.code === 'requires-recent-login',
  );
});

test('transfers owned horses to verified admin, preserves legacy conversations, and cleans user data', async () => {
  const riderEmail = 'rider@example.com';
  const coachEmail = 'coach@example.com';
  const adminEmail = 'horseandriderscompanion@gmail.com';
  const riderDocId = profileId(riderEmail);
  const coachDocId = profileId(coachEmail);
  const adminDocId = profileId(adminEmail);

  const db = createFirestoreMock([
    [`Rider_Profile/${riderDocId}`, {email: riderEmail, name: 'Rider', ownedHorses: [{id: 'atlas'}]}],
    [`Rider_Profile/${coachDocId}`, {
      email: coachEmail,
      name: 'Coach',
      students: [{id: riderEmail, name: 'Rider'}],
      studentHorses: [{id: 'atlas', name: 'Atlas'}],
      instructors: [],
    }],
    [`Rider_Profile/${adminDocId}`, {
      email: adminEmail,
      name: 'Horse And Rider\'s Companion',
      ownedHorses: [],
    }],
    ['Horse_Profile/atlas', {
      id: 'atlas',
      name: 'Atlas',
      currentOwnerId: riderEmail,
      currentOwnerName: 'Rider',
      archiveStatus: 'active',
      saleListing: {price: '$5000'},
      transferRequestId: 'conn-transfer',
      lastEditBy: riderEmail,
      notes: [{id: 'n1', note: 'Lesson 1'}],
      skillLevels: [{skillId: 's1', verified: true}],
      instructors: [{id: coachEmail, name: 'Coach'}],
    }],
    ['CoachingConnections/conn-transfer', {
      kind: 'transfer',
      horseId: 'atlas',
      status: 'pending',
      participantUids: ['u-rider', 'u-coach'],
      learnerEmail: riderEmail,
      coachEmail: coachEmail,
      learnerUid: 'u-rider',
      coachUid: 'u-coach',
    }],
    ['SharedRidingEntries/entry-owned', {riderUid: 'u-rider', authorUid: 'u-rider', horseId: 'atlas'}],
    ['SharedRidingEntries/entry-authored', {
      riderUid: 'u-coach',
      authorUid: 'u-rider',
      note: {riderLog: {instructor: 'Rider'}},
    }],
    ['Conversations/conv-shared', {
      partiesIds: [riderEmail, coachEmail],
      parties: [{id: riderEmail}, {id: coachEmail}],
      createdBy: riderEmail,
    }],
    ['Conversations/conv-shared/Messages/m1', {
      sender: 'Rider',
      senderId: riderEmail,
      senderProfilePicUrl: 'https://example.com/pic.jpg',
    }],
    ['Resources/res-1', {
      authorId: 'u-rider',
      authorName: 'Rider',
      authorPhoto: 'https://example.com/pic.jpg',
      lastEditBy: riderEmail,
      comments: [{
        id: 'c1',
        user: {id: riderEmail, name: 'Rider'},
        usersWhoRated: [{id: riderEmail, isSelected: true}],
      }],
    }],
    ['Resources/res-1/usersWhoRated/rider@example.com', {id: riderEmail, isSelected: true}],
    [`RiderProfiles/${riderEmail}/tokens/tok-1`, {token: 'tok-1'}],
  ]);

  const deletedFiles = [];
  const deletedPrefixes = [];
  const bucket = {
    file: (path) => ({delete: async () => deletedFiles.push(path)}),
    deleteFiles: async ({prefix}) => deletedPrefixes.push(prefix),
  };

  let revoked = false;
  let deletedUid = null;
  const auth = {
    revokeRefreshTokens: async (uid) => {
      assert.equal(uid, 'u-rider');
      revoked = true;
    },
    getUserByEmail: async (email) => {
      if (email === adminEmail) return {uid: 'u-admin', email: adminEmail};
      const err = new Error('not found');
      err.code = 'auth/user-not-found';
      throw err;
    },
    deleteUser: async (uid) => {
      deletedUid = uid;
    },
  };

  const handler = accountDeletionHandler(db, auth, bucket, {
    nowSeconds: () => 1000,
    adminEmail,
  });
  const result = await handler({
    auth: {
      uid: 'u-rider',
      token: {email: riderEmail, auth_time: 950, firebase: {sign_in_provider: 'password'}},
    },
  });

  assert.equal(result.status, 'completed');
  assert.equal(revoked, true);
  assert.equal(deletedUid, 'u-rider');
  assert.equal(db.docs.has(`Rider_Profile/${riderDocId}`), false);
  assert.equal(db.docs.has(`RiderProfiles/${riderEmail}/tokens/tok-1`), false);
  assert.equal(db.docs.has('SharedRidingEntries/entry-owned'), false);
  assert.equal(db.docs.has('Resources/res-1/usersWhoRated/rider@example.com'), false);
  assert.equal(db.docs.has('DeletionJobs/u-rider'), false);

  // Owned horse transferred to verified administrative account, preserving history
  const horse = db.docs.get('Horse_Profile/atlas');
  assert.equal(horse.currentOwnerId, adminEmail);
  assert.equal(horse.currentOwnerName, 'Horse And Rider\'s Companion');
  assert.equal(horse.saleListing, null);
  assert.equal(horse.transferRequestId, null);
  assert.equal(horse.lastEditBy, DELETED_NAME);
  assert.deepEqual(horse.notes, [{id: 'n1', note: 'Lesson 1'}]);
  assert.deepEqual(horse.skillLevels, [{skillId: 's1', verified: true}]);
  assert.deepEqual(horse.instructors, [{id: coachEmail, name: 'Coach'}]);

  const adminProfile = db.docs.get(`Rider_Profile/${adminDocId}`);
  assert.deepEqual(adminProfile.ownedHorses, [{id: 'atlas', name: 'Atlas'}]);

  const coachProfile = db.docs.get(`Rider_Profile/${coachDocId}`);
  assert.deepEqual(coachProfile.students, []);
  assert.deepEqual(coachProfile.studentHorses, []);

  // Legacy Conversations/Messages remain untouched pending discontinuation policy
  const sharedConv = db.docs.get('Conversations/conv-shared');
  assert.deepEqual(sharedConv.partiesIds, [riderEmail, coachEmail]);
  const sharedMsg = db.docs.get('Conversations/conv-shared/Messages/m1');
  assert.equal(sharedMsg.sender, 'Rider');

  const res = db.docs.get('Resources/res-1');
  assert.equal(res.authorName, DELETED_NAME);
  assert.equal(res.comments[0].user.name, DELETED_NAME);
  assert.deepEqual(res.comments[0].usersWhoRated, []);

  assert.ok(deletedFiles.includes(`Riders_Photo/${riderDocId}`));
  assert.ok(deletedPrefixes.includes(`covers/${riderEmail}/`));
});

test('blocks horse transfer if administrative account cannot be verified', async () => {
  const riderEmail = 'owner@example.com';
  const db = createFirestoreMock([
    ['Horse_Profile/atlas', {id: 'atlas', name: 'Atlas', currentOwnerId: riderEmail}],
  ]);
  const auth = {
    revokeRefreshTokens: async () => {},
    getUserByEmail: async () => {
      const err = new Error('not found');
      err.code = 'auth/user-not-found';
      throw err;
    },
    deleteUser: async () => {},
  };

  const handler = accountDeletionHandler(db, auth, null, {
    nowSeconds: () => 1000,
    adminEmail: 'missing-admin@example.com',
  });

  await assert.rejects(
      () => handler({
        auth: {
          uid: 'u-owner',
          token: {email: riderEmail, auth_time: 950, firebase: {sign_in_provider: 'password'}},
        },
      }),
      (err) => err.code === 'failed-precondition' && err.details?.code === 'admin-account-not-found',
  );
  assert.equal(db.docs.get('Horse_Profile/atlas').currentOwnerId, riderEmail);
});

test('retries idempotently from failed step after partial failure', async () => {
  const riderEmail = 'retry@example.com';
  const db = createFirestoreMock([
    [`Rider_Profile/${profileId(riderEmail)}`, {email: riderEmail, name: 'Retry'}],
  ]);

  let failStorageOnce = true;
  const bucket = {
    file: () => ({
      delete: async () => {
        if (failStorageOnce) {
          failStorageOnce = false;
          throw new Error('Transient storage failure');
        }
      },
    }),
  };

  let deleteAuthCalls = 0;
  const auth = {
    revokeRefreshTokens: async () => {},
    deleteUser: async () => {
      deleteAuthCalls += 1;
    },
  };

  const handler = accountDeletionHandler(db, auth, bucket, {nowSeconds: () => 1000});
  const req = {
    auth: {
      uid: 'u-retry',
      token: {email: riderEmail, auth_time: 950, firebase: {sign_in_provider: 'password'}},
    },
  };

  await assert.rejects(() => handler(req), (err) => err.code === 'internal');
  const failedJob = db.docs.get('DeletionJobs/u-retry');
  assert.equal(failedJob.status, 'failed_retryable');
  assert.equal(failedJob.steps.profileAndTokens, true);
  assert.equal(failedJob.steps.storage, undefined);
  assert.equal(deleteAuthCalls, 0);

  const retryResult = await handler(req);
  assert.equal(retryResult.status, 'completed');
  assert.equal(deleteAuthCalls, 1);
  assert.equal(db.docs.has('DeletionJobs/u-retry'), false);
});

test('cancels pending Requests involving the deleted user', async () => {
  const riderEmail = 'leaving@example.com';
  const otherEmail = 'staying@example.com';
  const db = createFirestoreMock([
    [`Rider_Profile/${profileId(riderEmail)}`, {email: riderEmail, name: 'Leaving'}],
    ['Requests/req-pending', {
      status: 'pending',
      partiesIds: [riderEmail, otherEmail],
      senderEmail: riderEmail,
      recipientEmail: otherEmail,
    }],
    ['Requests/req-unrelated', {
      status: 'pending',
      partiesIds: ['a@example.com', otherEmail],
      senderEmail: 'a@example.com',
      recipientEmail: otherEmail,
    }],
  ]);
  const auth = {
    revokeRefreshTokens: async () => {},
    deleteUser: async () => {},
  };
  const handler = accountDeletionHandler(db, auth, null, {nowSeconds: () => 2000});
  const result = await handler({
    auth: {
      uid: 'u-leaving',
      token: {email: riderEmail, auth_time: 1990, firebase: {sign_in_provider: 'password'}},
    },
  });
  assert.equal(result.status, 'completed');
  assert.equal(db.docs.get('Requests/req-pending').status, 'cancelled');
  assert.equal(db.docs.get('Requests/req-pending').dismissalNote, 'Account deleted');
  assert.equal(db.docs.get('Requests/req-unrelated').status, 'pending');
});

test('preserves retryable DeletionJob when Storage cleanup fails with non-404 error', async () => {
  const riderEmail = 'storagefail@example.com';
  const db = createFirestoreMock([
    [`Rider_Profile/${profileId(riderEmail)}`, {email: riderEmail, name: 'Storage Fail'}],
  ]);
  let authDeleted = false;
  const auth = {
    revokeRefreshTokens: async () => {},
    deleteUser: async () => {
      authDeleted = true;
    },
  };
  const bucket = {
    file: () => ({
      delete: async () => {
        const err = new Error('Storage unavailable');
        err.code = 500;
        throw err;
      },
    }),
  };
  const handler = accountDeletionHandler(db, auth, bucket, {nowSeconds: () => 3000});
  await assert.rejects(
      () => handler({
        auth: {
          uid: 'u-storage-fail',
          token: {email: riderEmail, auth_time: 2990, firebase: {sign_in_provider: 'password'}},
        },
      }),
      /Account deletion could not be completed/i,
  );
  assert.equal(authDeleted, false);
  const job = db.docs.get('DeletionJobs/u-storage-fail');
  assert.equal(job.status, 'failed_retryable');
  assert.equal(job.steps.profileAndTokens, true);
  assert.equal(job.steps.storage, undefined);
});
