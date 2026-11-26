/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {connectionHandler, profileId} = require('../connections');
const {
  createInvitationHandler,
  getInvitationPreviewHandler,
  redeemInvitationHandler,
  listMyInvitationsHandler,
  revokeInvitationHandler,
} = require('../invitations');

const instructorEmail = 'coach@example.com';
const studentEmail = 'student@example.com';
const thirdUserEmail = 'third@example.com';
const regularUserEmail = 'rider@example.com';

const uidFor = (email) => email.split('@')[0];

function createFixture({initialDocs = [], initialTimeMs = Date.UTC(2026, 10, 25, 12, 0, 0)} = {}) {
  const docs = new Map([
    [
      `Rider_Profile/${profileId(instructorEmail)}`,
      {
        email: instructorEmail,
        name: 'Coach Carter',
        isTrainer: true,
        picUrl: 'https://cdn.example.org/coach.jpg',
        locationName: 'Lexington, KY',
      },
    ],
    [
      `Public_Rider_Profile/${profileId(instructorEmail)}`,
      {
        email: instructorEmail,
        name: 'Coach Carter',
        isTrainer: true,
        picUrl: 'https://cdn.example.org/coach.jpg',
        locationName: 'Lexington, KY',
      },
    ],
    [
      `Rider_Profile/${profileId(studentEmail)}`,
      {
        email: studentEmail,
        name: 'Sam Student',
        isTrainer: false,
      },
    ],
    [
      `Rider_Profile/${profileId(regularUserEmail)}`,
      {
        email: regularUserEmail,
        name: 'Riley Rider',
        isTrainer: false,
      },
    ],
    ...initialDocs,
  ]);

  let nowMs = initialTimeMs;
  const nowFn = () => new Date(nowMs);
  let queue = Promise.resolve();

  function buildDocRef(path) {
    return {
      path,
      id: path.split('/').pop(),
      collection: (sub) => ({
        doc: (subId) => buildDocRef(`${path}/${sub}/${subId}`),
      }),
      get: async () => {
        const data = docs.get(path);
        return {
          exists: data !== undefined,
          id: path.split('/').pop(),
          data: () => structuredClone(data),
        };
      },
    };
  }

  function buildQuery(collectionPath, filters = []) {
    return {
      where: (field, op, value) => buildQuery(collectionPath, [...filters, {field, op, value}]),
      get: async () => {
        const matched = [...docs.entries()]
            .filter(([path, data]) => {
              if (!path.startsWith(`${collectionPath}/`)) return false;
              const rest = path.slice(collectionPath.length + 1);
              if (rest.includes('/')) return false;
              return filters.every((f) => {
                if (f.op === '==') return data?.[f.field] === f.value;
                if (f.op === 'array-contains') {
                  return Array.isArray(data?.[f.field]) && data[f.field].includes(f.value);
                }
                return false;
              });
            })
            .map(([path, data]) => ({
              id: path.split('/').pop(),
              ref: buildDocRef(path),
              data: () => structuredClone(data),
            }));
        return {empty: matched.length === 0, docs: matched};
      },
    };
  }

  const db = {
    collection: (collectionPath) => ({
      doc: (id) => buildDocRef(`${collectionPath}/${id}`),
      where: (field, op, value) => buildQuery(collectionPath, [{field, op, value}]),
    }),
    runTransaction: (run) => {
      const result = queue.then(async () => {
        const writes = [];
        const tx = {
          get: async (ref) => {
            if (ref && typeof ref.path === 'string') {
              const data = docs.get(ref.path);
              return {
                exists: data !== undefined,
                id: ref.id,
                data: () => structuredClone(data),
              };
            }
            return ref.get();
          },
          set: (ref, data) => writes.push(() => docs.set(ref.path, structuredClone(data))),
          update: (ref, data) => writes.push(() => docs.set(ref.path, {
            ...structuredClone(docs.get(ref.path)),
            ...structuredClone(data),
          })),
          delete: (ref) => writes.push(() => docs.delete(ref.path)),
        };
        const output = await run(tx);
        writes.forEach((write) => write());
        return output;
      });
      queue = result.catch(() => {});
      return result;
    },
  };

  const authUsers = new Map([
    [instructorEmail, {uid: uidFor(instructorEmail), email: instructorEmail}],
    [studentEmail, {uid: uidFor(studentEmail), email: studentEmail}],
    [thirdUserEmail, {uid: uidFor(thirdUserEmail), email: thirdUserEmail}],
    [regularUserEmail, {uid: uidFor(regularUserEmail), email: regularUserEmail}],
  ]);

  const fakeAuth = {
    getUserByEmail: async (email) => {
      const rec = authUsers.get(email.toLowerCase());
      if (!rec) {
        const err = new Error('User not found');
        err.code = 'auth/user-not-found';
        throw err;
      }
      return rec;
    },
  };

  const createFn = createInvitationHandler(db, {now: nowFn});
  const previewFn = getInvitationPreviewHandler(db, {now: nowFn});
  const redeemFn = redeemInvitationHandler(db, fakeAuth, {now: nowFn});
  const listFn = listMyInvitationsHandler(db, {now: nowFn});
  const revokeFn = revokeInvitationHandler(db, {now: nowFn});
  const connectFn = connectionHandler(db, fakeAuth);

  const authFor = (email, verified = true, displayName = '') => ({
    uid: uidFor(email),
    token: {email, email_verified: verified, name: displayName},
  });

  return {
    docs,
    advanceDays: (days) => {
      nowMs += days * 24 * 60 * 60 * 1000;
    },
    createInvite: (email, data, verified = true) => createFn({auth: authFor(email, verified), data}),
    previewInvite: (token, email = null) => previewFn({
      auth: email ? authFor(email) : null,
      data: {token},
    }),
    redeemInvite: (email, token, verified = true, displayName = '') => redeemFn({
      auth: authFor(email, verified, displayName),
      data: {token},
    }),
    listInvites: (email) => listFn({auth: authFor(email), data: {}}),
    revokeInvite: (email, invitationId) => revokeFn({auth: authFor(email), data: {invitationId}}),
    callConnection: (email, data) => connectFn({auth: authFor(email), data}),
  };
}

