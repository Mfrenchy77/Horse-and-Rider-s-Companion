/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {createHash, randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {validateCurriculum} = require('./curriculum_validator');
const {
  DRAFTS_COLLECTION,
  DEFAULT_DRAFT_ID,
} = require('./curriculum_drafts');

const REVISIONS_COLLECTION = 'SkillTreeCurriculumRevisions';
const CHUNKS_SUBCOLLECTION = 'Chunks';
const META_COLLECTION = 'SkillTreeCurriculumMeta';
const META_DOC_ID = 'current';
const AUDIT_SUBCOLLECTION = 'AuditEvents';

const DEFAULT_CHUNK_BYTE_LIMIT = 256 * 1024;
const LOCK_LEASE_MS = 5 * 60 * 1000;
const APPLY_BATCH_LIMIT = 400;

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

function actorNameFromToken(token) {
  if (typeof token.name === 'string' && token.name.trim()) {
    return token.name.trim();
  }
  if (typeof token.email === 'string' && token.email.trim()) {
    return token.email.trim().toLowerCase();
  }
  return 'Administrator';
}

function optionalNotes(value) {
  if (value == null) return null;
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', 'notes must be a string.');
  }
  const trimmed = value.trim();
  if (trimmed.length > 1000) {
    throw new HttpsError(
        'invalid-argument',
        'notes must be 1000 characters or fewer.',
    );
  }
  return trimmed || null;
}

function formatRevisionId(revisionNumber) {
  return `rev_${String(revisionNumber).padStart(6, '0')}`;
}

function sha256Hex(text) {
  return createHash('sha256').update(text, 'utf8').digest('hex');
}

function sortKeysDeep(value) {
  if (Array.isArray(value)) {
    return value.map(sortKeysDeep);
  }
  if (value && typeof value === 'object' && !(value instanceof Date)) {
    const sorted = {};
    for (const key of Object.keys(value).sort()) {
      if (value[key] !== undefined) {
        sorted[key] = sortKeysDeep(value[key]);
      }
    }
    return sorted;
  }
  return value;
}

function normalizeFamilyForSnapshot(f) {
  return {
    id: f.id,
    schemaVersion: 2,
    subject: f.subject,
    realm: f.realm,
    name: f.name,
    description: f.description || '',
    sortOrder: Number.isInteger(f.sortOrder) ? f.sortOrder : 0,
  };
}

function normalizeSkillForSnapshot(s) {
  const levels = {};
  for (const lvl of s.availableLevels || []) {
    const def = s.levels && s.levels[lvl];
    if (!def) continue;
    const entry = {
      overview: def.overview,
      components: (def.components || []).map((c) => ({
        title: c.title,
        description: c.description || '',
      })),
      learning: def.learning,
      proficient: def.proficient,
      standardVersion: def.standardVersion || 1,
    };
    if (def.standardUpdatedAt) {
      entry.standardUpdatedAt = typeof def.standardUpdatedAt === 'string' ?
        def.standardUpdatedAt :
        (def.standardUpdatedAt.toDate ?
          def.standardUpdatedAt.toDate().toISOString() :
          new Date(def.standardUpdatedAt).toISOString());
    }
    levels[lvl] = entry;
  }
  const normalized = {
    id: s.id,
    schemaVersion: 2,
    status: s.status || 'active',
    subject: s.subject,
    realm: s.realm,
    familyId: s.familyId,
    name: s.name,
    aliases: [...(s.aliases || [])],
    summary: s.summary,
    purpose: s.purpose,
    safety: [...(s.safety || [])],
    availableLevels: [...(s.availableLevels || [])],
    levels,
    relatedSkills: (s.relatedSkills || []).map((r) => {
      const item = {skillId: r.skillId, relation: r.relation};
      if (r.level) item.level = r.level;
      return item;
    }),
    legacyIds: [...(s.legacyIds || [])],
    sortOrder: Number.isInteger(s.sortOrder) ? s.sortOrder : 0,
  };
  if (s.replacedBy) normalized.replacedBy = s.replacedBy;
  return normalized;
}

function canonicalizeCurriculum({families, skills}) {
  const sortedFamilies = [...families]
      .map(normalizeFamilyForSnapshot)
      .sort((a, b) => a.id.localeCompare(b.id));
  const sortedSkills = [...skills]
      .map(normalizeSkillForSnapshot)
      .sort((a, b) => a.id.localeCompare(b.id));
  return {families: sortedFamilies, skills: sortedSkills};
}

