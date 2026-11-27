'use strict';

const assert = require('node:assert/strict');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'demo-horse-rules';

function emulatorHost() {
  return process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
}

function baseDocumentsUrl(projectId = PROJECT_ID) {
  return `http://${emulatorHost()}/v1/projects/${projectId}/databases/(default)/documents`;
}

function encodeEmulatorJwt(projectId, claims) {
  const nowSec = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({alg: 'none', typ: 'JWT'})).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: `https://securetoken.google.com/${projectId}`,
    aud: projectId,
    auth_time: nowSec,
    iat: nowSec,
    exp: nowSec + 3600,
    ...claims,
  })).toString('base64url');
  return `${header}.${payload}.`;
}

function encodeValue(value) {
  if (value === null || value === undefined) return {nullValue: null};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return {integerValue: String(value)};
    return {doubleValue: value};
  }
  if (typeof value === 'string') return {stringValue: value};
  if (value instanceof Date) return {timestampValue: value.toISOString()};
  if (Array.isArray(value)) {
    return {arrayValue: {values: value.map((item) => encodeValue(item))}};
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      if (v !== undefined) fields[k] = encodeValue(v);
    }
    return {mapValue: {fields}};
  }
  return {stringValue: String(value)};
}

function encodeFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj || {})) {
    if (v !== undefined) fields[k] = encodeValue(v);
  }
  return fields;
}

function expandDottedPatch(data) {
  const root = {};
  const fieldPaths = [];
  for (const [key, val] of Object.entries(data || {})) {
    if (val === undefined) continue;
    fieldPaths.push(key);
    const parts = key.split('.');
    let cursor = root;
    for (let i = 0; i < parts.length - 1; i++) {
      const part = parts[i];
      if (!cursor[part] || typeof cursor[part] !== 'object' || Array.isArray(cursor[part])) {
        cursor[part] = {};
      }
      cursor = cursor[part];
    }
    cursor[parts[parts.length - 1]] = val;
  }
  return {root, fieldPaths};
}

function decodeValue(val) {
  if (!val || typeof val !== 'object') return undefined;
  if ('nullValue' in val) return null;
  if ('booleanValue' in val) return val.booleanValue;
  if ('integerValue' in val) return Number(val.integerValue);
  if ('doubleValue' in val) return val.doubleValue;
  if ('stringValue' in val) return val.stringValue;
  if ('timestampValue' in val) return new Date(val.timestampValue);
  if ('arrayValue' in val) {
    return (val.arrayValue.values || []).map((item) => decodeValue(item));
  }
  if ('mapValue' in val) {
    return decodeFields(val.mapValue.fields || {});
  }
  return undefined;
}

function decodeFields(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields || {})) {
    out[k] = decodeValue(v);
  }
  return out;
}

function normalizePath(segments) {
  return segments
      .map((s) => String(s).replace(/^\/+|\/+$/g, ''))
      .filter(Boolean)
      .join('/');
}

function doc(db, ...segments) {
  const path = normalizePath(segments);
  const parts = path.split('/');
  return {
    _type: 'doc',
    _db: db,
    path,
    id: parts[parts.length - 1],
  };
}

function collection(db, ...segments) {
  const path = normalizePath(segments);
  const parts = path.split('/');
  return {
    _type: 'collection',
    _db: db,
    path,
    id: parts[parts.length - 1],
  };
}

const OP_MAP = {
  '==': 'EQUAL',
  '!=': 'NOT_EQUAL',
  '<': 'LESS_THAN',
  '<=': 'LESS_THAN_OR_EQUAL',
  '>': 'GREATER_THAN',
  '>=': 'GREATER_THAN_OR_EQUAL',
  'array-contains': 'ARRAY_CONTAINS',
  'in': 'IN',
  'array-contains-any': 'ARRAY_CONTAINS_ANY',
};

function where(field, op, value) {
  return {
    fieldFilter: {
      field: {fieldPath: field},
      op: OP_MAP[op] || op,
      value: encodeValue(value),
    },
  };
}

function query(target, ...filters) {
  return {
    _type: 'query',
    _db: target._db,
    path: target.path,
    filters: [...(target.filters || []), ...filters],
  };
}

function makeHttpError(status, bodyText) {
  const err = new Error(`Firestore emulator error (${status}): ${bodyText}`);
  err.status = status;
  err.code = status === 403 ? 'permission-denied' : `http-${status}`;
  return err;
}

function authHeaders(db) {
  const headers = {'Content-Type': 'application/json'};
  if (db._token) headers.Authorization = `Bearer ${db._token}`;
  return headers;
}

