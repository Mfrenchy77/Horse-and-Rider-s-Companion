/* eslint-disable require-jsdoc */
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');
const {
  validateBackfillEnvironment,
  backfillRequests,
} = require('../backfill_requests');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-horse-companion';
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const FUNCTIONS_HOST = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}

const db = admin.firestore();
const auth = admin.auth();

function profileId(email) {
  return email.replaceAll('.', '666').replaceAll('@', '999')
      .replaceAll('f', '5').replaceAll('e', '1').replaceAll('g', '2')
      .replaceAll('m', '').replaceAll('a', 'p').replaceAll('i', 'a')
      .replaceAll('co', 'l');
}

async function loadRequestsRules() {
  const rulesPath = path.resolve(__dirname, '../../firebase/firestore.requests.rules');
  const rulesSource = fs.readFileSync(rulesPath, 'utf8');
  const url = `http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}:securityRules`;
  const res = await fetch(url, {
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      rules: {
        files: [{name: 'firestore.rules', content: rulesSource}],
      },
    }),
  });
  if (!res.ok) {
    throw new Error(`Failed to load security rules: ${res.status} ${await res.text()}`);
  }
}

async function createAndSignInUser(email, password, {emailVerified = true, displayName = ''} = {}) {
  const user = await auth.createUser({
    email,
    password,
    emailVerified,
    displayName: displayName || email,
  });
  const signInUrl = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`;
  const res = await fetch(signInUrl, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email, password, returnSecureToken: true}),
  });
  const json = await res.json();
  if (!res.ok || !json.idToken) {
    throw new Error(`Failed to sign in ${email}: ${JSON.stringify(json)}`);
  }
  return {uid: user.uid, email, idToken: json.idToken};
}

function fsDocUrl(docPath) {
  return `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
}

function toFsValue(v) {
  if (v === null || v === undefined) return {nullValue: null};
  if (typeof v === 'boolean') return {booleanValue: v};
  if (typeof v === 'number') {
    return Number.isInteger(v) ? {integerValue: String(v)} : {doubleValue: v};
  }
  if (typeof v === 'string') return {stringValue: v};
  if (v instanceof Date) return {timestampValue: v.toISOString()};
  if (Array.isArray(v)) return {arrayValue: {values: v.map(toFsValue)}};
  if (typeof v === 'object') {
    const fields = {};
    for (const [k, val] of Object.entries(v)) {
      fields[k] = toFsValue(val);
    }
    return {mapValue: {fields}};
  }
  return {stringValue: String(v)};
}

function toFsFields(obj) {
  const fields = {};
  for (const [k, val] of Object.entries(obj)) {
    fields[k] = toFsValue(val);
  }
  return {fields};
}

async function fsGet(docPath, idToken) {
  return fetch(fsDocUrl(docPath), {
    method: 'GET',
    headers: idToken ? {Authorization: `Bearer ${idToken}`} : {},
  });
}

async function fsCreate(collectionPath, docId, data, idToken) {
  const url = `${fsDocUrl(collectionPath)}?documentId=${encodeURIComponent(docId)}`;
  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(idToken ? {Authorization: `Bearer ${idToken}`} : {}),
    },
    body: JSON.stringify(toFsFields(data)),
  });
}

async function fsPatch(docPath, data, updateMaskFields, idToken) {
  const params = updateMaskFields.map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
  const url = `${fsDocUrl(docPath)}?${params}`;
  return fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      ...(idToken ? {Authorization: `Bearer ${idToken}`} : {}),
    },
    body: JSON.stringify(toFsFields(data)),
  });
}

async function fsDelete(docPath, idToken) {
  return fetch(fsDocUrl(docPath), {
    method: 'DELETE',
    headers: idToken ? {Authorization: `Bearer ${idToken}`} : {},
  });
}

