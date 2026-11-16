'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {sharePreviewHandler} = require('../share_preview');

function fakeDb(docsById) {
  return {
    collection(name) {
      assert.equal(name, 'SkillsV2');
      return {
        doc(id) {
          return {
            async get() {
              const data = docsById[id];
              return data
                ? {exists: true, id, data: () => data}
                : {exists: false, id, data: () => undefined};
            },
          };
        },
        where(field, op, value) {
          assert.equal(field, 'legacyIds');
          assert.equal(op, 'array-contains');
          return {
            limit() {
              return {
                async get() {
                  for (const [id, data] of Object.entries(docsById)) {
                    if (Array.isArray(data.legacyIds) && data.legacyIds.includes(value)) {
                      return {empty: false, docs: [{id, data: () => data}]};
                    }
                  }
                  return {empty: true, docs: []};
                },
              };
            },
          };
        },
      };
    },
  };
}

function makeRes() {
  return {
    statusCode: 200,
    headers: {},
    body: '',
    set(k, v) {
      this.headers[k] = v;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    send(body) {
      this.body = body;
      return this;
    },
  };
}

test('sharePreview injects Open Graph tags for active V2 skill into index.html', async () => {
  const db = fakeDb({
    'rider.mounted.sidepass': {
      status: 'active',
      subject: 'rider',
      name: 'Sidepass',
      summary: 'Guiding a horse to step directly sideways.',
      legacyIds: ['rider.mounted.sidepass_rail'],
    },
  });
  const handler = sharePreviewHandler(db, {
    fetchFn: async () => ({
      ok: true,
      text: async () =>
        '<!DOCTYPE html><html><head><title>Old</title><meta name="description" content="Old"></head>' +
        '<body><script src="flutter_bootstrap.js" async></script></body></html>',
    }),
  });

  const req = {
    headers: {host: '127.0.0.1:5000'},
    query: {skillId: 'rider.mounted.sidepass'},
  };
  const res = makeRes();
  await handler(req, res);

  assert.equal(res.statusCode, 200);
  assert.match(res.body, /<meta property="og:title" content="Sidepass \(Rider Skill\) — Horse &amp; Rider&#39;s Companion">/);
  assert.match(res.body, /<meta property="og:description" content="Guiding a horse to step directly sideways\.">/);
  assert.match(res.body, /<meta property="og:image" content="http:\/\/127\.0\.0\.1:5000\/icons\/Icon-512\.png">/);
  assert.match(res.body, /<meta property="og:url" content="http:\/\/127\.0\.0\.1:5000\/SkillTree\?skillId=rider\.mounted\.sidepass">/);
  assert.match(res.body, /flutter_bootstrap\.js/);
});

test('sharePreview resolves legacy skill ID to canonical og:url and hides draft skills', async () => {
  const db = fakeDb({
    'rider.mounted.sidepass': {
      status: 'active',
      subject: 'rider',
      name: 'Sidepass',
      summary: 'Sideways movement.',
      legacyIds: ['rider.mounted.sidepass_rail'],
    },
    'rider.draft.secret': {
      status: 'draft',
      subject: 'rider',
      name: 'Secret Draft',
      summary: 'Do not leak',
    },
  });
  const handler = sharePreviewHandler(db, {
    fetchFn: async () => ({ok: false}),
  });

  const resLegacy = makeRes();
  await handler(
      {headers: {'x-forwarded-host': 'horse-and-riders-compani-d2bd4.web.app'}, query: {skillId: 'rider.mounted.sidepass_rail'}},
      resLegacy,
  );
  assert.equal(resLegacy.statusCode, 200);
  assert.match(
      resLegacy.body,
      /<meta property="og:url" content="https:\/\/horse-and-riders-compani-d2bd4\.web\.app\/SkillTree\?skillId=rider\.mounted\.sidepass">/,
  );

  const resDraft = makeRes();
  await handler(
      {headers: {'x-forwarded-host': 'horse-and-riders-compani-d2bd4.web.app'}, query: {skillId: 'rider.draft.secret'}},
      resDraft,
  );
  assert.equal(resDraft.statusCode, 200);
  assert.doesNotMatch(resDraft.body, /Secret Draft/);
  assert.match(resDraft.body, /Skill Tree 2\.0/);
});
