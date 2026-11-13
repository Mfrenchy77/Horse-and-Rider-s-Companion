/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');

const DELETED_NAME = 'Deleted User';

function profileId(email) {
  return email.replaceAll('.', '666').replaceAll('@', '999')
      .replaceAll('f', '5').replaceAll('e', '1').replaceAll('g', '2')
      .replaceAll('m', '').replaceAll('a', 'p').replaceAll('i', 'a')
      .replaceAll('co', 'l');
}

function emailKey(email) {
  return email.trim().toLowerCase();
}

function deletedMarker(uid) {
  return `deleted:${uid}`;
}

function withoutParty(list, emailSet) {
  if (!Array.isArray(list)) return [];
  return list.filter((item) => {
    if (typeof item === 'string') return !emailSet.has(emailKey(item));
    if (item && typeof item.id === 'string') return !emailSet.has(emailKey(item.id));
    return true;
  });
}

async function revokeTokens(auth, uid) {
  if (typeof auth.revokeRefreshTokens === 'function') {
    await auth.revokeRefreshTokens(uid);
  }
}

async function resolveAdminAccount(db, auth, configuredAdminEmail) {
  if (typeof configuredAdminEmail !== 'string' || !configuredAdminEmail.includes('@')) {
    throw new HttpsError(
        'failed-precondition',
        'Administrative horse-transfer account is not configured.',
        {code: 'admin-account-unconfigured'},
    );
  }
  const normalized = emailKey(configuredAdminEmail);
  let adminAuthUser;
  try {
    adminAuthUser = await auth.getUserByEmail(normalized);
  } catch (err) {
    if (err?.code === 'auth/user-not-found') {
      throw new HttpsError(
          'failed-precondition',
          'Administrative account could not be verified in authentication.',
          {code: 'admin-account-not-found'},
      );
    }
    throw err;
  }
  const adminProfileRef = db.collection('Rider_Profile').doc(profileId(normalized));
  const adminProfileSnap = await adminProfileRef.get();
  if (!adminProfileSnap.exists) {
    throw new HttpsError(
        'failed-precondition',
        'Administrative rider profile could not be verified.',
        {code: 'admin-profile-not-found'},
    );
  }
  const profile = adminProfileSnap.data() || {};
  return {
    uid: adminAuthUser.uid,
    email: profile.email || adminAuthUser.email || normalized,
    name: profile.name || 'Horse And Rider\'s Companion',
    profileRef: adminProfileRef,
    profile,
  };
}

async function cleanupConnections(db, uid, email, emailSet) {
  const snap = await db.collection('CoachingConnections')
      .where('participantUids', 'array-contains', uid).get();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (data.kind === 'transfer' && data.horseId) {
      const horseRef = db.collection('Horse_Profile').doc(data.horseId);
      const horseSnap = await horseRef.get();
      if (horseSnap.exists && horseSnap.data()?.transferRequestId === doc.id) {
        await horseRef.update({transferRequestId: null});
      }
    }

    const otherEmail = emailKey(data.learnerEmail || data.learner || '') === emailKey(email) ?
      (data.coachEmail || data.coach) :
      (data.learnerEmail || data.learner);
    if (typeof otherEmail === 'string' && otherEmail.includes('@')) {
      const otherRef = db.collection('Rider_Profile').doc(profileId(otherEmail));
      const otherSnap = await otherRef.get();
      if (otherSnap.exists) {
        const other = otherSnap.data() || {};
        await otherRef.update({
          students: withoutParty(other.students, emailSet),
          instructors: withoutParty(other.instructors, emailSet),
          studentHorses: data.horseId ?
            (Array.isArray(other.studentHorses) ?
              other.studentHorses.filter((h) => h?.id !== data.horseId) : []) :
            (other.studentHorses || []),
        });
      }
    }

    const updatedUids = Array.isArray(data.participantUids) ?
      data.participantUids.filter((id) => id !== uid) : [];
    if (updatedUids.length === 0) {
      await doc.ref.delete();
    } else {
      const marker = deletedMarker(uid);
      const patch = {
        participantUids: updatedUids,
        status: data.status === 'pending' ? 'cancelled' : 'revoked',
      };
      if (data.learnerUid === uid || emailKey(data.learnerEmail || '') === emailKey(email)) {
        patch.learner = marker;
        patch.learnerEmail = marker;
        patch.learnerName = DELETED_NAME;
        patch.learnerUid = marker;
      }
      if (data.coachUid === uid || emailKey(data.coachEmail || '') === emailKey(email)) {
        patch.coach = marker;
        patch.coachEmail = marker;
        patch.coachName = DELETED_NAME;
        patch.coachUid = marker;
      }
      await doc.ref.update(patch);
    }
  }
}

