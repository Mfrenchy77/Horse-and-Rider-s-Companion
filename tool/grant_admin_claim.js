#!/usr/bin/env node
/**
 * Operator-only local Firebase Admin SDK utility for inspecting and updating
 * custom role claims (`admin`, `moderator`, `editor`).
 *
 * Security invariants:
 * - Never imported by Flutter or Cloud Functions (refuses to run in Cloud Run /
 *   Cloud Functions environments).
 * - Requires an explicit `--uid <firebaseUid>`.
 * - Dry-run by default: displays existing claims and proposed changes without
 *   writing unless `--confirm` is passed.
 * - Requires `--allow-production` in addition to `--confirm` when
 *   `FIREBASE_AUTH_EMULATOR_HOST` is not set.
 * - Preserves all unrelated custom claims on the target user.
 * - Never hardcodes credentials; relies on `GOOGLE_APPLICATION_CREDENTIALS`
 *   (or `FIREBASE_AUTH_EMULATOR_HOST` for local emulator testing).
 *
 * Usage examples:
 *   # Dry-run inspection / preview
 *   node tool/grant_admin_claim.js --uid <UID> --grant admin
 *
 *   # Apply against local Auth emulator
 *   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
 *     node tool/grant_admin_claim.js --project demo-project --uid <UID> --grant moderator --confirm
 *
 *   # Apply against production (requires explicit credentials + flags)
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node tool/grant_admin_claim.js --uid <UID> --grant admin --confirm --allow-production
 */

'use strict';

const ALLOWED_ROLES = new Set(['admin', 'moderator', 'editor']);

function assertOperatorEnvironment(env = process.env) {
  if (env.FUNCTION_TARGET || env.K_SERVICE || env.FUNCTIONS_EMULATOR === 'true') {
    throw new Error(
      'Refusing to run grant_admin_claim.js inside a Cloud Functions / Cloud Run runtime.',
    );
  }
}

function parseArgs(argv) {
  const args = {
    uid: null,
    project: null,
    grants: [],
    revokes: [],
    confirm: false,
    allowProduction: false,
    help: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--help' || token === '-h') {
      args.help = true;
    } else if (token === '--confirm') {
      args.confirm = true;
    } else if (token === '--allow-production') {
      args.allowProduction = true;
    } else if (token === '--uid') {
      i += 1;
      args.uid = argv[i] || null;
    } else if (token.startsWith('--uid=')) {
      args.uid = token.slice('--uid='.length) || null;
    } else if (token === '--project') {
      i += 1;
      args.project = argv[i] || null;
    } else if (token.startsWith('--project=')) {
      args.project = token.slice('--project='.length) || null;
    } else if (token === '--grant') {
      i += 1;
      const role = argv[i];
      if (!ALLOWED_ROLES.has(role)) {
        throw new Error(
          `Invalid role for --grant: "${role}". Allowed: admin, moderator, editor.`,
        );
      }
      args.grants.push(role);
    } else if (token.startsWith('--grant=')) {
      const role = token.slice('--grant='.length);
      if (!ALLOWED_ROLES.has(role)) {
        throw new Error(
          `Invalid role for --grant: "${role}". Allowed: admin, moderator, editor.`,
        );
      }
      args.grants.push(role);
    } else if (token === '--revoke') {
      i += 1;
      const role = argv[i];
      if (!ALLOWED_ROLES.has(role)) {
        throw new Error(
          `Invalid role for --revoke: "${role}". Allowed: admin, moderator, editor.`,
        );
      }
      args.revokes.push(role);
    } else if (token.startsWith('--revoke=')) {
      const role = token.slice('--revoke='.length);
      if (!ALLOWED_ROLES.has(role)) {
        throw new Error(
          `Invalid role for --revoke: "${role}". Allowed: admin, moderator, editor.`,
        );
      }
      args.revokes.push(role);
    } else {
      throw new Error(`Unknown argument: ${token}`);
    }
  }

  if (!args.help && (!args.uid || !args.uid.trim())) {
    throw new Error('Missing required --uid <firebaseUid> argument.');
  }

  for (const role of args.grants) {
    if (args.revokes.includes(role)) {
      throw new Error(`Cannot both --grant and --revoke role "${role}".`);
    }
  }

  return args;
}

function computeUpdatedClaims(existingClaims, grants, revokes) {
  const next = { ...(existingClaims || {}) };
  for (const role of grants) {
    next[role] = true;
  }
  for (const role of revokes) {
    delete next[role];
  }
  return next;
}

async function applyRoleUpdate({
  authClient,
  uid,
  grants = [],
  revokes = [],
  confirm = false,
  allowProduction = false,
  env = process.env,
  logger = console,
}) {
  assertOperatorEnvironment(env);

  const isEmulator = Boolean(env.FIREBASE_AUTH_EMULATOR_HOST);
  const userRecord = await authClient.getUser(uid);
  const existingClaims = { ...(userRecord.customClaims || {}) };
  const nextClaims = computeUpdatedClaims(existingClaims, grants, revokes);

  logger.log(`Target UID:        ${userRecord.uid}`);
  logger.log(`Email:             ${userRecord.email || '(none)'}`);
  logger.log(`Email Verified:    ${Boolean(userRecord.emailVerified)}`);
  logger.log(`Environment:       ${isEmulator ? `emulator (${env.FIREBASE_AUTH_EMULATOR_HOST})` : 'production'}`);
  logger.log(`Existing claims:   ${JSON.stringify(existingClaims)}`);
  logger.log(`Proposed claims:   ${JSON.stringify(nextClaims)}`);

  const hasChanges =
    JSON.stringify(existingClaims) !== JSON.stringify(nextClaims);

  if (!confirm) {
    logger.log('DRY RUN: No claims were modified. Pass --confirm to apply.');
    return { applied: false, dryRun: true, existingClaims, nextClaims };
  }

  if (!isEmulator && !allowProduction) {
    throw new Error(
      'Refusing to modify production custom claims without --allow-production.',
    );
  }

  if (!hasChanges) {
    logger.log('No claim changes needed.');
    return { applied: false, dryRun: false, existingClaims, nextClaims };
  }

  await authClient.setCustomUserClaims(uid, nextClaims);
  logger.log('Custom claims updated successfully.');
  logger.log(
    'Note: The target user must refresh their ID token (sign out/in or call refreshUserRoles) to receive updated claims.',
  );

  return { applied: true, dryRun: false, existingClaims, nextClaims };
}

function printUsage() {
  console.log(`Usage:
  node tool/grant_admin_claim.js --uid <UID> [--grant <role>] [--revoke <role>] [--project <id>] [--confirm] [--allow-production]

Roles:
  admin | moderator | editor

Notes:
  - Runs in dry-run mode by default.
  - Preserves all unrelated custom claims.
  - Production writes require both --confirm and --allow-production.`);
}

async function main() {
  assertOperatorEnvironment(process.env);
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printUsage();
    return;
  }

  const admin = require('../functions/node_modules/firebase-admin');
  const appOptions = args.project ? { projectId: args.project } : undefined;
  if (admin.apps.length === 0) {
    admin.initializeApp(appOptions);
  }

  await applyRoleUpdate({
    authClient: admin.auth(),
    uid: args.uid.trim(),
    grants: args.grants,
    revokes: args.revokes,
    confirm: args.confirm,
    allowProduction: args.allowProduction,
    env: process.env,
  });
}

if (require.main === module) {
  main().catch((err) => {
    console.error(`Error: ${err.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  ALLOWED_ROLES,
  assertOperatorEnvironment,
  parseArgs,
  computeUpdatedClaims,
  applyRoleUpdate,
};
