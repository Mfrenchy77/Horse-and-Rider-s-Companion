/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {createHash, randomBytes, randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {key: connectionKey, profileId} = require('./connections');

const INVITATIONS_COLLECTION = 'Invitations';
const TOKENS_COLLECTION = 'InvitationTokens';
const RATE_LIMITS_COLLECTION = 'InvitationRateLimits';

const INVITATION_TYPE_GENERAL = 'general';
const INVITATION_TYPE_STUDENT = 'student_connection';
const VALID_TYPES = new Set([INVITATION_TYPE_GENERAL, INVITATION_TYPE_STUDENT]);

const MAX_CREATES_PER_24H = 20;
const MAX_REDEEMS_PER_24H = 30;
const RATE_WINDOW_MS = 24 * 60 * 60 * 1000;

const DEFAULT_GENERAL_TTL_DAYS = 30;
const DEFAULT_GENERAL_MAX_USES = 25;
const DEFAULT_STUDENT_TTL_DAYS = 14;
const MAX_PERSONAL_MESSAGE_LENGTH = 200;

const TOKEN_REGEX = /^[A-Za-z0-9_-]{16,128}$/;
const INVITATION_ID_REGEX = /^inv_[a-f0-9]{16,64}$/;

const emailKey = (email) => email.trim().toLowerCase();

function generateToken() {
  return randomBytes(24).toString('base64url');
}

function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

function toDateOrNull(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isFinite(value.getTime()) ? value : null;
  if (typeof value.toDate === 'function') {
    const d = value.toDate();
    return d instanceof Date && Number.isFinite(d.getTime()) ? d : null;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    const d = new Date(value);
    return Number.isFinite(d.getTime()) ? d : null;
  }
  return null;
}

function toIsoOrNull(value) {
  const date = toDateOrNull(value);
  return date ? date.toISOString() : null;
}

function sanitizeHttpsUrl(rawUrl) {
  if (typeof rawUrl !== 'string') return null;
  const trimmed = rawUrl.trim();
  if (!trimmed || trimmed.length > 500) return null;
  try {
    const parsed = new URL(trimmed);
    return parsed.protocol === 'https:' ? trimmed : null;
  } catch (_) {
    return null;
  }
}

function sanitizePersonalMessage(raw) {
  if (raw == null || raw === '') return null;
  if (typeof raw !== 'string') {
    throw new HttpsError('invalid-argument', 'Personal message must be text.');
  }
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (trimmed.length > MAX_PERSONAL_MESSAGE_LENGTH) {
    throw new HttpsError(
        'invalid-argument',
        `Personal message must be ${MAX_PERSONAL_MESSAGE_LENGTH} characters or fewer.`,
    );
  }
  return trimmed;
}

function normalizePositiveInt(value, fallback, min, max, label) {
  if (value == null) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    throw new HttpsError('invalid-argument', `${label} must be an integer between ${min} and ${max}.`);
  }
  return parsed;
}

function assertVerifiedAuth(request) {
  const uid = request.auth?.uid;
  const email = request.auth?.token?.email;
  const verified = request.auth?.token?.email_verified === true;
  if (!uid || typeof email !== 'string' || !email.includes('@') || !verified) {
    throw new HttpsError('unauthenticated', 'Sign in with a verified email first.');
  }
  return {
    uid,
    email: email.trim(),
    lowerEmail: emailKey(email),
    displayName: typeof request.auth?.token?.name === 'string' ? request.auth.token.name.trim() : '',
  };
}

function resolveDerivedStatus(inv, now) {
  if (!inv || typeof inv !== 'object') return 'invalid';
  if (inv.revokedAt || inv.status === 'revoked') {
    return 'revoked';
  }
  const expiresAt = toDateOrNull(inv.expiresAt);
  if (inv.type === INVITATION_TYPE_STUDENT) {
    if (inv.connectionStatus === 'accepted') return 'accepted';
    if (inv.connectionStatus === 'declined') return 'declined';
    if (inv.claimedByUid) return 'registered';
    if (expiresAt && now.getTime() > expiresAt.getTime()) return 'expired';
    return 'pending';
  }
  const maxUses = Number.isInteger(inv.maxUses) ? inv.maxUses : DEFAULT_GENERAL_MAX_USES;
  const redemptionCount = Number.isInteger(inv.redemptionCount) ? inv.redemptionCount : 0;
  if (redemptionCount >= maxUses) return 'used';
  if (expiresAt && now.getTime() > expiresAt.getTime()) return 'expired';
  return 'active';
}

