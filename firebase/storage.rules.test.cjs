'use strict';

const assert = require('node:assert/strict');
const {before, test} = require('node:test');

const STORAGE_HOST = process.env.FIREBASE_STORAGE_EMULATOR_HOST || '127.0.0.1:9199';
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-horse-rules';
const BUCKET = `${PROJECT_ID}.appspot.com`;
const BASE_URL = `http://${STORAGE_HOST}/v0/b/${BUCKET}/o`;

function emulatorJwt(claims) {
  const nowSec = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({alg: 'none', typ: 'JWT'})).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: `https://securetoken.google.com/${PROJECT_ID}`,
    aud: PROJECT_ID,
    auth_time: nowSec,
    iat: nowSec,
    exp: nowSec + 3600,
    ...claims,
  })).toString('base64url');
  return `${header}.${payload}.`;
}

async function uploadObject(path, body, contentType, token) {
  const url = `${BASE_URL}?uploadType=media&name=${encodeURIComponent(path)}`;
  const headers = {'Content-Type': contentType};
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(url, {method: 'POST', headers, body});
}

async function readObject(path, token) {
  const url = `${BASE_URL}/${encodeURIComponent(path)}?alt=media`;
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(url, {method: 'GET', headers});
}

const memberToken = emulatorJwt({
  user_id: 'member-1',
  sub: 'member-1',
  email: 'member@example.com',
  email_verified: true,
});

const unverifiedAdminToken = emulatorJwt({
  user_id: 'admin-unverified',
  sub: 'admin-unverified',
  email: 'admin@example.com',
  email_verified: false,
  admin: true,
});

const verifiedAdminToken = emulatorJwt({
  user_id: 'admin-1',
  sub: 'admin-1',
  email: 'admin@example.com',
  email_verified: true,
  admin: true,
});

before(async () => {
  // Seed one draft image as verified admin and one public image using owner bypass.
  const draftRes = await uploadObject(
      'dictionary_drafts/canter/seeded_draft.png',
      Buffer.from('draft-png'),
      'image/png',
      verifiedAdminToken,
  );
  assert.equal(draftRes.status, 200);

  const pubRes = await uploadObject(
      'dictionary_public/canter/seeded_public.png',
      Buffer.from('public-png'),
      'image/png',
      'owner',
  );
  assert.equal(pubRes.status, 200);
});

test('unauthenticated users cannot read/write dictionary_drafts or write dictionary_public, but can read dictionary_public', async () => {
  const draftRead = await readObject('dictionary_drafts/canter/seeded_draft.png', null);
  assert.equal(draftRead.status, 403);

  const draftWrite = await uploadObject(
      'dictionary_drafts/canter/guest.png',
      Buffer.from('x'),
      'image/png',
      null,
  );
  assert.equal(draftWrite.status, 403);

  const publicRead = await readObject('dictionary_public/canter/seeded_public.png', null);
  assert.equal(publicRead.status, 200);

  const publicWrite = await uploadObject(
      'dictionary_public/canter/guest_hack.png',
      Buffer.from('x'),
      'image/png',
      null,
  );
  assert.equal(publicWrite.status, 403);
});

test('ordinary authenticated users and unverified administrators are denied draft access and public writes', async () => {
  for (const token of [memberToken, unverifiedAdminToken]) {
    const draftRead = await readObject('dictionary_drafts/canter/seeded_draft.png', token);
    assert.equal(draftRead.status, 403);

    const draftWrite = await uploadObject(
        'dictionary_drafts/canter/unauthorized.png',
        Buffer.from('x'),
        'image/png',
        token,
    );
    assert.equal(draftWrite.status, 403);

    const publicWrite = await uploadObject(
        'dictionary_public/canter/unauthorized.png',
        Buffer.from('x'),
        'image/png',
        token,
    );
    assert.equal(publicWrite.status, 403);
  }
});

test('verified administrators can read/write valid PNG/JPEG/WebP drafts, cannot write dictionary_public, and invalid types/sizes are rejected', async () => {
  const draftRead = await readObject('dictionary_drafts/canter/seeded_draft.png', verifiedAdminToken);
  assert.equal(draftRead.status, 200);

  for (const [name, type] of [
    ['img.png', 'image/png'],
    ['img.jpg', 'image/jpeg'],
    ['img.webp', 'image/webp'],
  ]) {
    const res = await uploadObject(
        `dictionary_drafts/canter/${name}`,
        Buffer.from('valid-image-bytes'),
        type,
        verifiedAdminToken,
    );
    assert.equal(res.status, 200, `Expected ${type} upload to succeed`);
  }

  // Disallowed file types rejected even for verified admin.
  for (const [name, type] of [
    ['bad.gif', 'image/gif'],
    ['bad.pdf', 'application/pdf'],
    ['bad.txt', 'text/plain'],
  ]) {
    const res = await uploadObject(
        `dictionary_drafts/canter/${name}`,
        Buffer.from('bad'),
        type,
        verifiedAdminToken,
    );
    assert.equal(res.status, 403, `Expected ${type} upload to be rejected`);
  }

  // Oversized (> 10 MB) upload rejected even for verified admin.
  const oversized = Buffer.alloc(10 * 1024 * 1024 + 1, 0x41);
  const oversizedRes = await uploadObject(
      'dictionary_drafts/canter/huge.png',
      oversized,
      'image/png',
      verifiedAdminToken,
  );
  assert.equal(oversizedRes.status, 403);

  // Direct client writes to dictionary_public rejected even for verified admin.
  const publicWrite = await uploadObject(
      'dictionary_public/canter/direct.png',
      Buffer.from('x'),
      'image/png',
      verifiedAdminToken,
  );
  assert.equal(publicWrite.status, 403);
});
