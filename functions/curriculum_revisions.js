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
const PUBLIC_COLLECTION = 'SkillTreeCurriculumPublic';
const PUBLIC_ACTIVE_DOC_ID = 'active';
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

function optionalRequestId(value) {
  if (value == null || value === '') return null;
  if (typeof value !== 'string' || value.trim().length > 120) {
    throw new HttpsError(
        'invalid-argument',
        'requestId must be a string of 120 characters or fewer.',
    );
  }
  return value.trim();
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
  const families = Array.isArray(parsed.families) ? parsed.families : [];
  const skills = Array.isArray(parsed.skills) ? parsed.skills : [];
  if (
    Number.isInteger(header.familyCount) &&
    families.length !== header.familyCount
  ) {
    throw new HttpsError(
        'data-loss',
        `Revision ${header.id} family count mismatch (${families.length} vs ${header.familyCount}).`,
    );
  }
  if (
    Number.isInteger(header.skillCount) &&
    skills.length !== header.skillCount
  ) {
    throw new HttpsError(
        'data-loss',
        `Revision ${header.id} skill count mismatch (${skills.length} vs ${header.skillCount}).`,
    );
  }
  return {
    families,
    skills,
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

async function fetchActivePublishedCurriculum(db) {
  const activeSnap = await db
      .collection(PUBLIC_COLLECTION)
      .doc(PUBLIC_ACTIVE_DOC_ID)
      .get();
  if (activeSnap.exists && activeSnap.data() && activeSnap.data().activeRevisionId) {
    const revId = activeSnap.data().activeRevisionId;
    const {snapshot} = await loadRevisionWithChunks(db, revId);
    return {
      families: snapshot.families,
      skills: snapshot.skills,
      sourceRevisionId: revId,
    };
  }
  const [famSnap, skillSnap] = await Promise.all([
    db.collection('SkillFamilies').get(),
    db.collection('SkillsV2').get(),
  ]);
  const families = (famSnap.docs || []).map((d) => ({id: d.id, ...(d.data() || {})}));
  const skills = (skillSnap.docs || []).map((d) => ({id: d.id, ...(d.data() || {})}));
  return {families, skills, sourceRevisionId: null};
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

function serializeRevisionResponse(header, fallbackDate) {
  return {
    ...header,
    createdAt: toDateOrNull(header.createdAt)?.toISOString() || fallbackDate.toISOString(),
    publishedAt: toDateOrNull(header.publishedAt)?.toISOString() || fallbackDate.toISOString(),
  };
}

async function acquirePublicationLock(db, {
  uid,
  actorName,
  nowDate,
  requestId = null,
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

    // Idempotent retry after an unknown commit outcome (same requestId already activated).
    if (
      requestId &&
      meta.lastCompletedRequestId === requestId &&
      currentRevisionId &&
      state === 'idle'
    ) {
      return {
        idempotentReplay: true,
        resumed: false,
        revisionId: currentRevisionId,
        revisionNumber: currentRevisionNumber,
        previousRevisionId: currentRevisionId,
      };
    }

    const isInterrupted =
      state === 'failed' ||
      state === 'syncing_legacy' ||
      (state !== 'idle' && !lockActive);

    if (state !== 'idle' && lockActive && !isInterrupted) {
      throw new HttpsError(
          'aborted',
          `A curriculum publication (${meta.activePublicationId || 'active'}) is already in progress ` +
          `by ${meta.lockOwnerName || meta.lockOwnerUid || 'another administrator'}.`,
      );
    }

    if (isInterrupted && meta.activePublicationId) {
      // Allow transparent recovery if caller passes resumeFailedPublication OR retries same requestId.
      const sameRequestRetry = Boolean(requestId && meta.activeRequestId === requestId);
      if (!resumeFailedPublication && !sameRequestRetry) {
        throw new HttpsError(
            'failed-precondition',
            `Previous publication "${meta.activePublicationId}" was interrupted (${meta.failedStage || state}). ` +
            'Resume or discard the interrupted publication before starting a new one.',
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
      const alreadyActivated =
        meta.failedStage === 'syncing_legacy' ||
        state === 'syncing_legacy' ||
        currentRevisionId === meta.activePublicationId;
      tx.set(metaRef, {
        ...meta,
        publicationState: alreadyActivated ? 'syncing_legacy' : 'preparing',
        lockOwnerUid: uid,
        lockOwnerName: actorName,
        lockAcquiredAt: nowDate,
        lockExpiresAt: nextLease,
        updatedAt: nowDate,
      }, {merge: true});
      return {
        idempotentReplay: false,
        resumed: true,
        alreadyActivated,
        revisionId: meta.activePublicationId,
        revisionNumber: alreadyActivated ? currentRevisionNumber : currentRevisionNumber + 1,
        previousRevisionId: currentRevisionId,
      };
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
      activeRequestId: requestId || null,
      failedStage: null,
      lockOwnerUid: uid,
      lockOwnerName: actorName,
      lockAcquiredAt: nowDate,
      lockExpiresAt: nextLease,
      lastError: null,
      updatedAt: nowDate,
    }, {merge: true});

    return {
      idempotentReplay: false,
      resumed: false,
      alreadyActivated: false,
      revisionId,
      revisionNumber: nextNumber,
      previousRevisionId: currentRevisionId,
    };
  });
}

async function releaseLockToIdle(db, nowDate, errorMessage = null) {
  const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
  await metaRef.set({
    publicationState: 'idle',
    activePublicationId: null,
    activeRequestId: null,
    failedStage: null,
    lockOwnerUid: null,
    lockOwnerName: null,
    lockAcquiredAt: null,
    lockExpiresAt: null,
    lastError: errorMessage,
    updatedAt: nowDate,
  }, {merge: true});
}

async function markPublicationFailed(db, {
  revisionId,
  stage,
  errorMessage,
  nowDate,
  touchRevisionDoc = true,
}) {
  const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
  await metaRef.set({
    publicationState: 'failed',
    activePublicationId: revisionId,
    failedStage: stage,
    lockOwnerUid: null,
    lockOwnerName: null,
    lockAcquiredAt: null,
    lockExpiresAt: null,
    lastError: errorMessage,
    updatedAt: nowDate,
  }, {merge: true});
  if (touchRevisionDoc && stage !== 'syncing_legacy') {
    const revRef = db.collection(REVISIONS_COLLECTION).doc(revisionId);
    await revRef.set({
      status: 'failed',
      errorMessage,
    }, {merge: true});
  }
}

async function mirrorToLegacyCollections(db, {
  families,
  skills,
  revisionId,
  revisionNumber,
  actorName,
  nowDate,
  commitBatch,
}) {
  const [famSnap, skillSnap] = await Promise.all([
    db.collection('SkillFamilies').get(),
    db.collection('SkillsV2').get(),
  ]);
  const pubFamMap = new Map(
      (famSnap.docs || []).map((d) => [d.id, {id: d.id, ...(d.data() || {})}]),
  );
  const pubSkillMap = new Map(
      (skillSnap.docs || []).map((d) => [d.id, {id: d.id, ...(d.data() || {})}]),
  );

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
      await commitBatch(batch, batchIndex, slice.length, 'syncing_legacy');
    } else {
      await batch.commit();
    }
    batchIndex += 1;
  }
  return ops.length;
}

async function writeSnapshotChunksInBatches(db, {
  revRef,
  revisionHeader,
  chunks,
  commitBatch,
}) {
  const ops = [
    {ref: revRef, data: revisionHeader},
    ...chunks.map((chunk) => ({
      ref: revRef.collection(CHUNKS_SUBCOLLECTION).doc(chunk.id),
      data: chunk,
    })),
  ];
  let batchIndex = 0;
  for (let i = 0; i < ops.length; i += APPLY_BATCH_LIMIT) {
    const slice = ops.slice(i, i + APPLY_BATCH_LIMIT);
    const batch = db.batch();
    for (const op of slice) {
      batch.set(op.ref, op.data);
    }
    if (typeof commitBatch === 'function') {
      await commitBatch(batch, batchIndex, slice.length, 'staging');
    } else {
      await batch.commit();
    }
    batchIndex += 1;
  }
}

async function executePublicationStateMachine(db, {
  uid,
  actorName,
  kind,
  notes,
  requestId = null,
  candidateFamilies,
  candidateSkills,
  rollbackOfRevisionId = null,
  resumeFailedPublication = false,
  nowDate,
  uuid,
  chunkByteLimit = DEFAULT_CHUNK_BYTE_LIMIT,
  commitBatch = null,
  onBeforeActivate = null,
}) {
  const lock = await acquirePublicationLock(db, {
    uid,
    actorName,
    nowDate,
    requestId,
    resumeFailedPublication,
  });

  const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
  const publicRef = db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID);
  const revRef = db.collection(REVISIONS_COLLECTION).doc(lock.revisionId);

  if (lock.idempotentReplay) {
    const revSnap = await revRef.get();
    const header = {id: revSnap.id, ...(revSnap.data() || {})};
    return {
      revision: serializeRevisionResponse(header, nowDate),
      resumed: false,
      idempotentReplay: true,
    };
  }

  let revisionHeader;
  let verifiedSnapshot;

  // Stage 1-3: Prepare, Stage into isolated versioned revision, and Verify integrity.
  if (lock.alreadyActivated) {
    const loaded = await loadRevisionWithChunks(db, lock.revisionId);
    revisionHeader = loaded.header;
    verifiedSnapshot = loaded.snapshot;
  } else {
    let stagedAlready = false;
    if (lock.resumed) {
      // Check if an existing staged snapshot is already complete & valid.
      try {
        const loaded = await loadRevisionWithChunks(db, lock.revisionId);
        revisionHeader = loaded.header;
        verifiedSnapshot = loaded.snapshot;
        stagedAlready = true;
      } catch (_) {
        stagedAlready = false;
      }
    }

    if (!stagedAlready) {
      // If resuming a failed staging step without candidate payload, reload saved draft.
      let familiesInput = candidateFamilies;
      let skillsInput = candidateSkills;
      if (lock.resumed && (!Array.isArray(skillsInput) || skillsInput.length === 0)) {
        const draftSnap = await db.collection(DRAFTS_COLLECTION).doc(DEFAULT_DRAFT_ID).get();
        if (!draftSnap.exists || !draftSnap.data()) {
          await releaseLockToIdle(db, nowDate, 'Interrupted staging had no saved draft to resume.');
          throw new HttpsError(
              'failed-precondition',
              'No saved curriculum draft is available to resume the interrupted staging.',
          );
        }
        familiesInput = draftSnap.data().families || [];
        skillsInput = draftSnap.data().skills || [];
      }

      let published;
      try {
        published = await fetchActivePublishedCurriculum(db);
      } catch (err) {
        await releaseLockToIdle(db, nowDate, err.message);
        throw err;
      }

      const validation = validateCurriculum({
        families: familiesInput,
        skills: skillsInput,
        publishedFamilies: published.families,
        publishedSkills: published.skills,
        requireFamilyDescription: false,
        enforceSizeLimit: false,
      });
      if (!validation.ok) {
        const msg = validation.errors.slice(0, 5).join(' ');
        await releaseLockToIdle(db, nowDate, msg);
        throw new HttpsError('invalid-argument', msg, {errors: validation.errors});
      }

      const diff = computeCurriculumDiff(published, {
        families: validation.families,
        skills: validation.skills,
      });
      if (!diff.hasChanges) {
        const msg = 'No curriculum changes detected to publish.';
        await releaseLockToIdle(db, nowDate, msg);
        throw new HttpsError('failed-precondition', msg);
      }

      // Stage 2: Write isolated versioned chunks (active pointer untouched!).
      await metaRef.set({publicationState: 'staging', updatedAt: nowDate}, {merge: true});
      const {canonical, serialized, checksum, byteLength} = computeCurriculumChecksum({
        families: validation.families,
        skills: validation.skills,
      });
      const chunks = splitIntoChunks(serialized, chunkByteLimit);

      revisionHeader = {
        id: lock.revisionId,
        revisionNumber: lock.revisionNumber,
        kind,
        status: 'staging',
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

      try {
        await writeSnapshotChunksInBatches(db, {
          revRef,
          revisionHeader,
          chunks,
          commitBatch,
        });
      } catch (err) {
        const errMsg = err && err.message ? err.message : 'Snapshot chunk write failed.';
        await markPublicationFailed(db, {
          revisionId: lock.revisionId,
          stage: 'staging',
          errorMessage: errMsg,
          nowDate,
        });
        throw new HttpsError(
            'internal',
            `Publication "${lock.revisionId}" was interrupted while staging snapshot: ${errMsg}`,
        );
      }

      // Stage 3: Read back & verify every chunk and full SHA-256 checksum BEFORE activation.
      await metaRef.set({publicationState: 'verifying', updatedAt: nowDate}, {merge: true});
      try {
        const verified = await loadRevisionWithChunks(db, lock.revisionId);
        revisionHeader = verified.header;
        verifiedSnapshot = verified.snapshot;
      } catch (err) {
        const errMsg = err && err.message ? err.message : 'Snapshot verification failed.';
        await markPublicationFailed(db, {
          revisionId: lock.revisionId,
          stage: 'verifying',
          errorMessage: errMsg,
          nowDate,
        });
        throw err instanceof HttpsError ? err : new HttpsError('data-loss', errMsg);
      }
    }

    // Optional hook for testing failures right before atomic pointer activation.
    if (typeof onBeforeActivate === 'function') {
      try {
        await onBeforeActivate(lock.revisionId);
      } catch (err) {
        const errMsg = err && err.message ? err.message : 'Interrupted before activation.';
        await markPublicationFailed(db, {
          revisionId: lock.revisionId,
          stage: 'activating',
          errorMessage: errMsg,
          nowDate,
        });
        throw new HttpsError('internal', errMsg);
      }
    }

    // Stage 4: ATOMIC ACTIVATION TRANSACTION — flips public pointer in one transaction.
    try {
      await db.runTransaction(async (tx) => {
        const metaSnap = await tx.get(metaRef);
        const curMeta = metaSnap.exists ? (metaSnap.data() || {}) : {};
        if (curMeta.activePublicationId !== lock.revisionId) {
          throw new HttpsError(
              'aborted',
              'Publication lock ownership changed before activation.',
          );
        }
        tx.set(publicRef, {
          activeRevisionId: revisionHeader.id,
          activeRevisionNumber: revisionHeader.revisionNumber,
          checksum: revisionHeader.checksum,
          chunkCount: revisionHeader.chunkCount,
          familyCount: revisionHeader.familyCount,
          skillCount: revisionHeader.skillCount,
          activatedAt: nowDate,
        });
        tx.set(revRef, {
          status: 'completed',
          publishedAt: nowDate,
          immutable: true,
          errorMessage: null,
        }, {merge: true});
        tx.set(metaRef, {
          currentRevisionId: revisionHeader.id,
          currentRevisionNumber: revisionHeader.revisionNumber,
          currentChecksum: revisionHeader.checksum,
          publicationState: 'syncing_legacy',
          activePublicationId: revisionHeader.id,
          lastCompletedRequestId: requestId || curMeta.activeRequestId || null,
          failedStage: null,
          lastError: null,
          updatedAt: nowDate,
        }, {merge: true});
      });
    } catch (err) {
      const errMsg = err && err.message ? err.message : 'Active pointer update failed.';
      await markPublicationFailed(db, {
        revisionId: lock.revisionId,
        stage: 'activating',
        errorMessage: errMsg,
        nowDate,
      });
      throw err instanceof HttpsError ? err : new HttpsError('internal', errMsg);
    }
  }

  // Stage 5: Mirror into legacy SkillFamilies & SkillsV2 (for rules/older clients/sharePreview).
  // Note: New clients already see the complete new revision atomically via SkillTreeCurriculumPublic/active.
  try {
    await mirrorToLegacyCollections(db, {
      families: verifiedSnapshot.families,
      skills: verifiedSnapshot.skills,
      revisionId: revisionHeader.id,
      revisionNumber: revisionHeader.revisionNumber,
      actorName,
      nowDate,
      commitBatch,
    });
  } catch (err) {
    const errMsg = err && err.message ? err.message : 'Legacy mirror sync failed.';
    await markPublicationFailed(db, {
      revisionId: revisionHeader.id,
      stage: 'syncing_legacy',
      errorMessage: errMsg,
      nowDate,
      touchRevisionDoc: false, // Already completed & immutable!
    });
    throw new HttpsError(
        'internal',
        `Revision "${revisionHeader.id}" is active, but legacy compatibility sync was interrupted: ${errMsg}. ` +
        'Resume publication to finish compatibility sync.',
    );
  }

  // Finalize: release lock to idle and clear working draft on publish.
  const finalBatch = db.batch();
  finalBatch.set(metaRef, {
    publicationState: 'idle',
    activePublicationId: null,
    activeRequestId: null,
    failedStage: null,
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
    revision: serializeRevisionResponse({
      ...revisionHeader,
      status: 'completed',
      immutable: true,
      publishedAt: nowDate,
    }, nowDate),
    resumed: lock.resumed,
    idempotentReplay: false,
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
      onBeforeActivate = null,
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
    const requestId = optionalRequestId(data.requestId);
    const resumeFailedPublication = data.resumeFailedPublication === true;
    const actorName = actorNameFromToken(token);
    const nowDate = now();

    let draftFamilies = [];
    let draftSkills = [];
    if (!resumeFailedPublication) {
      const draftSnap = await db.collection(DRAFTS_COLLECTION).doc(DEFAULT_DRAFT_ID).get();
      if (draftSnap.exists && draftSnap.data()) {
        const draft = draftSnap.data();
        draftFamilies = Array.isArray(draft.families) ? draft.families : [];
        draftSkills = Array.isArray(draft.skills) ? draft.skills : [];
      } else if (!requestId) {
        throw new HttpsError(
            'failed-precondition',
            'No saved curriculum draft exists to publish.',
        );
      }
    }

    return executePublicationStateMachine(db, {
      uid,
      actorName,
      kind: 'publish',
      notes,
      requestId,
      candidateFamilies: draftFamilies,
      candidateSkills: draftSkills,
      resumeFailedPublication,
      nowDate,
      uuid,
      chunkByteLimit,
      commitBatch,
      onBeforeActivate,
    });
  };
}

function abortFailedPublicationHandler(
    db,
    {
      now = () => new Date(),
      publishingEnabled = false,
    } = {},
) {
  return async (request) => {
    requireVerifiedAdmin(request);
    if (!publishingEnabled) {
      throw new HttpsError(
          'failed-precondition',
          'Curriculum publishing controls are currently disabled in this environment.',
      );
    }

    const nowDate = now();
    const metaRef = db.collection(META_COLLECTION).doc(META_DOC_ID);
    const publicRef = db.collection(PUBLIC_COLLECTION).doc(PUBLIC_ACTIVE_DOC_ID);

    const outcome = await db.runTransaction(async (tx) => {
      const [metaSnap, publicSnap] = await Promise.all([
        tx.get(metaRef),
        tx.get(publicRef),
      ]);
      const meta = metaSnap.exists ? (metaSnap.data() || {}) : {};
      const activePublicId = publicSnap.exists ?
        (publicSnap.data()?.activeRevisionId || null) :
        null;
      const targetRevId = meta.activePublicationId;
      const state = meta.publicationState || 'idle';

      if (state === 'idle' || !targetRevId) {
        return {aborted: false, revisionId: null};
      }

      // Never discard a revision that has already become active!
      if (
        meta.failedStage === 'syncing_legacy' ||
        state === 'syncing_legacy' ||
        activePublicId === targetRevId ||
        meta.currentRevisionId === targetRevId
      ) {
        throw new HttpsError(
            'failed-precondition',
            `Revision "${targetRevId}" is already active and cannot be discarded. ` +
            'Use Resume Publication to finish compatibility sync.',
        );
      }

      const lockExpiresAt = toDateOrNull(meta.lockExpiresAt);
      if (state !== 'failed' && lockExpiresAt && lockExpiresAt.getTime() > nowDate.getTime()) {
        throw new HttpsError(
            'aborted',
            'Cannot discard while another administrator is actively publishing.',
        );
      }

      tx.set(metaRef, {
        publicationState: 'idle',
        activePublicationId: null,
        activeRequestId: null,
        failedStage: null,
        lockOwnerUid: null,
        lockOwnerName: null,
        lockAcquiredAt: null,
        lockExpiresAt: null,
        lastError: null,
        updatedAt: nowDate,
      }, {merge: true});
      return {aborted: true, revisionId: targetRevId};
    });

    // Clean up unpublished staging docs/chunks outside transaction.
    if (outcome.aborted && outcome.revisionId) {
      const revRef = db.collection(REVISIONS_COLLECTION).doc(outcome.revisionId);
      const revSnap = await revRef.get();
      if (revSnap.exists && revSnap.data()?.status !== 'completed') {
        const chunksSnap = await revRef.collection(CHUNKS_SUBCOLLECTION).get();
        const batch = db.batch();
        for (const chunkDoc of chunksSnap.docs || []) {
          batch.delete(revRef.collection(CHUNKS_SUBCOLLECTION).doc(chunkDoc.id));
        }
        batch.delete(revRef);
        await batch.commit();
      }
    }

    return outcome;
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
      onBeforeActivate = null,
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
    const requestId = optionalRequestId(data.requestId);
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

    const currentPublished = await fetchActivePublishedCurriculum(db);
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
      requestId,
      candidateFamilies: validation.families,
      candidateSkills: validation.skills,
      rollbackOfRevisionId: targetRevisionId,
      nowDate,
      uuid,
      chunkByteLimit,
      commitBatch,
      onBeforeActivate,
    });
  };
}

module.exports = {
  REVISIONS_COLLECTION,
  CHUNKS_SUBCOLLECTION,
  META_COLLECTION,
  META_DOC_ID,
  PUBLIC_COLLECTION,
  PUBLIC_ACTIVE_DOC_ID,
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
  abortFailedPublicationHandler,
  rollbackCurriculumRevisionHandler,
};
