/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {
  MAX_FAMILIES,
  MAX_SKILLS,
  validateCurriculum,
} = require('./curriculum_validator');

const DRAFTS_COLLECTION = 'SkillTreeCurriculumDrafts';
const AUDIT_SUBCOLLECTION = 'AuditEvents';
const DEFAULT_DRAFT_ID = 'default';

function requireVerifiedAdmin(request) {
  const auth = request && request.auth;
  if (!auth || !auth.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  const token = auth.token || {};
  if (token.email_verified !== true) {
    throw new HttpsError(
        'failed-precondition',
        'A verified email address is required.',
    );
  }
  if (token.admin !== true) {
    throw new HttpsError(
        'permission-denied',
        'Administrator privileges are required.',
    );
  }
  return {uid: auth.uid, token};
}

function optionalString(value, maxLen, label) {
  if (value == null) return '';
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${label} must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLen) {
    throw new HttpsError(
        'invalid-argument',
        `${label} must be ${maxLen} characters or fewer.`,
    );
  }
  return trimmed;
}

async function fetchPublishedCurriculum(db) {
  if (!db || typeof db.collection !== 'function') {
    return {publishedFamilies: [], publishedSkills: []};
  }
  const skillsCol = db.collection('SkillsV2');
  const familiesCol = db.collection('SkillFamilies');

  const publishedSkills = [];
  if (skillsCol && typeof skillsCol.get === 'function') {
    const snap = await skillsCol.get();
    for (const doc of snap.docs || []) {
      const data = typeof doc.data === 'function' ? doc.data() : {};
      publishedSkills.push({id: doc.id, ...(data || {})});
    }
  }

  const publishedFamilies = [];
  if (familiesCol && typeof familiesCol.get === 'function') {
    const snap = await familiesCol.get();
    for (const doc of snap.docs || []) {
      const data = typeof doc.data === 'function' ? doc.data() : {};
      publishedFamilies.push({id: doc.id, ...(data || {})});
    }
  }

  return {publishedFamilies, publishedSkills};
}

function saveCurriculumDraftHandler(
    db,
    {now = () => new Date(), uuid = randomUUID} = {},
) {
  return async (request) => {
    const {uid, token} = requireVerifiedAdmin(request);
    const data = (request && request.data) || {};

    if (!Array.isArray(data.families) || data.families.length > MAX_FAMILIES) {
      throw new HttpsError(
          'invalid-argument',
          `families must be an array of at most ${MAX_FAMILIES} entries.`,
      );
    }
    if (!Array.isArray(data.skills) || data.skills.length > MAX_SKILLS) {
      throw new HttpsError(
          'invalid-argument',
          `skills must be an array of at most ${MAX_SKILLS} entries.`,
      );
    }

    const note = optionalString(data.note, 500, 'note');
    const {publishedFamilies, publishedSkills} = await fetchPublishedCurriculum(db);

    const validation = validateCurriculum({
      families: data.families,
      skills: data.skills,
      publishedFamilies,
      publishedSkills,
      requireFamilyDescription: false,
      enforceSizeLimit: true,
    });

    if (!validation.ok) {
      const summary = validation.errors.slice(0, 5).join(' ');
      throw new HttpsError('invalid-argument', summary, {
        errors: validation.errors,
      });
    }

    const actorName =
      typeof token.name === 'string' && token.name.trim() ?
        token.name.trim() :
        (typeof token.email === 'string' ? token.email.toLowerCase() : 'Administrator');
    const current = now();
    const draftRef = db.collection(DRAFTS_COLLECTION).doc(DEFAULT_DRAFT_ID);
    const auditRef = draftRef.collection(AUDIT_SUBCOLLECTION).doc(uuid());

    const draftDoc = {
      id: DEFAULT_DRAFT_ID,
      schemaVersion: 2,
      families: validation.families,
      skills: validation.skills,
      updatedByUid: uid,
      updatedByName: actorName,
      updatedAt: current,
      published: false,
    };

    const batch = db.batch();
    batch.set(draftRef, draftDoc);
    batch.set(auditRef, {
      id: auditRef.id,
      type: 'draft_saved',
      actorUid: uid,
      actorName,
      familyCount: validation.families.length,
      skillCount: validation.skills.length,
      draftSizeBytes: validation.sizeBytes,
      note: note || null,
      at: current,
    });
    await batch.commit();

    return {
      draft: {
        ...draftDoc,
        updatedAt: current.toISOString(),
      },
      warnings: validation.warnings,
      sizeBytes: validation.sizeBytes,
    };
  };
}

function discardCurriculumDraftHandler(
    db,
    {now = () => new Date(), uuid = randomUUID} = {},
) {
  return async (request) => {
    const {uid, token} = requireVerifiedAdmin(request);
    const actorName =
      typeof token.name === 'string' && token.name.trim() ?
        token.name.trim() :
        (typeof token.email === 'string' ? token.email.toLowerCase() : 'Administrator');
    const current = now();
    const draftRef = db.collection(DRAFTS_COLLECTION).doc(DEFAULT_DRAFT_ID);
    const auditRef = draftRef.collection(AUDIT_SUBCOLLECTION).doc(uuid());

    const batch = db.batch();
    batch.delete(draftRef);
    batch.set(auditRef, {
      id: auditRef.id,
      type: 'draft_discarded',
      actorUid: uid,
      actorName,
      at: current,
    });
    await batch.commit();

    return {discarded: true};
  };
}

module.exports = {
  DRAFTS_COLLECTION,
  DEFAULT_DRAFT_ID,
  saveCurriculumDraftHandler,
  discardCurriculumDraftHandler,
};
