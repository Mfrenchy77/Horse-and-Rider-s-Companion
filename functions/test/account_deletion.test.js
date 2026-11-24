/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {
  accountDeletionHandler,
  DELETED_NAME,
  DEFAULT_ADMIN_ACCOUNT_EMAIL,
  profileId,
} = require('../account_deletion');

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
    runTransaction: async (fn) => {
      const tx = {
        get: (ref) => ref.get(),
        set: (ref, data, opts) => ref.set(data, opts),
        update: (ref, patch) => ref.update(patch),
      };
      return fn(tx);
    },
  };
}

test('rejects unauthenticated, guest, stale-login, and admin self-deletion requests', async () => {
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
          uid: 'u-guest',
          token: {email: 'guest@example.com', auth_time: 999, firebase: {sign_in_provider: 'anonymous'}},
        },
      }),
      (err) => err.code === 'permission-denied' && err.details?.code === 'guest-not-allowed',
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

  await assert.rejects(
      () => handler({
        auth: {
          uid: 'u-admin',
          token: {email: DEFAULT_ADMIN_ACCOUNT_EMAIL, auth_time: 990, firebase: {sign_in_provider: 'password'}},
        },
      }),
      (err) => err.code === 'failed-precondition' && err.details?.code === 'cannot-delete-admin-account',
  );
});

test('handles rider with no horses cleanly and removes rider subcollections & public projection', async () => {
  const riderEmail = 'nohorse@example.com';
  const docId = profileId(riderEmail);
  const db = createFirestoreMock([
    [`Rider_Profile/${docId}`, {email: riderEmail, ownerUid: 'u-nh', name: 'No Horse Rider'}],
    [`Rider_Profile/${docId}/SkillProgress/rider.in_hand.leading`, {levels: {introductory: {state: 'LEARNING'}}}],
    [`Rider_Profile/${docId}/SkillVerifications/rider.in_hand.leading`, {verified: true}],
    [`Rider_Profile/${docId}/SkillVerificationEvents/ev1`, {status: 'verified'}],
    [`Public_Rider_Profile/${docId}`, {id: docId, email: riderEmail, name: 'No Horse Rider'}],
    ['SkillTreeSuggestions/sug-1', {
      submittedByUid: 'u-nh',
      submitterEmail: riderEmail,
      submitterName: 'No Horse Rider',
      title: 'Add ground tying note',
    }],
  ]);
  let deletedUid = null;
  const auth = {
    revokeRefreshTokens: async () => {},
    deleteUser: async (uid) => {
      deletedUid = uid;
    },
  };

  const handler = accountDeletionHandler(db, auth, null, {nowSeconds: () => 1000});
  const result = await handler({
    auth: {
      uid: 'u-nh',
      token: {email: riderEmail, auth_time: 990, firebase: {sign_in_provider: 'password'}},
    },
  });

  assert.equal(result.status, 'completed');
  assert.equal(result.horsesTransferred, 0);
  assert.equal(deletedUid, 'u-nh');
  assert.equal(db.docs.has(`Rider_Profile/${docId}`), false);
  assert.equal(db.docs.has(`Rider_Profile/${docId}/SkillProgress/rider.in_hand.leading`), false);
  assert.equal(db.docs.has(`Rider_Profile/${docId}/SkillVerifications/rider.in_hand.leading`), false);
  assert.equal(db.docs.has(`Rider_Profile/${docId}/SkillVerificationEvents/ev1`), false);
  assert.equal(db.docs.has(`Public_Rider_Profile/${docId}`), false);

  const suggestion = db.docs.get('SkillTreeSuggestions/sug-1');
  assert.equal(suggestion.submitterName, DELETED_NAME);
  assert.equal(suggestion.submitterEmail, '');
  assert.equal(suggestion.submittedByUid, 'deleted:u-nh');

  const job = db.docs.get('DeletionJobs/u-nh');
  assert.equal(job.status, 'completed');
  assert.equal(job.email, undefined);
  assert.equal(job.horsesTransferredCount, 0);
});