function serializeForInviter(inv, now = new Date()) {
  const isStudent = inv.type === INVITATION_TYPE_STUDENT;
  return {
    id: inv.id,
    type: inv.type,
    relationshipRole: inv.relationshipRole || null,
    status: resolveDerivedStatus(inv, now),
    personalMessage: inv.personalMessage || null,
    createdAt: toIsoOrNull(inv.createdAt),
    expiresAt: toIsoOrNull(inv.expiresAt),
    revokedAt: toIsoOrNull(inv.revokedAt),
    maxUses: Number.isInteger(inv.maxUses) ? inv.maxUses : (isStudent ? 1 : DEFAULT_GENERAL_MAX_USES),
    redemptionCount: Number.isInteger(inv.redemptionCount) ? inv.redemptionCount : 0,
    acceptedCount: Number.isInteger(inv.acceptedCount) ? inv.acceptedCount : 0,
    declinedCount: Number.isInteger(inv.declinedCount) ? inv.declinedCount : 0,
    connectionId: isStudent ? (inv.connectionId || null) : null,
    connectionStatus: isStudent ? (inv.connectionStatus || null) : null,
    recipientDisplayName: isStudent && inv.claimedByUid ? (inv.recipientDisplayName || null) : null,
  };
}

function readRateTimestamps(rateSnap, nowMs) {
  const raw = rateSnap?.data()?.timestamps;
  if (!Array.isArray(raw)) return [];
  const cutoff = nowMs - RATE_WINDOW_MS;
  return raw.filter((ts) => typeof ts === 'number' && Number.isFinite(ts) && ts >= cutoff);
}

function assertAndNextRateTimestamps(recent, maxPerWindow, nowMs, errorMessage) {
  if (recent.length >= maxPerWindow) {
    throw new HttpsError('resource-exhausted', errorMessage);
  }
  return [...recent, nowMs];
}

function invalidPreviewResponse(statusMessage = 'This invitation link is not valid.') {
  return {
    tokenValid: false,
    status: 'invalid',
    type: null,
    relationshipRole: null,
    inviterDisplayName: null,
    inviterPhotoUrl: null,
    inviterIsTrainer: false,
    inviterLocation: null,
    personalMessage: null,
    expiresAt: null,
    canRedeem: false,
    statusMessage,
  };
}

