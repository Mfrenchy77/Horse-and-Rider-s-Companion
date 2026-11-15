'use strict';

/**
 * Safely establishes `ownerUid` on Rider_Profile and Horse_Profile documents
 * by resolving authoritative Firebase Auth UIDs via `auth.getUserByEmail(...)`.
 *
 * Dry-run by default. Never trusts client-supplied ownership claims.
 * Do NOT run against production without explicit approval and a backup.
 */
async function backfillOwnerUids({db, auth, dryRun = true} = {}) {
  const emailToUidCache = new Map();
  const report = {
    dryRun,
    ridersScanned: 0,
    ridersUpdated: 0,
    ridersAlreadySet: 0,
    ridersUnresolved: [],
    horsesScanned: 0,
    horsesUpdated: 0,
    horsesAlreadySet: 0,
    horsesUnresolved: [],
  };

  async function resolveUid(email) {
    if (typeof email !== 'string' || !email.includes('@')) return null;
    const key = email.trim().toLowerCase();
    if (emailToUidCache.has(key)) return emailToUidCache.get(key);
    try {
      const user = await auth.getUserByEmail(key);
      const uid = user && typeof user.uid === 'string' ? user.uid : null;
      emailToUidCache.set(key, uid);
      return uid;
    } catch (_) {
      emailToUidCache.set(key, null);
      return null;
    }
  }

  const riderSnap = await db.collection('Rider_Profile').get();
  for (const doc of riderSnap.docs) {
    report.ridersScanned++;
    const data = doc.data() || {};
    if (typeof data.ownerUid === 'string' && data.ownerUid.length > 0) {
      report.ridersAlreadySet++;
      continue;
    }
    const uid = await resolveUid(data.email || doc.id);
    if (!uid) {
      report.ridersUnresolved.push({docId: doc.id, email: data.email || null});
      continue;
    }
    if (!dryRun) {
      await doc.ref.update({ownerUid: uid});
    }
    report.ridersUpdated++;
  }

  const horseSnap = await db.collection('Horse_Profile').get();
  for (const doc of horseSnap.docs) {
    report.horsesScanned++;
    const data = doc.data() || {};
    if (typeof data.ownerUid === 'string' && data.ownerUid.length > 0) {
      report.horsesAlreadySet++;
      continue;
    }
    const uid = await resolveUid(data.currentOwnerId);
    if (!uid) {
      report.horsesUnresolved.push({
        docId: doc.id,
        currentOwnerId: data.currentOwnerId || null,
      });
      continue;
    }
    if (!dryRun) {
      await doc.ref.update({ownerUid: uid});
    }
    report.horsesUpdated++;
  }

  return report;
}

if (require.main === module) {
  const args = new Set(process.argv.slice(2));
  const commit = args.has('--commit');
  const emulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  if (commit && !emulator && !args.has('--allow-production')) {
    console.error('Refusing production write without --allow-production');
    process.exit(1);
  }
  const admin = require('../functions/node_modules/firebase-admin');
  admin.initializeApp({projectId: 'horse-and-riders-compani-d2bd4'});
  backfillOwnerUids({
    db: admin.firestore(),
    auth: admin.auth(),
    dryRun: !commit,
  }).then((res) => {
    console.log(JSON.stringify(res, null, 2));
    process.exit(0);
  }).catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = {backfillOwnerUids};
