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

const otherMemberToken = emulatorJwt({
  user_id: 'member-2',
  sub: 'member-2',
  email: 'other@example.com',
  email_verified: true,
});

const editorToken = emulatorJwt({
  user_id: 'editor-1',
  sub: 'editor-1',
  email: 'editor@example.com',
  email_verified: true,
  editor: true,
});

const unverifiedMemberToken = emulatorJwt({
  user_id: 'unverified-1',
  sub: 'unverified-1',
  email: 'unverified@example.com',
  email_verified: false,
});

async function seedFirestoreDoc(collection, docId, fields) {
  const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const url = `http://${host}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer owner',
    },
    body: JSON.stringify({fields}),
  });
  assert.equal(res.status, 200, `Expected seed ${collection}/${docId} to succeed`);
}

async function deleteObject(path, token) {
  const url = `${BASE_URL}/${encodeURIComponent(path)}`;
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(url, {method: 'DELETE', headers});
}

test('Riders_Photo, Horses_Photo, covers, and resources/pdfs enforce ownership, MIME types, and size limits', async () => {
  await seedFirestoreDoc('Rider_Profile', 'rider-doc-1', {
    ownerUid: {stringValue: 'member-1'},
    email: {stringValue: 'member@example.com'},
  });
  await seedFirestoreDoc('Horse_Profile', 'horse-doc-1', {
    ownerUid: {stringValue: 'member-1'},
    currentOwnerId: {stringValue: 'member@example.com'},
  });
  await seedFirestoreDoc('Resources', 'res-doc-1', {
    authorId: {stringValue: 'member@example.com'},
    lastEditBy: {stringValue: 'member@example.com'},
  });

  // Unverified users cannot write any user media path.
  assert.equal(
      (await uploadObject('Riders_Photo/unverified-1/avatar.jpg', Buffer.from('jpg'), 'image/jpeg', unverifiedMemberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/unverified-1/horse-1', Buffer.from('jpg'), 'image/jpeg', unverifiedMemberToken)).status,
      403,
  );

  // Owners can upload valid images to legacy and UID-scoped rider/horse paths.
  assert.equal(
      (await uploadObject('Riders_Photo/rider-doc-1', Buffer.from('jpg'), 'image/jpeg', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('Riders_Photo/member-1/avatar.png', Buffer.from('png'), 'image/png', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/horse-doc-1', Buffer.from('jpg'), 'image/jpeg', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/member-1/new-horse', Buffer.from('webp'), 'image/webp', memberToken)).status,
      200,
  );

  // Cross-user overwrites and deletes are rejected.
  assert.equal(
      (await uploadObject('Riders_Photo/rider-doc-1', Buffer.from('pwn'), 'image/jpeg', otherMemberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/horse-doc-1', Buffer.from('pwn'), 'image/jpeg', otherMemberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/member-1/new-horse', Buffer.from('pwn'), 'image/jpeg', otherMemberToken)).status,
      403,
  );
  assert.equal((await deleteObject('Horses_Photo/horse-doc-1', otherMemberToken)).status, 403);

  // Wrong MIME type or oversized image (>10 MB) rejected even for owner.
  assert.equal(
      (await uploadObject('Horses_Photo/member-1/bad.pdf', Buffer.from('%PDF'), 'application/pdf', memberToken)).status,
      403,
  );
  const bigImage = Buffer.alloc(10 * 1024 * 1024 + 1, 0x41);
  assert.equal(
      (await uploadObject('Horses_Photo/member-1/too-big.jpg', bigImage, 'image/jpeg', memberToken)).status,
      403,
  );

  // Covers allow owner email only and enforce image MIME.
  assert.equal(
      (await uploadObject('covers/member@example.com/c1/cover.jpg', Buffer.from('jpg'), 'image/jpeg', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('covers/member@example.com/c1/bad.txt', Buffer.from('txt'), 'text/plain', memberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('covers/member@example.com/c1/cover.jpg', Buffer.from('pwn'), 'image/jpeg', otherMemberToken)).status,
      403,
  );

  // Resource PDFs: UID-scoped, legacy owner, and editor succeed; non-owner / non-PDF / >25 MB fail.
  assert.equal(
      (await uploadObject('resources/pdfs/users/member-1/res-new/guide.pdf', Buffer.from('%PDF'), 'application/pdf', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('resources/pdfs/res-doc-1/guide.pdf', Buffer.from('%PDF'), 'application/pdf', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('resources/pdfs/editor-res/guide.pdf', Buffer.from('%PDF'), 'application/pdf', editorToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('resources/pdfs/res-doc-1/guide.pdf', Buffer.from('%PDF'), 'application/pdf', otherMemberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('resources/pdfs/users/member-1/res-new/evil.html', Buffer.from('<html>'), 'text/html', memberToken)).status,
      403,
  );
  const bigPdf = Buffer.alloc(25 * 1024 * 1024 + 1, 0x25);
  assert.equal(
      (await uploadObject('resources/pdfs/users/member-1/res-new/huge.pdf', bigPdf, 'application/pdf', memberToken)).status,
      403,
  );
});

test('legacy profiles without ownerUid remain compatible and dictionary_submissions enforce privacy', async () => {
  await seedFirestoreDoc('Rider_Profile', 'legacy-rider-no-uid', {
    email: {stringValue: 'MEMBER@example.com'},
  });
  await seedFirestoreDoc('Horse_Profile', 'legacy-horse-no-uid', {
    currentOwnerId: {stringValue: 'Member@Example.com'},
  });

  // Legacy owner without ownerUid can upload and delete via email / currentOwnerId fallback.
  assert.equal(
      (await uploadObject('Riders_Photo/legacy-rider-no-uid', Buffer.from('jpg'), 'image/jpeg', memberToken)).status,
      200,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/legacy-horse-no-uid', Buffer.from('png'), 'image/png', memberToken)).status,
      200,
  );
  // Different user is denied even when legacy doc lacks ownerUid.
  assert.equal(
      (await uploadObject('Riders_Photo/legacy-rider-no-uid', Buffer.from('pwn'), 'image/jpeg', otherMemberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('Horses_Photo/legacy-horse-no-uid', Buffer.from('pwn'), 'image/png', otherMemberToken)).status,
      403,
  );
  assert.ok([200, 204].includes((await deleteObject('Horses_Photo/legacy-horse-no-uid', memberToken)).status));

  // Dictionary submissions: owner creates & reads own file; other user denied; admin reads & deletes.
  assert.equal(
      (await uploadObject('dictionary_submissions/member-1/sub-1/img.webp', Buffer.from('webp'), 'image/webp', memberToken)).status,
      200,
  );
  assert.equal(
      (await readObject('dictionary_submissions/member-1/sub-1/img.webp', memberToken)).status,
      200,
  );
  assert.equal(
      (await readObject('dictionary_submissions/member-1/sub-1/img.webp', otherMemberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('dictionary_submissions/member-1/sub-2/spoof.png', Buffer.from('png'), 'image/png', otherMemberToken)).status,
      403,
  );
  assert.equal(
      (await readObject('dictionary_submissions/member-1/sub-1/img.webp', verifiedAdminToken)).status,
      200,
  );
  assert.ok([200, 204].includes((await deleteObject('dictionary_submissions/member-1/sub-1/img.webp', verifiedAdminToken)).status));

  // Staged deployment compatibility: legacy clients without explicit image/PDF MIME metadata
  // or uploading new-resource PDFs before creating Resources/{id} are blocked by hardened rules,
  // confirming why storage rules must deploy before hosting and roll back with hosting if reverted.
  assert.equal(
      (await uploadObject('Horses_Photo/legacy-horse-no-uid', Buffer.from('raw'), 'application/octet-stream', memberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('Riders_Photo/legacy-rider-no-uid', Buffer.from('raw'), 'application/octet-stream', memberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('resources/pdfs/uncreated-resource-doc/guide.pdf', Buffer.from('%PDF'), 'application/pdf', memberToken)).status,
      403,
  );
  // New clients with UID-scoped paths succeed even before Firestore docs exist, and legacy GETs stay public.
  assert.equal(
      (await uploadObject('resources/pdfs/users/member-1/uncreated-resource-doc/guide.pdf', Buffer.from('%PDF'), 'application/pdf', memberToken)).status,
      200,
  );
  assert.equal(
      (await readObject('Riders_Photo/legacy-rider-no-uid', null)).status,
      200,
  );

  // Dictionary contributor suspension blocks new dictionary_submissions uploads,
  // preserves non-Dictionary uploads (Riders_Photo), and re-allows when restored.
  await seedFirestoreDoc('DictionaryContributorModeration', 'member-1', {
    uid: {stringValue: 'member-1'},
    suspended: {booleanValue: true},
    reason: {stringValue: 'Temporary pause'},
  });
  assert.equal(
      (await uploadObject('dictionary_submissions/member-1/sub-blocked/img.png', Buffer.from('png'), 'image/png', memberToken)).status,
      403,
  );
  assert.equal(
      (await uploadObject('Riders_Photo/member-1/profile.png', Buffer.from('png'), 'image/png', memberToken)).status,
      200,
  );
  await seedFirestoreDoc('DictionaryContributorModeration', 'member-1', {
    uid: {stringValue: 'member-1'},
    suspended: {booleanValue: false},
    reason: {stringValue: 'Restored'},
  });
  assert.equal(
      (await uploadObject('dictionary_submissions/member-1/sub-restored/img.png', Buffer.from('png'), 'image/png', memberToken)).status,
      200,
  );
  // Regression check: verified non-suspended user uploading PNG to Trot submission path succeeds and stays private.
  assert.equal(
      (await uploadObject('dictionary_submissions/member-2/sub-trot/1795835000_trot.png', Buffer.from('png'), 'image/png', otherMemberToken)).status,
      200,
  );
  assert.equal(
      (await readObject('dictionary_submissions/member-2/sub-trot/1795835000_trot.png', null)).status,
      403,
  );
  assert.equal(
      (await readObject('dictionary_submissions/member-2/sub-trot/1795835000_trot.png', otherMemberToken)).status,
      200,
  );
});
