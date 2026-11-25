/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');

const SUGGESTIONS_COLLECTION = 'SkillTreeSuggestions';
const AUDIT_SUBCOLLECTION = 'AuditEvents';
const PUBLIC_CURRICULUM_COLLECTION = 'SkillTreeCurriculumPublic';
const PUBLIC_CONTRIBUTORS_DOC_ID = 'contributors';
const MAX_SUBMISSIONS_PER_24H = 10;
const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

const CONTRIBUTION_CATEGORIES = new Set([
  'missing_term_or_alias',
  'component_or_example',
  'level_adjustment_or_addition',
  'new_skill_proposal',
  'safety_or_wording_correction',
]);

const SUBJECTS = new Set(['rider', 'horse']);
const REALMS = new Set(['Husbandry', 'In_Hand', 'Mounted', 'Other']);
const LEVELS = new Set(['introductory', 'intermediate', 'advanced']);

const MODERATOR_STATUSES = new Set([
  'submitted',
  'under_review',
  'needs_clarification',
]);

const ADMIN_ONLY_STATUSES = new Set([
  'approved_as_alias_or_component',
  'approved_as_level',
  'approved_as_new_skill',
  'incorporated',
  'published',
  'declined_already_covered',
  'declined_out_of_scope',
]);

const ALL_STATUSES = new Set([
  ...MODERATOR_STATUSES,
  ...ADMIN_ONLY_STATUSES,
]);

function requireVerifiedAuth(request) {
  const auth = request && request.auth;
  const token = auth && auth.token;
  if (!auth || typeof auth.uid !== 'string' || !auth.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  if (token && token.firebase && token.firebase.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Guest users cannot perform this action.');
  }
  if (!token || token.email_verified !== true) {
    throw new HttpsError(
        'failed-precondition',
        'A verified email address is required.',
    );
  }
  return {uid: auth.uid, token};
}

function isAdminToken(token) {
  return Boolean(token && token.admin === true);
}

function isModeratorToken(token) {
  return Boolean(token && token.moderator === true);
}

function isStaffToken(token) {
  return isAdminToken(token) || isModeratorToken(token);
}

function requiredText(value, min, max, field) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  const trimmed = value.trim();
  if (trimmed.length < min || trimmed.length > max) {
    throw new HttpsError(
        'invalid-argument',
        `${field} must be between ${min} and ${max} characters.`,
    );
  }
  return trimmed;
}

function optionalText(value, max, field) {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  const trimmed = value.trim();
  if (!trimmed) return null;
  if (trimmed.length > max) {
    throw new HttpsError(
        'invalid-argument',
        `${field} must be at most ${max} characters.`,
    );
  }
  return trimmed;
}