test('transfers multiple active/archived/for-sale/private horses, preserves histories, and cleans PII', async () => {
  const riderEmail = 'rider@example.com';
  const coachEmail = 'coach@example.com';
  const studentEmail = 'student@example.com';
  const otherOwnerEmail = 'other@example.com';
  const adminEmail = DEFAULT_ADMIN_ACCOUNT_EMAIL;
  const riderDocId = profileId(riderEmail);
  const coachDocId = profileId(coachEmail);
  const studentDocId = profileId(studentEmail);
  const adminDocId = profileId(adminEmail);

  const db = createFirestoreMock([
    [`Rider_Profile/${riderDocId}`, {
      email: riderEmail,
      ownerUid: 'u-rider',
      name: 'Rider',
      ownedHorses: [{id: 'atlas', name: 'Atlas'}, {id: 'foreign-horse', name: 'Not Mine'}],
      archivedHorses: [{id: 'old-pal', name: 'Old Pal'}],
      instructors: [{id: coachEmail, name: 'Coach'}],
      students: [{id: studentEmail, name: 'Student'}],
    }],
    [`Public_Rider_Profile/${riderDocId}`, {id: riderDocId, email: riderEmail, name: 'Rider'}],
    [`Rider_Profile/${coachDocId}`, {
      email: coachEmail,
      ownerUid: 'u-coach',
      name: 'Coach',
      students: [{id: riderEmail, name: 'Rider'}],
      studentHorses: [{id: 'atlas', name: 'Atlas'}],
      instructors: [],
    }],
    [`Rider_Profile/${studentDocId}`, {
      email: studentEmail,
      ownerUid: 'u-student',
      name: 'Student',
      instructors: [{id: riderEmail, name: 'Rider'}],
      instructorUids: ['u-rider'],
    }],
    [`Rider_Profile/${adminDocId}`, {
      email: adminEmail,
      ownerUid: 'u-admin',
      name: 'Horse And Rider\'s Companion',
      ownedHorses: [],
      archivedHorses: [],
    }],
    ['Horse_Profile/atlas', {
      id: 'atlas',
      name: 'Atlas',
      isPublic: true,
      currentOwnerId: riderEmail,
      ownerUid: 'u-rider',
      currentOwnerName: 'Rider',
      archiveStatus: 'active',
      saleListing: {price: '$5000', location: 'TX', description: 'Nice horse'},
      transferRequestId: 'conn-transfer',
      lastEditBy: riderEmail,
      picUrl: 'https://example.com/horses/atlas.jpg',
      notes: [{id: 'n1', note: 'Lesson 1'}],
      skillLevels: [{skillId: 's1', verified: true}],
      instructors: [{id: coachEmail, name: 'Coach'}],
      instructorUids: ['u-coach'],
    }],
    ['Public_Horse_Profile/atlas', {
      id: 'atlas',
      name: 'Atlas',
      isPublic: true,
      archiveStatus: 'active',
      saleListing: {price: '$5000', location: 'TX', description: 'Nice horse'},
    }],
    ['Horse_Profile/atlas/SkillProgress/horse.in_hand.leading', {
      skillId: 'horse.in_hand.leading',
      subject: 'horse',
      levels: {
        introductory: {state: 'PROFICIENT', updatedByUid: 'u-rider', updatedByName: 'Rider'},
      },
    }],
    ['Horse_Profile/atlas/SkillVerifications/horse.in_hand.leading', {verified: true, verifiedBy: 'Coach'}],
    ['Horse_Profile/atlas/SkillVerificationEvents/hev1', {status: 'verified', horseId: 'atlas'}],
    ['Horse_Profile/old-pal', {
      id: 'old-pal',
      name: 'Old Pal',
      isPublic: false,
      currentOwnerId: 'stale-casing@EXAMPLE.com',
      ownerUid: 'u-rider',
      archiveStatus: 'archived',
      notes: [{id: 'n-old', name: 'Retired safely'}],
    }],
    ['Horse_Profile/other-owned', {
      id: 'other-owned',
      name: 'Other Horse',
      currentOwnerId: otherOwnerEmail,
      ownerUid: 'u-other',
      instructors: [{id: riderEmail, name: 'Rider'}, {id: coachEmail, name: 'Coach'}],
      instructorUids: ['u-rider', 'u-coach'],
    }],
    ['Horse_Profile/foreign-horse', {
      id: 'foreign-horse',
      name: 'Foreign Horse',
      currentOwnerId: otherOwnerEmail,
      ownerUid: 'u-other',
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
      parties: ['Rider', 'Coach'],
      createdBy: 'Rider',
      lastEditBy: riderEmail,
      recentMessage: {
        sender: 'Rider',
        senderId: riderEmail,
        senderProfilePicUrl: 'https://example.com/pic.jpg',
        message: 'Private chat text from departing user',
        messageType: 'CHAT',
        recipients: ['Coach'],
      },
    }],
    ['Conversations/conv-shared/Messages/m1', {
      sender: 'Rider',
      senderId: riderEmail,
      senderProfilePicUrl: 'https://example.com/pic.jpg',
      message: 'Private chat text from departing user',
      messageType: 'CHAT',
      recipients: ['Coach'],
    }],
    ['Conversations/conv-shared/Messages/m2', {
      sender: 'Coach',
      senderId: coachEmail,
      senderProfilePicUrl: 'https://example.com/coach.jpg',
      message: 'Coach message should remain readable by Coach',
      messageType: 'CHAT',
      recipients: ['Rider'],
    }],
    ['Conversations/conv-solo', {
      partiesIds: [riderEmail, 'deleted:u-old'],
      parties: ['Rider', DELETED_NAME],
      createdBy: riderEmail,
    }],
    ['Conversations/conv-solo/Messages/ms1', {
      sender: 'Rider',
      senderId: riderEmail,
      message: 'Should be deleted with solo conversation',
      messageType: 'CHAT',
    }],
    ['Resources/res-1', {
      authorId: 'u-rider',
      authorName: 'Rider',
      authorPhoto: 'https://example.com/pic.jpg',
      lastEditBy: riderEmail,
      comments: [{
        id: 'c1',
        user: {id: riderEmail, name: 'Rider', imageUrl: 'https://example.com/pic.jpg'},
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
  assert.equal(result.horsesTransferred, 2);
  assert.equal(revoked, true);
  assert.equal(deletedUid, 'u-rider');
  assert.equal(db.docs.has(`Rider_Profile/${riderDocId}`), false);
  assert.equal(db.docs.has(`Public_Rider_Profile/${riderDocId}`), false);
  assert.equal(db.docs.has(`RiderProfiles/${riderEmail}/tokens/tok-1`), false);
  assert.equal(db.docs.has('SharedRidingEntries/entry-owned'), false);
  assert.equal(db.docs.has('Resources/res-1/usersWhoRated/rider@example.com'), false);

  // Owned active public for-sale horse transferred cleanly
  const horse = db.docs.get('Horse_Profile/atlas');
  assert.equal(horse.currentOwnerId, adminEmail);
  assert.equal(horse.ownerUid, 'u-admin');
  assert.equal(horse.administrativeHold, true);
  assert.equal(horse.saleListing, null);
  assert.equal(horse.transferRequestId, null);
  assert.deepEqual(horse.instructors, []);
  assert.deepEqual(horse.instructorUids, []);
  assert.equal(horse.isPublic, true);
  assert.equal(horse.lastEditBy, DELETED_NAME);
  assert.deepEqual(horse.notes, [{id: 'n1', note: 'Lesson 1'}]);
  assert.deepEqual(horse.skillLevels, [{skillId: 's1', verified: true}]);
  assert.equal(horse.ownershipHistory[0].ownerRef, 'deleted:u-rider');

  // Public projection updated without saleListing
  const pubHorse = db.docs.get('Public_Horse_Profile/atlas');
  assert.equal(pubHorse.saleListing, undefined);
  assert.equal(pubHorse.name, 'Atlas');

  // Horse V2 progress & verifications preserved, owner name minimized
  const horseProg = db.docs.get('Horse_Profile/atlas/SkillProgress/horse.in_hand.leading');
  assert.equal(horseProg.levels.introductory.state, 'PROFICIENT');
  assert.equal(horseProg.levels.introductory.updatedByName, 'Former Owner');
  assert.equal(horseProg.levels.introductory.updatedByUid, 'deleted:u-rider');
  assert.equal(db.docs.get('Horse_Profile/atlas/SkillVerifications/horse.in_hand.leading').verified, true);
  assert.equal(db.docs.get('Horse_Profile/atlas/SkillVerificationEvents/hev1').status, 'verified');

  // Archived private horse discovered by ownerUid even with mismatched currentOwnerId casing, remains private
  const oldPal = db.docs.get('Horse_Profile/old-pal');
  assert.equal(oldPal.ownerUid, 'u-admin');
  assert.equal(oldPal.currentOwnerId, adminEmail);
  assert.equal(oldPal.isPublic, false);
  assert.equal(oldPal.archiveStatus, 'archived');
  assert.equal(db.docs.has('Public_Horse_Profile/old-pal'), false);

  // Foreign horse referenced in rider's roster was NOT stolen
  assert.equal(db.docs.get('Horse_Profile/foreign-horse').ownerUid, 'u-other');

  // Admin roster reflects active vs archived split
  const adminProfile = db.docs.get(`Rider_Profile/${adminDocId}`);
  assert.deepEqual(adminProfile.ownedHorses.map((h) => h.id), ['atlas']);
  assert.deepEqual(adminProfile.archivedHorses.map((h) => h.id), ['old-pal']);

  // Connected riders & other owners' horses have instructorUids cleaned
  const coachProfile = db.docs.get(`Rider_Profile/${coachDocId}`);
  assert.deepEqual(coachProfile.students, []);
  assert.deepEqual(coachProfile.studentHorses, []);
  const studentProfile = db.docs.get(`Rider_Profile/${studentDocId}`);
  assert.deepEqual(studentProfile.instructors, []);
  assert.deepEqual(studentProfile.instructorUids, []);
  const otherHorse = db.docs.get('Horse_Profile/other-owned');
  assert.deepEqual(otherHorse.instructorUids, ['u-coach']);
  assert.deepEqual(otherHorse.instructors.map((i) => i.id), [coachEmail]);

  // Legacy Conversations/Messages anonymize departing user while preserving surviving user's messages;
  // solo/all-deleted conversations are removed completely.
  const sharedConv = db.docs.get('Conversations/conv-shared');
  assert.deepEqual(sharedConv.partiesIds, ['deleted:u-rider', coachEmail]);
  assert.deepEqual(sharedConv.parties, [DELETED_NAME, 'Coach']);
  assert.equal(sharedConv.createdBy, DELETED_NAME);
  assert.equal(sharedConv.lastEditBy, DELETED_NAME);
  assert.equal(sharedConv.recentMessage.sender, DELETED_NAME);
  assert.equal(sharedConv.recentMessage.senderId, 'deleted:u-rider');
  assert.equal(sharedConv.recentMessage.senderProfilePicUrl, '');
  assert.equal(sharedConv.recentMessage.message, '[Message removed — account deleted]');

  const sharedMsg1 = db.docs.get('Conversations/conv-shared/Messages/m1');
  assert.equal(sharedMsg1.sender, DELETED_NAME);
  assert.equal(sharedMsg1.senderId, 'deleted:u-rider');
  assert.equal(sharedMsg1.senderProfilePicUrl, '');
  assert.equal(sharedMsg1.message, '[Message removed — account deleted]');

  const sharedMsg2 = db.docs.get('Conversations/conv-shared/Messages/m2');
  assert.equal(sharedMsg2.sender, 'Coach');
  assert.equal(sharedMsg2.senderId, coachEmail);
  assert.equal(sharedMsg2.message, 'Coach message should remain readable by Coach');
  assert.deepEqual(sharedMsg2.recipients, [DELETED_NAME]);

  assert.equal(db.docs.has('Conversations/conv-solo'), false);
  assert.equal(db.docs.has('Conversations/conv-solo/Messages/ms1'), false);

  const res = db.docs.get('Resources/res-1');
  assert.equal(res.authorName, DELETED_NAME);
  assert.equal(res.comments[0].user.name, DELETED_NAME);
  assert.equal(res.comments[0].user.imageUrl, '');
  assert.deepEqual(res.comments[0].usersWhoRated, []);

  assert.ok(deletedFiles.includes(`Riders_Photo/${riderDocId}`));
  assert.ok(deletedPrefixes.includes(`covers/${riderEmail}/`));
});

test('blocks horse transfer BEFORE mutating connections/tokens if admin account is invalid', async () => {
  const riderEmail = 'owner@example.com';
  const db = createFirestoreMock([
    ['Horse_Profile/atlas', {id: 'atlas', name: 'Atlas', currentOwnerId: riderEmail, ownerUid: 'u-owner'}],
    ['Requests/req-1', {status: 'pending', partiesIds: [riderEmail, 'coach@example.com']}],
  ]);
  let revoked = false;
  const auth = {
    revokeRefreshTokens: async () => {
      revoked = true;
    },
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
  assert.equal(revoked, false);
  assert.equal(db.docs.get('Horse_Profile/atlas').currentOwnerId, riderEmail);
  assert.equal(db.docs.get('Requests/req-1').status, 'pending');
});

test('rejects duplicate in-progress requests, handles missing Auth user on retry, and completes idempotently', async () => {
  const riderEmail = 'retry@example.com';
  const adminEmail = DEFAULT_ADMIN_ACCOUNT_EMAIL;
  const db = createFirestoreMock([
    [`Rider_Profile/${profileId(riderEmail)}`, {email: riderEmail, ownerUid: 'u-retry', name: 'Retry'}],
    [`Rider_Profile/${profileId(adminEmail)}`, {email: adminEmail, ownerUid: 'u-admin', name: 'Admin'}],
    ['DeletionJobs/u-retry', {
      uid: 'u-retry',
      status: 'in_progress',
      lockExpiresAt: 1060,
      steps: {horses: true},
    }],
  ]);

  let failStorageOnce = true;
  const bucket = {
    file: () => ({
      delete: async () => {
        if (failStorageOnce) {
          failStorageOnce = false;
          const err = new Error('Transient storage failure');
          err.code = 500;
          throw err;
        }
      },
    }),
  };

  const auth = {
    getUserByEmail: async (email) => ({uid: 'u-admin', email}),
    revokeRefreshTokens: async () => {
      const err = new Error('not found');
      err.code = 'auth/user-not-found';
      throw err;
    },
    deleteUser: async () => {
      const err = new Error('not found');
      err.code = 'auth/user-not-found';
      throw err;
    },
  };

  const handler = accountDeletionHandler(db, auth, bucket, {nowSeconds: () => 1000});
  const req = {
    auth: {
      uid: 'u-retry',
      token: {email: riderEmail, auth_time: 950, firebase: {sign_in_provider: 'password'}},
    },
  };

  // Concurrent active lock is rejected
  await assert.rejects(
      () => handler(req),
      (err) => err.code === 'already-exists' && err.details?.code === 'deletion-in-progress',
  );

  // Expire lock -> resumes and hits transient storage error -> marks failed_retryable
  db.docs.get('DeletionJobs/u-retry').lockExpiresAt = 999;
  await assert.rejects(() => handler(req), (err) => err.code === 'internal');
  const failedJob = db.docs.get('DeletionJobs/u-retry');
  assert.equal(failedJob.status, 'failed_retryable');
  assert.equal(failedJob.steps.profileAndTokens, true);
  assert.equal(failedJob.steps.storage, undefined);

  // Retry succeeds even though Auth user is already gone (auth/user-not-found)
  const retryResult = await handler(req);
  assert.equal(retryResult.status, 'completed');
  const doneJob = db.docs.get('DeletionJobs/u-retry');
  assert.equal(doneJob.status, 'completed');
  assert.equal(doneJob.email, undefined);

  // Idempotent duplicate call on completed job returns completed cleanly
  const secondResult = await handler(req);
  assert.equal(secondResult.status, 'completed');
});

test('cancels pending Requests, scrubs PII, preserves surviving access, and deletes orphaned Requests', async () => {
  const riderEmail = 'Al@example.com';
  const riderLower = 'al@example.com';
  const otherEmail = 'alice@example.com';
  const thirdEmail = 'third@example.com';
  const db = createFirestoreMock([
    [`Rider_Profile/${profileId(riderLower)}`, {email: riderLower, name: 'Al'}],
    ['Requests/req-pending-out', {
      id: 'req-pending-out',
      kind: 'instructor',
      status: 'pending',
      isAccepted: false,
      partiesIds: [riderLower, otherEmail],
      parties: ['Al', 'Alice'],
      senderEmail: riderLower,
      senderName: 'Al',
      senderPicUrl: 'https://example.com/p.jpg',
      recipientEmail: otherEmail,
      recipientName: 'Alice',
      title: 'Instructor Request from Al',
      summary: 'Al (al@example.com) has requested Alice to be their Instructor',
    }],
    ['Requests/req-accepted-horse', {
      id: 'req-accepted-horse',
      kind: 'studentHorse',
      status: 'accepted',
      isAccepted: true,
      partiesIds: [otherEmail, riderLower],
      parties: ['Alice', 'Al'],
      senderEmail: otherEmail,
      senderName: 'Alice',
      senderPicUrl: 'https://example.com/alice.jpg',
      recipientEmail: riderLower,
      recipientName: 'Al',
      horseId: 'horse-1',
      horseName: 'Comet',
      horseOwnerId: riderEmail,
      horseOwnerName: 'Al',
      title: 'Student Horse Request',
      summary: 'Alice requested Comet owned by Al',
    }],
    ['Requests/req-declined', {
      id: 'req-declined',
      kind: 'student',
      status: 'declined',
      isAccepted: false,
      partiesIds: [otherEmail, riderLower],
      parties: ['Alice', 'Al'],
      senderEmail: otherEmail,
      senderName: 'Alice',
      recipientEmail: riderLower,
      recipientName: 'Al',
      dismissalNote: 'Declined by Al',
    }],
    ['Requests/req-both-deleted', {
      id: 'req-both-deleted',
      kind: 'instructor',
      status: 'cancelled',
      partiesIds: [riderLower, 'deleted:u-old'],
      parties: ['Al', DELETED_NAME],
      senderEmail: riderLower,
      recipientEmail: 'deleted:u-old',
    }],
    ['Requests/req-unrelated', {
      id: 'req-unrelated',
      status: 'pending',
      partiesIds: [thirdEmail, otherEmail],
      parties: ['Third', 'Alice'],
      senderEmail: thirdEmail,
      senderName: 'Third',
      recipientEmail: otherEmail,
      recipientName: 'Alice',
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
      token: {email: riderLower, name: 'Al', auth_time: 1990, firebase: {sign_in_provider: 'password'}},
    },
  });
  assert.equal(result.status, 'completed');

  const pendingOut = db.docs.get('Requests/req-pending-out');
  assert.equal(pendingOut.status, 'cancelled');
  assert.equal(pendingOut.isAccepted, false);
  assert.equal(pendingOut.dismissalNote, 'Account deleted');
  assert.deepEqual(pendingOut.partiesIds, ['deleted:u-leaving', otherEmail]);
  assert.deepEqual(pendingOut.parties, [DELETED_NAME, 'Alice']);
  assert.equal(pendingOut.senderEmail, 'deleted:u-leaving');
  assert.equal(pendingOut.senderName, DELETED_NAME);
  assert.equal(pendingOut.senderPicUrl, '');
  assert.equal(pendingOut.recipientEmail, otherEmail);
  assert.equal(pendingOut.recipientName, 'Alice');
  assert.equal(pendingOut.title, 'Instructor Request from Deleted User');
  assert.equal(
      pendingOut.summary,
      'Deleted User (Deleted User) has requested Alice to be their Instructor',
  );

  const acceptedHorse = db.docs.get('Requests/req-accepted-horse');
  assert.equal(acceptedHorse.status, 'accepted');
  assert.equal(acceptedHorse.isAccepted, true);
  assert.deepEqual(acceptedHorse.partiesIds, [otherEmail, 'deleted:u-leaving']);
  assert.deepEqual(acceptedHorse.parties, ['Alice', DELETED_NAME]);
  assert.equal(acceptedHorse.senderEmail, otherEmail);
  assert.equal(acceptedHorse.senderName, 'Alice');
  assert.equal(acceptedHorse.recipientEmail, 'deleted:u-leaving');
  assert.equal(acceptedHorse.recipientName, DELETED_NAME);
  assert.equal(acceptedHorse.horseOwnerId, 'deleted:u-leaving');
  assert.equal(acceptedHorse.horseOwnerName, DELETED_NAME);
  assert.equal(acceptedHorse.summary, 'Alice requested Comet owned by Deleted User');

  const declined = db.docs.get('Requests/req-declined');
  assert.equal(declined.status, 'declined');
  assert.equal(declined.dismissalNote, 'Declined by Deleted User');
  assert.equal(declined.recipientEmail, 'deleted:u-leaving');

  assert.equal(db.docs.has('Requests/req-both-deleted'), false);

  const unrelated = db.docs.get('Requests/req-unrelated');
  assert.equal(unrelated.status, 'pending');
  assert.deepEqual(unrelated.partiesIds, [thirdEmail, otherEmail]);

  // Idempotent duplicate / retry call preserves final scrubbed state cleanly.
  const retryResult = await handler({
    auth: {
      uid: 'u-leaving',
      token: {email: riderLower, name: 'Al', auth_time: 1995, firebase: {sign_in_provider: 'password'}},
    },
  });
  assert.equal(retryResult.status, 'completed');
});