test('student invitation enforces trainer role, single use, pending request, and explicit accept', async () => {
  const f = createFixture();

  // Unauthenticated and non-trainer cannot create student invitations.
  await assert.rejects(
      f.createInvite(regularUserEmail, {type: 'student_connection'}),
      {code: 'permission-denied'},
  );
  await assert.rejects(
      f.createInvite(instructorEmail, {type: 'student_connection'}, false),
      {code: 'unauthenticated'},
  );

  const created = await f.createInvite(instructorEmail, {
    type: 'student_connection',
    personalMessage: 'Welcome to lessons!',
  });
  assert.equal(created.invitation.type, 'student_connection');
  assert.equal(created.invitation.maxUses, 1);
  assert.ok(created.token.length >= 24);
  assert.equal(created.sharePath, `/invite/${created.token}`);

  // Stored invitation hashes token instead of storing plaintext token.
  const rawStored = f.docs.get(`Invitations/${created.invitation.id}`);
  assert.ok(rawStored.tokenHash);
  assert.equal(rawStored.token, undefined);

  // Unauthenticated preview hides private emails while exposing safe inviter details.
  const preview = await f.previewInvite(created.token);
  assert.equal(preview.tokenValid, true);
  assert.equal(preview.status, 'pending');
  assert.equal(preview.inviterDisplayName, 'Coach Carter');
  assert.equal(preview.inviterIsTrainer, true);
  assert.equal(preview.inviterEmail, undefined);
  assert.equal(preview.canRedeem, true);

  // Self-invite is rejected.
  await assert.rejects(
      f.redeemInvite(instructorEmail, created.token),
      {code: 'failed-precondition'},
  );

  // Student redeems: creates PENDING connection and Request, never auto-accepted.
  const redeemed = await f.redeemInvite(studentEmail, created.token);
  assert.equal(redeemed.outcome, 'pending_connection_created');
  assert.equal(redeemed.connectionStatus, 'pending');
  const conn = f.docs.get(`CoachingConnections/${redeemed.connectionId}`);
  const req = f.docs.get(`Requests/${redeemed.requestDocId}`);
  const studentProfileBeforeAccept = f.docs.get(`Rider_Profile/${profileId(studentEmail)}`);
  assert.equal(conn.status, 'pending');
  assert.equal(conn.sender, instructorEmail);
  assert.equal(conn.recipient, studentEmail);
  assert.equal(req.status, 'pending');
  assert.equal(req.kind, 'student');
  assert.equal(studentProfileBeforeAccept.instructorUids, undefined);

  // Idempotent duplicate redemption by same student returns existing pending decision without incrementing count.
  const repeated = await f.redeemInvite(studentEmail, created.token);
  assert.equal(repeated.outcome, 'pending_connection_existing');
  assert.equal(f.docs.get(`Invitations/${created.invitation.id}`).redemptionCount, 1);

  // Another user sees used preview and cannot hijack single-use student invite.
  const otherPreview = await f.previewInvite(created.token, thirdUserEmail);
  assert.equal(otherPreview.status, 'used');
  assert.equal(otherPreview.canRedeem, false);
  await assert.rejects(
      f.redeemInvite(thirdUserEmail, created.token),
      {code: 'failed-precondition'},
  );

  // Only the student can accept; outsider or instructor cannot accept on student's behalf.
  await assert.rejects(
      f.callConnection(thirdUserEmail, {
        action: 'accept',
        id: redeemed.connectionId,
        version: redeemed.connectionVersion,
      }),
      {code: 'permission-denied'},
  );
  await assert.rejects(
      f.callConnection(instructorEmail, {
        action: 'accept',
        id: redeemed.connectionId,
        version: redeemed.connectionVersion,
      }),
      {code: 'permission-denied'},
  );

  // Student accepts explicitly -> Connection & Request & Invitation sync, instructorUids granted.
  const accepted = await f.callConnection(studentEmail, {
    action: 'accept',
    id: redeemed.connectionId,
    version: redeemed.connectionVersion,
    requestDocId: redeemed.requestDocId,
  });
  assert.equal(accepted.status, 'accepted');
  const updatedStudent = f.docs.get(`Rider_Profile/${profileId(studentEmail)}`);
  assert.deepEqual(updatedStudent.instructorUids, [uidFor(instructorEmail)]);
  assert.equal(f.docs.get(`Requests/${redeemed.requestDocId}`).status, 'accepted');

  const inviterList = await f.listInvites(instructorEmail);
  assert.equal(inviterList.invitations.length, 1);
  assert.equal(inviterList.invitations[0].status, 'accepted');
  assert.equal(inviterList.invitations[0].acceptedCount, 1);
  assert.equal(inviterList.invitations[0].recipientDisplayName, 'Sam Student');
  // Accepted invite cannot be revoked through invite manager.
  await assert.rejects(
      f.revokeInvite(instructorEmail, created.invitation.id),
      {code: 'failed-precondition'},
  );
});

