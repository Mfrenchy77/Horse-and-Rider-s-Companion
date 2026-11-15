/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');

const DRAFTS_COLLECTION = 'SkillTreeCurriculumDrafts';
const AUDIT_SUBCOLLECTION = 'AuditEvents';
const DEFAULT_DRAFT_ID = 'default';

const SUBJECTS = new Set(['rider', 'horse']);
const REALMS = new Set(['Husbandry', 'In_Hand', 'Mounted', 'Other']);
const LEVELS = new Set(['introductory', 'intermediate', 'advanced']);
const RELATIONS = new Set(['counterpart', 'foundation', 'next', 'theory']);
const STATUSES = new Set(['draft', 'active', 'retired']);
const DOC_ID_REGEX = /^[A-Za-z0-9._-]{1,120}$/;

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

function requiredId(value, label) {
  if (typeof value !== 'string' || !DOC_ID_REGEX.test(value.trim())) {
    throw new HttpsError('invalid-argument', `${label} is invalid.`);
  }
  return value.trim();
}

function requiredString(value, maxLen, label) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new HttpsError('invalid-argument', `${label} is required.`);
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

function requiredEnum(value, allowed, label) {
  if (typeof value !== 'string' || !allowed.has(value)) {
    throw new HttpsError('invalid-argument', `Invalid ${label}.`);
  }
  return value;
}

function stringList(value, maxItems, maxItemLen, label) {
  if (value == null) return [];
  if (!Array.isArray(value) || value.length > maxItems) {
    throw new HttpsError(
        'invalid-argument',
        `${label} must be an array of at most ${maxItems} items.`,
    );
  }
  return value
      .map((item, index) => {
        if (typeof item !== 'string') {
          throw new HttpsError(
              'invalid-argument',
              `${label}[${index}] must be a string.`,
          );
        }
        const trimmed = item.trim();
        if (trimmed.length > maxItemLen) {
          throw new HttpsError(
              'invalid-argument',
              `${label}[${index}] exceeds ${maxItemLen} characters.`,
          );
        }
        return trimmed;
      })
      .filter((item) => item.length > 0);
}

function validateFamily(raw, index) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError('invalid-argument', `families[${index}] is invalid.`);
  }
  const id = requiredId(raw.id, `families[${index}].id`);
  const subject = requiredEnum(
      raw.subject,
      SUBJECTS,
      `families[${index}].subject`,
  );
  const realm = requiredEnum(raw.realm, REALMS, `families[${index}].realm`);
  const name = requiredString(raw.name, 120, `families[${index}].name`);
  const description = optionalString(
      raw.description,
      1000,
      `families[${index}].description`,
  );
  const sortOrder =
    typeof raw.sortOrder === 'number' && Number.isFinite(raw.sortOrder) ?
      Math.trunc(raw.sortOrder) :
      0;

  return {
    id,
    schemaVersion: 2,
    subject,
    realm,
    name,
    description,
    sortOrder,
  };
}

function validateLevelDefinition(raw, skillIndex, levelKey) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError(
        'invalid-argument',
        `skills[${skillIndex}].levels.${levelKey} is invalid.`,
    );
  }
  const overview = optionalString(
      raw.overview,
      1000,
      `skills[${skillIndex}].levels.${levelKey}.overview`,
  );
  const learning = requiredString(
      raw.learning,
      1000,
      `skills[${skillIndex}].levels.${levelKey}.learning`,
  );
  const proficient = requiredString(
      raw.proficient,
      1000,
      `skills[${skillIndex}].levels.${levelKey}.proficient`,
  );

  const rawComponents = raw.components == null ? [] : raw.components;
  if (!Array.isArray(rawComponents) || rawComponents.length > 20) {
    throw new HttpsError(
        'invalid-argument',
        `skills[${skillIndex}].levels.${levelKey}.components is invalid.`,
    );
  }
  const components = rawComponents.map((comp, compIdx) => {
    if (!comp || typeof comp !== 'object' || Array.isArray(comp)) {
      throw new HttpsError(
          'invalid-argument',
          `skills[${skillIndex}].levels.${levelKey}.components[${compIdx}] is invalid.`,
      );
    }
    return {
      title: requiredString(
          comp.title,
          120,
          `skills[${skillIndex}].levels.${levelKey}.components[${compIdx}].title`,
      ),
      description: optionalString(
          comp.description,
          1000,
          `skills[${skillIndex}].levels.${levelKey}.components[${compIdx}].description`,
      ),
    };
  });

  const standardVersion =
    typeof raw.standardVersion === 'number' && raw.standardVersion >= 1 ?
      Math.trunc(raw.standardVersion) :
      1;

  return {
    overview,
    components,
    learning,
    proficient,
    standardVersion,
  };
}

