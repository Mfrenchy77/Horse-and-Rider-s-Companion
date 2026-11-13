/* eslint-env node */
'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Exercise public handlers with the real HTML parsers. Only Firebase, CORS,
// logging and external HTTP are replaced; no credentials or live data are used.
function harness({fetch, conversation, tokens = ['token-1']} = {}) {
  const pushes = [];
  const errors = [];
  const tokenOwners = [];
  const admin = {
    app() {},
    messaging: () => ({
      sendEachForMulticast: async (message) => pushes.push(message),
    }),
    firestore: () => ({collection: () => ({doc: (id) => ({
      get: async () => ({exists: !!conversation, data: () => conversation}),
      collection: () => ({get: async () => {
        tokenOwners.push(id);
        return {docs: tokens.map((token) => ({id: token, data: () => ({token})}))};
      }}),
    })})}),
  };
  const exports = {};
  const mocks = {
    'cors': () => (req, res, next) => next(),
    'firebase-admin': admin,
    'firebase-functions/logger': {error: (...args) => errors.push(args), info() {}},
    'firebase-functions/v2/https': {onRequest: (_, handler) => handler, onCall: (_, handler) => handler},
    'firebase-functions/v2/firestore': {onDocumentCreated: (_, handler) => handler},
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8'), {
    exports, URL, AbortSignal,
    fetch: fetch || (async () => { throw new Error('Unexpected network access'); }),
    require: (id) => mocks[id] ||
      (id === './connections' ? require('../connections') :
      id === './account_deletion' ? require('../account_deletion') : require(id)),
  }, {filename: 'index.js'});
  return {handlers: exports, pushes, errors, tokenOwners};
}

function response({url = 'https://stable.example/guide', status = 200,
  type = 'text/html', html = '', headers = {}} = {}) {
  return {url, ok: status >= 200 && status < 300, status,
    headers: {get: (name) => name === 'content-type' ? type : headers[name]}, text: async () => html, json: async () => []};
}

async function request(handler, {method = 'POST', body = {}} = {}) {
  let status = 200;
  return new Promise((resolve, reject) => {
    const res = {
      status(value) { status = value; return this; },
      json(value) { resolve({status, body: JSON.parse(JSON.stringify(value))}); },
    };
    Promise.resolve(handler({method, body}, res)).catch(reject);
  });
}

for (const name of ['previewMeta', 'fetchReadable', 'resolveImage']) {
  test(`${name} rejects non-POST requests`, {timeout: 2000}, async () => {
    const {handlers} = harness();
    assert.equal((await request(handlers[name], {method: 'GET'})).status, 400);
  });
  for (const url of [undefined, 42, '']) {
    test(`${name} rejects invalid URL input ${url}`, {timeout: 2000}, async () => {
      const {handlers} = harness();
      assert.equal((await request(handlers[name], {body: {url}})).status, 400);
    });
  }
  test(`${name} reports upstream failures`, {timeout: 2000}, async () => {
    const {handlers} = harness({fetch: async () => response({status: 503})});
    assert.equal((await request(handlers[name], {body: {url: 'https://stable.example'}})).status, 502);
  });
  test(`${name} handles network exceptions`, {timeout: 2000}, async () => {
    const {handlers} = harness();
    assert.equal((await request(handlers[name], {body: {url: 'https://stable.example'}})).status, 500);
  });
}

test('previewMeta extracts metadata and resolves relative image URLs after redirects', async () => {
  const {handlers} = harness({fetch: async () => response({html: `
    <title>Fallback</title><meta property="og:title" content="Training guide">
    <meta name="description" content="Learn transitions">
    <meta property="og:image" content="/cover.jpg">`})});
  const result = await request(handlers.previewMeta, {body: {url: 'https://old.example'}});
  assert.deepEqual(result, {status: 200, body: {
    url: 'https://stable.example/guide', title: 'Training guide',
    description: 'Learn transitions', image: 'https://stable.example/cover.jpg',
  }});
});

test('previewMeta reports restrictions from the publisher response', async () => {
  for (const headers of [
    {'x-frame-options': 'SAMEORIGIN'},
    {'x-frame-options': 'DENY'},
    {'content-security-policy': 'default-src \'self\'; frame-ancestors \'none\''},
  ]) {
    const {handlers} = harness({fetch: async () => response({headers})});
    const result = await request(handlers.previewMeta, {body: {url: 'https://stable.example'}});
    assert.equal(result.body.blocksEmbedding, true);
  }
});

test('previewMeta falls back to title and empty optional metadata', async () => {
  const {handlers} = harness({fetch: async () => response({html: '<title>Guide</title>'})});
  const result = await request(handlers.previewMeta, {body: {url: 'https://stable.example'}});
  assert.equal(result.body.title, 'Guide');
  assert.equal(result.body.image, '');
  assert.equal(result.body.description, '');
});

for (const name of ['previewMeta', 'fetchReadable']) {
  test(`${name} rejects non-HTML content`, async () => {
    const {handlers} = harness({fetch: async () => response({type: 'application/pdf'})});
    assert.equal((await request(handlers[name], {body: {url: 'https://stable.example'}})).status, 415);
  });
}

