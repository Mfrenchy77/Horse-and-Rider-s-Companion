'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {sharePreviewHandler} = require('../share_preview');

function fakeDb(docsById, horsesById = {}) {
  return {
    collection(name) {
      if (name === 'Horse_Profile') {
        return {
          doc(id) {
            return {
              async get() {
                const data = horsesById[id];
                return data
                  ? {exists: true, id, data: () => data}
                  : {exists: false, id, data: () => undefined};
              },
            };
          },
        };
      }
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

test('sharePreview serves public active horse metadata without leaking private fields', async () => {
  const db = fakeDb({}, {
    'horse-1': {
      isPublic: true,
      archiveStatus: 'active',
      name: 'Starlight',
      breed: 'Quarter Horse',
      gender: 'Mare',
      color: 'Bay',
      locationName: 'Austin, TX',
      picUrl: 'https://firebasestorage.googleapis.com/v0/b/demo/o/Horses_Photo%2Fhorse-1?alt=media',
      currentOwnerId: 'owner@example.com',
      currentOwnerName: 'Secret Owner',
      purchasePrice: 12000,
      notes: [{id: 'n1', name: 'Private vet note'}],
      instructors: [{id: 'trainer@example.com', name: 'Trainer Bob'}],
    },
    'horse-sale': {
      isPublic: true,
      archiveStatus: 'active',
      name: 'Comet',
      breed: 'Morgan',
      saleListing: {
        price: 9500,
        location: 'Dallas, TX',
        description: 'Calm trail partner with solid groundwork.',
      },
      currentOwnerId: 'owner@example.com',
    },
  });
  const handler = sharePreviewHandler(db, {
    fetchFn: async () => ({ok: false}),
  });

  const resPublic = makeRes();
  await handler(
      {
        headers: {'x-forwarded-host': 'horse-and-riders-compani-d2bd4.web.app'},
        path: '/Profile/Horse_Profile/horse-1',
        query: {},
      },
      resPublic,
  );
  assert.equal(resPublic.statusCode, 200);
  assert.match(resPublic.body, /<meta property="og:title" content="Starlight — Horse &amp; Rider&#39;s Companion">/);
  assert.match(resPublic.body, /<meta property="og:description" content="Quarter Horse · Mare · Bay · Austin, TX">/);
  assert.match(resPublic.body, /<meta property="og:image" content="https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/demo\/o\/Horses_Photo%2Fhorse-1\?alt=media">/);
  assert.match(resPublic.body, /<meta property="og:url" content="https:\/\/horse-and-riders-compani-d2bd4\.web\.app\/Profile\/Horse_Profile\/horse-1">/);
  assert.doesNotMatch(resPublic.body, /Secret Owner|owner@example\.com|12000|Private vet note|Trainer Bob/);

  const resSale = makeRes();
  await handler(
      {
        headers: {'x-forwarded-host': 'horse-and-riders-compani-d2bd4.web.app'},
        path: '/Profile/Horse_Profile/horse-sale',
        query: {},
      },
      resSale,
  );
  assert.equal(resSale.statusCode, 200);
  assert.match(resSale.body, /<meta property="og:title" content="Comet \(For Sale\) — Horse &amp; Rider&#39;s Companion">/);
  assert.match(resSale.body, /<meta property="og:description" content="Calm trail partner with solid groundwork\.">/);
  assert.match(resSale.body, /<meta property="og:image" content="https:\/\/horse-and-riders-compani-d2bd4\.web\.app\/icons\/Icon-512\.png">/);
});

test('sharePreview hides private, archived, and missing horse profiles', async () => {
  const db = fakeDb({}, {
    'horse-private': {
      isPublic: false,
      archiveStatus: 'active',
      name: 'Hidden Horse',
      breed: 'Arabian',
    },
    'horse-default': {
      archiveStatus: 'active',
      name: 'Default Private Horse',
    },
    'horse-archived': {
      isPublic: true,
      archiveStatus: 'archived',
      name: 'Archived Horse',
    },
  });
  const handler = sharePreviewHandler(db, {
    fetchFn: async () => ({ok: false}),
  });

  for (const id of ['horse-private', 'horse-default', 'horse-archived', 'horse-missing']) {
    const res = makeRes();
    await handler(
        {
          headers: {'x-forwarded-host': 'horse-and-riders-compani-d2bd4.web.app'},
          path: `/Profile/Horse_Profile/${id}`,
          query: {},
        },
        res,
    );
    assert.equal(res.statusCode, 200);
    assert.equal(res.headers['Cache-Control'], 'no-store');
    assert.doesNotMatch(res.body, /Hidden Horse|Default Private Horse|Archived Horse|Arabian/);
    assert.match(res.body, /<meta property="og:title" content="Horse &amp; Rider&#39;s Companion">/);
    assert.match(res.body, /<meta property="og:url" content="https:\/\/horse-and-riders-compani-d2bd4\.web\.app">/);
  }
});
