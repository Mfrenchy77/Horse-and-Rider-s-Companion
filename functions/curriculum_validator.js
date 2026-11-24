/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const SUBJECTS = new Set(['rider', 'horse']);
const REALMS = new Set(['Husbandry', 'In_Hand', 'Mounted', 'Other']);
const VALID_REALMS = {
  rider: ['Husbandry', 'In_Hand', 'Mounted', 'Other'],
  horse: ['In_Hand', 'Mounted'],
};
const LEVEL_ORDER = ['introductory', 'intermediate', 'advanced'];
const LEVELS = new Set(LEVEL_ORDER);
const RELATIONS = new Set(['counterpart', 'foundation', 'next', 'theory']);
const STATUSES = new Set(['draft', 'active', 'retired']);
const DOC_ID_REGEX = /^[A-Za-z0-9._-]{1,120}$/;

const MAX_FAMILIES = 100;
const MAX_SKILLS = 250;
const WARN_DRAFT_DOC_BYTES = 700 * 1024;
const MAX_DRAFT_DOC_BYTES = 900 * 1024;

function isPlainObject(value) {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function checkId(value, label, errors) {
  if (typeof value !== 'string' || !DOC_ID_REGEX.test(value.trim())) {
    errors.push(`${label} is invalid.`);
    return null;
  }
  return value.trim();
}

function checkRequiredString(value, maxLen, label, errors) {
  if (typeof value !== 'string' || !value.trim()) {
    errors.push(`${label} is required.`);
    return null;
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLen) {
    errors.push(`${label} must be ${maxLen} characters or fewer.`);
    return null;
  }
  return trimmed;
}

function checkOptionalString(value, maxLen, label, errors, {allowEmpty = true} = {}) {
  if (value == null) return allowEmpty ? '' : null;
  if (typeof value !== 'string') {
    errors.push(`${label} must be a string.`);
    return null;
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLen) {
    errors.push(`${label} must be ${maxLen} characters or fewer.`);
    return null;
  }
  return trimmed;
}

function checkEnum(value, allowed, label, errors) {
  if (typeof value !== 'string' || !allowed.has(value)) {
    errors.push(`Invalid ${label}: "${value}".`);
    return null;
  }
  return value;
}

function checkStringList(
    value,
    maxItems,
    maxItemLen,
    label,
    errors,
    {allowEmptyItems = true} = {},
) {
  if (value == null) return [];
  if (!Array.isArray(value)) {
    errors.push(`${label} must be an array.`);
    return [];
  }
  if (value.length > maxItems) {
    errors.push(`${label} must contain at most ${maxItems} items.`);
  }
  const result = [];
  for (let i = 0; i < value.length && i < maxItems; i += 1) {
    const item = value[i];
    if (typeof item !== 'string') {
      errors.push(`${label}[${i}] must be a string.`);
      continue;
    }
    const trimmed = item.trim();
    if (!trimmed) {
      if (!allowEmptyItems) {
        errors.push(`${label}[${i}] must not be empty.`);
      }
      continue;
    }
    if (trimmed.length > maxItemLen) {
      errors.push(`${label}[${i}] exceeds ${maxItemLen} characters.`);
      continue;
    }
    result.push(trimmed);
  }
  return result;
}

function normalizeOptionalIsoTimestamp(value, label, errors) {
  if (value == null || value === '') return null;
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      errors.push(`${label} is an invalid date.`);
      return null;
    }
    return value.toISOString();
  }
  if (isPlainObject(value) && typeof value.toDate === 'function') {
    const dt = value.toDate();
    if (!(dt instanceof Date) || Number.isNaN(dt.getTime())) {
      errors.push(`${label} is an invalid timestamp.`);
      return null;
    }
    return dt.toISOString();
  }
  if (typeof value === 'string') {
    const trimmed = value.trim();
    const parsed = Date.parse(trimmed);
    if (!trimmed || Number.isNaN(parsed)) {
      errors.push(`${label} must be a valid ISO timestamp.`);
      return null;
    }
    return new Date(parsed).toISOString();
  }
  errors.push(`${label} must be a valid timestamp.`);
  return null;
}