test('general invitation allows multi-user onboarding without creating connections or leaking recipient identity', async () => {
  const f = createFixture();
  const created = await f.createInvite(regularUserEmail, {
    type: 'general',
    maxUses: 2,
    personalMessage: 'Come join me!',
  });

  const first = await f.redeemInvite(studentEmail, created.token);
  assert.equal(first.outcome, 'redeemed_general');

  // Same user again -> idempotent without consuming second slot.
  const repeat = await f.redeemInvite(studentEmail, created.token);
  assert.equal(repeat.outcome, 'already_redeemed_general');
  assert.equal(f.docs.get(`Invitations/${created.invitation.id}`).redemptionCount, 1);

  // Second user -> redeemed; third user -> hits usage limit.
  const second = await f.redeemInvite(thirdUserEmail, created.token, true, 'Third Rider');
  assert.equal(second.outcome, 'redeemed_general');
  await assert.rejects(
      f.redeemInvite(instructorEmail, created.token),
      {code: 'failed-precondition'},
  );

  // Inviter management view never exposes recipient names or private data on general invites.
  const listed = await f.listInvites(regularUserEmail);
  assert.equal(listed.invitations[0].redemptionCount, 2);
  assert.equal(listed.invitations[0].status, 'used');
  assert.equal(listed.invitations[0].recipientDisplayName, null);
  assert.equal(listed.invitations[0].connectionId, null);

  // Zero CoachingConnections created.
  const connectionCount = [...f.docs.keys()].filter((k) => k.startsWith('CoachingConnections/')).length;
  assert.equal(connectionCount, 0);
});