function canonicalJsonStringify(value) {
  return JSON.stringify(sortKeysDeep(value));
}

function computeCurriculumChecksum({families, skills}) {
  const canonical = canonicalizeCurriculum({families, skills});
  const serialized = canonicalJsonStringify(canonical);
  return {
    canonical,
    serialized,
    checksum: sha256Hex(serialized),
    byteLength: Buffer.byteLength(serialized, 'utf8'),
  };
}

function splitIntoChunks(serialized, chunkByteLimit = DEFAULT_CHUNK_BYTE_LIMIT) {
  const limit = Math.max(1024, chunkByteLimit);
  const chunks = [];
  let offset = 0;
  let index = 0;
  while (offset < serialized.length || chunks.length === 0) {
    // Slice safely on UTF-16 code unit boundaries while keeping UTF-8 byte length <= limit.
    let end = Math.min(serialized.length, offset + limit);
    while (end > offset && Buffer.byteLength(serialized.slice(offset, end), 'utf8') > limit) {
      end -= Math.max(1, Math.floor((end - offset) / 4));
    }
    const payload = serialized.slice(offset, end);
    chunks.push({
      id: String(index).padStart(4, '0'),
      index,
      payload,
      chunkChecksum: sha256Hex(payload),
      byteLength: Buffer.byteLength(payload, 'utf8'),
    });
    offset = end;
    index += 1;
    if (offset >= serialized.length) break;
  }
  return chunks;
}

function reassembleAndVerifySnapshot(header, chunkDocs) {
  if (!header || typeof header !== 'object') {
    throw new HttpsError('not-found', 'Revision record not found.');
  }
  const ordered = [...chunkDocs].sort((a, b) => a.index - b.index);
  if (ordered.length !== header.chunkCount) {
    throw new HttpsError(
        'data-loss',
        `Revision ${header.id} is incomplete: expected ${header.chunkCount} chunks, found ${ordered.length}.`,
    );
  }
  let serialized = '';
  for (let i = 0; i < ordered.length; i += 1) {
    const chunk = ordered[i];
    if (chunk.index !== i) {
      throw new HttpsError(
          'data-loss',
          `Revision ${header.id} chunk index mismatch at position ${i}.`,
      );
    }
    const expected = sha256Hex(chunk.payload || '');
    if (expected !== chunk.chunkChecksum) {
      throw new HttpsError(
          'data-loss',
          `Revision ${header.id} chunk ${i} failed checksum verification.`,
      );
    }
    serialized += chunk.payload || '';
  }
  const fullChecksum = sha256Hex(serialized);
  if (fullChecksum !== header.checksum) {
    throw new HttpsError(
        'data-loss',
        `Revision ${header.id} failed snapshot integrity checksum verification.`,
    );
  }
  const parsed = JSON.parse(serialized);
  return {
    families: parsed.families || [],
    skills: parsed.skills || [],
    checksum: fullChecksum,
    byteLength: Buffer.byteLength(serialized, 'utf8'),
  };
}

function stripVolatileForDiff(skill) {
  const normalized = normalizeSkillForSnapshot(skill);
  for (const lvl of Object.keys(normalized.levels)) {
    delete normalized.levels[lvl].standardUpdatedAt;
  }
  return canonicalJsonStringify(normalized);
}

