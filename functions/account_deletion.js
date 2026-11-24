/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {PUBLIC_HORSE_COLLECTION, buildPublicHorseProfile} = require('./public_horse_profile');
const {PUBLIC_RIDER_COLLECTION, buildPublicRiderProfile} = require('./public_rider_profile');

const DELETED_NAME = 'Deleted User';
const FORMER_OWNER_NAME = 'Former Owner';
const DEFAULT_ADMIN_ACCOUNT_EMAIL = 'horseandriderscompanion@gmail.com';
const LOCK_TTL_SECONDS = 120;

function profileId(email) {
  return email.replaceAll('.', '666').replaceAll('@', '999')
      .replaceAll('f', '5').replaceAll('e', '1').replaceAll('g', '2')
      .replaceAll('m', '').replaceAll('a', 'p').replaceAll('i', 'a')
      .replaceAll('co', 'l');
}

function emailKey(email) {
  return typeof email === 'string' ? email.trim().toLowerCase() : '';
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

function withoutUid(list, uid) {
  if (!Array.isArray(list)) return [];
  return list.filter((id) => id !== uid);
}

function mergeHorseRosterItem(list, horseId, horseData) {
  const existing = Array.isArray(list) ? list.filter((item) => item?.id !== horseId) : [];
  const entry = {
    id: horseId,
    name: horseData.name || horseId,
  };
  if (typeof horseData.picUrl === 'string' && horseData.picUrl.trim()) {
    entry.imageUrl = horseData.picUrl.trim();
  }
  return [...existing, entry];
}

async function revokeTokens(auth, uid) {
  if (typeof auth.revokeRefreshTokens === 'function') {
    try {
      await auth.revokeRefreshTokens(uid);
    } catch (err) {
      if (err?.code !== 'auth/user-not-found') throw err;
    }
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
  if (!adminAuthUser || !adminAuthUser.uid) {
    throw new HttpsError(
        'failed-precondition',
        'Administrative account UID could not be resolved.',
        {code: 'admin-account-not-found'},
    );
  }
  if (adminAuthUser.disabled === true) {
    throw new HttpsError(
        'failed-precondition',
        'Administrative account is disabled.',
        {code: 'admin-account-disabled'},
    );
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
  if (profile.ownerUid && profile.ownerUid !== adminAuthUser.uid) {
    throw new HttpsError(
        'failed-precondition',
        'Administrative profile ownership metadata does not match authentication.',
        {code: 'admin-profile-uid-mismatch'},
    );
  }
  return {
    uid: adminAuthUser.uid,
    email: emailKey(profile.email || adminAuthUser.email || normalized),
    name: profile.name || 'Horse And Rider\'s Companion',
    profileRef: adminProfileRef,
    profile,
  };
}

async function discoverOwnedHorses(db, uid, email, emailSet) {
  const ownedDocs = [];
  const seen = new Set();
  const addDocIfOwned = (doc) => {
    if (!doc || !doc.exists || seen.has(doc.id)) return;
    const data = doc.data() || {};
    const ownerMatches = data.ownerUid === uid || emailSet.has(emailKey(data.currentOwnerId || ''));
    if (!ownerMatches) return;
    seen.add(doc.id);
    ownedDocs.push(doc);
  };

  const candidates = new Set([email, emailKey(email)].filter(Boolean));
  for (const ownerId of candidates) {
    const snap = await db.collection('Horse_Profile')
        .where('currentOwnerId', '==', ownerId).get();
    for (const doc of snap.docs) {
      if (seen.has(doc.id)) continue;
      seen.add(doc.id);
      ownedDocs.push(doc);
    }
  }

  const uidSnap = await db.collection('Horse_Profile')
      .where('ownerUid', '==', uid).get();
  for (const doc of uidSnap.docs) {
    if (seen.has(doc.id)) continue;
    seen.add(doc.id);
    ownedDocs.push(doc);
  }

  for (const candidateProfileId of new Set([profileId(email), profileId(emailKey(email))])) {
    const riderSnap = await db.collection('Rider_Profile').doc(candidateProfileId).get();
    if (!riderSnap.exists) continue;
    const riderData = riderSnap.data() || {};
    const roster = [
      ...(Array.isArray(riderData.ownedHorses) ? riderData.ownedHorses : []),
      ...(Array.isArray(riderData.archivedHorses) ? riderData.archivedHorses : []),
    ];
    for (const entry of roster) {
      const horseId = typeof entry?.id === 'string' ? entry.id.trim() : '';
      if (!horseId || seen.has(horseId)) continue;
      const horseSnap = await db.collection('Horse_Profile').doc(horseId).get();
      addDocIfOwned(horseSnap);
    }
  }

  return ownedDocs;
}

async function anonymizeHorseSkillProgress(horseRef, uid) {
  if (typeof horseRef.collection !== 'function') return;
  const progressSnap = await horseRef.collection('SkillProgress').get();
  const marker = deletedMarker(uid);
  for (const progDoc of progressSnap.docs) {
    const data = progDoc.data() || {};
    if (!data.levels || typeof data.levels !== 'object') continue;
    let changed = false;
    const nextLevels = {};
    for (const [levelKey, entry] of Object.entries(data.levels)) {
      if (entry && typeof entry === 'object' && entry.updatedByUid === uid) {
        nextLevels[levelKey] = {
          ...entry,
          updatedByUid: marker,
          updatedByName: FORMER_OWNER_NAME,
        };
        changed = true;
      } else {
        nextLevels[levelKey] = entry;
      }
    }
    if (changed) {
      await progDoc.ref.update({levels: nextLevels});
    }
  }
}

async function syncPublicRiderIfPresent(db, docId, riderData) {
  const pubRef = db.collection(PUBLIC_RIDER_COLLECTION).doc(docId);
  const pubSnap = await pubRef.get();
  if (!pubSnap.exists) return;
  const nextPub = buildPublicRiderProfile(docId, riderData);
  if (nextPub) {
    await pubRef.set(nextPub);
  } else {
    await pubRef.delete();
  }
}

async function syncPublicHorseProjection(db, horseId, horseData) {
  const pubRef = db.collection(PUBLIC_HORSE_COLLECTION).doc(horseId);
  const nextPub = buildPublicHorseProfile(horseId, horseData);
  if (nextPub) {
    await pubRef.set(nextPub);
  } else {
    const pubSnap = await pubRef.get();
    if (pubSnap.exists) {
      await pubRef.delete();
    }
  }
}

async function transferOwnedHorsesToAdmin(
    db,
    auth,
    uid,
    emailSet,
    adminEmail,
    nowSeconds,
    preResolvedAdmin = null,
    preDiscoveredHorses = null,
) {
  const ownedDocs = preDiscoveredHorses ?? await discoverOwnedHorses(db, uid, [...emailSet][0] || '', emailSet);
  if (ownedDocs.length === 0) return 0;

  const adminAccount = preResolvedAdmin ?? await resolveAdminAccount(db, auth, adminEmail);
  let nextOwned = Array.isArray(adminAccount.profile.ownedHorses) ?
    [...adminAccount.profile.ownedHorses] : [];
  let nextArchived = Array.isArray(adminAccount.profile.archivedHorses) ?
    [...adminAccount.profile.archivedHorses] : [];
  const version = randomUUID();
  const marker = deletedMarker(uid);
  const now = nowSeconds();

  for (const doc of ownedDocs) {
    const data = doc.data() || {};
    const archiveStatus = data.archiveStatus || 'active';
    const isArchivedOrDeceased = archiveStatus === 'archived' || archiveStatus === 'deceased';
    const existingHistory = Array.isArray(data.ownershipHistory) ? [...data.ownershipHistory] : [];
    const alreadyRecorded = existingHistory.some(
        (entry) => entry?.ownerRef === marker && entry?.reason === 'owner_account_deleted',
    );
    const nextHistory = alreadyRecorded ?
      existingHistory :
      [
        ...existingHistory,
        {
          ownerType: 'former_owner',
          ownerRef: marker,
          transferredTo: adminAccount.email,
          transferredToUid: adminAccount.uid,
          transferredAt: now,
          reason: 'owner_account_deleted',
        },
      ];

    const horsePatch = {
      currentOwnerId: adminAccount.email,
      currentOwnerName: adminAccount.name,
      ownerUid: adminAccount.uid,
      administrativeHold: true,
      transferredToAdminAt: now,
      transferReason: 'owner_account_deleted',
      ownershipVersion: version,
      saleListing: null,
      transferRequestId: null,
      instructors: [],
      instructorUids: [],
      ownershipHistory: nextHistory,
      lastEditBy: (emailSet.has(emailKey(data.lastEditBy || '')) || data.lastEditBy === uid) ?
        DELETED_NAME :
        (data.lastEditBy || ''),
    };

    await doc.ref.update(horsePatch);
    await anonymizeHorseSkillProgress(doc.ref, uid);
    await syncPublicHorseProjection(db, doc.id, {...data, ...horsePatch});

    if (isArchivedOrDeceased) {
      nextOwned = nextOwned.filter((item) => item?.id !== doc.id);
      nextArchived = mergeHorseRosterItem(nextArchived, doc.id, data);
    } else {
      nextArchived = nextArchived.filter((item) => item?.id !== doc.id);
      nextOwned = mergeHorseRosterItem(nextOwned, doc.id, data);
    }
  }

  const adminProfilePatch = {
    ownedHorses: nextOwned,
    archivedHorses: nextArchived,
    ownershipRosterVersion: version,
    ownerUid: adminAccount.uid,
  };
  await adminAccount.profileRef.update(adminProfilePatch);
  await syncPublicRiderIfPresent(
      db,
      adminAccount.profileRef.id,
      {...adminAccount.profile, ...adminProfilePatch},
  );
  return ownedDocs.length;
}

async function cleanupConnections(db, uid, email, emailSet, ownedHorseIds = [], relatedEmails = []) {
  const connDocs = [];
  const seenConnIds = new Set();
  const participantSnap = await db.collection('CoachingConnections')
      .where('participantUids', 'array-contains', uid).get();
  for (const doc of participantSnap.docs) {
    if (seenConnIds.has(doc.id)) continue;
    seenConnIds.add(doc.id);
    connDocs.push(doc);
  }
  for (const horseId of ownedHorseIds) {
    const horseConnSnap = await db.collection('CoachingConnections')
        .where('horseId', '==', horseId).get();
    for (const doc of horseConnSnap.docs) {
      if (seenConnIds.has(doc.id)) continue;
      seenConnIds.add(doc.id);
      connDocs.push(doc);
    }
  }

  const cleanedRiderIds = new Set();
  const cleanOtherRiderRef = async (otherId, horseIdToRemove = null) => {
    const otherRef = db.collection('Rider_Profile').doc(otherId);
    const otherSnap = await otherRef.get();
    if (!otherSnap.exists) return;
    cleanedRiderIds.add(otherId);
    const other = otherSnap.data() || {};
    const patch = {
      students: withoutParty(other.students, emailSet),
      instructors: withoutParty(other.instructors, emailSet),
      instructorUids: withoutUid(other.instructorUids, uid),
      studentHorses: horseIdToRemove ?
        (Array.isArray(other.studentHorses) ?
          other.studentHorses.filter((h) => h?.id !== horseIdToRemove) : []) :
        withoutParty(other.studentHorses, new Set(ownedHorseIds.map(emailKey))),
    };
    await otherRef.update(patch);
    await syncPublicRiderIfPresent(db, otherId, {...other, ...patch});
  };

  for (const doc of connDocs) {
    const data = doc.data() || {};
    if (data.horseId) {
      const horseRef = db.collection('Horse_Profile').doc(data.horseId);
      const horseSnap = await horseRef.get();
      if (horseSnap.exists && horseSnap.data()?.transferRequestId === doc.id) {
        await horseRef.update({transferRequestId: null});
      }
    }

    const participantEmails = [
      data.learnerEmail || data.learner,
      data.coachEmail || data.coach,
    ].filter((addr) => typeof addr === 'string' && addr.includes('@') && !emailSet.has(emailKey(addr)));

    for (const otherEmail of participantEmails) {
      await cleanOtherRiderRef(profileId(emailKey(otherEmail)), data.horseId || null);
    }

    const updatedUids = withoutUid(data.participantUids, uid);
    if (updatedUids.length === 0) {
      await doc.ref.delete();
    } else {
      const marker = deletedMarker(uid);
      const patch = {
        participantUids: updatedUids,
        status: data.status === 'pending' ? 'cancelled' : 'revoked',
      };
      if (data.learnerUid === uid || emailSet.has(emailKey(data.learnerEmail || data.learner || ''))) {
        patch.learner = marker;
        patch.learnerEmail = marker;
        patch.learnerName = DELETED_NAME;
        patch.learnerUid = marker;
      }
      if (data.coachUid === uid || emailSet.has(emailKey(data.coachEmail || data.coach || ''))) {
        patch.coach = marker;
        patch.coachEmail = marker;
        patch.coachName = DELETED_NAME;
        patch.coachUid = marker;
      }
      await doc.ref.update(patch);
    }
  }

  // Clean legacy or connectionless student/instructor profiles referencing departing UID/email.
  const studentProfilesSnap = await db.collection('Rider_Profile')
      .where('instructorUids', 'array-contains', uid).get();
  for (const riderDoc of studentProfilesSnap.docs) {
    if (!cleanedRiderIds.has(riderDoc.id)) {
      await cleanOtherRiderRef(riderDoc.id);
    }
  }
  for (const relEmail of relatedEmails) {
    if (typeof relEmail !== 'string' || !relEmail.includes('@') || emailSet.has(emailKey(relEmail))) continue;
    const relId = profileId(emailKey(relEmail));
    if (!cleanedRiderIds.has(relId)) {
      await cleanOtherRiderRef(relId);
    }
  }

  // Remove the departing trainer from any other owners' horses.
  const instructedHorsesSnap = await db.collection('Horse_Profile')
      .where('instructorUids', 'array-contains', uid).get();
  for (const horseDoc of instructedHorsesSnap.docs) {
    const horseData = horseDoc.data() || {};
    await horseDoc.ref.update({
      instructors: withoutParty(horseData.instructors, emailSet),
      instructorUids: withoutUid(horseData.instructorUids, uid),
    });
  }
}

async function cleanupRequests(db, email, nowSeconds) {
  const normalized = emailKey(email);
  const snap = await db.collection('Requests')
      .where('partiesIds', 'array-contains', normalized)
      .get();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const patch = {};
    if (data.status === 'pending') {
      patch.status = 'cancelled';
      patch.dismissalNote = 'Account deleted';
      patch.updatedAt = nowSeconds();
    }
    if (emailKey(data.senderEmail || '') === normalized &&
        (data.senderName !== DELETED_NAME || data.senderPicUrl !== '')) {
      patch.senderName = DELETED_NAME;
      patch.senderPicUrl = '';
    }
    if (emailKey(data.recipientEmail || '') === normalized &&
        data.recipientName !== DELETED_NAME) {
      patch.recipientName = DELETED_NAME;
    }
    if (Object.keys(patch).length > 0) {
      await doc.ref.update(patch);
    }
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

async function cleanupResourcesAndSuggestions(db, uid, email, emailSet) {
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
            imageUrl: '',
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

    if (typeof doc.ref.collection === 'function') {
      const ratingsRef = doc.ref.collection('usersWhoRated');
      for (const candidate of new Set([email, emailKey(email), uid].filter(Boolean))) {
        const rDoc = ratingsRef.doc(candidate);
        const rSnap = await rDoc.get();
        if (rSnap.exists) {
          await rDoc.delete();
        }
      }
    }
  }

  const suggestionsSnap = await db.collection('SkillTreeSuggestions')
      .where('submittedByUid', '==', uid).get();
  for (const sDoc of suggestionsSnap.docs) {
    await sDoc.ref.update({
      submittedByUid: marker,
      submitterEmail: '',
      submitterName: DELETED_NAME,
    });
  }
}

async function deleteSubcollectionDocs(docRef, subcollectionName) {
  if (!docRef || typeof docRef.collection !== 'function') return;
  const subSnap = await docRef.collection(subcollectionName).get();
  for (const doc of subSnap.docs) {
    await doc.ref.delete();
  }
}

async function cleanupProfileAndTokens(db, uid, email) {
  const normalized = emailKey(email);
  for (const tokenDocId of new Set([email, normalized].filter(Boolean))) {
    const tokenParentRef = db.collection('RiderProfiles').doc(tokenDocId);
    if (typeof tokenParentRef.collection === 'function') {
      const tokensSnap = await tokenParentRef.collection('tokens').get();
      for (const doc of tokensSnap.docs) {
        await doc.ref.delete();
      }
    }
    const tokenParentSnap = await tokenParentRef.get();
    if (tokenParentSnap.exists) {
      await tokenParentRef.delete();
    }
  }

  const profileIds = new Set([profileId(email), profileId(normalized)].filter(Boolean));
  const uidProfiles = await db.collection('Rider_Profile').where('ownerUid', '==', uid).get();
  for (const doc of uidProfiles.docs) {
    profileIds.add(doc.id);
  }

  for (const candidate of profileIds) {
    const profileRef = db.collection('Rider_Profile').doc(candidate);
    await deleteSubcollectionDocs(profileRef, 'SkillProgress');
    await deleteSubcollectionDocs(profileRef, 'SkillVerifications');
    await deleteSubcollectionDocs(profileRef, 'SkillVerificationEvents');
    const snap = await profileRef.get();
    if (snap.exists) {
      await profileRef.delete();
    }

    const pubRef = db.collection(PUBLIC_RIDER_COLLECTION).doc(candidate);
    const pubSnap = await pubRef.get();
    if (pubSnap.exists) {
      await pubRef.delete();
    }
  }
}

async function cleanupStorage(bucket, uid, email) {
  if (!bucket) return;
  const normalized = emailKey(email);
  const paths = [
    `Riders_Photo/${profileId(email)}`,
    `Riders_Photo/${profileId(normalized)}`,
    `Riders_Photo/${email}`,
    `Riders_Photo/${uid}`,
  ];
  for (const path of new Set(paths.filter(Boolean))) {
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

async function acquireDeletionLock(db, jobRef, uid, now) {
  const runAcquire = async (getFn, setFn) => {
    const snap = await getFn(jobRef);
    const existing = snap.exists ? (snap.data() || {}) : {};
    if (existing.status === 'completed') {
      return {
        alreadyCompleted: true,
        horsesTransferredCount: existing.horsesTransferredCount || 0,
      };
    }
    if (
      existing.status === 'in_progress' &&
      typeof existing.lockExpiresAt === 'number' &&
      existing.lockExpiresAt > now
    ) {
      throw new HttpsError(
          'already-exists',
          'An account deletion request is already in progress. Please wait and try again.',
          {code: 'deletion-in-progress'},
      );
    }

    const steps = {...(existing.steps || {})};
    const lockId = randomUUID();
    await setFn(jobRef, {
      uid,
      status: 'in_progress',
      lockId,
      lockExpiresAt: now + LOCK_TTL_SECONDS,
      steps,
      horsesTransferredCount: existing.horsesTransferredCount || 0,
      transferredHorseIds: Array.isArray(existing.transferredHorseIds) ?
        existing.transferredHorseIds :
        [],
      startedAt: existing.startedAt || now,
      updatedAt: now,
    }, {merge: true});

    return {
      alreadyCompleted: false,
      lockId,
      steps,
      horsesTransferredCount: existing.horsesTransferredCount || 0,
      transferredHorseIds: Array.isArray(existing.transferredHorseIds) ?
        existing.transferredHorseIds :
        [],
      startedAt: existing.startedAt || now,
    };
  };

  if (typeof db.runTransaction === 'function') {
    return db.runTransaction((tx) => runAcquire(
        (ref) => tx.get(ref),
        (ref, data, opts) => tx.set(ref, data, opts),
    ));
  }
  return runAcquire(
      (ref) => ref.get(),
      (ref, data, opts) => ref.set(data, opts),
  );
}

function accountDeletionHandler(db, auth, bucket = null, options = {}) {
  const maxAuthAgeSeconds = options.maxAuthAgeSeconds ?? 300;
  const nowSeconds = options.nowSeconds ?? (() => Math.floor(Date.now() / 1000));
  const adminEmail = options.adminEmail !== undefined ?
    options.adminEmail :
    (process.env.ADMIN_ACCOUNT_EMAIL || DEFAULT_ADMIN_ACCOUNT_EMAIL);

  return async (request) => {
    const uid = request.auth?.uid;
    const email = request.auth?.token?.email;
    const authTime = request.auth?.token?.auth_time;
    const provider = request.auth?.token?.firebase?.sign_in_provider;

    if (!uid || typeof email !== 'string' || !email.trim()) {
      throw new HttpsError('unauthenticated', 'Sign in with an authenticated account first.');
    }

    if (provider === 'anonymous') {
      throw new HttpsError(
          'permission-denied',
          'Guest accounts cannot delete a permanent rider profile.',
          {code: 'guest-not-allowed'},
      );
    }

    if (typeof authTime !== 'number' || nowSeconds() - authTime > maxAuthAgeSeconds) {
      throw new HttpsError(
          'failed-precondition',
          'Recent authentication is required before deleting your account.',
          {code: 'requires-recent-login'},
      );
    }

    if (typeof adminEmail === 'string' && emailKey(adminEmail) === emailKey(email)) {
      throw new HttpsError(
          'failed-precondition',
          'The administrative account cannot be deleted.',
          {code: 'cannot-delete-admin-account'},
      );
    }

    const jobRef = db.collection('DeletionJobs').doc(uid);
    const acquired = await acquireDeletionLock(db, jobRef, uid, nowSeconds());
    if (acquired.alreadyCompleted) {
      return {
        status: 'completed',
        horsesTransferred: acquired.horsesTransferredCount,
      };
    }

    const steps = {...acquired.steps};
    let horsesTransferredCount = acquired.horsesTransferredCount || 0;
    let transferredHorseIds = [...(acquired.transferredHorseIds || [])];
    const emailSet = new Set([emailKey(email)]);
    const runStep = async (name, fn) => {
      if (steps[name]) return;
      await fn();
      steps[name] = true;
      await jobRef.set({steps, updatedAt: nowSeconds()}, {merge: true});
    };

    try {
      const ownedHorses = !steps.horses ?
        await discoverOwnedHorses(db, uid, email, emailSet) :
        [];
      const relatedEmails = [];
      for (const pid of new Set([profileId(email), profileId(emailKey(email))])) {
        const pSnap = await db.collection('Rider_Profile').doc(pid).get();
        if (!pSnap.exists) continue;
        const pData = pSnap.data() || {};
        for (const item of [...(pData.students || []), ...(pData.instructors || [])]) {
          if (typeof item?.id === 'string') relatedEmails.push(item.id);
        }
      }
      if (ownedHorses.length > 0) {
        transferredHorseIds = ownedHorses.map((d) => d.id);
      }
      const preResolvedAdmin = !steps.horses && ownedHorses.length > 0 ?
        await resolveAdminAccount(db, auth, adminEmail) :
        null;

      // Preserve horses first before removing connections, profile, media, or Auth.
      await runStep('horses', async () => {
        horsesTransferredCount = await transferOwnedHorsesToAdmin(
            db,
            auth,
            uid,
            emailSet,
            adminEmail,
            nowSeconds,
            preResolvedAdmin,
            ownedHorses,
        );
        await jobRef.set({
          horsesTransferredCount,
          transferredHorseIds,
        }, {merge: true});
      });

      await runStep('connections', () =>
        cleanupConnections(db, uid, email, emailSet, transferredHorseIds, relatedEmails),
      );
      await runStep('requests', () => cleanupRequests(db, email, nowSeconds));
      await runStep('journal', () => cleanupJournalEntries(db, uid));
      // Legacy Conversations/Messages remain untouched until messaging retirement is approved.
      await runStep('resources', () => cleanupResourcesAndSuggestions(db, uid, email, emailSet));
      await runStep('profileAndTokens', () => cleanupProfileAndTokens(db, uid, email));
      await runStep('storage', () => cleanupStorage(bucket, uid, email));
      await runStep('revokeTokens', () => revokeTokens(auth, uid));
      await runStep('auth', () => deleteAuthUser(auth, uid));

      await jobRef.set({
        uid,
        status: 'completed',
        lockId: null,
        lockExpiresAt: null,
        lastErrorCode: null,
        steps,
        horsesTransferredCount,
        startedAt: acquired.startedAt,
        completedAt: nowSeconds(),
        updatedAt: nowSeconds(),
      }, {merge: true});

      return {
        status: 'completed',
        horsesTransferred: horsesTransferredCount,
      };
    } catch (err) {
      await jobRef.set({
        status: 'failed_retryable',
        lockId: null,
        lockExpiresAt: null,
        lastErrorCode: err?.details?.code || err?.code || 'internal',
        steps,
        horsesTransferredCount,
        updatedAt: nowSeconds(),
      }, {merge: true});
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', 'Account deletion could not be completed. Please retry.');
    }
  };
}

module.exports = {
  DELETED_NAME,
  DEFAULT_ADMIN_ACCOUNT_EMAIL,
  accountDeletionHandler,
  profileId,
};