async function resolvePublicInvitationPreview(db, rawToken, callerUid = null, now = new Date()) {
  const token = typeof rawToken === 'string' ? rawToken.trim() : '';
  if (!TOKEN_REGEX.test(token)) {
    return invalidPreviewResponse();
  }

  const tokenSnap = await db.collection(TOKENS_COLLECTION).doc(hashToken(token)).get();
  const tokenData = tokenSnap.data();
  if (!tokenSnap.exists || typeof tokenData?.invitationId !== 'string') {
    return invalidPreviewResponse();
  }

  const invSnap = await db.collection(INVITATIONS_COLLECTION).doc(tokenData.invitationId).get();
  const inv = invSnap.data();
  if (!invSnap.exists || !inv) {
    return invalidPreviewResponse();
  }

  let inviterDisplayName = typeof inv.inviterDisplayName === 'string' && inv.inviterDisplayName.trim() ?
    inv.inviterDisplayName.trim() :
    'Horse & Rider\'s Companion Member';
  let inviterPhotoUrl = sanitizeHttpsUrl(inv.inviterPhotoUrl);
  let inviterIsTrainer = inv.inviterIsTrainer === true;
  let inviterLocation = typeof inv.inviterLocation === 'string' && inv.inviterLocation.trim() ?
    inv.inviterLocation.trim() :
    null;

  if (typeof inv.inviterProfileId === 'string' && inv.inviterProfileId) {
    try {
      const pubSnap = await db.collection('Public_Rider_Profile').doc(inv.inviterProfileId).get();
      const pub = pubSnap.data();
      if (pubSnap.exists && pub) {
        if (typeof pub.name === 'string' && pub.name.trim()) {
          inviterDisplayName = pub.name.trim();
        }
        const livePhoto = sanitizeHttpsUrl(pub.picUrl);
        if (livePhoto) inviterPhotoUrl = livePhoto;
        if (typeof pub.isTrainer === 'boolean') inviterIsTrainer = pub.isTrainer;
        if (typeof pub.locationName === 'string' && pub.locationName.trim()) {
          inviterLocation = pub.locationName.trim();
        }
      }
    } catch (_) {
      // Non-fatal fallback to snapshot fields stored on the invitation.
    }
  }

  const isStudent = inv.type === INVITATION_TYPE_STUDENT;
  const expiresAt = toDateOrNull(inv.expiresAt);
  const derived = resolveDerivedStatus(inv, now);

  let status = derived;
  let canRedeem = false;
  let statusMessage = '';

  if (inv.revokedAt || inv.status === 'revoked') {
    status = 'revoked';
    statusMessage = 'This invitation has been revoked by the sender.';
  } else if (isStudent) {
    if (inv.claimedByUid) {
      if (callerUid && callerUid === inv.claimedByUid) {
        canRedeem = true;
        status = derived;
        if (status === 'accepted') {
          statusMessage = `You are connected with ${inviterDisplayName}.`;
        } else if (status === 'declined') {
          statusMessage = 'You previously declined this student connection request.';
        } else {
          statusMessage = `Continue reviewing ${inviterDisplayName}'s student connection request.`;
        }
      } else {
        status = 'used';
        statusMessage = 'This student invitation has already been claimed.';
      }
    } else if (expiresAt && now.getTime() > expiresAt.getTime()) {
      status = 'expired';
      statusMessage = 'This invitation link has expired. Ask the instructor to send a new one.';
    } else if (!inviterIsTrainer) {
      status = 'revoked';
      statusMessage = 'This instructor invitation is no longer available.';
    } else {
      status = 'pending';
      canRedeem = true;
      statusMessage =
        `${inviterDisplayName} invited you to connect as their student. ` +
        'After signing in, you can review and accept or decline the connection request.';
    }
  } else {
    const maxUses = Number.isInteger(inv.maxUses) ? inv.maxUses : DEFAULT_GENERAL_MAX_USES;
    const redemptionCount = Number.isInteger(inv.redemptionCount) ? inv.redemptionCount : 0;
    if (redemptionCount >= maxUses) {
      status = 'used';
      statusMessage = 'This invitation link has reached its usage limit.';
    } else if (expiresAt && now.getTime() > expiresAt.getTime()) {
      status = 'expired';
      statusMessage = 'This invitation link has expired.';
    } else {
      status = 'active';
      canRedeem = true;
      statusMessage = `${inviterDisplayName} invited you to join Horse & Rider's Companion.`;
    }
  }

  return {
    tokenValid: true,
    status,
    type: inv.type,
    relationshipRole: inv.relationshipRole || null,
    inviterDisplayName,
    inviterPhotoUrl,
    inviterIsTrainer,
    inviterLocation,
    personalMessage: inv.personalMessage || null,
    expiresAt: toIsoOrNull(inv.expiresAt),
    canRedeem,
    statusMessage,
  };
}

