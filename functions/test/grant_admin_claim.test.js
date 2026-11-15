'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  assertOperatorEnvironment,
  parseArgs,
  computeUpdatedClaims,
  applyRoleUpdate,
} = require('../../tool/grant_admin_claim');

test('parseArgs requires --uid unless --help is passed', () => {
  assert.throws(() => parseArgs(['--grant', 'admin']), /--uid/);
  const help = parseArgs(['--help']);
  assert.equal(help.help, true);
});

test('parseArgs rejects invalid roles and conflicting grant/revoke', () => {
  assert.throws(() => parseArgs(['--uid', 'u1', '--grant', 'superuser']), /Invalid role/);
  assert.throws(
    () => parseArgs(['--uid', 'u1', '--grant', 'admin', '--revoke', 'admin']),
    /Cannot both/,
  );
});

test('computeUpdatedClaims preserves unrelated claims while granting and revoking', () => {
  const updated = computeUpdatedClaims(
    { tier: 'beta', editor: true, moderator: true },
    ['admin'],
    ['moderator'],
  );
  assert.deepEqual(updated, { tier: 'beta', editor: true, admin: true });
});

test('applyRoleUpdate defaults to dry-run and does not call setCustomUserClaims', async () => {
  let setCalled = false;
  const authClient = {
    async getUser(uid) {
      return {
        uid,
        email: 'admin@example.com',
        emailVerified: true,
        customClaims: { existingFlag: 'keep' },
      };
    },
    async setCustomUserClaims() {
      setCalled = true;
    },
  };
  const logs = [];
  const res = await applyRoleUpdate({
    authClient,
    uid: 'uid-123',
    grants: ['admin'],
    confirm: false,
    env: {},
    logger: { log: (m) => logs.push(m) },
  });

  assert.equal(res.dryRun, true);
  assert.equal(res.applied, false);
  assert.equal(setCalled, false);
  assert.deepEqual(res.nextClaims, { existingFlag: 'keep', admin: true });
  assert.ok(logs.some((line) => line.includes('DRY RUN')));
});

test('applyRoleUpdate refuses production write without --allow-production', async () => {
  const authClient = {
    async getUser(uid) {
      return { uid, email: 'a@b.com', emailVerified: true, customClaims: {} };
    },
    async setCustomUserClaims() {
      throw new Error('should not be called');
    },
  };

  await assert.rejects(
    () =>
      applyRoleUpdate({
        authClient,
        uid: 'uid-123',
        grants: ['admin'],
        confirm: true,
        allowProduction: false,
        env: {},
        logger: { log: () => {} },
      }),
    /--allow-production/,
  );
});

test('applyRoleUpdate applies claims in emulator with --confirm and preserves unrelated claims', async () => {
  let written = null;
  const authClient = {
    async getUser(uid) {
      return {
        uid,
        email: 'mod@example.com',
        emailVerified: true,
        customClaims: { org: 'equestrian' },
      };
    },
    async setCustomUserClaims(uid, claims) {
      written = { uid, claims };
    },
  };

  const res = await applyRoleUpdate({
    authClient,
    uid: 'uid-mod',
    grants: ['moderator'],
    confirm: true,
    env: { FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' },
    logger: { log: () => {} },
  });

  assert.equal(res.applied, true);
  assert.deepEqual(written, {
    uid: 'uid-mod',
    claims: { org: 'equestrian', moderator: true },
  });
});

test('assertOperatorEnvironment blocks Cloud Functions runtime', () => {
  assert.throws(
    () => assertOperatorEnvironment({ FUNCTION_TARGET: 'fn' }),
    /Cloud Functions/,
  );
  assert.throws(
    () => assertOperatorEnvironment({ K_SERVICE: 'svc' }),
    /Cloud Functions/,
  );
});