function computeCurriculumDiff(published, candidate) {
  const pubFamMap = new Map(published.families.map((f) => [f.id, f]));
  const pubSkillMap = new Map(published.skills.map((s) => [s.id, s]));

  const addedFamilyIds = [];
  const modifiedFamilyIds = [];
  for (const fam of candidate.families) {
    const pub = pubFamMap.get(fam.id);
    if (!pub) {
      addedFamilyIds.push(fam.id);
    } else if (
      canonicalJsonStringify(normalizeFamilyForSnapshot(pub)) !==
      canonicalJsonStringify(normalizeFamilyForSnapshot(fam))
    ) {
      modifiedFamilyIds.push(fam.id);
    }
  }

  const addedSkillIds = [];
  const modifiedSkillIds = [];
  const retiredSkillIds = [];
  const revisedStandards = [];

  for (const skill of candidate.skills) {
    const pub = pubSkillMap.get(skill.id);
    if (!pub) {
      addedSkillIds.push(skill.id);
      continue;
    }
    if (pub.status !== 'retired' && skill.status === 'retired') {
      retiredSkillIds.push(skill.id);
    }
    if (stripVolatileForDiff(pub) !== stripVolatileForDiff(skill)) {
      modifiedSkillIds.push(skill.id);
    }
    for (const lvl of skill.availableLevels || []) {
      const pubVer = pub.levels && pub.levels[lvl] ? (pub.levels[lvl].standardVersion || 1) : null;
      const nextVer = skill.levels && skill.levels[lvl] ? (skill.levels[lvl].standardVersion || 1) : 1;
      if (pubVer != null && nextVer !== pubVer) {
        revisedStandards.push({
          skillId: skill.id,
          level: lvl,
          fromVersion: pubVer,
          toVersion: nextVer,
        });
      }
    }
  }

  const hasChanges =
    addedFamilyIds.length > 0 ||
    modifiedFamilyIds.length > 0 ||
    addedSkillIds.length > 0 ||
    modifiedSkillIds.length > 0 ||
    retiredSkillIds.length > 0;

  return {
    hasChanges,
    addedFamilyIds: addedFamilyIds.sort(),
    modifiedFamilyIds: modifiedFamilyIds.sort(),
    addedSkillIds: addedSkillIds.sort(),
    modifiedSkillIds: modifiedSkillIds.sort(),
    retiredSkillIds: retiredSkillIds.sort(),
    revisedStandards,
  };
}

async function fetchPublishedCurriculum(db) {
  const [famSnap, skillSnap] = await Promise.all([
    db.collection('SkillFamilies').get(),
    db.collection('SkillsV2').get(),
  ]);
  const families = (famSnap.docs || []).map((d) => ({id: d.id, ...(d.data() || {})}));
  const skills = (skillSnap.docs || []).map((d) => ({id: d.id, ...(d.data() || {})}));
  return {families, skills};
}

async function loadRevisionWithChunks(db, revisionId) {
  const revRef = db.collection(REVISIONS_COLLECTION).doc(revisionId);
  const revSnap = await revRef.get();
  if (!revSnap.exists) {
    throw new HttpsError('not-found', `Revision "${revisionId}" does not exist.`);
  }
  const header = {id: revSnap.id, ...(revSnap.data() || {})};
  const chunksSnap = await revRef.collection(CHUNKS_SUBCOLLECTION).get();
  const chunks = (chunksSnap.docs || []).map((d) => ({id: d.id, ...(d.data() || {})}));
  const snapshot = reassembleAndVerifySnapshot(header, chunks);
  return {header, snapshot};
}

function toDateOrNull(val) {
  if (!val) return null;
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  const parsed = Date.parse(val);
  return Number.isNaN(parsed) ? null : new Date(parsed);
}