async function getDoc(docRef) {
  const url = `${baseDocumentsUrl(docRef._db._projectId)}/${docRef.path}`;
  const res = await fetch(url, {headers: authHeaders(docRef._db)});
  if (res.status === 404) {
    return {
      id: docRef.id,
      path: docRef.path,
      exists: () => false,
      data: () => undefined,
    };
  }
  const text = await res.text();
  if (!res.ok) throw makeHttpError(res.status, text);
  const json = JSON.parse(text);
  const decoded = decodeFields(json.fields);
  return {
    id: docRef.id,
    path: docRef.path,
    exists: () => true,
    data: () => decoded,
  };
}

async function getDocs(colOrQuery) {
  const parts = colOrQuery.path.split('/');
  const collectionId = parts.pop();
  const parentSuffix = parts.length ? `/${parts.join('/')}` : '';
  const url = `${baseDocumentsUrl(colOrQuery._db._projectId)}${parentSuffix}:runQuery`;

  const structuredQuery = {
    from: [{collectionId}],
  };
  const filters = colOrQuery.filters || [];
  if (filters.length === 1) {
    structuredQuery.where = filters[0];
  } else if (filters.length > 1) {
    structuredQuery.where = {compositeFilter: {op: 'AND', filters}};
  }

  const res = await fetch(url, {
    method: 'POST',
    headers: authHeaders(colOrQuery._db),
    body: JSON.stringify({structuredQuery}),
  });
  const text = await res.text();
  if (!res.ok) throw makeHttpError(res.status, text);
  const rows = JSON.parse(text);
  const docs = (Array.isArray(rows) ? rows : [])
      .filter((row) => row.document)
      .map((row) => {
        const docName = row.document.name;
        const decoded = decodeFields(row.document.fields);
        return {
          id: docName.split('/').pop(),
          exists: () => true,
          data: () => decoded,
        };
      });
  return {
    size: docs.length,
    empty: docs.length === 0,
    docs,
  };
}

async function setDoc(docRef, data, options = {}) {
  const base = `${baseDocumentsUrl(docRef._db._projectId)}/${docRef.path}`;
  let payloadFields;
  let maskQuery = '';
  if (options && options.merge) {
    const {root, fieldPaths} = expandDottedPatch(data);
    payloadFields = encodeFields(root);
    if (fieldPaths.length) {
      maskQuery = `?${fieldPaths.map((p) => `updateMask.fieldPaths=${encodeURIComponent(p)}`).join('&')}`;
    }
  } else {
    payloadFields = encodeFields(data);
  }
  const res = await fetch(`${base}${maskQuery}`, {
    method: 'PATCH',
    headers: authHeaders(docRef._db),
    body: JSON.stringify({fields: payloadFields}),
  });
  if (!res.ok) throw makeHttpError(res.status, await res.text());
}

async function updateDoc(docRef, data) {
  const {root, fieldPaths} = expandDottedPatch(data);
  const params = [
    'currentDocument.exists=true',
    ...fieldPaths.map((p) => `updateMask.fieldPaths=${encodeURIComponent(p)}`),
  ];
  const url = `${baseDocumentsUrl(docRef._db._projectId)}/${docRef.path}?${params.join('&')}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: authHeaders(docRef._db),
    body: JSON.stringify({fields: encodeFields(root)}),
  });
  if (!res.ok) throw makeHttpError(res.status, await res.text());
}

async function deleteDoc(docRef) {
  const url = `${baseDocumentsUrl(docRef._db._projectId)}/${docRef.path}`;
  const res = await fetch(url, {
    method: 'DELETE',
    headers: authHeaders(docRef._db),
  });
  if (!res.ok) throw makeHttpError(res.status, await res.text());
}

async function initializeTestEnvironment({projectId = PROJECT_ID, firestore} = {}) {
  const host = emulatorHost();
  if (firestore?.rules) {
    await fetch(`http://${host}/emulator/v1/projects/${projectId}:securityRules`, {
      method: 'PUT',
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer owner'},
      body: JSON.stringify({
        rules: {files: [{content: firestore.rules, name: 'firestore.rules'}]},
      }),
    }).catch(() => {});
  }
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
    headers: {'Authorization': 'Bearer owner'},
  });

  return {
    unauthenticatedContext() {
      return {firestore: () => ({_projectId: projectId, _token: null})};
    },
    authenticatedContext(uid, claims = {}) {
      const token = encodeEmulatorJwt(projectId, {user_id: uid, sub: uid, ...claims});
      return {firestore: () => ({_projectId: projectId, _token: token})};
    },
    async withSecurityRulesDisabled(fn) {
      return fn({firestore: () => ({_projectId: projectId, _token: 'owner'})});
    },
    async cleanup() {},
  };
}

async function assertSucceeds(promise) {
  return promise;
}

async function assertFails(promise) {
  let succeeded = false;
  try {
    await promise;
    succeeded = true;
  } catch (err) {
    return err;
  }
  assert.fail('Expected Firestore operation to fail under security rules, but it succeeded.');
}

module.exports = {
  assertFails,
  assertSucceeds,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  initializeTestEnvironment,
  query,
  setDoc,
  updateDoc,
  where,
};