async function transferOwnedHorsesToAdmin(db, auth, email, emailSet, adminEmail) {
  const candidates = [email, emailKey(email)];
  const ownedDocs = [];
  const seen = new Set();
  for (const ownerId of candidates) {
    const snap = await db.collection('Horse_Profile')
        .where('currentOwnerId', '==', ownerId).get();
    for (const doc of snap.docs) {
      if (seen.has(doc.id)) continue;
      seen.add(doc.id);
      ownedDocs.push(doc);
    }
  }
  if (ownedDocs.length === 0) return;

  const adminAccount = await resolveAdminAccount(db, auth, adminEmail);
  const existingOwned = Array.isArray(adminAccount.profile.ownedHorses) ?
    [...adminAccount.profile.ownedHorses] : [];
  const existingIds = new Set(existingOwned.map((item) => item?.id).filter(Boolean));
  const version = randomUUID();

  for (const doc of ownedDocs) {
    const data = doc.data() || {};
    await doc.ref.update({
      currentOwnerId: adminAccount.email,
      currentOwnerName: adminAccount.name,
      saleListing: null,
      transferRequestId: null,
      ownershipVersion: version,
      lastEditBy: emailSet.has(emailKey(data.lastEditBy || '')) ? DELETED_NAME : (data.lastEditBy || ''),
    });
    if (!existingIds.has(doc.id)) {
      existingIds.add(doc.id);
      existingOwned.push({id: doc.id, name: data.name || doc.id});
    }
  }

  await adminAccount.profileRef.update({
    ownedHorses: existingOwned,
    ownershipRosterVersion: version,
  });
}

async function cleanupRequests(db, email, nowSeconds) {
  const normalized = emailKey(email);
  const snap = await db.collection('Requests')
      .where('partiesIds', 'array-contains', normalized)
      .get();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (data.status !== 'pending') continue;
    await doc.ref.update({
      status: 'cancelled',
      dismissalNote: 'Account deleted',
      updatedAt: nowSeconds(),
    });
  }
}

async function cleanupJournalEntries(db, uid) {
  const ownedSnap = await db.collection('SharedRidingEntries')
      .where('riderUid', '==', uid).get();
  for (const doc of ownedSnap.docs) {
    await doc.ref.delete();
  }

  const authoredSnap = await db.collection('SharedRidingEntries')
      .where('authorUid', '==', uid).get();
  const marker = deletedMarker(uid);
  for (const doc of authoredSnap.docs) {
    const data = doc.data() || {};
    const note = data.note && typeof data.note === 'object' ? {...data.note} : null;
    if (note && note.riderLog && typeof note.riderLog === 'object') {
      note.riderLog = {
        ...note.riderLog,
        instructor: DELETED_NAME,
      };
    }
    await doc.ref.update({
      authorUid: marker,
      ...(note ? {note} : {}),
    });
  }
}

async function cleanupResources(db, uid, email, emailSet) {
  const marker = deletedMarker(uid);
  const allSnap = await db.collection('Resources').get();
  for (const doc of allSnap.docs) {
    const data = doc.data() || {};
    const patch = {};
    const authorId = typeof data.authorId === 'string' ? data.authorId : '';
    if (authorId === uid || emailSet.has(emailKey(authorId))) {
      patch.authorId = marker;
      patch.authorName = DELETED_NAME;
      patch.authorPhoto = '';
    }
    if (typeof data.lastEditBy === 'string' &&
        (data.lastEditBy === uid || emailSet.has(emailKey(data.lastEditBy)))) {
      patch.lastEditBy = DELETED_NAME;
    }

    if (Array.isArray(data.comments)) {
      let commentsChanged = false;
      const nextComments = data.comments.map((c) => {
        if (!c || typeof c !== 'object') return c;
        const next = {...c};
        const user = next.user && typeof next.user === 'object' ? {...next.user} : null;
        if (user && typeof user.id === 'string' &&
            (user.id === uid || emailSet.has(emailKey(user.id)))) {
          next.user = {
            ...user,
            id: marker,
            name: DELETED_NAME,
          };
          commentsChanged = true;
        }
        if (Array.isArray(next.usersWhoRated)) {
          const filtered = next.usersWhoRated.filter((r) => {
            const rid = typeof r?.id === 'string' ? r.id : '';
            return rid !== uid && !emailSet.has(emailKey(rid));
          });
          if (filtered.length !== next.usersWhoRated.length) {
            next.usersWhoRated = filtered;
            commentsChanged = true;
          }
        }
        return next;
      });
      if (commentsChanged) {
        patch.comments = nextComments;
      }
    }

    if (Object.keys(patch).length > 0) {
      await doc.ref.update(patch);
    }

    const ratingsRef = doc.ref.collection('usersWhoRated');
    for (const candidate of [email, emailKey(email), uid]) {
      if (!candidate) continue;
      const rDoc = ratingsRef.doc(candidate);
      const rSnap = await rDoc.get();
      if (rSnap.exists) {
        await rDoc.delete();
      }
    }
  }
}