async function acquirePublicationLock(db, {
  uid,
  actorName,
  nowDate,
  resumeFailedPublication = false,
}) {
  const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(metaRef);
    const meta = snap.exists ? (snap.data() || {}) : {};
    const state = meta.publicationState || 'idle';
    const currentRevisionNumber = Number.isInteger(meta.currentRevisionNumber) ?
      meta.currentRevisionNumber :
      0;
    const currentRevisionId = meta.currentRevisionId || null;
    const lockExpiresAt = toDateOrNull(meta.lockExpiresAt);
    const lockActive = lockExpiresAt != null && lockExpiresAt.getTime() > nowDate.getTime();

    if (state === 'failed' && meta.activePublicationId) {
      if (!resumeFailedPublication) {
        throw new HttpsError(
            'failed-precondition',
            `Previous publication "${meta.activePublicationId}" was interrupted. ` +
            'Recover it with resumeFailedPublication before starting a new publication.',
        );
      }
      if (lockActive && meta.lockOwnerUid && meta.lockOwnerUid !== uid) {
        throw new HttpsError(
            'aborted',
            `Another administrator (${meta.lockOwnerName || meta.lockOwnerUid}) ` +
            'is currently recovering the interrupted publication.',
        );
      }
      const nextLease = new Date(nowDate.getTime() + LOCK_LEASE_MS);
      tx.set(metaRef, {
        ...meta,
        publicationState: 'applying',
        lockOwnerUid: uid,
        lockOwnerName: actorName,
        lockAcquiredAt: nowDate,
        lockExpiresAt: nextLease,
        updatedAt: nowDate,
      }, {merge: true});
      return {
        resumed: true,
        revisionId: meta.activePublicationId,
        revisionNumber: currentRevisionNumber + 1,
        previousRevisionId: currentRevisionId,
      };
    }

    if (state !== 'idle') {
      if (lockActive) {
        throw new HttpsError(
            'aborted',
            `A curriculum publication (${meta.activePublicationId || 'active'}) is already in progress ` +
            `by ${meta.lockOwnerName || meta.lockOwnerUid || 'another administrator'}.`,
        );
      }
      // Lease expired on an interrupted pre-apply/applying job: require explicit recovery if applying.
      if (state === 'applying' && meta.activePublicationId && !resumeFailedPublication) {
        throw new HttpsError(
            'failed-precondition',
            `Previous publication "${meta.activePublicationId}" appears interrupted while applying. ` +
            'Run recovery with resumeFailedPublication: true.',
        );
      }
    }

    const nextNumber = currentRevisionNumber + 1;
    const revisionId = formatRevisionId(nextNumber);
    const nextLease = new Date(nowDate.getTime() + LOCK_LEASE_MS);
    tx.set(metaRef, {
      currentRevisionId,
      currentRevisionNumber,
      currentChecksum: meta.currentChecksum || null,
      publicationState: 'preparing',
      activePublicationId: revisionId,
      lockOwnerUid: uid,
      lockOwnerName: actorName,
      lockAcquiredAt: nowDate,
      lockExpiresAt: nextLease,
      lastError: null,
      updatedAt: nowDate,
    }, {merge: true});

    return {
      resumed: false,
      revisionId,
      revisionNumber: nextNumber,
      previousRevisionId: currentRevisionId,
    };
  });
}

async function releaseLockOnPreApplyError(db, nowDate, errorMessage) {
  const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
  await metaRef.set({
    publicationState: 'idle',
    activePublicationId: null,
    lockOwnerUid: null,
    lockOwnerName: null,
    lockAcquiredAt: null,
    lockExpiresAt: null,
    lastError: errorMessage || null,
    updatedAt: nowDate,
  }, {merge: true});
}

async function applyCurriculumInBatches(db, {
  families,
  skills,
  publishedFamilies,
  publishedSkills,
  revisionId,
  revisionNumber,
  actorName,
  nowDate,
  commitBatch,
}) {
  const pubFamMap = new Map(publishedFamilies.map((f) => [f.id, f]));
  const pubSkillMap = new Map(publishedSkills.map((s) => [s.id, s]));

  const ops = [];
  for (const fam of families) {
    const pub = pubFamMap.get(fam.id);
    if (
      !pub ||
      canonicalJsonStringify(normalizeFamilyForSnapshot(pub)) !==
      canonicalJsonStringify(normalizeFamilyForSnapshot(fam))
    ) {
      ops.push({
        ref: db.collection('SkillFamilies').doc(fam.id),
        data: {
          ...fam,
          revisionId,
          revisionNumber,
          updatedAt: nowDate,
          updatedBy: actorName,
        },
      });
    }
  }
  for (const skill of skills) {
    const pub = pubSkillMap.get(skill.id);
    if (!pub || stripVolatileForDiff(pub) !== stripVolatileForDiff(skill)) {
      ops.push({
        ref: db.collection('SkillsV2').doc(skill.id),
        data: {
          ...skill,
          revisionId,
          revisionNumber,
          updatedAt: nowDate,
          updatedBy: actorName,
        },
      });
    }
  }

  let batchIndex = 0;
  for (let i = 0; i < ops.length; i += APPLY_BATCH_LIMIT) {
    const slice = ops.slice(i, i + APPLY_BATCH_LIMIT);
    const batch = db.batch();
    for (const op of slice) {
      batch.set(op.ref, op.data, {merge: true});
    }
    if (typeof commitBatch === 'function') {
      await commitBatch(batch, batchIndex, slice.length);
    } else {
      await batch.commit();
    }
    batchIndex += 1;
  }
  return ops.length;
}