function createInvitationHandler(db, options = {}) {
  const nowFn = options.now || (() => new Date());
  return async (request) => {
    const identity = assertVerifiedAuth(request);
    const data = request.data || {};
    const type = typeof data.type === 'string' ? data.type.trim() : '';
    if (!VALID_TYPES.has(type)) {
      throw new HttpsError('invalid-argument', 'Choose a valid invitation type.');
    }
    const personalMessage = sanitizePersonalMessage(data.personalMessage);
    const isStudent = type === INVITATION_TYPE_STUDENT;
    const expiresInDays = normalizePositiveInt(
        data.expiresInDays,
        isStudent ? DEFAULT_STUDENT_TTL_DAYS : DEFAULT_GENERAL_TTL_DAYS,
        1,
        isStudent ? 30 : 90,
        'expiresInDays',
    );
    const maxUses = isStudent ?
      1 :
      normalizePositiveInt(data.maxUses, DEFAULT_GENERAL_MAX_USES, 1, 50, 'maxUses');

    const now = nowFn();
    const nowMs = now.getTime();
    const expiresAt = new Date(nowMs + expiresInDays * 24 * 60 * 60 * 1000);
    const inviterProfileId = profileId(identity.lowerEmail);
    const profileRef = db.collection('Rider_Profile').doc(inviterProfileId);
    const rateRef = db.collection(RATE_LIMITS_COLLECTION).doc(`create_${identity.uid}`);

    const created = await db.runTransaction(async (tx) => {
      const [profileSnap, rateSnap] = await Promise.all([
        tx.get(profileRef),
        tx.get(rateRef),
      ]);
      const profile = profileSnap.data();
      if (!profileSnap.exists || !profile || typeof profile.email !== 'string' ||
          emailKey(profile.email) !== identity.lowerEmail) {
        throw new HttpsError('failed-precondition', 'Complete your rider profile before creating invitations.');
      }
      if (isStudent && profile.isTrainer !== true) {
        throw new HttpsError(
            'permission-denied',
            'Only instructors and trainers can create student invitations.',
        );
      }

      const recentCreates = readRateTimestamps(rateSnap, nowMs);
      const nextRateTimestamps = assertAndNextRateTimestamps(
          recentCreates,
          MAX_CREATES_PER_24H,
          nowMs,
          'Daily invitation creation limit reached. Try again later.',
      );

      const invitationId = `inv_${randomUUID().replace(/-/g, '')}`;
      const token = generateToken();
      const tokenHash = hashToken(token);
      const inviterDisplayName = (typeof profile.name === 'string' && profile.name.trim()) ?
        profile.name.trim() :
        (identity.displayName || profile.email);
      const inviterPhotoUrl = sanitizeHttpsUrl(profile.picUrl);
      const inviterLocation = typeof profile.locationName === 'string' && profile.locationName.trim() ?
        profile.locationName.trim() :
        null;

      const doc = {
        id: invitationId,
        tokenHash,
        inviterUid: identity.uid,
        inviterEmail: identity.lowerEmail,
        inviterProfileId,
        inviterDisplayName,
        inviterPhotoUrl,
        inviterIsTrainer: profile.isTrainer === true,
        inviterLocation,
        type,
        relationshipRole: isStudent ? 'student' : null,
        personalMessage,
        status: 'active',
        maxUses,
        redemptionCount: 0,
        acceptedCount: 0,
        declinedCount: 0,
        claimedByUid: null,
        recipientDisplayName: null,
        connectionId: null,
        connectionStatus: null,
        createdAt: now,
        updatedAt: now,
        expiresAt,
        revokedAt: null,
      };

      tx.set(db.collection(INVITATIONS_COLLECTION).doc(invitationId), doc);
      tx.set(db.collection(TOKENS_COLLECTION).doc(tokenHash), {
        invitationId,
        createdAt: now,
      });
      tx.set(rateRef, {timestamps: nextRateTimestamps, updatedAt: now});

      return {doc, token};
    });

    return {
      invitation: serializeForInviter(created.doc, now),
      token: created.token,
      sharePath: `/invite/${created.token}`,
    };
  };
}

function getInvitationPreviewHandler(db, options = {}) {
  const nowFn = options.now || (() => new Date());
  return async (request) => {
    const rawToken = request.data?.token;
    const callerUid = request.auth?.uid || null;
    return resolvePublicInvitationPreview(db, rawToken, callerUid, nowFn());
  };
}