test('new user without Rider_Profile gets minimal profile bootstrapped during student invite redemption', async () => {
  const f = createFixture();
  const created = await f.createInvite(instructorEmail, {type: 'student_connection'});
  const redeemed = await f.redeemInvite(thirdUserEmail, created.token, true, 'Brand New Rider');

  assert.equal(redeemed.outcome, 'pending_connection_created');
  const bootstrapped = f.docs.get(`Rider_Profile/${profileId(thirdUserEmail)}`);
  assert.equal(bootstrapped.email, thirdUserEmail);
  assert.equal(bootstrapped.name, 'Brand New Rider');
  assert.equal(bootstrapped.isTrainer, false);
  assert.equal(bootstrapped.ownerUid, uidFor(thirdUserEmail));
  assert.equal(bootstrapped.instructorUids, undefined);
});

test('decline, expiration, revocation, invalid token, and existing connection behave safely', async () => {
  const f = createFixture();

  // Unknown token preview never leaks details.
  const badPreview = await f.previewInvite('not_a_real_token_12345678');
  assert.equal(badPreview.tokenValid, false);
  assert.equal(badPreview.status, 'invalid');

  // 1. Decline syncs invitation status & declines pending connection/request.
  const inv1 = await f.createInvite(instructorEmail, {type: 'student_connection'});
  const red1 = await f.redeemInvite(studentEmail, inv1.token);
  await f.callConnection(studentEmail, {
    action: 'decline',
    id: red1.connectionId,
    version: red1.connectionVersion,
    requestDocId: red1.requestDocId,
  });
  const repeatAfterDecline = await f.redeemInvite(studentEmail, inv1.token);
  assert.equal(repeatAfterDecline.outcome, 'previously_declined');
  assert.equal((await f.listInvites(instructorEmail)).invitations[0].declinedCount, 1);

  // 2. Revoking an unaccepted student invite marks invitation revoked and cancels pending connection.
  const inv2 = await f.createInvite(instructorEmail, {type: 'student_connection'});
  const red2 = await f.redeemInvite(thirdUserEmail, inv2.token, true, 'Third Rider');
  const revokeRes = await f.revokeInvite(instructorEmail, inv2.invitation.id);
  assert.equal(revokeRes.invitation.status, 'revoked');
  assert.equal(f.docs.get(`CoachingConnections/${red2.connectionId}`).status, 'cancelled');
  assert.equal(f.docs.get(`Requests/${red2.requestDocId}`).status, 'cancelled');

  // Non-owner cannot revoke another user's invitation.
  await assert.rejects(
      f.revokeInvite(regularUserEmail, inv2.invitation.id),
      {code: 'permission-denied'},
  );

  // 3. Expiration rejects redemption and shows expired preview.
  const inv3 = await f.createInvite(instructorEmail, {type: 'student_connection', expiresInDays: 1});
  f.advanceDays(2);
  const expiredPreview = await f.previewInvite(inv3.token);
  assert.equal(expiredPreview.status, 'expired');
  assert.equal(expiredPreview.canRedeem, false);
  await assert.rejects(
      f.redeemInvite(studentEmail, inv3.token),
      {code: 'failed-precondition'},
  );
});

test('creation and redemption rate limits protect against abuse', async () => {
  const f = createFixture();
  for (let i = 0; i < 20; i++) {
    await f.createInvite(regularUserEmail, {type: 'general'});
  }
  await assert.rejects(
      f.createInvite(regularUserEmail, {type: 'general'}),
      {code: 'resource-exhausted'},
  );

  // Create 31 valid general invites from instructor across two create windows.
  f.advanceDays(2);
  const tokens = [];
  for (let i = 0; i < 20; i++) {
    tokens.push((await f.createInvite(instructorEmail, {type: 'general'})).token);
  }
  f.advanceDays(2);
  for (let i = 0; i < 11; i++) {
    tokens.push((await f.createInvite(instructorEmail, {type: 'general', expiresInDays: 30})).token);
  }
  for (let i = 0; i < 30; i++) {
    await f.redeemInvite(studentEmail, tokens[i]);
  }
  await assert.rejects(
      f.redeemInvite(studentEmail, tokens[30]),
      {code: 'resource-exhausted'},
  );
});