async function executePublicationStateMachine(db, {
  uid,
  actorName,
  kind,
  notes,
  candidateFamilies,
  candidateSkills,
  rollbackOfRevisionId = null,
  resumeFailedPublication = false,
  nowDate,
  uuid,
  chunkByteLimit = DEFAULT_CHUNK_BYTE_LIMIT,
  commitBatch = null,
}) {
  const lock = await acquirePublicationLock(db, {
    uid,
    actorName,
    nowDate,
    resumeFailedPublication,
  });

  const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
  const revRef = db.collection(REVISIONS_COLLECTION).doc(lock.revisionId);

  let familiesToApply = candidateFamilies;
  let skillsToApply = candidateSkills;
  let revisionHeader;
  let published;

  try {
    published = await fetchPublishedCurriculum(db);

    if (lock.resumed) {
      const loaded = await loadRevisionWithChunks(db, lock.revisionId);
      revisionHeader = loaded.header;
      familiesToApply = loaded.snapshot.families;
      skillsToApply = loaded.snapshot.skills;
    } else {
      const validation = validateCurriculum({
        families: candidateFamilies,
        skills: candidateSkills,
        publishedFamilies: published.families,
        publishedSkills: published.skills,
        requireFamilyDescription: false,
        enforceSizeLimit: false,
      });
      if (!validation.ok) {
        const msg = validation.errors.slice(0, 5).join(' ');
        await releaseLockOnPreApplyError(db, nowDate, msg);
        throw new HttpsError('invalid-argument', msg, {errors: validation.errors});
      }

      const diff = computeCurriculumDiff(published, {
        families: validation.families,
        skills: validation.skills,
      });
      if (!diff.hasChanges) {
        const msg = 'No curriculum changes detected to publish.';
        await releaseLockOnPreApplyError(db, nowDate, msg);
        throw new HttpsError('failed-precondition', msg);
      }

      // Transition to snapshotting and write immutable chunks BEFORE mutating live curriculum.
      await metaRef.set({
        publicationState: 'snapshotting',
        updatedAt: nowDate,
      }, {merge: true});

      const {canonical, serialized, checksum, byteLength} = computeCurriculumChecksum({
        families: validation.families,
        skills: validation.skills,
      });
      const chunks = splitIntoChunks(serialized, chunkByteLimit);

      revisionHeader = {
        id: lock.revisionId,
        revisionNumber: lock.revisionNumber,
        kind,
        status: 'snapshotting',
        previousRevisionId: lock.previousRevisionId,
        rollbackOfRevisionId: rollbackOfRevisionId || null,
        createdAt: nowDate,
        publishedAt: null,
        publishedByUid: uid,
        publishedByName: actorName,
        notes: notes || null,
        checksum,
        chunkCount: chunks.length,
        chunkByteLimit,
        snapshotByteLength: byteLength,
        familyCount: canonical.families.length,
        skillCount: canonical.skills.length,
        totalLevels: validation.totalLevels,
        summary: {
          addedFamilyIds: diff.addedFamilyIds,
          modifiedFamilyIds: diff.modifiedFamilyIds,
          addedSkillIds: diff.addedSkillIds,
          modifiedSkillIds: diff.modifiedSkillIds,
          retiredSkillIds: diff.retiredSkillIds,
          revisedStandards: diff.revisedStandards,
        },
        validation: {
          ok: true,
          warningCount: validation.warnings.length,
          warnings: validation.warnings,
        },
        immutable: false,
        errorMessage: null,
      };

      const snapBatch = db.batch();
      snapBatch.set(revRef, revisionHeader);
      for (const chunk of chunks) {
        snapBatch.set(revRef.collection(CHUNKS_SUBCOLLECTION).doc(chunk.id), chunk);
      }
      await snapBatch.commit();

      // Read back and verify snapshot integrity before modifying SkillFamilies / SkillsV2.
      const verified = await loadRevisionWithChunks(db, lock.revisionId);
      familiesToApply = verified.snapshot.families;
      skillsToApply = verified.snapshot.skills;
    }
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    await releaseLockOnPreApplyError(db, nowDate, err.message);
    throw new HttpsError('internal', err.message || 'Failed preparing curriculum publication.');
  }

  // Transition to applying live curriculum documents.
  await metaRef.set({publicationState: 'applying', updatedAt: nowDate}, {merge: true});
  await revRef.set({status: 'applying', errorMessage: null}, {merge: true});

  try {
    await applyCurriculumInBatches(db, {
      families: familiesToApply,
      skills: skillsToApply,
      publishedFamilies: published.families,
      publishedSkills: published.skills,
      revisionId: revisionHeader.id,
      revisionNumber: revisionHeader.revisionNumber,
      actorName,
      nowDate,
      commitBatch,
    });
  } catch (err) {
    const errMsg = err && err.message ? err.message : 'Batch write failed during apply.';
    await metaRef.set({
      publicationState: 'failed',
      activePublicationId: revisionHeader.id,
      lastError: errMsg,
      updatedAt: nowDate,
    }, {merge: true});
    await revRef.set({
      status: 'failed',
      errorMessage: errMsg,
    }, {merge: true});
    throw new HttpsError(
        'internal',
        `Publication "${revisionHeader.id}" failed while applying changes: ${errMsg}. ` +
        'Run recovery with resumeFailedPublication: true to complete safely from the verified snapshot.',
    );
  }

  // Finalize revision as immutable & completed, advance live pointer, and clear draft if publish.
  const finalBatch = db.batch();
  finalBatch.set(revRef, {
    status: 'completed',
    publishedAt: nowDate,
    immutable: true,
    errorMessage: null,
  }, {merge: true});
  finalBatch.set(metaRef, {
    currentRevisionId: revisionHeader.id,
    currentRevisionNumber: revisionHeader.revisionNumber,
    currentChecksum: revisionHeader.checksum,
    publicationState: 'idle',
    activePublicationId: null,
    lockOwnerUid: null,
    lockOwnerName: null,
    lockAcquiredAt: null,
    lockExpiresAt: null,
    lastError: null,
    updatedAt: nowDate,
  }, {merge: true});

  if ((revisionHeader.kind || kind) === 'publish') {
    const draftRef = db.collection(DRAFTS_COLLECTION).doc(DEFAULT_DRAFT_ID);
    const auditRef = draftRef.collection(AUDIT_SUBCOLLECTION).doc(uuid());
    finalBatch.delete(draftRef);
    finalBatch.set(auditRef, {
      id: auditRef.id,
      type: 'draft_published',
      revisionId: revisionHeader.id,
      revisionNumber: revisionHeader.revisionNumber,
      actorUid: uid,
      actorName,
      notes: revisionHeader.notes || null,
      at: nowDate,
    });
  }
  await finalBatch.commit();

  return {
    revision: {
      ...revisionHeader,
      status: 'completed',
      immutable: true,
      createdAt: toDateOrNull(revisionHeader.createdAt)?.toISOString() || nowDate.toISOString(),
      publishedAt: nowDate.toISOString(),
    },
    resumed: lock.resumed,
  };
}