function validateSkill(raw, index) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError('invalid-argument', `skills[${index}] is invalid.`);
  }
  const id = requiredId(raw.id, `skills[${index}].id`);
  const subject = requiredEnum(
      raw.subject,
      SUBJECTS,
      `skills[${index}].subject`,
  );
  const realm = requiredEnum(raw.realm, REALMS, `skills[${index}].realm`);
  const familyId = requiredId(raw.familyId, `skills[${index}].familyId`);
  const name = requiredString(raw.name, 120, `skills[${index}].name`);
  const status = raw.status == null ?
    'active' :
    requiredEnum(raw.status, STATUSES, `skills[${index}].status`);
  const aliases = stringList(raw.aliases, 20, 120, `skills[${index}].aliases`);
  const summary = optionalString(raw.summary, 1000, `skills[${index}].summary`);
  const purpose = optionalString(raw.purpose, 1000, `skills[${index}].purpose`);
  const safety = stringList(raw.safety, 15, 400, `skills[${index}].safety`);
  const legacyIds = stringList(
      raw.legacyIds,
      20,
      120,
      `skills[${index}].legacyIds`,
  );

  if (!Array.isArray(raw.availableLevels) || raw.availableLevels.length === 0) {
    throw new HttpsError(
        'invalid-argument',
        `skills[${index}].availableLevels must contain at least one level.`,
    );
  }
  const availableLevels = [];
  const seenLevels = new Set();
  for (const lvl of raw.availableLevels) {
    const validLvl = requiredEnum(
        lvl,
        LEVELS,
        `skills[${index}].availableLevels`,
    );
    if (!seenLevels.has(validLvl)) {
      seenLevels.add(validLvl);
      availableLevels.push(validLvl);
    }
  }

  if (!raw.levels || typeof raw.levels !== 'object' || Array.isArray(raw.levels)) {
    throw new HttpsError(
        'invalid-argument',
        `skills[${index}].levels is required.`,
    );
  }
  const levels = {};
  for (const lvl of availableLevels) {
    levels[lvl] = validateLevelDefinition(raw.levels[lvl], index, lvl);
  }

  const rawRelated = raw.relatedSkills == null ? [] : raw.relatedSkills;
  if (!Array.isArray(rawRelated) || rawRelated.length > 20) {
    throw new HttpsError(
        'invalid-argument',
        `skills[${index}].relatedSkills is invalid.`,
    );
  }
  const relatedSkills = rawRelated.map((rel, relIdx) => {
    if (!rel || typeof rel !== 'object' || Array.isArray(rel)) {
      throw new HttpsError(
          'invalid-argument',
          `skills[${index}].relatedSkills[${relIdx}] is invalid.`,
      );
    }
    const item = {
      skillId: requiredId(
          rel.skillId,
          `skills[${index}].relatedSkills[${relIdx}].skillId`,
      ),
      relation: requiredEnum(
          rel.relation,
          RELATIONS,
          `skills[${index}].relatedSkills[${relIdx}].relation`,
      ),
    };
    if (rel.level != null) {
      item.level = requiredEnum(
          rel.level,
          LEVELS,
          `skills[${index}].relatedSkills[${relIdx}].level`,
      );
    }
    return item;
  });

  const sortOrder =
    typeof raw.sortOrder === 'number' && Number.isFinite(raw.sortOrder) ?
      Math.trunc(raw.sortOrder) :
      0;

  return {
    id,
    schemaVersion: 2,
    status,
    subject,
    realm,
    familyId,
    name,
    aliases,
    summary,
    purpose,
    safety,
    availableLevels,
    levels,
    relatedSkills,
    legacyIds,
    sortOrder,
  };
}

function saveCurriculumDraftHandler(
    db,
    {now = () => new Date(), uuid = randomUUID} = {},
) {
  return async (request) => {
    const {uid, token} = requireVerifiedAdmin(request);
    const data = (request && request.data) || {};

    if (!Array.isArray(data.families) || data.families.length > 100) {
      throw new HttpsError(
          'invalid-argument',
          'families must be an array of at most 100 entries.',
      );
    }
    if (!Array.isArray(data.skills) || data.skills.length > 250) {
      throw new HttpsError(
          'invalid-argument',
          'skills must be an array of at most 250 entries.',
      );
    }

    const families = data.families.map((f, i) => validateFamily(f, i));
    const skills = data.skills.map((s, i) => validateSkill(s, i));
    const note = optionalString(data.note, 500, 'note');

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
      families,
      skills,
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
      familyCount: families.length,
      skillCount: skills.length,
      note: note || null,
      at: current,
    });
    await batch.commit();

    return {
      draft: {
        ...draftDoc,
        updatedAt: current.toISOString(),
      },
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