test('fetchReadable extracts a readable article with text and image', async () => {
  const paragraph = 'Training horses requires patience and consistent practice. '.repeat(30);
  const {handlers} = harness({fetch: async () => response({html: `
    <html><head><title>Horse training</title>
    <meta property="og:image" content="/horse.png"></head>
    <body><article><h1>Horse training</h1><p>${paragraph}</p></article></body></html>`})});
  const result = await request(handlers.fetchReadable, {body: {url: 'https://stable.example'}});
  assert.equal(result.status, 200);
  assert.match(result.body.textContent, /requires patience/);
  assert.ok(result.body.length > 100);
  assert.equal(result.body.image, 'https://stable.example/horse.png');
});

test('fetchReadable reports unparseable pages', async () => {
  const {handlers} = harness({fetch: async () => response({html: '<html></html>'})});
  assert.equal((await request(handlers.fetchReadable, {body: {url: 'https://stable.example'}})).status, 422);
});

test('resolveImage returns a direct image and proxy URL', async () => {
  const {handlers} = harness({fetch: async () => response({type: 'image/png', url: 'https://stable.example/horse.png'})});
  const result = await request(handlers.resolveImage, {body: {url: 'https://stable.example/horse.png'}});
  assert.equal(result.body.resolvedUrl, 'https://stable.example/horse.png');
  assert.equal(result.body.proxiedUrl, 'https://wsrv.nl/?url=https%3A%2F%2Fstable.example%2Fhorse.png');
});

test('resolveImage validates HTML image candidates and falls back from HEAD to GET', async () => {
  const calls = [];
  const {handlers} = harness({fetch: async (url, options = {}) => {
    calls.push([url, options.method]);
    if (url === 'https://stable.example/guide') {
      return response({html: '<meta property="og:image" content="/wp-content/uploads/horse.jpg">'});
    }
    if (url.includes('/wp-json/')) return response({status: 404});
    return response({status: options.method === 'HEAD' ? 405 : 200, type: 'image/jpeg'});
  }});
  const result = await request(handlers.resolveImage, {body: {url: 'https://stable.example/guide'}});
  assert.equal(result.body.resolvedUrl, 'https://stable.example/wp-content/uploads/horse.jpg');
  assert.ok(calls.some(([, method]) => method === 'HEAD'));
  assert.ok(calls.some(([, method]) => method === 'GET'));
});

test('resolveImage recovers stale thumbnails from current page metadata before media search', async () => {
  const page = 'https://stable.example/guide';
  const stale = 'https://stable.example/legacy.jpg';
  const replacement = 'https://cdn.example/replacement.jpg';
  const calls = [];
  const {handlers} = harness({fetch: async (url) => {
    calls.push(url);
    if (url === page) {
      return response({html: `<meta property="og:image" content="${replacement}">`});
    }
    return url === replacement ? response({type: 'image/jpeg'}) : response({status: 404});
  }});
  const result = await request(handlers.resolveImage, {body: {url: page, hint: stale}});
  assert.equal(result.body.resolvedUrl, replacement);
  assert.deepEqual(calls, [page, replacement]);
});

test('resolveImage bounds probes when page images and the legacy hint return 404', async () => {
  const page = 'https://stable.example/guide';
  const probes = [];
  const images = Array.from({length: 30}, (_, i) => `<img src="/image-${i}.jpg">`).join('');
  const {handlers} = harness({fetch: async (url) => {
    if (url === page) return response({html: images});
    probes.push(url);
    return response({status: 404});
  }});
  const result = await request(handlers.resolveImage, {
    body: {url: page, hint: 'https://stable.example/stale.jpg'},
  });
  assert.equal(result.status, 404);
  assert.equal(probes.filter((url) => !url.includes('/wp-json/')).length, 12);
  assert.ok(probes.filter((url) => url.includes('/wp-json/')).length <= 3);
});

test('resolveImage reports pages with no image', async () => {
  const {handlers} = harness({fetch: async (url) => response({status: url.includes('/wp-json/') ? 404 : 200})});
  assert.equal((await request(handlers.resolveImage, {body: {url: 'https://stable.example'}})).status, 404);
});

test('notification trigger ignores missing events and ordinary chats', async () => {
  const h = harness();
  await h.handlers.onMessageCreated({});
  await h.handlers.onMessageCreated({data: {data: () => ({messageType: 'CHAT'})}, params: {convId: 'c'}});
  assert.equal(h.pushes.length, 0);
});

test('notification trigger excludes sender case-insensitively and deduplicates tokens', async () => {
  const h = harness({conversation: {
    parties: ['Rider', 'Trainer'], partiesIds: ['rider@example.com', 'trainer@example.com'],
  }, tokens: ['token-1', 'token-1']});
  await h.handlers.onMessageCreated({params: {convId: 'c'}, data: {data: () => ({
    messageType: 'INSTRUCTOR_REQUEST', sender: 'Rider', senderId: 'Rider@Example.com',
    subject: 'Training request', message: 'Please teach me',
  })}});
  assert.deepEqual(h.tokenOwners, ['trainer@example.com']);
  assert.equal(h.pushes.length, 1);
  assert.deepEqual(Array.from(h.pushes[0].tokens), ['token-1']);
  assert.equal(h.pushes[0].data.convId, 'c');
  assert.equal(h.errors.length, 0);
});