async function cleanupProfileAndTokens(db, email) {
  const normalized = emailKey(email);
  const tokenParentRef = db.collection('RiderProfiles').doc(normalized);
  const tokensSnap = await tokenParentRef.collection('tokens').get();
  for (const doc of tokensSnap.docs) {
    await doc.ref.delete();
  }
  const tokenParentSnap = await tokenParentRef.get();
  if (tokenParentSnap.exists) {
    await tokenParentRef.delete();
  }

  for (const candidate of [profileId(email), profileId(normalized)]) {
    const profileRef = db.collection('Rider_Profile').doc(candidate);
    const snap = await profileRef.get();
    if (snap.exists) {
      await profileRef.delete();
    }
  }
}

async function cleanupStorage(bucket, email) {
  if (!bucket) return;
  const normalized = emailKey(email);
  const paths = [
    `Riders_Photo/${profileId(email)}`,
    `Riders_Photo/${profileId(normalized)}`,
    `Riders_Photo/${email}`,
  ];
  for (const path of new Set(paths)) {
    try {
      await bucket.file(path).delete({ignoreNotFound: true});
    } catch (err) {
      if (err?.code !== 404) throw err;
    }
  }
  if (typeof bucket.deleteFiles === 'function') {
    for (const prefix of new Set([`covers/${email}/`, `covers/${normalized}/`])) {
      try {
        await bucket.deleteFiles({prefix});
      } catch (err) {
        if (err?.code !== 404) throw err;
      }
    }
  }
}

async function deleteAuthUser(auth, uid) {
  try {
    await auth.deleteUser(uid);
  } catch (err) {
    if (err?.code !== 'auth/user-not-found') throw err;
  }
}

function accountDeletionHandler(db, auth, bucket = null, options = {}) {
  const maxAuthAgeSeconds = options.maxAuthAgeSeconds ?? 300;
  const nowSeconds = options.nowSeconds ?? (() => Math.floor(Date.now() / 1000));
  const adminEmail = options.adminEmail ?? process.env.ADMIN_ACCOUNT_EMAIL;

  return async (request) => {
    const uid = request.auth?.uid;
    const email = request.auth?.token?.email;
    const authTime = request.auth?.token?.auth_time;
    const provider = request.auth?.token?.firebase?.sign_in_provider;

    if (!uid || typeof email !== 'string' || !email.trim()) {
      throw new HttpsError('unauthenticated', 'Sign in with an authenticated account first.');
    }

    if (provider !== 'anonymous') {
      if (typeof authTime !== 'number' || nowSeconds() - authTime > maxAuthAgeSeconds) {
        throw new HttpsError(
            'failed-precondition',
            'Recent authentication is required before deleting your account.',
            {code: 'requires-recent-login'},
        );
      }
    }

    const jobRef = db.collection('DeletionJobs').doc(uid);
    const existingSnap = await jobRef.get();
    const existing = existingSnap.exists ? (existingSnap.data() || {}) : {};
    const steps = {...(existing.steps || {})};

    await jobRef.set({
      uid,
      email: emailKey(email),
      status: 'in_progress',
      steps,
      updatedAt: nowSeconds(),
    }, {merge: true});

    const emailSet = new Set([emailKey(email)]);
    const runStep = async (name, fn) => {
      if (steps[name]) return;
      await fn();
      steps[name] = true;
      await jobRef.set({steps, updatedAt: nowSeconds()}, {merge: true});
    };

    try {
      await runStep('revokeTokens', () => revokeTokens(auth, uid));
      await runStep('connections', () => cleanupConnections(db, uid, email, emailSet));
      await runStep('requests', () => cleanupRequests(db, email, nowSeconds));
      await runStep(
          'horses',
          () => transferOwnedHorsesToAdmin(db, auth, email, emailSet, adminEmail),
      );
      await runStep('journal', () => cleanupJournalEntries(db, uid));
      // Legacy Conversations/Messages are intentionally left untouched until
      // the discontinued-messaging cleanup policy is approved.
      await runStep('resources', () => cleanupResources(db, uid, email, emailSet));
      await runStep('profileAndTokens', () => cleanupProfileAndTokens(db, email));
      await runStep('storage', () => cleanupStorage(bucket, email));
      await runStep('auth', () => deleteAuthUser(auth, uid));
      await jobRef.delete();
      return {status: 'completed'};
    } catch (err) {
      await jobRef.set({
        status: 'failed_retryable',
        lastError: err?.message || 'Account deletion failed',
        steps,
        updatedAt: nowSeconds(),
      }, {merge: true});
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', 'Account deletion could not be completed. Please retry.');
    }
  };
}

module.exports = {
  DELETED_NAME,
  accountDeletionHandler,
  profileId,
};