function optionalDocId(value, field) {
  const text = optionalText(value, 160, field);
  if (text == null) return null;
  if (text.includes('/') || text === '.' || text === '..') {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  return text;
}

function requiredEnum(value, allowedSet, field) {
  if (typeof value !== 'string' || !allowedSet.has(value)) {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  return value;
}

function toMillis(value) {
  if (value == null) return null;
  if (typeof value === 'number') return value;
  if (value instanceof Date) return value.getTime();
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value._seconds === 'number') return value._seconds * 1000;
  return null;
}

function serializeSuggestion(data) {
  const createdMs = toMillis(data.createdAt);
  const updatedMs = toMillis(data.updatedAt);
  const reviewedMs = toMillis(data.reviewedAt);
  const incorporatedMs = toMillis(data.incorporatedAt);
  return {
    ...data,
    creditConsent: data.creditConsent === true,
    creditGranted: data.creditGranted === true,
    createdAt: createdMs != null ? new Date(createdMs).toISOString() : null,
    updatedAt: updatedMs != null ? new Date(updatedMs).toISOString() : null,
    reviewedAt: reviewedMs != null ? new Date(reviewedMs).toISOString() : null,
    incorporatedAt: incorporatedMs != null ? new Date(incorporatedMs).toISOString() : null,
  };
}

function safePublicContributorName(rawName) {
  if (typeof rawName !== 'string') return null;
  const trimmed = rawName.trim();
  if (!trimmed || trimmed.length > 80) return null;
  // Never expose email addresses as public contributor names.
  if (trimmed.includes('@')) return null;
  return trimmed;
}

function submitSuggestionHandler(db, {now = () => new Date(), uuid = randomUUID} = {}) {
  return async (request) => {
    const {uid, token} = requireVerifiedAuth(request);
    const data = (request && request.data) || {};

    const contributionCategory = requiredEnum(
        data.contributionCategory,
        CONTRIBUTION_CATEGORIES,
        'contributionCategory',
    );
    const subject = requiredEnum(data.subject, SUBJECTS, 'subject');
    const realm = requiredEnum(data.realm, REALMS, 'realm');
    const targetLevel = data.targetLevel == null || data.targetLevel === '' ?
      null :
      requiredEnum(data.targetLevel, LEVELS, 'targetLevel');

    const familyId = optionalDocId(data.familyId, 'familyId');
    const targetSkillId = optionalDocId(data.targetSkillId, 'targetSkillId');
    const targetSkillName = optionalText(data.targetSkillName, 120, 'targetSkillName');
    const title = requiredText(data.title, 5, 120, 'title');
    const description = requiredText(data.description, 10, 2000, 'description');
    const rationale = optionalText(data.rationale, 1000, 'rationale');
    const proposedAlias = optionalText(data.proposedAlias, 120, 'proposedAlias');
    const creditConsent = data.creditConsent === true;

    const nowDate = now();
    const nowMs = nowDate.getTime();
    const cutoffMs = nowMs - TWENTY_FOUR_HOURS_MS;

    const existingSnap = await db
        .collection(SUGGESTIONS_COLLECTION)
        .where('submittedByUid', '==', uid)
        .get();

    let recentCount = 0;
    for (const doc of existingSnap.docs) {
      const docData = doc.data() || {};
      const createdMs = toMillis(docData.createdAt);
      if (createdMs != null && createdMs >= cutoffMs) {
        recentCount += 1;
      }
    }

    if (recentCount >= MAX_SUBMISSIONS_PER_24H) {
      throw new HttpsError(
          'resource-exhausted',
          `Rate limit exceeded: maximum ${MAX_SUBMISSIONS_PER_24H} suggestions per 24 hours.`,
      );
    }

    const suggestionId = uuid();
    const eventId = uuid();
    const submitterEmail = typeof token.email === 'string' ? token.email.toLowerCase() : '';
    const contributorDisplayName = safePublicContributorName(token.name);
    const submitterName =
      contributorDisplayName || (submitterEmail || 'Community Member');

    const suggestionDoc = {
      id: suggestionId,
      submittedByUid: uid,
      submitterEmail,
      submitterName,
      contributorDisplayName,
      creditConsent,
      creditGranted: false,
      contributionCategory,
      subject,
      realm,
      familyId,
      targetSkillId,
      targetSkillName,
      targetLevel,
      title,
      description,
      rationale,
      proposedAlias,
      status: 'submitted',
      assignedToUid: null,
      publicResolutionNote: null,
      reviewedByUid: null,
      reviewedByName: null,
      incorporatedByUid: null,
      incorporatedAt: null,
      createdAt: nowDate,
      updatedAt: nowDate,
      reviewedAt: null,
    };

    const auditEventDoc = {
      id: eventId,
      type: 'submitted',
      actorUid: uid,
      actorName: submitterName,
      actorRole: 'submitter',
      fromStatus: null,
      toStatus: 'submitted',
      privateNote: null,
      publicNote: null,
      at: nowDate,
    };

    const suggestionRef = db.collection(SUGGESTIONS_COLLECTION).doc(suggestionId);
    const auditRef = suggestionRef.collection(AUDIT_SUBCOLLECTION).doc(eventId);

    const batch = db.batch();
    batch.set(suggestionRef, suggestionDoc);
    batch.set(auditRef, auditEventDoc);
    await batch.commit();

    return {suggestion: serializeSuggestion(suggestionDoc)};
  };
}

function reviewSuggestionHandler(db, {now = () => new Date(), uuid = randomUUID} = {}) {
  return async (request) => {
    const {uid, token} = requireVerifiedAuth(request);
    if (!isStaffToken(token)) {
      throw new HttpsError(
          'permission-denied',
          'Administrator or moderator privileges are required.',
      );
    }

    const data = (request && request.data) || {};
    const suggestionId = optionalDocId(data.suggestionId, 'suggestionId');
    if (!suggestionId) {
      throw new HttpsError('invalid-argument', 'suggestionId is required.');
    }

    const hasStatus = Object.prototype.hasOwnProperty.call(data, 'status') && data.status != null;
    const nextStatus = hasStatus ? requiredEnum(data.status, ALL_STATUSES, 'status') : null;

    const actorIsAdmin = isAdminToken(token);
    if (nextStatus && ADMIN_ONLY_STATUSES.has(nextStatus) && !actorIsAdmin) {
      throw new HttpsError(
          'permission-denied',
          'Only administrators may approve, decline, or publish suggestions.',
      );
    }

    const hasAssigned = Object.prototype.hasOwnProperty.call(data, 'assignedToUid');
    const nextAssignedToUid = hasAssigned ?
      optionalDocId(data.assignedToUid, 'assignedToUid') :
      undefined;

    const hasPublicNote = Object.prototype.hasOwnProperty.call(data, 'publicResolutionNote');
    const nextPublicNote = hasPublicNote ?
      optionalText(data.publicResolutionNote, 1000, 'publicResolutionNote') :
      undefined;

    const privateNote = optionalText(data.privateNote, 2000, 'privateNote');

    const hasGrantCredit = Object.prototype.hasOwnProperty.call(data, 'grantPublicCredit');
    const grantPublicCredit = hasGrantCredit ? data.grantPublicCredit === true : undefined;
    if (hasGrantCredit && !actorIsAdmin) {
      throw new HttpsError(
          'permission-denied',
          'Only administrators may manage contributor recognition.',
      );
    }

    if (!nextStatus && nextAssignedToUid === undefined &&
        nextPublicNote === undefined && !privateNote &&
        grantPublicCredit === undefined) {
      throw new HttpsError(
          'invalid-argument',
          'Provide at least one update (status, assignment, public note, private note, or credit).',
      );
    }

    const actorRole = actorIsAdmin ? 'admin' : 'moderator';
    const actorEmail = typeof token.email === 'string' ? token.email.toLowerCase() : '';
    const actorName =
      typeof token.name === 'string' && token.name.trim() ?
        token.name.trim() :
        (actorEmail || actorRole);

    const suggestionRef = db.collection(SUGGESTIONS_COLLECTION).doc(suggestionId);
    const contributorsRef = db
        .collection(PUBLIC_CURRICULUM_COLLECTION)
        .doc(PUBLIC_CONTRIBUTORS_DOC_ID);
    const nowDate = now();

    const updatedSuggestion = await db.runTransaction(async (tx) => {
      const snap = await tx.get(suggestionRef);
      if (!snap.exists) {
        throw new HttpsError('not-found', 'Suggestion not found.');
      }

      const current = snap.data() || {};
      const fromStatus = current.status || 'submitted';
      const toStatus = nextStatus || fromStatus;
      const statusChanged = toStatus !== fromStatus;

      if (grantPublicCredit === true && current.creditConsent !== true) {
        throw new HttpsError(
            'failed-precondition',
            'Contributor did not opt into public credit for this suggestion.',
        );
      }

      let contributorsSnap = null;
      if (grantPublicCredit === true) {
        contributorsSnap = await tx.get(contributorsRef);
      }

      const patch = {
        updatedAt: nowDate,
      };
      if (nextStatus) {
        patch.status = nextStatus;
        patch.reviewedAt = nowDate;
        patch.reviewedByUid = uid;
        patch.reviewedByName = actorName;
        if (nextStatus === 'incorporated') {
          patch.incorporatedAt = current.incorporatedAt || nowDate;
          patch.incorporatedByUid = current.incorporatedByUid || uid;
        }
      }
      if (nextAssignedToUid !== undefined) {
        patch.assignedToUid = nextAssignedToUid;
      }
      if (nextPublicNote !== undefined) {
        patch.publicResolutionNote = nextPublicNote;
      }
      if (grantPublicCredit !== undefined) {
        patch.creditGranted = grantPublicCredit;
      }

      if (grantPublicCredit === true) {
        const publicName = safePublicContributorName(
            current.contributorDisplayName || current.submitterName,
        );
        if (publicName) {
          const existingNames = contributorsSnap && contributorsSnap.exists &&
              Array.isArray(contributorsSnap.data()?.names) ?
            contributorsSnap.data().names.filter((n) => typeof n === 'string' && n.trim()) :
            [];
          const mergedSet = new Set([...existingNames, publicName]);
          const sortedNames = [...mergedSet].sort((a, b) => a.localeCompare(b));
          tx.set(contributorsRef, {
            names: sortedNames,
            updatedAt: nowDate,
          }, {merge: true});
        }
      }

      let eventType = 'note_added';
      if (statusChanged) {
        eventType = 'status_changed';
      } else if (nextAssignedToUid !== undefined && !privateNote &&
          nextPublicNote === undefined) {
        eventType = 'assigned';
      }

      const eventId = uuid();
      const auditRef = suggestionRef.collection(AUDIT_SUBCOLLECTION).doc(eventId);
      const auditEvent = {
        id: eventId,
        type: eventType,
        actorUid: uid,
        actorName,
        actorRole,
        fromStatus,
        toStatus,
        privateNote,
        publicNote: nextPublicNote !== undefined ? nextPublicNote : null,
        at: nowDate,
      };

      tx.update(suggestionRef, patch);
      tx.set(auditRef, auditEvent);

      return {
        ...current,
        ...patch,
      };
    });

    return {suggestion: serializeSuggestion(updatedSuggestion)};
  };
}

module.exports = {
  SUGGESTIONS_COLLECTION,
  AUDIT_SUBCOLLECTION,
  PUBLIC_CURRICULUM_COLLECTION,
  PUBLIC_CONTRIBUTORS_DOC_ID,
  MAX_SUBMISSIONS_PER_24H,
  CONTRIBUTION_CATEGORIES,
  MODERATOR_STATUSES,
  ADMIN_ONLY_STATUSES,
  ALL_STATUSES,
  safePublicContributorName,
  submitSuggestionHandler,
  reviewSuggestionHandler,
};
