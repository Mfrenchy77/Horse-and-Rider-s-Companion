/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreStrings": true, "ignoreTemplateLiterals": true }] */
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');
const {DEFAULT_ADMIN_ACCOUNT_EMAIL, profileId} = require('../account_deletion');
const {retireLegacyMessaging} = require('../retire_legacy_messaging');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-account-deletion';
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const FUNCTIONS_HOST = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}

const db = admin.firestore();
const auth = admin.auth();

async function loadFirestoreRules() {
  const rulesPath = path.resolve(__dirname, '../../firebase/firestore.rules');
  const rulesSource = fs.readFileSync(rulesPath, 'utf8');
  const url = `http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}:securityRules`;
  const res = await fetch(url, {
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({rules: {files: [{name: 'firestore.rules', content: rulesSource}]}}),
  });
  if (!res.ok) {
    throw new Error(`Failed to load security rules: ${res.status} ${await res.text()}`);
  }
}

async function createAndSignIn(email, {emailVerified = true, displayName = ''} = {}) {
  const user = await auth.createUser({
    email,
    password: 'Password123!',
    emailVerified,
    displayName: displayName || email,
  });
  const signInUrl = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`;
  const res = await fetch(signInUrl, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email, password: 'Password123!', returnSecureToken: true}),
  });
  const json = await res.json();
  if (!res.ok || !json.idToken) {
    throw new Error(`Sign-in failed for ${email}: ${JSON.stringify(json)}`);
  }
  return {uid: user.uid, email, idToken: json.idToken};
}

async function callFunction(name, data, idToken = null) {
  const url = `http://${FUNCTIONS_HOST}/${PROJECT_ID}/us-central1/${name}`;
  const headers = {'Content-Type': 'application/json'};
  if (idToken) headers.Authorization = `Bearer ${idToken}`;
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({data}),
  });
  const text = await res.text();
  let body = text;
  try {
    body = JSON.parse(text);
  } catch {
    // Keep raw text on non-JSON error
  }
  return {status: res.status, ok: res.ok, body};
}

async function fsGet(docPath, idToken = null) {
  const headers = idToken ? {Authorization: `Bearer ${idToken}`} : {};
  const url = `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
  const res = await fetch(url, {headers});
  let body = null;
  try {
    body = await res.json();
  } catch {
    body = null;
  }
  return {status: res.status, ok: res.ok, body};
}

async function fsRunQuery(collectionId, field, op, value, idToken = null) {
  const headers = {'Content-Type': 'application/json'};
  if (idToken) headers.Authorization = `Bearer ${idToken}`;
  const url = `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      structuredQuery: {
        from: [{collectionId}],
        where: {
          fieldFilter: {
            field: {fieldPath: field},
            op,
            value: {stringValue: value},
          },
        },
      },
    }),
  });
  const body = await res.json();
  return {status: res.status, ok: res.ok, body};
}