function publishCurriculumDraftHandler(
    db,
    {
      now = () => new Date(),
      uuid = randomUUID,
      publishingEnabled = false,
      chunkByteLimit = DEFAULT_CHUNK_BYTE_LIMIT,
      commitBatch = null,
    } = {},
) {
  return async (request) => {
    const {uid, token} = requireVerifiedAdmin(request);
    if (!publishingEnabled) {
      throw new HttpsError(
          'failed-precondition',
          'Curriculum publishing is currently disabled in this environment.',
      );
    }

    const data = (request && request.data) || {};
    const notes = optionalNotes(data.notes);
    const resumeFailedPublication = data.resumeFailedPublication === true;
    const actorName = actorNameFromToken(token);
    const nowDate = now();

    let draftFamilies = [];
    let draftSkills = [];
    if (!resumeFailedPublication) {
      const draftSnap = await db.collection(DRAFTS_COLLECTION).doc(DEFAULT_DRAFT_ID).get();
      if (!draftSnap.exists || !draftSnap.data()) {
        throw new HttpsError(
            'failed-precondition',
            'No saved curriculum draft exists to publish.',
        );
      }
      const draft = draftSnap.data();
      draftFamilies = Array.isArray(draft.families) ? draft.families : [];
      draftSkills = Array.isArray(draft.skills) ? draft.skills : [];
    }

    return executePublicationStateMachine(db, {
      uid,
      actorName,
      kind: 'publish',
      notes,
      candidateFamilies: draftFamilies,
      candidateSkills: draftSkills,
      resumeFailedPublication,
      nowDate,
      uuid,
      chunkByteLimit,
      commitBatch,
    });
  };
}

