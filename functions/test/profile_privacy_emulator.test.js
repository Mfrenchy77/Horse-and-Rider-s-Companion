'use strict';

const assert = require('node:assert/strict');
const {test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-horse-privacy';
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}

const db = admin.firestore();
const auth = admin.auth();

async function createAndSignIn(email, {emailVerified = true, claims = null} = {}) {
  const user = await auth.createUser({email, password: 'Password123!', emailVerified});
  if (claims) {
    await auth.setCustomUserClaims(user.uid, claims);
  }
  const res = await fetch(
      `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
      {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({email, password: 'Password123!', returnSecureToken: true}),
      },
  );
  const json = await res.json();
  if (!res.ok || !json.idToken) {
    throw new Error(`Sign-in failed for ${email}: ${JSON.stringify(json)}`);
  }
  return {uid: user.uid, email, idToken: json.idToken};
}

async function fsGet(docPath, idToken = null) {
  const headers = idToken ? {Authorization: `Bearer ${idToken}`} : {};
  const res = await fetch(
      `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`,
      {headers},
  );
  return res.status;
}

async function fsList(colPath, idToken = null) {
  const headers = idToken ? {Authorization: `Bearer ${idToken}`} : {};
  const res = await fetch(
      `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${colPath}`,
      {headers},
  );
  return res.status;
}

async function fsPatch(docPath, fields, idToken) {
  const mask = Object.keys(fields).map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
  const res = await fetch(
      `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}?${mask}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${idToken}`,
        },
        body: JSON.stringify({fields}),
      },
  );
  return res.status;
}

async function main() {
  const rulesPath = path.resolve(__dirname, '../../firebase/firestore.rules');
  const rulesSource = fs.readFileSync(rulesPath, 'utf8');
  const putRes = await fetch(
      `http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}:securityRules`,
      {
        method: 'PUT',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({rules: {files: [{name: 'firestore.rules', content: rulesSource}]}}),
      },
  );
  assert.equal(putRes.status, 200, 'Security rules must load cleanly');

  const owner = await createAndSignIn('owner@example.com');
  const trainer = await createAndSignIn('trainer@example.com');
  const unrelated = await createAndSignIn('unrelated@example.com');
  const unverified = await createAndSignIn('unverified@example.com', {emailVerified: false});
  const adminUser = await createAndSignIn('admin@example.com', {claims: {admin: true}});

  await db.doc('Rider_Profile/owner_doc').set({
    email: owner.email,
    ownerUid: owner.uid,
    name: 'Synthetic Owner',
    notes: [{id: 'n1', name: 'Private journal'}],
    archivedHorses: [{id: 'horse_private', name: 'Private Horse'}],
    savedProfilesList: [{id: 'friend@example.com', name: 'Friend'}],
    instructorUids: [trainer.uid],
  });
  await db.doc('Public_Rider_Profile/owner_doc').set({
    id: 'owner_doc',
    email: owner.email,
    name: 'Synthetic Owner',
  });
  await db.doc('Rider_Profile/owner_doc/SkillProgress/rider.in_hand.leading').set({
    skillId: 'rider.in_hand.leading',
    subject: 'rider',
    levels: {introductory: {state: 'LEARNING', updatedByUid: owner.uid}},
    schemaVersion: 2,
  });
  await db.doc('Rider_Profile/owner_doc/SkillVerifications/rider.in_hand.leading').set({
    skillId: 'rider.in_hand.leading',
    levels: {introductory: {verifiedState: 'PROFICIENT'}},
  });
  await db.doc('CoachingConnections/conn_accepted').set({
    status: 'accepted',
    coachUid: trainer.uid,
    learnerUid: owner.uid,
    participantUids: [owner.uid, trainer.uid],
  });
  await db.doc('Rider_Profile/owner_doc/SkillVerificationEvents/ev1').set({
    connectionId: 'conn_accepted',
    skillId: 'rider.in_hand.leading',
  });

  await db.doc('Horse_Profile/horse_private').set({
    id: 'horse_private',
    name: 'Private Horse',
    currentOwnerId: owner.email,
    ownerUid: owner.uid,
    isPublic: false,
    notes: [{id: 'hn1', name: 'Private vet note'}],
    instructorUids: [trainer.uid],
  });
  await db.doc('Horse_Profile/horse_private/SkillProgress/horse.in_hand.leading').set({
    skillId: 'horse.in_hand.leading',
    subject: 'horse',
    levels: {introductory: {state: 'PROFICIENT', updatedByUid: owner.uid}},
    schemaVersion: 2,
  });
  await db.doc('Horse_Profile/horse_private/SkillVerifications/horse.in_hand.leading').set({
    skillId: 'horse.in_hand.leading',
    levels: {introductory: {verifiedState: 'PROFICIENT'}},
  });
  await db.doc('Horse_Profile/horse_private/SkillVerificationEvents/hev1').set({
    connectionId: 'conn_accepted',
    skillId: 'horse.in_hand.leading',
  });
  await db.doc('Public_Horse_Profile/horse_public').set({
    id: 'horse_public',
    name: 'Public Horse',
    isPublic: true,
    archiveStatus: 'active',
  });

  // 1. Private Horse_Profile: blocked for guest, unverified, unrelated; allowed for trainer, owner, admin
  assert.equal(await fsGet('Horse_Profile/horse_private', null), 403);
  assert.equal(await fsGet('Horse_Profile/horse_private', unverified.idToken), 403);
  assert.equal(await fsGet('Horse_Profile/horse_private', unrelated.idToken), 403);
  assert.equal(await fsList('Horse_Profile', unrelated.idToken), 403);
  assert.equal(await fsGet('Horse_Profile/horse_private', trainer.idToken), 200);
  assert.equal(await fsGet('Horse_Profile/horse_private', owner.idToken), 200);
  assert.equal(await fsGet('Horse_Profile/horse_private', adminUser.idToken), 200);

  // 2. Public_Horse_Profile: get allowed for all; list allowed for verified only (not guests)
  assert.equal(await fsGet('Public_Horse_Profile/horse_public', null), 200);
  assert.equal(await fsGet('Public_Horse_Profile/horse_public', unrelated.idToken), 200);
  assert.equal(await fsList('Public_Horse_Profile', null), 403);
  assert.equal(await fsList('Public_Horse_Profile', unrelated.idToken), 200);

  // 3. Private Rider_Profile: blocked for guest, unverified, unrelated; allowed for trainer, owner, admin
  assert.equal(await fsGet('Rider_Profile/owner_doc', null), 403);
  assert.equal(await fsGet('Rider_Profile/owner_doc', unverified.idToken), 403);
  assert.equal(await fsGet('Rider_Profile/owner_doc', unrelated.idToken), 403);
  assert.equal(await fsList('Rider_Profile', null), 403);
  assert.equal(await fsList('Rider_Profile', unrelated.idToken), 403);
  assert.equal(await fsGet('Rider_Profile/owner_doc', trainer.idToken), 200);
  assert.equal(await fsGet('Rider_Profile/owner_doc', owner.idToken), 200);
  assert.equal(await fsGet('Rider_Profile/owner_doc', adminUser.idToken), 200);

  // 4. Public_Rider_Profile: blocked for guest & unverified; allowed for verified users
  assert.equal(await fsGet('Public_Rider_Profile/owner_doc', null), 403);
  assert.equal(await fsGet('Public_Rider_Profile/owner_doc', unverified.idToken), 403);
  assert.equal(await fsGet('Public_Rider_Profile/owner_doc', unrelated.idToken), 200);
  assert.equal(await fsList('Public_Rider_Profile', unrelated.idToken), 200);

  // 5. SkillProgress & SkillVerifications (Horse & Rider): owner, accepted trainer, admin only
  for (const subPath of [
    'Horse_Profile/horse_private/SkillProgress/horse.in_hand.leading',
    'Horse_Profile/horse_private/SkillVerifications/horse.in_hand.leading',
    'Rider_Profile/owner_doc/SkillProgress/rider.in_hand.leading',
    'Rider_Profile/owner_doc/SkillVerifications/rider.in_hand.leading',
  ]) {
    assert.equal(await fsGet(subPath, null), 403, `guest denied ${subPath}`);
    assert.equal(await fsGet(subPath, unrelated.idToken), 403, `unrelated denied ${subPath}`);
    assert.equal(await fsGet(subPath, trainer.idToken), 200, `trainer allowed ${subPath}`);
    assert.equal(await fsGet(subPath, owner.idToken), 200, `owner allowed ${subPath}`);
    assert.equal(await fsGet(subPath, adminUser.idToken), 200, `admin allowed ${subPath}`);
  }

  // 6. SkillVerificationEvents: owner, accepted trainer, and admin allowed; guest/unrelated denied
  for (const evPath of [
    'Horse_Profile/horse_private/SkillVerificationEvents/hev1',
    'Rider_Profile/owner_doc/SkillVerificationEvents/ev1',
  ]) {
    assert.equal(await fsGet(evPath, null), 403, `guest denied ${evPath}`);
    assert.equal(await fsGet(evPath, unrelated.idToken), 403, `unrelated denied ${evPath}`);
    assert.equal(await fsGet(evPath, trainer.idToken), 200, `trainer allowed ${evPath}`);
    assert.equal(await fsGet(evPath, owner.idToken), 200, `owner allowed ${evPath}`);
    assert.equal(await fsGet(evPath, adminUser.idToken), 200, `admin allowed ${evPath}`);
  }

  // 7. Client cannot modify server-controlled instructorUids on Horse_Profile or Rider_Profile
  assert.equal(
      await fsPatch(
          'Horse_Profile/horse_private',
          {instructorUids: {arrayValue: {values: [{stringValue: unrelated.uid}]}}},
          owner.idToken,
      ),
      403,
  );
  assert.equal(
      await fsPatch(
          'Rider_Profile/owner_doc',
          {instructorUids: {arrayValue: {values: [{stringValue: unrelated.uid}]}}},
          owner.idToken,
      ),
      403,
  );

  // 8. Brand-new verified user reading non-existent own Rider_Profile gets 404 (not 403)
  assert.equal(await fsGet('Rider_Profile/brand_new_doc', unrelated.idToken), 404);

  console.log('ALL PROFILE PRIVACY EMULATOR ASSERTIONS PASSED');
}

const hasEmulators = Boolean(
    process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST,
);

test(
    'profile privacy rules enforce owner, instructor, and public projections under Firebase emulators',
    {skip: !hasEmulators && 'Requires FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST'},
    main,
);
