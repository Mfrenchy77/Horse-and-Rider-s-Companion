/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true, "ignoreComments": true }] */

'use strict';

const {
  PUBLIC_HORSE_COLLECTION,
  buildPublicHorseProfile,
} = require('./public_horse_profile');
const {
  PUBLIC_RIDER_COLLECTION,
  buildPublicRiderProfile,
} = require('./public_rider_profile');

function emailKey(email) {
  return typeof email === 'string' ? email.trim().toLowerCase() : '';
}

function sortedUnique(list) {
  return Array.from(
      new Set((list || []).filter((v) => typeof v === 'string' && v.trim())),
  ).sort();
}

function sameStringArray(a, b) {
  const left = sortedUnique(a);
  const right = sortedUnique(b);
  return left.length === right.length && left.every((v, i) => v === right[i]);
}

/**
 * Idempotent, dry-run-first backfill for profile privacy projections and
 * server-maintained authorization fields (`ownerUid`, `instructorUids`).
 *
 * Safe to re-run repeatedly: only writes when computed values differ.
 * Never alters private notes, skills, or ownership.
 *
 * @param {FirebaseFirestore.Firestore} db Firestore instance.
 * @param {object} [options] Backfill options.
 * @param {boolean} [options.apply=false] When false (default), computes planned
 *   changes without writing to Firestore.
 * @param {object} [options.auth] Optional Firebase Auth instance to resolve
 *   missing `ownerUid` fields by email.
 * @return {Promise<object>} Summary counts of scanned and updated records.
 */
async function backfillProfilePrivacy(db, {apply = false, auth = null} = {}) {
  const uidByEmail = new Map();

  async function resolveUid(email) {
    const key = emailKey(email);
    if (!key) return null;
    if (uidByEmail.has(key)) return uidByEmail.get(key);
    if (!auth) return null;
    try {
      const user = await auth.getUserByEmail(key);
      const uid = user?.uid || null;
      uidByEmail.set(key, uid);
      return uid;
    } catch {
      uidByEmail.set(key, null);
      return null;
    }
  }

  const [riderSnap, horseSnap, connSnap, publicHorseSnap, publicRiderSnap] =
    await Promise.all([
      db.collection('Rider_Profile').get(),
      db.collection('Horse_Profile').get(),
      db.collection('CoachingConnections')
          .where('status', '==', 'accepted')
          .get(),
      db.collection(PUBLIC_HORSE_COLLECTION).get(),
      db.collection(PUBLIC_RIDER_COLLECTION).get(),
    ]);

  // Index accepted coaching connections by learner email and horseId.
  const riderCoachUids = new Map();
  const horseCoachLinks = new Map();

  for (const doc of connSnap.docs) {
    const link = doc.data() || {};
    if (link.status !== 'accepted' || !link.coachUid) continue;
    if (link.kind === 'rider') {
      const learner = emailKey(link.learner || link.learnerEmail);
      if (!learner) continue;
      if (!riderCoachUids.has(learner)) riderCoachUids.set(learner, []);
      riderCoachUids.get(learner).push(link.coachUid);
    } else if (link.kind === 'horse' && link.horseId) {
      if (!horseCoachLinks.has(link.horseId)) {
        horseCoachLinks.set(link.horseId, []);
      }
      horseCoachLinks.get(link.horseId).push(link);
    }
  }

  const summary = {
    apply,
    ridersScanned: riderSnap.docs.length,
    ridersUpdated: 0,
    publicRidersUpserted: 0,
    publicRidersDeleted: 0,
    horsesScanned: horseSnap.docs.length,
    horsesUpdated: 0,
    publicHorsesUpserted: 0,
    publicHorsesDeleted: 0,
  };

  const validRiderIds = new Set();
  for (const doc of riderSnap.docs) {
    validRiderIds.add(doc.id);
    const data = doc.data() || {};
    const key = emailKey(data.email);
    const desiredUids = sortedUnique(riderCoachUids.get(key) || []);
    const ownerUid = data.ownerUid || (await resolveUid(key));

    const updates = {};
    if (ownerUid && data.ownerUid !== ownerUid) {
      updates.ownerUid = ownerUid;
    }
    if (!sameStringArray(data.instructorUids, desiredUids)) {
      updates.instructorUids = desiredUids;
    }

    if (Object.keys(updates).length > 0) {
      summary.ridersUpdated++;
      if (apply) {
        await doc.ref.update(updates);
      }
    }

    const publicPayload = buildPublicRiderProfile(doc.id, data);
    if (publicPayload) {
      summary.publicRidersUpserted++;
      if (apply) {
        await db.collection(PUBLIC_RIDER_COLLECTION).doc(doc.id).set(publicPayload);
      }
    }
  }

  for (const doc of publicRiderSnap.docs) {
    if (!validRiderIds.has(doc.id)) {
      summary.publicRidersDeleted++;
      if (apply) {
        await doc.ref.delete();
      }
    }
  }

  const validPublicHorseIds = new Set();
  for (const doc of horseSnap.docs) {
    const data = doc.data() || {};
    const ownerEmail = emailKey(data.currentOwnerId);
    const ownerUid = data.ownerUid || (await resolveUid(ownerEmail));
    const ownershipVersion = data.ownershipVersion ?? null;

    const matchingCoachUids = (horseCoachLinks.get(doc.id) || [])
        .filter((link) => {
          const linkLearner = emailKey(link.learner || link.learnerEmail);
          return linkLearner === ownerEmail &&
              (link.ownershipVersion ?? null) === ownershipVersion;
        })
        .map((link) => link.coachUid);
    const desiredUids = sortedUnique(matchingCoachUids);

    const updates = {};
    if (ownerUid && data.ownerUid !== ownerUid) {
      updates.ownerUid = ownerUid;
    }
    if (!sameStringArray(data.instructorUids, desiredUids)) {
      updates.instructorUids = desiredUids;
    }

    if (Object.keys(updates).length > 0) {
      summary.horsesUpdated++;
      if (apply) {
        await doc.ref.update(updates);
      }
    }

    const publicPayload = buildPublicHorseProfile(doc.id, data);
    if (publicPayload) {
      validPublicHorseIds.add(doc.id);
      summary.publicHorsesUpserted++;
      if (apply) {
        await db.collection(PUBLIC_HORSE_COLLECTION).doc(doc.id).set(publicPayload);
      }
    }
  }

  for (const doc of publicHorseSnap.docs) {
    if (!validPublicHorseIds.has(doc.id)) {
      summary.publicHorsesDeleted++;
      if (apply) {
        await doc.ref.delete();
      }
    }
  }

  return summary;
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const apply = args.includes('--apply');
  const projectIndex = args.indexOf('--project');
  const projectId = projectIndex >= 0 ? args[projectIndex + 1] : null;
  if (!projectId) {
    console.error('Usage: node backfill_profile_privacy.js --project <projectId> [--apply]');
    process.exit(1);
  }
  const admin = require('firebase-admin');
  if (!admin.apps.length) {
    admin.initializeApp({projectId});
  }
  backfillProfilePrivacy(admin.firestore(), {apply, auth: admin.auth()})
      .then((result) => {
        console.log(JSON.stringify(result, null, 2));
      })
      .catch((err) => {
        console.error(err);
        process.exit(1);
      });
}

module.exports = {
  backfillProfilePrivacy,
};