async function callFunction(name, data, idToken) {
  const url = `http://${FUNCTIONS_HOST}/${PROJECT_ID}/us-central1/${name}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(idToken ? {Authorization: `Bearer ${idToken}`} : {}),
    },
    body: JSON.stringify({data}),
  });
  const json = await res.json();
  return {status: res.status, ok: res.ok, body: json};
}

async function seedRiderProfile(email, name, extra = {}) {
  await db.collection('Rider_Profile').doc(profileId(email)).set({
    id: profileId(email),
    email,
    name,
    ownedHorses: [],
    archivedHorses: [],
    studentHorses: [],
    instructors: [],
    students: [],
    notes: [],
    ...extra,
  });
}

async function main() {
  const results = [];
  function record(name, fn) {
    return fn().then(() => {
      results.push({name, ok: true});
      console.log(`PASS: ${name}`);
    }).catch((err) => {
      results.push({name, ok: false, err});
      console.error(`FAIL: ${name}\n`, err);
      throw err;
    });
  }

  await loadRequestsRules();

  const owner = await createAndSignInUser('owner@example.com', 'pass1234', {displayName: 'Owner Rider'});
  const trainer = await createAndSignInUser('trainer@example.com', 'pass1234', {displayName: 'Trainer Rider'});
  const student = await createAndSignInUser('student@example.com', 'pass1234', {displayName: 'Student Rider'});
  const recipient = await createAndSignInUser('recipient@example.com', 'pass1234', {displayName: 'Recipient Rider'});
  const adminUser = await createAndSignInUser('admin@example.com', 'pass1234', {displayName: 'Admin Account'});
  const intruder = await createAndSignInUser('intruder@example.com', 'pass1234', {displayName: 'Intruder'});
  const unverified = await createAndSignInUser('unverified@example.com', 'pass1234', {emailVerified: false, displayName: 'Unverified'});

  await Promise.all([
    seedRiderProfile(owner.email, 'Owner Rider', {
      ownedHorses: [{id: 'horse-1', name: 'Comet', isCollapsed: false}],
    }),
    seedRiderProfile(trainer.email, 'Trainer Rider', {isTrainer: true}),
    seedRiderProfile(student.email, 'Student Rider'),
    seedRiderProfile(recipient.email, 'Recipient Rider'),
    seedRiderProfile(adminUser.email, 'Admin Account'),
    seedRiderProfile(intruder.email, 'Intruder'),
  ]);

  await db.collection('Horse_Profile').doc('horse-1').set({
    id: 'horse-1',
    name: 'Comet',
    currentOwnerId: owner.email,
    currentOwnerName: 'Owner Rider',
    archiveStatus: 'active',
    instructors: [],
    notes: [{id: 'note-1', name: 'Original training history', date: new Date()}],
  });

  // 1. Staged Firestore Security Rules: wildcard exclusion, unverified, spoofing, self-request, status forgery, cross-party
  await record('Rules enforce participant-scoped access, block unverified/spoofing/status-forgery/wildcard', async () => {
    const reqDoc = {
      id: 'req-sec-1',
      messageId: 'm1',
      kind: 'instructor',
      senderEmail: student.email,
      senderName: 'Student Rider',
      recipientEmail: trainer.email,
      recipientName: 'Trainer Rider',
      title: 'Instructor Request',
      summary: 'Student wants Trainer',
      parties: ['Student Rider', 'Trainer Rider'],
      partiesIds: [student.email, trainer.email],
      createdAt: new Date(),
      updatedAt: new Date(),
      isAccepted: false,
      status: 'pending',
    };

    // Unverified cannot create
    const unverifiedRes = await fsCreate('Requests', 'req-unverified', {
      ...reqDoc,
      id: 'req-unverified',
      senderEmail: unverified.email,
      partiesIds: [unverified.email, trainer.email],
    }, unverified.idToken);
    assert.equal(unverifiedRes.status, 403);

    // Intruder cannot spoof senderEmail
    const spoofRes = await fsCreate('Requests', 'req-spoof', reqDoc, intruder.idToken);
    assert.equal(spoofRes.status, 403);

    // Self-request blocked
    const selfRes = await fsCreate('Requests', 'req-self', {
      ...reqDoc,
      id: 'req-self',
      recipientEmail: student.email,
      partiesIds: [student.email],
    }, student.idToken);
    assert.equal(selfRes.status, 403);

    // Legitimate student creates pending instructor request
    const okRes = await fsCreate('Requests', 'req-sec-1', reqDoc, student.idToken);
    assert.equal(okRes.status, 200);

    // Intruder cannot read or mutate
    assert.equal((await fsGet('Requests/req-sec-1', intruder.idToken)).status, 403);
    assert.equal((await fsPatch('Requests/req-sec-1', {status: 'dismissed'}, ['status'], intruder.idToken)).status, 403);
    assert.equal((await fsDelete('Requests/req-sec-1', student.idToken)).status, 403);

    // Recipient cannot forge accepted directly in Firestore
    assert.equal((await fsPatch('Requests/req-sec-1', {status: 'accepted'}, ['status'], trainer.idToken)).status, 403);

    // Sender cannot decline; recipient cannot cancel
    assert.equal((await fsPatch('Requests/req-sec-1', {status: 'declined'}, ['status'], student.idToken)).status, 403);
    assert.equal((await fsPatch('Requests/req-sec-1', {status: 'cancelled'}, ['status'], trainer.idToken)).status, 403);

    // Recipient can decline; then terminal request cannot be reopened
    assert.equal((await fsPatch('Requests/req-sec-1', {status: 'declined'}, ['status'], trainer.idToken)).status, 200);
    assert.equal((await fsPatch('Requests/req-sec-1', {status: 'pending'}, ['status'], student.idToken)).status, 403);

    // Wildcard exclusion: CoachingConnections & DeletionJobs cannot be read/written by intruder
    assert.equal((await fsGet('CoachingConnections/nonexistent', intruder.idToken)).status, 403);
    assert.equal((await fsGet('DeletionJobs/nonexistent', intruder.idToken)).status, 403);
  });

  // 2. Instructor Request End-to-End (create in Firestore + accept via coachingConnection)
  await record('Instructor request creation and acceptance via coachingConnection', async () => {
    const reqId = 'inst_req_1';
    const createRes = await fsCreate('Requests', reqId, {
      id: reqId,
      messageId: 'm-inst-1',
      kind: 'instructor',
      senderEmail: student.email,
      senderName: 'Student Rider',
      recipientEmail: trainer.email,
      recipientName: 'Trainer Rider',
      title: 'Instructor Request',
      summary: 'Student Rider has requested Trainer Rider to be their Instructor',
      parties: ['Student Rider', 'Trainer Rider'],
      partiesIds: [student.email, trainer.email],
      createdAt: new Date(),
      updatedAt: new Date(),
      isAccepted: false,
      status: 'pending',
    }, student.idToken);
    assert.equal(createRes.status, 200);

    // Intruder cannot accept via coachingConnection
    const intruderCall = await callFunction('coachingConnection', {
      action: 'send',
      kind: 'rider',
      learnerEmail: student.email,
      coachEmail: trainer.email,
      requestDocId: reqId,
    }, intruder.idToken);
    assert.equal(intruderCall.ok, false);

    // Trainer accepts instructor request
    const acceptCall = await callFunction('coachingConnection', {
      action: 'send',
      kind: 'rider',
      learnerEmail: student.email,
      coachEmail: trainer.email,
      requestDocId: reqId,
    }, trainer.idToken);
    assert.equal(acceptCall.ok, true, JSON.stringify(acceptCall.body));

    const reqSnap = await db.collection('Requests').doc(reqId).get();
    assert.equal(reqSnap.data().status, 'accepted');
    assert.equal(reqSnap.data().isAccepted, true);
  });

  // 3. Student Request End-to-End (create + cancel by sender)
  await record('Student request creation and cancellation by sender', async () => {
    const reqId = 'stud_req_1';
    const createRes = await fsCreate('Requests', reqId, {
      id: reqId,
      messageId: 'm-stud-1',
      kind: 'student',
      senderEmail: trainer.email,
      senderName: 'Trainer Rider',
      recipientEmail: student.email,
      recipientName: 'Student Rider',
      title: 'Student Request',
      summary: 'Trainer Rider requested Student Rider as student',
      parties: ['Trainer Rider', 'Student Rider'],
      partiesIds: [trainer.email, student.email],
      createdAt: new Date(),
      updatedAt: new Date(),
      isAccepted: false,
      status: 'pending',
    }, trainer.idToken);
    assert.equal(createRes.status, 200);

    const cancelRes = await fsPatch(`Requests/${reqId}`, {
      status: 'cancelled',
      dismissalNote: 'Cancelled by trainer',
    }, ['status', 'dismissalNote'], trainer.idToken);
    assert.equal(cancelRes.status, 200);

    const reqSnap = await db.collection('Requests').doc(reqId).get();
    assert.equal(reqSnap.data().status, 'cancelled');
  });

  // 4. Student-Horse Request End-to-End
  await record('Student-horse request creation and acceptance via coachingConnection', async () => {
    const reqId = 'sh_req_1';
    const createRes = await fsCreate('Requests', reqId, {
      id: reqId,
      messageId: 'm-sh-1',
      kind: 'studentHorse',
      senderEmail: trainer.email,
      senderName: 'Trainer Rider',
      recipientEmail: owner.email,
      recipientName: 'Owner Rider',
      title: 'Student Horse Request',
      summary: 'Trainer Rider wants to add Comet',
      parties: ['Trainer Rider', 'Owner Rider'],
      partiesIds: [trainer.email, owner.email],
      createdAt: new Date(),
      updatedAt: new Date(),
      isAccepted: false,
      status: 'pending',
      horseId: 'horse-1',
      horseName: 'Comet',
      horseOwnerId: owner.email,
      horseOwnerName: 'Owner Rider',
    }, trainer.idToken);
    assert.equal(createRes.status, 200);

    const acceptCall = await callFunction('coachingConnection', {
      action: 'send',
      kind: 'horse',
      horseId: 'horse-1',
      learnerEmail: owner.email,
      coachEmail: trainer.email,
      requestDocId: reqId,
    }, owner.idToken);
    assert.equal(acceptCall.ok, true, JSON.stringify(acceptCall.body));

    const reqSnap = await db.collection('Requests').doc(reqId).get();
    assert.equal(reqSnap.data().status, 'accepted');
    assert.equal(reqSnap.data().isAccepted, true);
  });

  // 5. Horse Transfer: creation, duplicate block, unauthorized block, concurrent acceptance, expiration
  await record('Horse transfer lifecycle: sendTransfer, duplicate block, auth, concurrency, expiration', async () => {
    // Intruder cannot initiate transfer of owner's horse
    const intruderSend = await callFunction('coachingConnection', {
      action: 'sendTransfer',
      horseId: 'horse-1',
      recipientEmail: recipient.email,
      createRequest: true,
    }, intruder.idToken);
    assert.equal(intruderSend.ok, false);

    // Owner initiates transfer to recipient
    const sendRes = await callFunction('coachingConnection', {
      action: 'sendTransfer',
      horseId: 'horse-1',
      recipientEmail: recipient.email,
      createRequest: true,
    }, owner.idToken);
    assert.equal(sendRes.ok, true, JSON.stringify(sendRes.body));
    const transferId = sendRes.body.result.id;

    // Duplicate transfer to a different user is blocked
    const dupRes = await callFunction('coachingConnection', {
      action: 'sendTransfer',
      horseId: 'horse-1',
      recipientEmail: student.email,
      createRequest: true,
    }, owner.idToken);
    assert.equal(dupRes.ok, false);

    const transferDoc = await db.collection('CoachingConnections').doc(transferId).get();
    const transferVersion = transferDoc.data().version;

    // Intruder cannot accept transfer
    const intruderAccept = await callFunction('coachingConnection', {
      action: 'accept',
      id: transferId,
      version: transferVersion,
      requestDocId: transferId,
    }, intruder.idToken);
    assert.equal(intruderAccept.ok, false);

    // Test expiration rejection before accepting
    await db.collection('CoachingConnections').doc(transferId).update({
      expiresAt: new Date(Date.now() - 60_000),
    });
    const expiredAccept = await callFunction('coachingConnection', {
      action: 'accept',
      id: transferId,
      version: transferVersion,
      requestDocId: transferId,
    }, recipient.idToken);
    assert.equal(expiredAccept.ok, false);

    // Restore valid expiresAt and run simultaneous acceptances
    await db.collection('CoachingConnections').doc(transferId).update({
      expiresAt: new Date(Date.now() + 3600_000),
    });
    const [accept1, accept2] = await Promise.all([
      callFunction('coachingConnection', {
        action: 'accept',
        id: transferId,
        version: transferVersion,
        requestDocId: transferId,
      }, recipient.idToken),
      callFunction('coachingConnection', {
        action: 'accept',
        id: transferId,
        version: transferVersion,
        requestDocId: transferId,
      }, recipient.idToken),
    ]);
    assert.ok(accept1.ok || accept2.ok, 'At least one concurrent acceptance must succeed');

    const horseSnap = await db.collection('Horse_Profile').doc('horse-1').get();
    assert.equal(horseSnap.data().currentOwnerId, recipient.email);
    assert.equal(horseSnap.data().transferRequestId, null);

    const reqSnap = await db.collection('Requests').doc(transferId).get();
    assert.equal(reqSnap.data().status, 'accepted');
  });

  // 6. Legacy compatibility & idempotent backfill against Firestore Emulator
  await record('Legacy Conversations/Messages backfill dry-run, idempotency, and acceptance', async () => {
    assert.throws(() => validateBackfillEnvironment({
      dryRun: false,
      projectId: PROJECT_ID,
      emulatorHost: '',
      confirmProduction: false,
    }), /Refusing non-emulator writes/);

    const convId = 'student_trainer';
    await db.collection('Conversations').doc(convId).set({
      id: convId,
      parties: ['Student Rider', 'Trainer Rider'],
      partiesIds: [student.email, trainer.email],
      lastEditDate: new Date(),
    });
    await db.collection('Conversations').doc(convId).collection('Messages').doc('leg-1').set({
      messageId: 'leg-1',
      messageType: 'INSTRUCTOR_REQUEST',
      senderId: student.email,
      sender: 'Student Rider',
      subject: 'Legacy Instructor',
      message: 'Legacy summary',
      date: new Date(),
      requestItem: {isSelected: false},
    });

    // Dry-run does not write
    const drySummary = await backfillRequests(db, {projectId: PROJECT_ID, dryRun: true});
    assert.equal(drySummary.dryRun, true);
    assert.ok(drySummary.wouldCreate >= 1);
    const beforeDoc = await db.collection('Requests').doc(`legacy_${convId}_leg-1`).get();
    assert.equal(beforeDoc.exists, false);

    // Live emulator backfill creates deterministic doc with migratedFromLegacy: true
    const run1 = await backfillRequests(db, {projectId: PROJECT_ID, dryRun: false});
    assert.ok(run1.created >= 1);
    const afterDoc = await db.collection('Requests').doc(`legacy_${convId}_leg-1`).get();
    assert.equal(afterDoc.exists, true);
    assert.equal(afterDoc.data().migratedFromLegacy, true);
    assert.equal(afterDoc.data().status, 'pending');

    // Second run is idempotent
    const run2 = await backfillRequests(db, {projectId: PROJECT_ID, dryRun: false});
    assert.equal(run2.created, 0);

    // Accepting the backfilled legacy request via fallbackRequestDocIds marks it accepted
    const acceptLegacy = await callFunction('coachingConnection', {
      action: 'send',
      kind: 'rider',
      learnerEmail: student.email,
      coachEmail: trainer.email,
      requestDocId: 'missing_client_doc_id',
      fallbackRequestDocIds: [`legacy_${convId}_leg-1`],
    }, trainer.idToken);
    assert.equal(acceptLegacy.ok, true, JSON.stringify(acceptLegacy.body));
    const resolvedLegacy = await db.collection('Requests').doc(`legacy_${convId}_leg-1`).get();
    assert.equal(resolvedLegacy.data().status, 'accepted');
    assert.equal(resolvedLegacy.data().isAccepted, true);
  });

  // 7. Account Deletion Integration with pending requests & owned horse
  await record('Account deletion cancels pending Requests, transfers horse to admin, protects others, deletes Auth', async () => {
    await db.collection('Horse_Profile').doc('horse-2').set({
      id: 'horse-2',
      name: 'Starlight',
      currentOwnerId: recipient.email,
      currentOwnerName: 'Recipient Rider',
      archiveStatus: 'active',
      notes: [{id: 'h2-note-1', name: 'Preserved dressage log', date: new Date()}],
    });
    await db.collection('Rider_Profile').doc(profileId(recipient.email)).update({
      ownedHorses: [{id: 'horse-2', name: 'Starlight', isCollapsed: false}],
    });
    await db.collection('Requests').doc('pending-del-1').set({
      id: 'pending-del-1',
      messageId: 'm-del-1',
      kind: 'instructor',
      senderEmail: recipient.email,
      senderName: 'Recipient Rider',
      recipientEmail: trainer.email,
      recipientName: 'Trainer Rider',
      title: 'Instructor Request',
      summary: 'Pending before deletion',
      parties: ['Recipient Rider', 'Trainer Rider'],
      partiesIds: [recipient.email, trainer.email],
      createdAt: new Date(),
      updatedAt: new Date(),
      isAccepted: false,
      status: 'pending',
    });

    const delRes = await callFunction('requestAccountDeletion', {}, recipient.idToken);
    assert.equal(delRes.ok, true, JSON.stringify(delRes.body));
    assert.equal(delRes.body.result.status, 'completed');

    // Pending request cancelled
    const cancelledReq = await db.collection('Requests').doc('pending-del-1').get();
    assert.equal(cancelledReq.data().status, 'cancelled');
    assert.equal(cancelledReq.data().dismissalNote, 'Account deleted');

    // Horse transferred to verified admin account with training history intact
    const h2 = await db.collection('Horse_Profile').doc('horse-2').get();
    assert.equal(h2.data().currentOwnerId, adminUser.email);
    assert.equal(h2.data().notes.length, 1);
    assert.equal(h2.data().notes[0].name, 'Preserved dressage log');

    // Other rider's profile remains intact
    const studentProfile = await db.collection('Rider_Profile').doc(profileId(student.email)).get();
    assert.equal(studentProfile.exists, true);
    assert.equal(studentProfile.data().email, student.email);

    // DeletionJob is cleaned up on completion and Auth user is deleted after cleanup
    const job = await db.collection('DeletionJobs').doc(recipient.uid).get();
    assert.equal(job.exists, false);
    await assert.rejects(() => auth.getUser(recipient.uid), /user-not-found|no user record/i);

    // Interrupted/failed DeletionJob recovery: seed failed_retryable job and resume
    const retryUser = await createAndSignInUser('retry-delete@example.com', 'pass1234', {
      displayName: 'Retry Delete',
    });
    await seedRiderProfile(retryUser.email, 'Retry Delete');
    await db.collection('DeletionJobs').doc(retryUser.uid).set({
      uid: retryUser.uid,
      email: retryUser.email,
      status: 'failed_retryable',
      steps: {revokeTokens: true, connections: true, requests: true},
    });
    const retryRes = await callFunction('requestAccountDeletion', {}, retryUser.idToken);
    assert.equal(retryRes.ok, true, JSON.stringify(retryRes.body));
    assert.equal(retryRes.body.result.status, 'completed');
    const recoveredJob = await db.collection('DeletionJobs').doc(retryUser.uid).get();
    assert.equal(recoveredJob.exists, false);
    await assert.rejects(() => auth.getUser(retryUser.uid), /user-not-found|no user record/i);
  });

  console.log(`\nEmulator integration summary: ${results.length} passed, 0 failed.`);
}

main().catch((err) => {
  console.error('Emulator integration suite failed:', err);
  process.exit(1);
});