function validateFamilyRecord(raw, index, errors, {requireFamilyDescription}) {
  const prefix = `families[${index}]`;
  if (!isPlainObject(raw)) {
    errors.push(`${prefix} must be an object.`);
    return null;
  }

  const id = checkId(raw.id, `${prefix}.id`, errors);
  const label = id || prefix;

  if (raw.schemaVersion != null && raw.schemaVersion !== 2) {
    errors.push(`Family ${label}: schemaVersion must be 2.`);
  }

  const subject = checkEnum(raw.subject, SUBJECTS, `${label}.subject`, errors);
  const realm = checkEnum(raw.realm, REALMS, `${label}.realm`, errors);
  if (subject && realm && !VALID_REALMS[subject].includes(realm)) {
    errors.push(`Family ${label}: invalid subject/realm combination ${subject}/${realm}.`);
  }

  const name = checkRequiredString(raw.name, 120, `Family ${label}.name`, errors);
  const description = requireFamilyDescription ?
    checkRequiredString(raw.description, 1000, `Family ${label}.description`, errors) :
    checkOptionalString(raw.description, 1000, `Family ${label}.description`, errors);

  let sortOrder = 0;
  if (raw.sortOrder != null) {
    if (typeof raw.sortOrder !== 'number' || !Number.isInteger(raw.sortOrder)) {
      errors.push(`Family ${label}.sortOrder must be an integer.`);
    } else {
      sortOrder = raw.sortOrder;
    }
  }

  if (!id || !subject || !realm || !name || description == null) {
    return null;
  }

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

function validateLevelRecord(raw, skillLabel, levelKey, errors) {
  const prefix = `${skillLabel}.levels.${levelKey}`;
  if (!isPlainObject(raw)) {
    errors.push(`${prefix} must be an object.`);
    return null;
  }

  const overview = checkRequiredString(raw.overview, 1000, `${prefix}.overview`, errors);
  const learning = checkRequiredString(raw.learning, 1000, `${prefix}.learning`, errors);
  const proficient = checkRequiredString(raw.proficient, 1000, `${prefix}.proficient`, errors);

  const rawComponents = raw.components == null ? [] : raw.components;
  const components = [];
  if (!Array.isArray(rawComponents)) {
    errors.push(`${prefix}.components must be an array.`);
  } else {
    if (rawComponents.length > 20) {
      errors.push(`${prefix}.components must contain at most 20 items.`);
    }
    for (let i = 0; i < rawComponents.length && i < 20; i += 1) {
      const comp = rawComponents[i];
      if (!isPlainObject(comp)) {
        errors.push(`${prefix}.components[${i}] must be an object.`);
        continue;
      }
      const title = checkRequiredString(
          comp.title,
          120,
          `${prefix}.components[${i}].title`,
          errors,
      );
      const description = checkOptionalString(
          comp.description,
          1000,
          `${prefix}.components[${i}].description`,
          errors,
      );
      if (title && description != null) {
        components.push({title, description});
      }
    }
  }

  let standardVersion = 1;
  if (raw.standardVersion != null) {
    if (
      typeof raw.standardVersion !== 'number' ||
      !Number.isInteger(raw.standardVersion) ||
      raw.standardVersion < 1
    ) {
      errors.push(`${prefix}.standardVersion must be an integer >= 1.`);
    } else {
      standardVersion = raw.standardVersion;
    }
  }

  const standardUpdatedAt = normalizeOptionalIsoTimestamp(
      raw.standardUpdatedAt,
      `${prefix}.standardUpdatedAt`,
      errors,
  );

  if (!overview || !learning || !proficient) {
    return null;
  }

  const sanitized = {
    overview,
    components,
    learning,
    proficient,
    standardVersion,
  };
  if (standardUpdatedAt != null) {
    sanitized.standardUpdatedAt = standardUpdatedAt;
  }
  return sanitized;
}

function validateSkillRecord(raw, index, errors) {
  const prefix = `skills[${index}]`;
  if (!isPlainObject(raw)) {
    errors.push(`${prefix} must be an object.`);
    return null;
  }

  const id = checkId(raw.id, `${prefix}.id`, errors);
  const label = id || prefix;

  if (raw.schemaVersion != null && raw.schemaVersion !== 2) {
    errors.push(`Skill ${label}: schemaVersion must be 2.`);
  }

  const status = raw.status == null ?
    'active' :
    checkEnum(raw.status, STATUSES, `${label}.status`, errors);
  const subject = checkEnum(raw.subject, SUBJECTS, `${label}.subject`, errors);
  const realm = checkEnum(raw.realm, REALMS, `${label}.realm`, errors);
  if (subject && realm && !VALID_REALMS[subject].includes(realm)) {
    errors.push(`Skill ${label}: invalid subject/realm combination ${subject}/${realm}.`);
  }

  const familyId = checkId(raw.familyId, `${label}.familyId`, errors);
  const name = checkRequiredString(raw.name, 120, `Skill ${label}.name`, errors);
  const summary = checkRequiredString(raw.summary, 1000, `Skill ${label}.summary`, errors);
  const purpose = checkRequiredString(raw.purpose, 1000, `Skill ${label}.purpose`, errors);
  const aliases = checkStringList(raw.aliases, 20, 120, `${label}.aliases`, errors);
  const safety = checkStringList(raw.safety, 15, 400, `${label}.safety`, errors);
  const legacyIds = checkStringList(
      raw.legacyIds,
      20,
      120,
      `${label}.legacyIds`,
      errors,
      {allowEmptyItems: false},
  );

  const availableLevels = [];
  if (!Array.isArray(raw.availableLevels) || raw.availableLevels.length === 0 || raw.availableLevels.length > 3) {
    errors.push(`Skill ${label}.availableLevels must contain 1 to 3 levels.`);
  } else {
    let lastOrder = -1;
    const seen = new Set();
    for (const lvl of raw.availableLevels) {
      const validLvl = checkEnum(lvl, LEVELS, `${label}.availableLevels`, errors);
      if (!validLvl) continue;
      if (seen.has(validLvl)) {
        errors.push(`Skill ${label}.availableLevels contains duplicate level "${validLvl}".`);
        continue;
      }
      seen.add(validLvl);
      const orderIdx = LEVEL_ORDER.indexOf(validLvl);
      if (orderIdx <= lastOrder) {
        errors.push(`Skill ${label}.availableLevels must follow introductory -> intermediate -> advanced order.`);
      }
      lastOrder = orderIdx;
      availableLevels.push(validLvl);
    }
  }

  const levels = {};
  if (!isPlainObject(raw.levels)) {
    errors.push(`Skill ${label}.levels must be an object.`);
  } else {
    const rawLevelKeys = Object.keys(raw.levels);
    for (const key of rawLevelKeys) {
      if (!LEVELS.has(key)) {
        errors.push(`Skill ${label}.levels contains invalid level key "${key}".`);
      } else if (!availableLevels.includes(key)) {
        errors.push(`Skill ${label}.levels defines "${key}", which is missing from availableLevels.`);
      }
    }
    for (const lvl of availableLevels) {
      if (!Object.prototype.hasOwnProperty.call(raw.levels, lvl)) {
        errors.push(`Skill ${label}.levels is missing definition for "${lvl}".`);
        continue;
      }
      const def = validateLevelRecord(raw.levels[lvl], label, lvl, errors);
      if (def) {
        levels[lvl] = def;
      }
    }
  }

  const rawRelated = raw.relatedSkills == null ? [] : raw.relatedSkills;
  const relatedSkills = [];
  if (!Array.isArray(rawRelated)) {
    errors.push(`Skill ${label}.relatedSkills must be an array.`);
  } else {
    if (rawRelated.length > 20) {
      errors.push(`Skill ${label}.relatedSkills must contain at most 20 entries.`);
    }
    const seenPairs = new Set();
    for (let i = 0; i < rawRelated.length && i < 20; i += 1) {
      const rel = rawRelated[i];
      if (!isPlainObject(rel)) {
        errors.push(`${label}.relatedSkills[${i}] must be an object.`);
        continue;
      }
      const targetId = checkId(
          rel.skillId,
          `${label}.relatedSkills[${i}].skillId`,
          errors,
      );
      const relation = checkEnum(
          rel.relation,
          RELATIONS,
          `${label}.relatedSkills[${i}].relation`,
          errors,
      );
      let level;
      if (rel.level != null) {
        level = checkEnum(
            rel.level,
            LEVELS,
            `${label}.relatedSkills[${i}].level`,
            errors,
        );
      }
      if (!targetId || !relation) continue;
      if (id && targetId === id) {
        errors.push(`Skill ${label} cannot reference itself in relatedSkills.`);
        continue;
      }
      const pairKey = `${targetId}:${relation}`;
      if (seenPairs.has(pairKey)) {
        errors.push(`Skill ${label} contains duplicate ${relation} link to ${targetId}.`);
        continue;
      }
      seenPairs.add(pairKey);
      const entry = {skillId: targetId, relation};
      if (level) entry.level = level;
      relatedSkills.push(entry);
    }
  }

  let sortOrder = 0;
  if (raw.sortOrder != null) {
    if (typeof raw.sortOrder !== 'number' || !Number.isInteger(raw.sortOrder)) {
      errors.push(`Skill ${label}.sortOrder must be an integer.`);
    } else {
      sortOrder = raw.sortOrder;
    }
  }

  let replacedBy = null;
  if (raw.replacedBy != null && raw.replacedBy !== '') {
    replacedBy = checkId(raw.replacedBy, `${label}.replacedBy`, errors);
    if (replacedBy && id && replacedBy === id) {
      errors.push(`Skill ${label}.replacedBy cannot reference itself.`);
    }
    if (status && status !== 'retired') {
      errors.push(`Skill ${label}: replacedBy is only allowed when status is "retired".`);
    }
  }

  const updatedAt = normalizeOptionalIsoTimestamp(
      raw.updatedAt,
      `${label}.updatedAt`,
      errors,
  );
  const updatedBy = raw.updatedBy == null ?
    null :
    checkOptionalString(raw.updatedBy, 120, `${label}.updatedBy`, errors);

  if (!id || !status || !subject || !realm || !familyId || !name || summary == null || purpose == null) {
    return null;
  }

  const sanitized = {
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
  if (replacedBy) sanitized.replacedBy = replacedBy;
  if (updatedAt) sanitized.updatedAt = updatedAt;
  if (updatedBy) sanitized.updatedBy = updatedBy;
  return sanitized;
}

function validateGraphAndReferences(families, skills, errors) {
  const familyMap = new Map();
  for (const f of families) {
    if (familyMap.has(f.id)) {
      errors.push(`Duplicate family ID: ${f.id}.`);
      continue;
    }
    familyMap.set(f.id, f);
  }

  const skillMap = new Map();
  const legacySeen = new Map();
  let totalLevels = 0;

  for (const s of skills) {
    if (skillMap.has(s.id)) {
      errors.push(`Duplicate skill ID: ${s.id}.`);
      continue;
    }
    skillMap.set(s.id, s);
    totalLevels += s.availableLevels.length;

    const fam = familyMap.get(s.familyId);
    if (!fam) {
      errors.push(`Skill ${s.id}: unknown familyId "${s.familyId}".`);
    } else if (fam.subject !== s.subject || fam.realm !== s.realm) {
      errors.push(
          `Skill ${s.id}: family "${s.familyId}" subject/realm (${fam.subject}/${fam.realm}) ` +
          `does not match skill (${s.subject}/${s.realm}).`,
      );
    }

    for (const oldId of s.legacyIds) {
      if (legacySeen.has(oldId)) {
        errors.push(`Legacy ID "${oldId}" mapped twice: ${legacySeen.get(oldId)} and ${s.id}.`);
      } else {
        legacySeen.set(oldId, s.id);
      }
    }
  }

  for (const s of skillMap.values()) {
    if (s.replacedBy) {
      const replacement = skillMap.get(s.replacedBy);
      if (!replacement) {
        errors.push(`Skill ${s.id}: replacedBy target "${s.replacedBy}" not found.`);
      } else {
        if (replacement.status !== 'active') {
          errors.push(`Skill ${s.id}: replacedBy target "${s.replacedBy}" must have status "active".`);
        }
        if (replacement.subject !== s.subject) {
          errors.push(
              `Skill ${s.id}: replacedBy target "${s.replacedBy}" subject (${replacement.subject}) ` +
              `must match retired skill subject (${s.subject}).`,
          );
        }
      }
    }

    for (const rel of s.relatedSkills) {
      const target = skillMap.get(rel.skillId);
      if (!target) {
        errors.push(`Skill ${s.id}: relatedSkill "${rel.skillId}" not found.`);
        continue;
      }
      if (rel.relation === 'counterpart') {
        if (target.subject === s.subject) {
          errors.push(`Skill ${s.id}: counterpart "${rel.skillId}" must be opposite subject.`);
        }
        const reverse = target.relatedSkills.some(
            (r) => r.skillId === s.id && r.relation === 'counterpart',
        );
        if (!reverse) {
          errors.push(`Skill ${s.id}: counterpart "${rel.skillId}" is not symmetric.`);
        }
      }
      if (rel.level && !target.availableLevels.includes(rel.level)) {
        errors.push(`Skill ${s.id}: relatedSkill "${rel.skillId}" does not offer level "${rel.level}".`);
      }
    }
  }

  // Foundation edges must form a DAG (zero cycles).
  const visiting = new Set();
  const visited = new Set();
  const stack = [];
  function detectCycle(skillId) {
    if (visited.has(skillId)) return;
    if (visiting.has(skillId)) {
      const idx = stack.indexOf(skillId);
      const cycle = [...stack.slice(idx), skillId].join(' -> ');
      errors.push(`Cycle detected in foundation links: ${cycle}.`);
      return;
    }
    visiting.add(skillId);
    stack.push(skillId);
    const skill = skillMap.get(skillId);
    if (skill) {
      for (const rel of skill.relatedSkills) {
        if (rel.relation === 'foundation' && skillMap.has(rel.skillId)) {
          detectCycle(rel.skillId);
        }
      }
    }
    stack.pop();
    visiting.delete(skillId);
    visited.add(skillId);
  }
  for (const skillId of skillMap.keys()) {
    detectCycle(skillId);
  }

  return {familyMap, skillMap, legacySeen, totalLevels};
}

function validatePublishedPreservation(skillMap, publishedSkills, errors) {
  if (!Array.isArray(publishedSkills) || publishedSkills.length === 0) return;

  for (const pub of publishedSkills) {
    if (!pub || typeof pub.id !== 'string' || !pub.id.trim()) continue;
    const pubId = pub.id.trim();
    const draft = skillMap.get(pubId);
    if (!draft) {
      errors.push(`Published skill "${pubId}" cannot be deleted; set status to "retired" instead.`);
      continue;
    }

    if (typeof pub.subject === 'string' && draft.subject !== pub.subject) {
      errors.push(`Published skill "${pubId}" cannot change subject from "${pub.subject}" to "${draft.subject}".`);
    }

    if (Array.isArray(pub.legacyIds)) {
      const draftLegacy = new Set(draft.legacyIds);
      for (const legacyId of pub.legacyIds) {
        if (typeof legacyId === 'string' && !draftLegacy.has(legacyId)) {
          errors.push(`Published legacyId "${legacyId}" on skill "${pubId}" cannot be removed.`);
        }
      }
    }

    if (Array.isArray(pub.availableLevels)) {
      const draftLevels = new Set(draft.availableLevels);
      for (const lvl of pub.availableLevels) {
        if (typeof lvl === 'string' && !draftLevels.has(lvl)) {
          errors.push(
              `Published difficulty level "${lvl}" on skill "${pubId}" cannot be deleted ` +
              'so existing user progress stays valid.',
          );
        }
      }
    }

    if (isPlainObject(pub.levels)) {
      const pubLevelKeys = Array.isArray(pub.availableLevels) ?
        pub.availableLevels :
        Object.keys(pub.levels);
      for (const lvl of pubLevelKeys) {
        const pubDef = pub.levels[lvl];
        const draftDef = draft.levels[lvl];
        if (!isPlainObject(pubDef) || !draftDef) continue;
        const pubVer =
          typeof pubDef.standardVersion === 'number' &&
          Number.isInteger(pubDef.standardVersion) &&
          pubDef.standardVersion >= 1 ?
            pubDef.standardVersion :
            1;
        if (draftDef.standardVersion < pubVer) {
          errors.push(
              `Skill "${pubId}" level "${lvl}": standardVersion cannot decrease below published v${pubVer}.`,
          );
        } else if (
          typeof pubDef.proficient === 'string' &&
          draftDef.proficient.trim() !== pubDef.proficient.trim() &&
          draftDef.standardVersion <= pubVer
        ) {
          errors.push(
              `Skill "${pubId}" level "${lvl}": proficient standard changed; ` +
              `increment standardVersion above v${pubVer}.`,
          );
        }
      }
    }
  }
}

function validateLegacyMappings(skillMap, legacySeen, legacySnapshotIds, legacyMapping, errors) {
  if (legacySnapshotIds != null) {
    const snapIds = legacySnapshotIds instanceof Set ?
      legacySnapshotIds :
      new Set(legacySnapshotIds);
    for (const id of snapIds) {
      if (!legacySeen.has(id)) {
        errors.push(`Unmapped legacy skill ID: ${id}`);
      }
    }
    for (const id of legacySeen.keys()) {
      if (!snapIds.has(id)) {
        errors.push(`Unknown legacy ID in v2: ${id}`);
      }
    }

    if (Array.isArray(legacyMapping)) {
      if (legacyMapping.length !== snapIds.size) {
        errors.push(`legacy_mapping.json has ${legacyMapping.length} entries, expected ${snapIds.size}`);
      }
      for (const row of legacyMapping) {
        if (!snapIds.has(row.legacyId)) {
          errors.push(`legacy_mapping unknown legacyId: ${row.legacyId}`);
        }
        const v2 = skillMap.get(row.v2SkillId);
        if (!v2) {
          errors.push(`legacy_mapping unknown v2SkillId: ${row.v2SkillId}`);
        } else {
          if (!v2.legacyIds.includes(row.legacyId)) {
            errors.push(`legacy_mapping mismatch: ${row.legacyId} -> ${row.v2SkillId}`);
          }
          if (!v2.availableLevels.includes(row.targetLevel)) {
            errors.push(`legacy_mapping invalid targetLevel ${row.targetLevel} on ${row.v2SkillId}`);
          }
        }
      }
    }
  }
}

function validateCurriculum({
  families: rawFamilies,
  skills: rawSkills,
  publishedFamilies = [],
  publishedSkills = [],
  legacySnapshotIds = null,
  legacyMapping = null,
  requireFamilyDescription = false,
  enforceSizeLimit = false,
} = {}) {
  const errors = [];
  const warnings = [];

  if (!Array.isArray(rawFamilies)) {
    errors.push(`families must be an array of at most ${MAX_FAMILIES} entries.`);
  } else if (rawFamilies.length > MAX_FAMILIES) {
    errors.push(`families must contain at most ${MAX_FAMILIES} entries.`);
  }

  if (!Array.isArray(rawSkills)) {
    errors.push(`skills must be an array of at most ${MAX_SKILLS} entries.`);
  } else if (rawSkills.length > MAX_SKILLS) {
    errors.push(`skills must contain at most ${MAX_SKILLS} entries.`);
  }

  const sanitizedFamilies = Array.isArray(rawFamilies) ?
    rawFamilies
        .slice(0, MAX_FAMILIES)
        .map((f, i) => validateFamilyRecord(f, i, errors, {requireFamilyDescription}))
        .filter(Boolean) :
    [];

  const sanitizedSkills = Array.isArray(rawSkills) ?
    rawSkills
        .slice(0, MAX_SKILLS)
        .map((s, i) => validateSkillRecord(s, i, errors))
        .filter(Boolean) :
    [];

  const {skillMap, legacySeen, totalLevels} = validateGraphAndReferences(
      sanitizedFamilies,
      sanitizedSkills,
      errors,
  );

  // Only enforce published preservation when all structural entries parsed cleanly
  // OR always check what exists in skillMap so missing IDs are clearly reported.
  validatePublishedPreservation(skillMap, publishedSkills, errors);
  validateLegacyMappings(skillMap, legacySeen, legacySnapshotIds, legacyMapping, errors);

  // Unused publishedFamilies parameter reserved for future Phase 2B family checks.
  void publishedFamilies;

  const sizeBytes = Buffer.byteLength(
      JSON.stringify({families: sanitizedFamilies, skills: sanitizedSkills}),
      'utf8',
  );
  if (sizeBytes > WARN_DRAFT_DOC_BYTES) {
    warnings.push(
        `Draft payload size (${Math.round(sizeBytes / 1024)} KB) is approaching Firestore's 1 MiB document limit.`,
    );
  }
  if (enforceSizeLimit && sizeBytes > MAX_DRAFT_DOC_BYTES) {
    const sizeKb = Math.round(sizeBytes / 1024);
    const limitKb = Math.round(MAX_DRAFT_DOC_BYTES / 1024);
    errors.push(
        `Draft payload size (${sizeKb} KB) exceeds safe single-document limit (${limitKb} KB).`,
    );
  }

  return {
    ok: errors.length === 0,
    errors,
    warnings,
    families: sanitizedFamilies,
    skills: sanitizedSkills,
    totalLevels,
    legacyCount: legacySeen.size,
    sizeBytes,
  };
}

module.exports = {
  SUBJECTS,
  REALMS,
  VALID_REALMS,
  LEVEL_ORDER,
  LEVELS,
  RELATIONS,
  STATUSES,
  DOC_ID_REGEX,
  MAX_FAMILIES,
  MAX_SKILLS,
  WARN_DRAFT_DOC_BYTES,
  MAX_DRAFT_DOC_BYTES,
  validateCurriculum,
};
