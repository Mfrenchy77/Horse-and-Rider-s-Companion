/* eslint-env node */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {
  MAX_HTML_BYTES,
  applyCors,
  assertSafeRemoteUrl,
  createFetchReadableHandler,
  createPreviewMetaHandler,
  createResolveImageHandler,
  isDisallowedIp,
  readTextWithLimit,
  safeFetch,
} = require('../link_preview');

function makeRes() {
  const res = {
    statusCode: 200,
    headers: {},
    body: null,
    set(k, v) {
      this.headers[k] = v;
      return this;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.body = data;
      return this;
    },
    send(data) {
      this.body = data;
      return this;
    },
  };
  return res;
}

test('isDisallowedIp rejects private, loopback, link-local, metadata, and mapped IPv6 addresses', () => {
  for (const ip of [
    '127.0.0.1',
    '10.0.0.1',
    '172.16.0.1',
    '192.168.1.50',
    '169.254.169.254',
    '100.64.0.1',
    '224.0.0.1',
    '::1',
    '::',
    'fc00::1',
    'fd12:3456::1',
    'fe80::1',
    '::ffff:127.0.0.1',
    '::ffff:7f00:1',
    '0:0:0:0:0:ffff:169.254.169.254',
  ]) {
    assert.equal(isDisallowedIp(ip), true, `Expected ${ip} to be rejected`);
  }

  for (const ip of ['93.184.216.34', '1.1.1.1', '2606:4700:4700::1111']) {
    assert.equal(isDisallowedIp(ip), false, `Expected ${ip} to be allowed`);
  }
});

test('assertSafeRemoteUrl blocks unsafe schemes, credentials, internal hosts, and private DNS answers', async () => {
  const publicLookup = async () => [{address: '93.184.216.34', family: 4}];
  await assert.rejects(assertSafeRemoteUrl('file:///etc/passwd', {lookupFn: publicLookup}), {status: 400});
  await assert.rejects(assertSafeRemoteUrl('https://user:pass@example.com', {lookupFn: publicLookup}), {status: 400});
  await assert.rejects(assertSafeRemoteUrl('http://metadata.google.internal/', {lookupFn: publicLookup}), {status: 400});
  await assert.rejects(
      assertSafeRemoteUrl('https://rebind.example', {
        lookupFn: async () => [{address: '169.254.169.254', family: 4}],
      }),
      {status: 400},
  );
  const safe = await assertSafeRemoteUrl('https://example.com/path', {lookupFn: publicLookup});
  assert.equal(safe, 'https://example.com/path');
});

test('safeFetch validates every manual redirect hop and enforces redirect cap', async () => {
  const lookupFn = async (host) =>
    host === 'internal.localtest' ?
      [{address: '127.0.0.1', family: 4}] :
      [{address: '93.184.216.34', family: 4}];

  await assert.rejects(
      safeFetch('https://public.example/start', {
        lookupFn,
        fetchFn: async () => ({
          status: 302,
          headers: {get: (k) => (k === 'location' ? 'http://169.254.169.254/latest' : null)},
          body: {cancel: async () => {}},
        }),
      }),
      {status: 400},
  );

  await assert.rejects(
      safeFetch('https://public.example/loop', {
        lookupFn: async () => [{address: '93.184.216.34', family: 4}],
        fetchFn: async () => ({
          status: 302,
          headers: {get: (k) => (k === 'location' ? 'https://public.example/loop' : null)},
          body: {cancel: async () => {}},
        }),
      }),
      {status: 400},
  );
});

test('readTextWithLimit aborts oversized HTML payloads', async () => {
  await assert.rejects(
      readTextWithLimit({
        headers: {get: () => String(MAX_HTML_BYTES + 10)},
        body: {cancel: async () => {}},
      }),
      {status: 413},
  );

  let cancelled = false;
  const chunkSize = 1024 * 1024;
  let reads = 0;
  await assert.rejects(
      readTextWithLimit({
        headers: {get: () => null},
        body: {
          getReader() {
            return {
              async read() {
                reads += 1;
                if (reads <= 3) {
                  return {done: false, value: new Uint8Array(chunkSize)};
                }
                return {done: true};
              },
              async cancel() {
                cancelled = true;
              },
            };
          },
        },
      }),
      {status: 413},
  );
  assert.equal(cancelled, true);
});

test('applyCors rejects disallowed origins and echoes allowlisted origins', () => {
  const denied = makeRes();
  assert.equal(applyCors({method: 'POST', headers: {origin: 'https://evil.example'}}, denied), false);
  assert.equal(denied.statusCode, 403);
  assert.equal(denied.headers['Access-Control-Allow-Origin'], undefined);

  const allowed = makeRes();
  assert.equal(
      applyCors({method: 'POST', headers: {origin: 'https://horse-and-riders-compani-d2bd4.web.app'}}, allowed),
      true,
  );
  assert.equal(allowed.headers['Access-Control-Allow-Origin'], 'https://horse-and-riders-compani-d2bd4.web.app');
});

test('previewMeta and fetchReadable require verified Firebase Auth while resolveImage stays public with cache', async () => {
  const previewHandler = createPreviewMetaHandler({
    verifyIdToken: async (token) => {
      if (token === 'unverified') return {uid: 'u1', email_verified: false};
      if (token === 'verified') return {uid: 'u1', email_verified: true};
      throw new Error('invalid');
    },
    lookupFn: async () => [{address: '93.184.216.34', family: 4}],
    fetchFn: async () => ({
      ok: true,
      status: 200,
      url: 'https://example.com',
      headers: {get: (k) => (k === 'content-type' ? 'text/html' : null)},
      text: async () => '<title>Safe</title>',
    }),
  });

  const readableHandler = createFetchReadableHandler({
    verifyIdToken: async () => {
      throw new Error('invalid');
    },
  });

  const unauthRes = makeRes();
  await previewHandler({method: 'POST', headers: {}, body: {url: 'https://example.com'}}, unauthRes);
  assert.equal(unauthRes.statusCode, 401);

  const unverifiedRes = makeRes();
  await previewHandler(
      {method: 'POST', headers: {authorization: 'Bearer unverified'}, body: {url: 'https://example.com'}},
      unverifiedRes,
  );
  assert.equal(unverifiedRes.statusCode, 403);

  const okRes = makeRes();
  await previewHandler(
      {method: 'POST', headers: {authorization: 'Bearer verified'}, body: {url: 'https://example.com'}},
      okRes,
  );
  assert.equal(okRes.statusCode, 200);
  assert.equal(okRes.body.title, 'Safe');

  const readableUnauth = makeRes();
  await readableHandler({method: 'POST', headers: {}, body: {url: 'https://example.com'}}, readableUnauth);
  assert.equal(readableUnauth.statusCode, 401);

  const resolveHandler = createResolveImageHandler({
    lookupFn: async () => [{address: '93.184.216.34', family: 4}],
    fetchFn: async () => ({
      ok: true,
      status: 200,
      url: 'https://example.com/photo.jpg',
      headers: {get: (k) => (k === 'content-type' ? 'image/jpeg' : null)},
      body: {cancel: async () => {}},
    }),
  });
  const resolveRes = makeRes();
  await resolveHandler({method: 'POST', headers: {}, body: {url: 'https://example.com/photo.jpg'}}, resolveRes);
  assert.equal(resolveRes.statusCode, 200);
  assert.equal(resolveRes.headers['Cache-Control'], 'public, max-age=1800, s-maxage=3600');
});