function redeemInvitationHandler(db, auth, options = {}) {
  const nowFn = options.now || (() => new Date());
  return async (request) => {
    const identity = assertVerifiedAuth(request);
    const rawToken = request.data?.token;
    const token = typeof rawToken === 'string' ? rawToken.trim() : '';
    if (!TOKEN_REGEX.test(token)) {
      throw new HttpsError('not-found', 'This invitation link is not valid.');
    }

    const now = nowFn();
    const nowMs = now.getTime();
    const tokenHash = hashToken(token);
    const tokenRef = db.collection(TOKENS_COLLECTION).doc(tokenHash);
    const rateRef = db.collection(RATE_LIMITS_COLLECTION).doc(`redeem_${identity.uid}`);
    const nonce = randomUUID();

    return db.runTransaction(async (tx) => {
      // Phase A: perform all base reads before any writes.
      const tokenSnap = await tx.get(tokenRef);
      const tokenData = tokenSnap.data();
      if (!tokenSnap.exists || typeof tokenData?.invitationId !== 'string') {
        throw new HttpsError('not-found', 'This invitation link is not valid.');
      }

      const invitationId = tokenData.invitationId;
      const invRef = db.collection(INVITATIONS_COLLECTION).doc(invitationId);
      const redemptionRef = invRef.collection('Redemptions').doc(identity.uid);

      const [invSnap, redemptionSnap, rateSnap] = await Promise.all([
        tx.get(invRef),
        tx.get(redemptionRef),
        tx.get(rateRef),
      ]);
      const inv = invSnap.data();
      if (!invSnap.exists || !inv) {
        throw new HttpsError('not-found', 'This invitation link is not valid.');
      }

      if (inv.inviterUid === identity.uid || emailKey(inv.inviterEmail || '') === identity.lowerEmail) {
        throw new HttpsError('failed-precondition', 'You cannot redeem your own invitation link.');
      }

      const inviterName = (typeof inv.inviterDisplayName === 'string' && inv.inviterDisplayName.trim()) ?
        inv.inviterDisplayName.trim() :
        'Member';
      const inviterPhotoUrl = sanitizeHttpsUrl(inv.inviterPhotoUrl);
      const isStudent = inv.type === INVITATION_TYPE_STUDENT;

      // For student invitations, read coach, learner, connection, and request docs before any write.
      let coachRef = null;
      let coachSnap = null;
      let learnerRef = null;
      let learnerSnap = null;
      let connectionId = null;
      let connRef = null;
      let connSnap = null;
      let reqRef = null;
      let reqSnap = null;

      if (isStudent) {
        coachRef = db.collection('Rider_Profile').doc(profileId(inv.inviterEmail));
        learnerRef = db.collection('Rider_Profile').doc(profileId(identity.lowerEmail));
        connectionId = connectionKey(['rider', identity.uid, inv.inviterUid, null]);
        connRef = db.collection('CoachingConnections').doc(connectionId);
        reqRef = db.collection('Requests').doc(connectionId);
        [coachSnap, learnerSnap, connSnap, reqSnap] = await Promise.all([
          tx.get(coachRef),
          tx.get(learnerRef),
          tx.get(connRef),
          tx.get(reqRef),
        ]);
      }

      // Phase B: idempotency check for an existing redemption by the same authenticated user.
      if (redemptionSnap.exists) {
        if (!isStudent) {
          return {
            invitationId,
            type: inv.type,
            outcome: 'already_redeemed_general',
            inviterDisplayName: inviterName,
            inviterPhotoUrl,
            connectionId: null,
            connectionVersion: null,
            connectionStatus: null,
            requestDocId: null,
            message: 'You have already joined using this invitation.',
          };
        }
        const conn = connSnap?.data();
        if (conn?.status === 'accepted') {
          return {
            invitationId,
            type: inv.type,
            outcome: 'already_connected',
            inviterDisplayName: inviterName,
            inviterPhotoUrl,
            connectionId,
            connectionVersion: conn.version || null,
            connectionStatus: 'accepted',
            requestDocId: null,
            message: `You are already connected with ${inviterName}.`,
          };
        }
        if (conn?.status === 'pending') {
          return {
            invitationId,
            type: inv.type,
            outcome: 'pending_connection_existing',
            inviterDisplayName: inviterName,
            inviterPhotoUrl,
            connectionId,
            connectionVersion: conn.version || null,
            connectionStatus: 'pending',
            requestDocId: connectionId,
            message: `Review ${inviterName}'s student connection request below.`,
          };
        }
        return {
          invitationId,
          type: inv.type,
          outcome: 'previously_declined',
          inviterDisplayName: inviterName,
          inviterPhotoUrl,
          connectionId,
          connectionVersion: conn?.version || null,
          connectionStatus: conn?.status || inv.connectionStatus || 'declined',
          requestDocId: null,
          message: conn?.status === 'cancelled' || conn?.status === 'revoked' ?
            'This student connection request is no longer active.' :
            'You previously declined this student connection request.',
        };
      }

      // Enforce rate limit for fresh redemption attempts.
      const recentRedeems = readRateTimestamps(rateSnap, nowMs);
      const nextRateTimestamps = assertAndNextRateTimestamps(
          recentRedeems,
          MAX_REDEEMS_PER_24H,
          nowMs,
          'Too many invitation redemption attempts today. Try again later.',
      );

      if (inv.revokedAt || inv.status === 'revoked') {
        throw new HttpsError('failed-precondition', 'This invitation has been revoked by the sender.');
      }
      const expiresAt = toDateOrNull(inv.expiresAt);
      if (expiresAt && nowMs > expiresAt.getTime()) {
        throw new HttpsError('failed-precondition', 'This invitation link has expired.');
      }

      if (!isStudent) {
        const maxUses = Number.isInteger(inv.maxUses) ? inv.maxUses : DEFAULT_GENERAL_MAX_USES;
        const currentUses = Number.isInteger(inv.redemptionCount) ? inv.redemptionCount : 0;
        if (currentUses >= maxUses) {
          throw new HttpsError('failed-precondition', 'This invitation link has reached its usage limit.');
        }

        tx.set(redemptionRef, {
          recipientUid: identity.uid,
          type: INVITATION_TYPE_GENERAL,
          redeemedAt: now,
        });
        tx.update(invRef, {
          redemptionCount: currentUses + 1,
          updatedAt: now,
        });
        tx.set(rateRef, {timestamps: nextRateTimestamps, updatedAt: now});

        return {
          invitationId,
          type: INVITATION_TYPE_GENERAL,
          outcome: 'redeemed_general',
          inviterDisplayName: inviterName,
          inviterPhotoUrl,
          connectionId: null,
          connectionVersion: null,
          connectionStatus: null,
          requestDocId: null,
          message: `Welcome! ${inviterName} invited you to Horse & Rider's Companion.`,
        };
      }

      // Student connection invitation checks & transactional creation.
      if ((inv.claimedByUid && inv.claimedByUid !== identity.uid) ||
          (Number.isInteger(inv.redemptionCount) && inv.redemptionCount >= 1)) {
        throw new HttpsError('failed-precondition', 'This student invitation has already been claimed.');
      }

      const coachProfile = coachSnap?.data();
      if (!coachSnap?.exists || !coachProfile || coachProfile.isTrainer !== true) {
        throw new HttpsError('failed-precondition', 'This instructor invitation is no longer available.');
      }

      const coachEmail = coachProfile.email || inv.inviterEmail;
      const coachLower = emailKey(coachEmail);
      const coachName = (typeof coachProfile.name === 'string' && coachProfile.name.trim()) ?
        coachProfile.name.trim() :
        inviterName;
      const coachPhotoUrl = sanitizeHttpsUrl(coachProfile.picUrl) || inviterPhotoUrl;

      let learnerProfile = learnerSnap?.exists ? learnerSnap.data() : null;
      const fallbackName = identity.displayName || identity.lowerEmail.split('@')[0] || 'Rider';
      const learnerName = (learnerProfile && typeof learnerProfile.name === 'string' && learnerProfile.name.trim()) ?
        learnerProfile.name.trim() :
        fallbackName;

      if (!learnerProfile) {
        learnerProfile = {
          id: identity.uid,
          ownerUid: identity.uid,
          email: identity.email,
          name: learnerName,
          isTrainer: false,
          editor: false,
        };
        tx.set(learnerRef, learnerProfile);
      }

      const existingConn = connSnap?.data();
      const existingReq = reqSnap?.data();

      if (existingConn && existingConn.status === 'accepted') {
        tx.set(redemptionRef, {
          recipientUid: identity.uid,
          type: INVITATION_TYPE_STUDENT,
          connectionId,
          redeemedAt: now,
        });
        tx.update(invRef, {
          claimedByUid: identity.uid,
          recipientDisplayName: learnerName,
          connectionId,
          connectionStatus: 'accepted',
          redemptionCount: 1,
          acceptedCount: 1,
          acceptedAt: now,
          updatedAt: now,
        });
        tx.set(rateRef, {timestamps: nextRateTimestamps, updatedAt: now});
        return {
          invitationId,
          type: INVITATION_TYPE_STUDENT,
          outcome: 'already_connected',
          inviterDisplayName: coachName,
          inviterPhotoUrl: coachPhotoUrl,
          connectionId,
          connectionVersion: existingConn.version || null,
          connectionStatus: 'accepted',
          requestDocId: null,
          message: `You are already connected with ${coachName}.`,
        };
      }

      const requestPayload = {
        id: connectionId,
        messageId: connectionId,
        kind: 'student',
        senderEmail: coachLower,
        senderName: coachName,
        ...(coachPhotoUrl ? {senderPicUrl: coachPhotoUrl} : {}),
        recipientEmail: identity.lowerEmail,
        recipientName: learnerName,
        title: 'Student Invitation',
        summary: `${coachName} invited you to connect as their student.`,
        parties: [coachName, learnerName],
        partiesIds: [coachLower, identity.lowerEmail],
        createdAt: existingReq?.createdAt || now,
        updatedAt: now,
        isAccepted: false,
        status: 'pending',
        connectionId,
      };

      if (existingConn && existingConn.status === 'pending') {
        // Preserve existing pending connection; ensure the recipient can explicitly accept/decline it.
        const version = existingConn.sender === identity.lowerEmail ? nonce : existingConn.version;
        tx.update(connRef, {
          sender: coachLower,
          recipient: identity.lowerEmail,
          version,
          invitationId,
          updatedAt: now,
        });
        tx.set(reqRef, requestPayload);
        tx.set(redemptionRef, {
          recipientUid: identity.uid,
          type: INVITATION_TYPE_STUDENT,
          connectionId,
          redeemedAt: now,
        });
        tx.update(invRef, {
          claimedByUid: identity.uid,
          recipientDisplayName: learnerName,
          connectionId,
          connectionStatus: 'pending',
          redemptionCount: 1,
          updatedAt: now,
        });
        tx.set(rateRef, {timestamps: nextRateTimestamps, updatedAt: now});
        return {
          invitationId,
          type: INVITATION_TYPE_STUDENT,
          outcome: 'pending_connection_existing',
          inviterDisplayName: coachName,
          inviterPhotoUrl: coachPhotoUrl,
          connectionId,
          connectionVersion: version,
          connectionStatus: 'pending',
          requestDocId: connectionId,
          message: `${coachName} sent you a student connection request. Accept or decline below.`,
        };
      }

      // Create a fresh pending CoachingConnections document and matching pending Request.
      // Never auto-accept and never grant instructorUids here!
      tx.set(connRef, {
        kind: 'rider',
        version: nonce,
        horseId: null,
        ownershipVersion: null,
        horseName: null,
        learner: identity.lowerEmail,
        coach: coachLower,
        learnerEmail: learnerProfile.email || identity.email,
        coachEmail: coachEmail,
        learnerName,
        coachName,
        participantUids: [identity.uid, inv.inviterUid],
        learnerUid: identity.uid,
        coachUid: inv.inviterUid,
        sender: coachLower,
        recipient: identity.lowerEmail,
        reason: inv.personalMessage || 'Student invitation link',
        invitationId,
        status: 'pending',
        updatedAt: now,
      });
      tx.set(reqRef, requestPayload);
      tx.set(redemptionRef, {
        recipientUid: identity.uid,
        type: INVITATION_TYPE_STUDENT,
        connectionId,
        redeemedAt: now,
      });
      tx.update(invRef, {
        claimedByUid: identity.uid,
        recipientDisplayName: learnerName,
        connectionId,
        connectionStatus: 'pending',
        redemptionCount: 1,
        updatedAt: now,
      });
      tx.set(rateRef, {timestamps: nextRateTimestamps, updatedAt: now});

      return {
        invitationId,
        type: INVITATION_TYPE_STUDENT,
        outcome: 'pending_connection_created',
        inviterDisplayName: coachName,
        inviterPhotoUrl: coachPhotoUrl,
        connectionId,
        connectionVersion: nonce,
        connectionStatus: 'pending',
        requestDocId: connectionId,
        message: `${coachName} wants to connect with you as their student.`,
      };
    });
  };
}