function prepareRollbackCandidate(targetSnapshot, currentPublished, nowDate) {
  const pubSkillMap = new Map(currentPublished.skills.map((s) => [s.id, s]));
  const skills = targetSnapshot.skills.map((skill) => {
    const cloned = structuredClone(skill);
    const currentPub = pubSkillMap.get(cloned.id);
    if (!currentPub || !currentPub.levels || !cloned.levels) {
      return cloned;
    }
    for (const lvl of cloned.availableLevels || []) {
      const curDef = currentPub.levels[lvl];
      const tgtDef = cloned.levels[lvl];
      if (!curDef || !tgtDef) continue;
      const curVer = Number.isInteger(curDef.standardVersion) && curDef.standardVersion >= 1 ?
        curDef.standardVersion :
        1;
      const proficientDiffers =
        typeof curDef.proficient === 'string' &&
        typeof tgtDef.proficient === 'string' &&
        curDef.proficient.trim() !== tgtDef.proficient.trim();
      if (proficientDiffers) {
        tgtDef.standardVersion = curVer + 1;
        tgtDef.standardUpdatedAt = nowDate.toISOString();
      } else if ((tgtDef.standardVersion || 1) < curVer) {
        tgtDef.standardVersion = curVer;
      }
    }
    return cloned;
  });
  return {
    families: structuredClone(targetSnapshot.families),
    skills,
  };
}

function rollbackCurriculumRevisionHandler(
    db,
    {
      now = () => new Date(),
      uuid = randomUUID,
      publishingEnabled = false,
      chunkByteLimit = DEFAULT_CHUNK_BYTE_LIMIT,
      commitBatch = null,
    } = {},
) {
  return async (request) => {
    const {uid, token} = requireVerifiedAdmin(request);
    if (!publishingEnabled) {
      throw new HttpsError(
          'failed-precondition',
          'Curriculum rollback is currently disabled in this environment.',
      );
    }

    const data = (request && request.data) || {};
    const targetRevisionId = typeof data.targetRevisionId === 'string' ?
      data.targetRevisionId.trim() :
      '';
    if (!targetRevisionId) {
      throw new HttpsError('invalid-argument', 'targetRevisionId is required.');
    }
    const notes = optionalNotes(data.notes);
    const dryRun = data.dryRun === true;
    const actorName = actorNameFromToken(token);
    const nowDate = now();

    const {header, snapshot} = await loadRevisionWithChunks(db, targetRevisionId);
    if (header.status !== 'completed') {
      throw new HttpsError(
          'failed-precondition',
          `Revision "${targetRevisionId}" is not a completed revision and cannot be restored.`,
      );
    }

    const currentPublished = await fetchPublishedCurriculum(db);
    const candidate = prepareRollbackCandidate(snapshot, currentPublished, nowDate);
    const validation = validateCurriculum({
      families: candidate.families,
      skills: candidate.skills,
      publishedFamilies: currentPublished.families,
      publishedSkills: currentPublished.skills,
      requireFamilyDescription: false,
      enforceSizeLimit: false,
    });
    if (!validation.ok) {
      const msg = validation.errors.slice(0, 5).join(' ');
      throw new HttpsError('failed-precondition', msg, {errors: validation.errors});
    }

    const diff = computeCurriculumDiff(currentPublished, {
      families: validation.families,
      skills: validation.skills,
    });

    if (dryRun) {
      return {
        dryRun: true,
        targetRevisionId,
        targetRevisionNumber: header.revisionNumber,
        checksum: snapshot.checksum,
        diff,
        validation: {
          ok: true,
          warnings: validation.warnings,
        },
      };
    }

    return executePublicationStateMachine(db, {
      uid,
      actorName,
      kind: 'rollback',
      notes: notes || `Restored from revision #${header.revisionNumber} (${targetRevisionId}).`,
      candidateFamilies: validation.families,
      candidateSkills: validation.skills,
      rollbackOfRevisionId: targetRevisionId,
      nowDate,
      uuid,
      chunkByteLimit,
      commitBatch,
    });
  };
}

module.exports = {
  REVISIONS_COLLECTION,
  CHUNKS_SUBCOLLECTION,
  META_COLLECTION,
  META_DOC_ID,
  DEFAULT_CHUNK_BYTE_LIMIT,
  LOCK_LEASE_MS,
  formatRevisionId,
  canonicalizeCurriculum,
  canonicalJsonStringify,
  computeCurriculumChecksum,
  splitIntoChunks,
  reassembleAndVerifySnapshot,
  computeCurriculumDiff,
  publishCurriculumDraftHandler,
  rollbackCurriculumRevisionHandler,
};
