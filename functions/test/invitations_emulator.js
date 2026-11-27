/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

/**
 * Firebase Emulator integration check for Invitation Firestore security rules
 * and server-side Cloud Functions.
 *
 * Run against Firebase emulators:
 *   firebase emulators:exec --only auth,firestore,functions "node functions/test/invitations_emulator.js"
 */

const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const {profileId} = require('../connections');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-horse-rules';
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const FUNCTIONS_HOST = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}

const db = admin.firestore();
const auth = admin.auth();

async function createSignedInUser(email, password, displayName) {
  await auth.createUser({email, password, displayName, emailVerified: true});
  const res = await fetch(
      `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-api-key`,
      {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({email, password, returnSecureToken: true}),
      },
  );
  const json = await res.json();
  return json.idToken;
}

async function callFn(name, data, idToken = null) {
  const res = await fetch(`http://${FUNCTIONS_HOST}/${PROJECT_ID}/us-central1/${name}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(idToken ? {Authorization: `Bearer ${idToken}`} : {}),
    },
    body: JSON.stringify({data}),
  });
  return {status: res.status, json: await res.json()};
}

async function main() {
  const coachEmail = 'emu-coach@example.com';
  const studentEmail = 'emu-student@example.com';
  const coachToken = await createSignedInUser(coachEmail, 'password123', 'Emu Coach');
  const studentToken = await createSignedInUser(studentEmail, 'password123', 'Emu Student');

  await db.collection('Rider_Profile').doc(profileId(coachEmail)).set({
    email: coachEmail,
    name: 'Emu Coach',
    isTrainer: true,
  });

  const created = await callFn('createInvitation', {type: 'student_connection'}, coachToken);
  assert.equal(created.status, 200);
  const invId = created.json.result.invitation.id;
  const token = created.json.result.token;

  // Direct Firestore client reads/writes on Invitations must fail closed (403).
  const directRead = await fetch(
      `http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/Invitations/${invId}`,
      {headers: {Authorization: `Bearer ${studentToken}`}},
  );
  assert.equal(directRead.status, 403);

  const preview = await callFn('getInvitationPreview', {token});
  assert.equal(preview.status, 200);
  assert.equal(preview.json.result.tokenValid, true);

  const redeemed = await callFn('redeemInvitation', {token}, studentToken);
  assert.equal(redeemed.status, 200);
  assert.equal(redeemed.json.result.outcome, 'pending_connection_created');

  console.log('Invitation emulator security & workflow checks passed.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