function listMyInvitationsHandler(db, options = {}) {
  const nowFn = options.now || (() => new Date());
  return async (request) => {
    const identity = assertVerifiedAuth(request);
    const now = nowFn();
    const snap = await db
        .collection(INVITATIONS_COLLECTION)
        .where('inviterUid', '==', identity.uid)
        .get();
    const docs = Array.isArray(snap?.docs) ? snap.docs : [];
    const invitations = docs
        .map((doc) => doc.data())
        .filter(Boolean)
        .sort((a, b) => {
          const bMs = toDateOrNull(b.createdAt)?.getTime() || 0;
          const aMs = toDateOrNull(a.createdAt)?.getTime() || 0;
          return bMs - aMs;
        })
        .slice(0, 100)
        .map((inv) => serializeForInviter(inv, now));

    return {invitations};
  };
}

function revokeInvitationHandler(db, options = {}) {
  const nowFn = options.now || (() => new Date());
  return async (request) => {
    const identity = assertVerifiedAuth(request);
    const rawId = typeof request.data?.invitationId === 'string' ?
      request.data.invitationId.trim() :
      '';
    if (!INVITATION_ID_REGEX.test(rawId)) {
      throw new HttpsError('invalid-argument', 'Invalid invitation ID.');
    }

    const now = nowFn();
    const invRef = db.collection(INVITATIONS_COLLECTION).doc(rawId);

    const updated = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      const inv = invSnap.data();
      if (!invSnap.exists || !inv) {
        throw new HttpsError('not-found', 'Invitation not found.');
      }
      if (inv.inviterUid !== identity.uid) {
        throw new HttpsError('permission-denied', 'You can only revoke your own invitations.');
      }

      let connRef = null;
      let connSnap = null;
      let reqRef = null;
      let reqSnap = null;
      if (typeof inv.connectionId === 'string' && inv.connectionId) {
        connRef = db.collection('CoachingConnections').doc(inv.connectionId);
        reqRef = db.collection('Requests').doc(inv.connectionId);
        [connSnap, reqSnap] = await Promise.all([tx.get(connRef), tx.get(reqRef)]);
      }

      const liveConn = connSnap?.data();
      if (inv.connectionStatus === 'accepted' || liveConn?.status === 'accepted') {
        throw new HttpsError(
            'failed-precondition',
            'Accepted connections must be ended from Connections and requests.',
        );
      }

      if (inv.revokedAt || inv.status === 'revoked') {
        return inv;
      }

      const nextDoc = {
        ...inv,
        status: 'revoked',
        revokedAt: now,
        updatedAt: now,
        ...(liveConn?.status === 'pending' && liveConn.invitationId === rawId ?
          {connectionStatus: 'cancelled'} :
          {}),
      };

      tx.update(invRef, {
        status: 'revoked',
        revokedAt: now,
        updatedAt: now,
        ...(liveConn?.status === 'pending' && liveConn.invitationId === rawId ?
          {connectionStatus: 'cancelled'} :
          {}),
      });

      if (connRef && liveConn?.status === 'pending' && liveConn.invitationId === rawId) {
        tx.update(connRef, {status: 'cancelled', updatedAt: now});
        const liveReq = reqSnap?.data();
        if (reqRef && liveReq && (liveReq.status || 'pending') === 'pending') {
          tx.update(reqRef, {status: 'cancelled', updatedAt: now});
        }
      }

      return nextDoc;
    });

    return {invitation: serializeForInviter(updated, now)};
  };
}

module.exports = {
  INVITATIONS_COLLECTION,
  TOKENS_COLLECTION,
  RATE_LIMITS_COLLECTION,
  INVITATION_TYPE_GENERAL,
  INVITATION_TYPE_STUDENT,
  MAX_CREATES_PER_24H,
  MAX_REDEEMS_PER_24H,
  createInvitationHandler,
  getInvitationPreviewHandler,
  hashToken,
  listMyInvitationsHandler,
  redeemInvitationHandler,
  resolveDerivedStatus,
  resolvePublicInvitationPreview,
  revokeInvitationHandler,
  serializeForInviter,
};