async function runTest(name, fn) {
  await fn();
  console.log(`PASS: ${name}`);
}

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Must be executed inside Firebase emulators (Auth, Firestore, Functions, Storage).');
  }

  await loadFirestoreRules();

  const adminUser = await createAndSignIn(DEFAULT_ADMIN_ACCOUNT_EMAIL, {
    displayName: 'Horse And Rider\'s Companion',
  });
  const departing = await createAndSignIn('departing@example.com', {displayName: 'Departing Rider'});
  const trainer = await createAndSignIn('trainer@example.com', {displayName: 'Coach Taylor'});
  const otherActive = await createAndSignIn('active-student@example.com', {displayName: 'Active Student'});
  const unrelated = await createAndSignIn('stranger@example.com', {displayName: 'Unrelated User'});

  await db.collection('Rider_Profile').doc(profileId(adminUser.email)).set({
    id: profileId(adminUser.email),
    email: adminUser.email,
    ownerUid: adminUser.uid,
    name: 'Horse And Rider\'s Companion',
    ownedHorses: [],
    archivedHorses: [],
  });

  await db.collection('Rider_Profile').doc(profileId(trainer.email)).set({
    id: profileId(trainer.email),
    email: trainer.email,
    ownerUid: trainer.uid,
    name: 'Coach Taylor',
    students: [
      {id: departing.email, name: 'Departing Rider'},
      {id: otherActive.email, name: 'Active Student'},
    ],
    studentHorses: [{id: 'horse-priv', name: 'Shadow'}, {id: 'horse-sale', name: 'Comet'}],
    instructors: [],
  });

  await db.collection('Rider_Profile').doc(profileId(otherActive.email)).set({
    id: profileId(otherActive.email),
    email: otherActive.email,
    ownerUid: otherActive.uid,
    name: 'Active Student',
    instructors: [{id: trainer.email, name: 'Coach Taylor'}],
    instructorUids: [trainer.uid],
  });

  await db.collection('Rider_Profile').doc(profileId(departing.email)).set({
    id: profileId(departing.email),
    email: departing.email,
    ownerUid: departing.uid,
    name: 'Departing Rider',
    notes: [{id: 'personal-note-1', name: 'Private diary'}],
    savedProfilesList: [{id: trainer.email, name: 'Coach Taylor'}],
    ownedHorses: [{id: 'horse-priv', name: 'Shadow'}, {id: 'horse-sale', name: 'Comet'}],
    archivedHorses: [{id: 'horse-arch', name: 'Veteran'}],
    instructors: [{id: trainer.email, name: 'Coach Taylor'}],
    instructorUids: [trainer.uid],
  });
  await db.doc(`Rider_Profile/${profileId(departing.email)}/SkillProgress/rider.in_hand.leading`).set({
    skillId: 'rider.in_hand.leading',
    subject: 'rider',
    schemaVersion: 2,
    levels: {introductory: {state: 'PROFICIENT', updatedByUid: departing.uid, updatedByName: 'Departing Rider'}},
  });
  await db.doc(`Rider_Profile/${profileId(departing.email)}/SkillVerifications/rider.in_hand.leading`).set({
    skillId: 'rider.in_hand.leading',
    verified: true,
  });
  await db.collection('Public_Rider_Profile').doc(profileId(departing.email)).set({
    id: profileId(departing.email),
    email: departing.email,
    name: 'Departing Rider',
  });

  // 1) Active private horse with progress, verifications, and logbook
  await db.collection('Horse_Profile').doc('horse-priv').set({
    id: 'horse-priv',
    name: 'Shadow',
    isPublic: false,
    archiveStatus: 'active',
    currentOwnerId: departing.email,
    currentOwnerName: 'Departing Rider',
    ownerUid: departing.uid,
    instructors: [{id: trainer.email, name: 'Coach Taylor'}],
    instructorUids: [trainer.uid],
    notes: [{id: 'h-note-1', name: 'Calmer transitions at trot'}],
    skillLevels: [{skillId: 'legacy-1', verified: true}],
    lastEditBy: departing.email,
  });
  await db.doc('Horse_Profile/horse-priv/SkillProgress/horse.in_hand.leading').set({
    skillId: 'horse.in_hand.leading',
    subject: 'horse',
    schemaVersion: 2,
    levels: {introductory: {state: 'PROFICIENT', updatedByUid: departing.uid, updatedByName: 'Departing Rider'}},
  });
  await db.doc('Horse_Profile/horse-priv/SkillVerifications/horse.in_hand.leading').set({
    skillId: 'horse.in_hand.leading',
    verified: true,
    verifiedByUid: trainer.uid,
  });

  // 2) Active public horse currently listed for sale
  await db.collection('Horse_Profile').doc('horse-sale').set({
    id: 'horse-sale',
    name: 'Comet',
    isPublic: true,
    archiveStatus: 'active',
    currentOwnerId: departing.email,
    currentOwnerName: 'Departing Rider',
    ownerUid: departing.uid,
    saleListing: {price: '$8500', location: 'TX', description: 'Schooling well'},
    notes: [{id: 'sale-note', name: 'Trail mileage log'}],
  });
  await db.collection('Public_Horse_Profile').doc('horse-sale').set({
    id: 'horse-sale',
    name: 'Comet',
    isPublic: true,
    archiveStatus: 'active',
    saleListing: {price: '$8500', location: 'TX', description: 'Schooling well'},
  });

  // 3) Archived private horse
  await db.collection('Horse_Profile').doc('horse-arch').set({
    id: 'horse-arch',
    name: 'Veteran',
    isPublic: false,
    archiveStatus: 'archived',
    currentOwnerId: departing.email,
    ownerUid: departing.uid,
    notes: [{id: 'arch-note', name: 'Retired healthy'}],
  });

  // Connections, Requests, Journal, Resources, Suggestions, Tokens, and Storage
  await db.collection('CoachingConnections').doc('conn-1').set({
    kind: 'horse',
    horseId: 'horse-priv',
    status: 'accepted',
    participantUids: [departing.uid, trainer.uid],
    learnerEmail: departing.email,
    learnerUid: departing.uid,
    coachEmail: trainer.email,
    coachUid: trainer.uid,
  });
  await db.collection('CoachingConnections').doc('conn-trainer-other').set({
    kind: 'rider',
    status: 'accepted',
    participantUids: [otherActive.uid, trainer.uid],
    learnerEmail: otherActive.email,
    learnerUid: otherActive.uid,
    coachEmail: trainer.email,
    coachUid: trainer.uid,
  });
  await db.collection('Requests').doc('req-pending').set({
    id: 'req-pending',
    messageId: 'm-req-pending',
    kind: 'instructor',
    senderEmail: departing.email,
    senderName: 'Departing Rider',
    senderPicUrl: 'https://example.com/rider.jpg',
    recipientEmail: trainer.email,
    recipientName: 'Coach Taylor',
    parties: ['Departing Rider', 'Coach Taylor'],
    partiesIds: [departing.email, trainer.email],
    title: 'Instructor Request from Departing Rider',
    summary: 'Departing Rider (departing@example.com) has requested Coach Taylor to be their Instructor',
    status: 'pending',
    isAccepted: false,
  });
  await db.collection('Requests').doc('req-accepted-horse').set({
    id: 'req-accepted-horse',
    messageId: 'm-req-accepted',
    kind: 'studentHorse',
    senderEmail: trainer.email,
    senderName: 'Coach Taylor',
    recipientEmail: departing.email,
    recipientName: 'Departing Rider',
    parties: ['Coach Taylor', 'Departing Rider'],
    partiesIds: [trainer.email, departing.email],
    horseId: 'horse-priv',
    horseName: 'Shadow',
    horseOwnerId: departing.email,
    horseOwnerName: 'Departing Rider',
    title: 'Student Horse Request',
    summary: 'Coach Taylor requested Shadow owned by Departing Rider',
    status: 'accepted',
    isAccepted: true,
  });
  await db.collection('Requests').doc('req-both-deleted').set({
    id: 'req-both-deleted',
    messageId: 'm-req-old',
    kind: 'student',
    senderEmail: 'deleted:u-old',
    senderName: 'Deleted User',
    recipientEmail: departing.email,
    recipientName: 'Departing Rider',
    parties: ['Deleted User', 'Departing Rider'],
    partiesIds: ['deleted:u-old', departing.email],
    status: 'cancelled',
    isAccepted: false,
  });
  await db.collection('Requests').doc('req-trainer-other').set({
    id: 'req-trainer-other',
    messageId: 'm-req-other',
    kind: 'instructor',
    senderEmail: otherActive.email,
    senderName: 'Active Student',
    recipientEmail: trainer.email,
    recipientName: 'Coach Taylor',
    parties: ['Active Student', 'Coach Taylor'],
    partiesIds: [otherActive.email, trainer.email],
    title: 'Instructor Request',
    summary: 'Active Student has requested Coach Taylor to be their Instructor',
    status: 'pending',
    isAccepted: false,
  });
  await db.collection('SharedRidingEntries').doc('entry-owned').set({
    riderUid: departing.uid,
    authorUid: departing.uid,
    horseId: 'horse-priv',
  });
  await db.collection('Resources').doc('res-1').set({
    id: 'res-1',
    name: 'Groundwork Video',
    authorId: departing.uid,
    authorName: 'Departing Rider',
    lastEditBy: departing.email,
    comments: [{id: 'c1', user: {id: departing.email, name: 'Departing Rider'}}],
  });
  await db.collection('Resources/res-1/usersWhoRated').doc(departing.uid).set({id: departing.uid, isSelected: true});
  await db.collection('SkillTreeSuggestions').doc('sug-1').set({
    submittedByUid: departing.uid,
    submitterEmail: departing.email,
    submitterName: 'Departing Rider',
    title: 'Clearer mounting cue note',
  });
  await db.collection('RiderProfiles').doc(departing.email).collection('tokens').doc('fcm-1').set({token: 'fcm-1'});

  // Legacy Conversations/Messages (shared with surviving trainer + solo/already-deleted)
  await db.collection('Conversations').doc('conv-shared').set({
    id: 'conv-shared',
    partiesIds: [departing.email, trainer.email],
    parties: ['Departing Rider', 'Coach Taylor'],
    createdBy: 'Departing Rider',
    lastEditBy: departing.email,
    recentMessage: {
      sender: 'Departing Rider',
      senderId: departing.email,
      senderProfilePicUrl: 'https://example.com/rider.jpg',
      message: 'Private chat from departing rider',
      messageType: 'CHAT',
      recipients: ['Coach Taylor'],
    },
  });
  await db.collection('Conversations/conv-shared/Messages').doc('m-dep').set({
    sender: 'Departing Rider',
    senderId: departing.email,
    senderProfilePicUrl: 'https://example.com/rider.jpg',
    message: 'Private chat from departing rider',
    messageType: 'CHAT',
    recipients: ['Coach Taylor'],
  });
  await db.collection('Conversations/conv-shared/Messages').doc('m-tr').set({
    sender: 'Coach Taylor',
    senderId: trainer.email,
    message: 'Trainer note remains intact',
    messageType: 'CHAT',
    recipients: ['Departing Rider'],
  });
  await db.collection('Conversations').doc('conv-solo').set({
    id: 'conv-solo',
    partiesIds: [departing.email, 'deleted:u-old'],
    parties: ['Departing Rider', 'Deleted User'],
  });
  await db.collection('Conversations/conv-solo/Messages').doc('m-solo').set({
    sender: 'Departing Rider',
    senderId: departing.email,
    message: 'Solo message deleted',
    messageType: 'CHAT',
  });

  const bucket = admin.storage().bucket(`${PROJECT_ID}.appspot.com`);
  const riderPhotoPath = `Riders_Photo/${profileId(departing.email)}`;
  const coverPath = `covers/${departing.email}/cover.jpg`;
  const horsePhotoPath = 'Horses_Photo/horse-priv';
  await bucket.file(riderPhotoPath).save(Buffer.from('rider'), {contentType: 'image/jpeg'});
  await bucket.file(coverPath).save(Buffer.from('cover'), {contentType: 'image/jpeg'});
  await bucket.file(horsePhotoPath).save(Buffer.from('horse'), {contentType: 'image/jpeg'});

  await runTest('Unauthenticated account deletion request is rejected', async () => {
    const res = await callFunction('requestAccountDeletion', {});
    assert.equal(res.ok, false);
    assert.equal(res.status, 401);
  });

  await runTest('Deletes rider account cleanly while transferring and preserving all 3 horses', async () => {
    const res = await callFunction('requestAccountDeletion', {}, departing.idToken);
    assert.equal(res.ok, true, JSON.stringify(res.body));
    assert.equal(res.body.result.status, 'completed');
    assert.equal(res.body.result.horsesTransferred, 3);

    // Departing Auth + personal profile + subcollections + tokens + personal media deleted
    await assert.rejects(() => auth.getUser(departing.uid), /user-not-found|no user record/i);
    assert.equal((await db.collection('Rider_Profile').doc(profileId(departing.email)).get()).exists, false);
    assert.equal(
        (await db.doc(`Rider_Profile/${profileId(departing.email)}/SkillProgress/rider.in_hand.leading`).get()).exists,
        false,
    );
    assert.equal((await db.collection('Public_Rider_Profile').doc(profileId(departing.email)).get()).exists, false);
    assert.equal(
        (await db.collection('RiderProfiles').doc(departing.email).collection('tokens').doc('fcm-1').get()).exists,
        false,
    );
    assert.equal((await db.collection('SharedRidingEntries').doc('entry-owned').get()).exists, false);
    assert.equal((await bucket.file(riderPhotoPath).exists())[0], false);
    assert.equal((await bucket.file(coverPath).exists())[0], false);

    // Horses transferred to verified admin UID, preserving photos, notes, V2 progress & verifications
    assert.equal((await bucket.file(horsePhotoPath).exists())[0], true);
    const privHorse = (await db.collection('Horse_Profile').doc('horse-priv').get()).data();
    assert.equal(privHorse.ownerUid, adminUser.uid);
    assert.equal(privHorse.currentOwnerId, adminUser.email);
    assert.equal(privHorse.administrativeHold, true);
    assert.equal(privHorse.isPublic, false);
    assert.equal(privHorse.notes[0].name, 'Calmer transitions at trot');
    assert.deepEqual(privHorse.instructorUids, []);

    const privProg = (await db.doc('Horse_Profile/horse-priv/SkillProgress/horse.in_hand.leading').get()).data();
    assert.equal(privProg.levels.introductory.state, 'PROFICIENT');
    assert.equal(privProg.levels.introductory.updatedByName, 'Former Owner');
    assert.equal(
        (await db.doc('Horse_Profile/horse-priv/SkillVerifications/horse.in_hand.leading').get()).data().verified,
        true,
    );

    // Public for-sale horse stays public via Public_Horse_Profile but saleListing is cleared
    const saleHorse = (await db.collection('Horse_Profile').doc('horse-sale').get()).data();
    assert.equal(saleHorse.saleListing, null);
    assert.equal(saleHorse.isPublic, true);
    const pubSale = (await db.collection('Public_Horse_Profile').doc('horse-sale').get()).data();
    assert.equal(pubSale.saleListing, undefined);
    assert.equal(pubSale.name, 'Comet');

    // Archived horse lands in admin archivedHorses & stays private
    assert.equal((await db.collection('Public_Horse_Profile').doc('horse-arch').get()).exists, false);
    const adminProf = (await db.collection('Rider_Profile').doc(profileId(adminUser.email)).get()).data();
    assert.deepEqual(adminProf.ownedHorses.map((h) => h.id).sort(), ['horse-priv', 'horse-sale']);
    assert.deepEqual(adminProf.archivedHorses.map((h) => h.id), ['horse-arch']);

    // DeletionJobs contains minimal non-PII administrative status
    const job = (await db.collection('DeletionJobs').doc(departing.uid).get()).data();
    assert.equal(job.status, 'completed');
    assert.equal(job.email, undefined);
    assert.equal(job.horsesTransferredCount, 3);

    // Requests privacy cleanup: pending cancelled + scrubbed, accepted preserved & scrubbed,
    // all-deleted orphaned Request removed, unrelated surviving requests/connections intact.
    const reqPending = (await db.collection('Requests').doc('req-pending').get()).data();
    assert.equal(reqPending.status, 'cancelled');
    assert.equal(reqPending.isAccepted, false);
    assert.equal(reqPending.dismissalNote, 'Account deleted');
    assert.deepEqual(reqPending.partiesIds, [`deleted:${departing.uid}`, trainer.email]);
    assert.deepEqual(reqPending.parties, ['Deleted User', 'Coach Taylor']);
    assert.equal(reqPending.senderEmail, `deleted:${departing.uid}`);
    assert.equal(reqPending.senderName, 'Deleted User');
    assert.equal(reqPending.senderPicUrl, '');
    assert.equal(reqPending.recipientEmail, trainer.email);
    assert.equal(JSON.stringify(reqPending).includes(departing.email), false);
    assert.equal(JSON.stringify(reqPending).includes('Departing Rider'), false);

    const reqAccepted = (await db.collection('Requests').doc('req-accepted-horse').get()).data();
    assert.equal(reqAccepted.status, 'accepted');
    assert.equal(reqAccepted.isAccepted, true);
    assert.deepEqual(reqAccepted.partiesIds, [trainer.email, `deleted:${departing.uid}`]);
    assert.deepEqual(reqAccepted.parties, ['Coach Taylor', 'Deleted User']);
    assert.equal(reqAccepted.recipientEmail, `deleted:${departing.uid}`);
    assert.equal(reqAccepted.recipientName, 'Deleted User');
    assert.equal(reqAccepted.horseOwnerId, `deleted:${departing.uid}`);
    assert.equal(reqAccepted.horseOwnerName, 'Deleted User');
    assert.equal(JSON.stringify(reqAccepted).includes(departing.email), false);
    assert.equal(JSON.stringify(reqAccepted).includes('Departing Rider'), false);

    assert.equal((await db.collection('Requests').doc('req-both-deleted').get()).exists, false);

    const reqOther = (await db.collection('Requests').doc('req-trainer-other').get()).data();
    assert.equal(reqOther.status, 'pending');
    assert.deepEqual(reqOther.partiesIds, [otherActive.email, trainer.email]);

    const trainerProfAfter = (await db.collection('Rider_Profile').doc(profileId(trainer.email)).get()).data();
    assert.deepEqual(trainerProfAfter.students.map((s) => s.id), [otherActive.email]);
    assert.equal((await db.collection('CoachingConnections').doc('conn-trainer-other').get()).data().status, 'accepted');

    // Legacy Conversations/Messages anonymized for departing user without erasing trainer's message
    const convShared = (await db.collection('Conversations').doc('conv-shared').get()).data();
    assert.deepEqual(convShared.partiesIds, [`deleted:${departing.uid}`, trainer.email]);
    assert.deepEqual(convShared.parties, ['Deleted User', 'Coach Taylor']);
    assert.equal(convShared.createdBy, 'Deleted User');
    assert.equal(convShared.recentMessage.sender, 'Deleted User');
    assert.equal(convShared.recentMessage.message, '[Message removed — account deleted]');
    const mDep = (await db.collection('Conversations/conv-shared/Messages').doc('m-dep').get()).data();
    assert.equal(mDep.sender, 'Deleted User');
    assert.equal(mDep.senderId, `deleted:${departing.uid}`);
    assert.equal(mDep.senderProfilePicUrl, '');
    const mTr = (await db.collection('Conversations/conv-shared/Messages').doc('m-tr').get()).data();
    assert.equal(mTr.sender, 'Coach Taylor');
    assert.equal(mTr.message, 'Trainer note remains intact');
    assert.equal((await db.collection('Conversations').doc('conv-solo').get()).exists, false);
    assert.equal((await db.collection('Conversations/conv-solo/Messages').doc('m-solo').get()).exists, false);

    // Dry-run retirement migration check against emulator
    const dryRetire = await retireLegacyMessaging(db, {projectId: PROJECT_ID, dryRun: true});
    assert.equal(dryRetire.scannedConversations, 1);
    assert.equal(dryRetire.anonymizedConversations, 0);
  });

  await runTest('Post-deletion Firestore security rules block unauthorized access while allowing admin transfer', async () => {
    // Guest and unrelated user blocked from private transferred horse, subcollections, and DeletionJobs
    for (const token of [null, unrelated.idToken, trainer.idToken]) {
      assert.equal((await fsGet('Horse_Profile/horse-priv', token)).status, 403);
      assert.equal((await fsGet('Horse_Profile/horse-priv/SkillProgress/horse.in_hand.leading', token)).status, 403);
      assert.equal(
          (await fsGet('Horse_Profile/horse-priv/SkillVerifications/horse.in_hand.leading', token)).status,
          403,
      );
      assert.equal((await fsGet(`DeletionJobs/${departing.uid}`, token)).status, 403);
    }

    // Surviving trainer can still read and list-query their Requests; unrelated user is blocked.
    assert.equal((await fsGet('Requests/req-pending', trainer.idToken)).status, 200);
    assert.equal((await fsGet('Requests/req-accepted-horse', trainer.idToken)).status, 200);
    assert.equal((await fsGet('Requests/req-trainer-other', trainer.idToken)).status, 200);
    const trainerQuery = await fsRunQuery('Requests', 'partiesIds', 'ARRAY_CONTAINS', trainer.email, trainer.idToken);
    assert.equal(trainerQuery.status, 200);
    const trainerDocNames = (Array.isArray(trainerQuery.body) ? trainerQuery.body : [])
        .map((row) => row.document?.name?.split('/').pop())
        .filter(Boolean)
        .sort();
    assert.deepEqual(trainerDocNames, ['req-accepted-horse', 'req-pending', 'req-trainer-other']);

    assert.equal((await fsGet('Requests/req-pending', unrelated.idToken)).status, 403);
    assert.equal((await fsGet('Requests/req-accepted-horse', unrelated.idToken)).status, 403);
    assert.equal((await fsGet('Requests/req-trainer-other', unrelated.idToken)).status, 403);

    // Re-registering the same email address after deletion cannot read historical Requests.
    const reregistered = await createAndSignIn(departing.email, {displayName: 'New Claimant'});
    assert.equal((await fsGet('Requests/req-pending', reregistered.idToken)).status, 403);
    assert.equal((await fsGet('Requests/req-accepted-horse', reregistered.idToken)).status, 403);
    assert.equal((await fsGet('Requests/req-trainer-other', reregistered.idToken)).status, 403);

    // Public active transferred horse remains readable via Public_Horse_Profile
    const pubRes = await fsGet('Public_Horse_Profile/horse-sale', null);
    assert.equal(pubRes.status, 200);
    assert.equal(pubRes.body.fields.saleListing, undefined);

    // Admin can read transferred horse and transfer it later via coachingConnection
    assert.equal((await fsGet('Horse_Profile/horse-priv', adminUser.idToken)).status, 200);

    const newOwner = await createAndSignIn('newowner@example.com', {displayName: 'New Owner'});
    await db.collection('Rider_Profile').doc(profileId(newOwner.email)).set({
      id: profileId(newOwner.email),
      email: newOwner.email,
      ownerUid: newOwner.uid,
      name: 'New Owner',
      ownedHorses: [],
      archivedHorses: [],
    });

    const proposeRes = await callFunction('coachingConnection', {
      action: 'sendTransfer',
      horseId: 'horse-priv',
      recipientEmail: newOwner.email,
    }, adminUser.idToken);
    assert.equal(proposeRes.ok, true, JSON.stringify(proposeRes.body));

    const transferSnap = await db.collection('CoachingConnections').doc(proposeRes.body.result.id).get();
    const acceptRes = await callFunction('coachingConnection', {
      action: 'accept',
      id: proposeRes.body.result.id,
      version: transferSnap.data().version,
    }, newOwner.idToken);
    assert.equal(acceptRes.ok, true, JSON.stringify(acceptRes.body));

    const transferred = (await db.collection('Horse_Profile').doc('horse-priv').get()).data();
    assert.equal(transferred.ownerUid, newOwner.uid);
    assert.equal(transferred.currentOwnerId, newOwner.email);
    assert.equal(transferred.administrativeHold, false);
  });

  await runTest('Emulator rejects concurrent lock and resumes failed_retryable DeletionJob', async () => {
    const retryUser = await createAndSignIn('retry-emu@example.com', {displayName: 'Retry Emu'});
    await db.collection('Rider_Profile').doc(profileId(retryUser.email)).set({
      id: profileId(retryUser.email),
      email: retryUser.email,
      ownerUid: retryUser.uid,
      name: 'Retry Emu',
    });

    const futureLock = Math.floor(Date.now() / 1000) + 120;
    await db.collection('DeletionJobs').doc(retryUser.uid).set({
      uid: retryUser.uid,
      status: 'in_progress',
      lockExpiresAt: futureLock,
      steps: {},
    });
    const dupRes = await callFunction('requestAccountDeletion', {}, retryUser.idToken);
    assert.equal(dupRes.ok, false);
    assert.equal(dupRes.body?.error?.details?.code, 'deletion-in-progress');

    await db.collection('DeletionJobs').doc(retryUser.uid).set({
      uid: retryUser.uid,
      status: 'failed_retryable',
      lockExpiresAt: null,
      steps: {horses: true, connections: true, requests: true},
    });
    const retryRes = await callFunction('requestAccountDeletion', {}, retryUser.idToken);
    assert.equal(retryRes.ok, true, JSON.stringify(retryRes.body));
    assert.equal(retryRes.body.result.status, 'completed');
    await assert.rejects(() => auth.getUser(retryUser.uid), /user-not-found|no user record/i);
  });

  console.log('\nAll account deletion emulator tests passed!');
}

main().catch((err) => {
  console.error('Account deletion emulator test failed:', err);
  process.exit(1);
});
