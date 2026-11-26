/* eslint-disable require-jsdoc */
'use strict';

const {createHmac, randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {safePublicContributorName} = require('./suggestions');
const seed = require('./dictionary_seed.json');

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const KINDS = ['missing_term', 'definition', 'correction', 'improvement', 'regional_usage', 'related_term'];
const STATUSES = ['submitted', 'under_review', 'needs_clarification', 'approved', 'rejected', 'published'];
const EMAIL_PATTERN = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i;
const ALLOWED_IMAGE_TYPES = new Set(['image/png', 'image/jpeg', 'image/webp']);
const IMAGE_EXT_BY_TYPE = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/webp': 'webp',
};
const STRUCTURED_KEYS = ['definition', 'explanation', 'usage', 'regionalUsage', 'examples', 'synonyms'];
const FIELD_LABELS = {
  definition: 'Short definition',
  explanation: 'Detailed explanation',
  usage: 'Discipline & general usage',
  regionalUsage: 'Regional usage',
  examples: 'Examples',
  synonyms: 'Synonyms',
};

function text(value, max, field, required = false) {
  if (value == null && !required) return '';
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) {
    throw new HttpsError('invalid-argument', 'Invalid ' + field + '.');
  }
  return value.trim();
}

function strings(value, field, max = 30) {
  if (value == null) return [];
  if (!Array.isArray(value) || value.length > max) {
    throw new HttpsError('invalid-argument', 'Invalid ' + field + '.');
  }
  return [...new Set(value.map((item) => text(item, 240, field, true)))];
}

function extractStructuredFields(source) {
  if (!source || typeof source !== 'object') {
    return {definition: '', explanation: '', usage: '', regionalUsage: '', examples: [], synonyms: []};
  }
  return {
    definition: text(source.definition, 500, 'definition'),
    explanation: text(source.explanation, 6000, 'explanation'),
    usage: text(source.usage, 2000, 'usage'),
    regionalUsage: text(source.regionalUsage, 2000, 'regional usage'),
    examples: strings(source.examples, 'examples', 12),
    synonyms: strings(source.synonyms, 'synonyms', 30),
  };
}

function validateStructuredFields(raw, label = 'proposed fields', {requireDefinition = false} = {}) {
  if (raw == null) return null;
  if (typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError('invalid-argument', 'Invalid ' + label + '.');
  }
  for (const key of Object.keys(raw)) {
    if (!STRUCTURED_KEYS.includes(key)) {
      throw new HttpsError('invalid-argument', 'Invalid field in ' + label + '.');
    }
  }
  const normalized = {
    definition: text(raw.definition, 500, 'definition', requireDefinition),
    explanation: text(raw.explanation, 6000, 'explanation'),
    usage: text(raw.usage, 2000, 'usage'),
    regionalUsage: text(raw.regionalUsage, 2000, 'regional usage'),
    examples: strings(raw.examples, 'examples', 12),
    synonyms: strings(raw.synonyms, 'synonyms', 30),
  };
  if (EMAIL_PATTERN.test(JSON.stringify(normalized))) {
    throw new HttpsError('invalid-argument', 'Public definitions must not contain email addresses.');
  }
  return normalized;
}

function computeChangedFields(baseFields, proposedFields) {
  if (!proposedFields) return [];
  const base = baseFields || extractStructuredFields(null);
  return STRUCTURED_KEYS.filter((key) => JSON.stringify(base[key]) !== JSON.stringify(proposedFields[key]));
}

function summarizeStructuredProposal(changedFields, reason) {
  const labels = changedFields.map((key) => FIELD_LABELS[key] || key).join(', ');
  const prefix = labels ? 'Suggested improvement to ' + labels + '.' : 'Suggested improvement.';
  return reason ? prefix + ' Reason: ' + reason : prefix;
}

function effectivePublishedRevision(publicSnap) {
  if (!publicSnap || !publicSnap.exists) return 0;
  const data = publicSnap.data() || {};
  if (!data.publishedAt && (data.revision || 0) <= 1) return 0;
  return typeof data.revision === 'number' ? data.revision : 0;
}

function validateEntry(raw) {
  if (!raw || typeof raw !== 'object') throw new HttpsError('invalid-argument', 'Entry required.');
  const id = text(raw.id, 100, 'id', true);
  const slug = text(raw.slug, 100, 'slug', true);
  if (!SLUG.test(id) || !SLUG.test(slug)) throw new HttpsError('invalid-argument', 'Use lowercase slugs.');
  const media = raw.media == null ? [] : raw.media;
  if (!Array.isArray(media) || media.length > 8) throw new HttpsError('invalid-argument', 'Invalid media.');
  const entry = {
    id, slug, schemaVersion: 1,
    term: text(raw.term, 120, 'term', true),
    definition: text(raw.definition, 500, 'definition', true),
    explanation: text(raw.explanation, 6000, 'explanation'),
    synonyms: strings(raw.synonyms, 'synonyms'),
    categories: strings(raw.categories, 'categories', 10),
    usage: text(raw.usage, 2000, 'usage'),
    regionalUsage: text(raw.regionalUsage, 2000, 'regional usage'),
    examples: strings(raw.examples, 'examples', 12),
    relatedTerms: strings(raw.relatedTerms, 'related terms'),
    skillIds: strings(raw.skillIds, 'skill IDs'),
    resourceIds: strings(raw.resourceIds, 'resource IDs'),
    contextual: raw.contextual === true,
    media: media.map((item) => {
      const url = text(item.url, 2048, 'media URL', true);
      if (!/^https:\/\//.test(url)) throw new HttpsError('invalid-argument', 'HTTPS media required.');
      return {url, label: text(item.label, 120, 'media label', true)};
    }),
  };
  if (EMAIL_PATTERN.test(JSON.stringify(entry))) {
    throw new HttpsError('invalid-argument', 'Public definitions must not contain email addresses.');
  }
  return entry;
}

function requireAdmin(request) {
  if (!request.auth || request.auth.token?.admin !== true || request.auth.token?.email_verified !== true) {
    throw new HttpsError('permission-denied', 'A verified administrator is required.');
  }
}

function submitDictionarySuggestion(db, {secret, now = () => Date.now(), requireAppCheck = true} = {}) {
  return async (request) => {
    if (requireAppCheck && !request.app) throw new HttpsError('unauthenticated', 'App verification required.');
    const raw = request.data || {};
    if (raw.website) throw new HttpsError('invalid-argument', 'Invalid submission.');
    const term = text(raw.term, 120, 'term', true);
    const kind = raw.kind;
    if (!KINDS.includes(kind)) throw new HttpsError('invalid-argument', 'Invalid contribution type.');
    const termId = text(raw.termId, 100, 'term ID');
    if (termId && !SLUG.test(termId)) throw new HttpsError('invalid-argument', 'Invalid term ID.');
    const reason = text(raw.reason, 2000, 'reason');
    const proposedFields = validateStructuredFields(
        raw.proposedFields,
        'proposed fields',
        {requireDefinition: Boolean(termId && raw.proposedFields != null)},
    );
    const clientBaseFields = validateStructuredFields(raw.baseFields, 'base fields');
    if (raw.baseRevision != null && (!Number.isInteger(raw.baseRevision) || raw.baseRevision < 0)) {
      throw new HttpsError('invalid-argument', 'Invalid base revision.');
    }
    const rawProposal = text(raw.proposal, 4000, 'proposal', !proposedFields);
    const recognitionConsent = raw.recognitionConsent === true;
    const publicName = recognitionConsent ? safePublicContributorName(raw.publicName) : null;
    if (recognitionConsent && !publicName) throw new HttpsError('invalid-argument', 'A public name is required.');
    const submissionId = text(raw.submissionId, 64, 'submission ID', true);
    if (!/^[a-zA-Z0-9-]{16,64}$/.test(submissionId)) {
      throw new HttpsError('invalid-argument', 'Invalid submission ID.');
    }
    if (!secret) throw new HttpsError('failed-precondition', 'Submission protection is not configured.');
    const at = now();
    const ip = request.rawRequest?.ip || '';
    if (!ip) throw new HttpsError('invalid-argument', 'Missing request address.');
    // Daily keyed hashes avoid storing IP addresses and rotate limiter identities.
    const day = Math.floor(at / 86400000);
    const digest = (value) => createHmac('sha256', secret).update(day + ':' + value).digest('hex');
    const buckets = [db.collection('DictionaryRateLimits').doc(digest('ip:' + ip))];
    if (request.auth?.uid) buckets.push(db.collection('DictionaryRateLimits').doc(digest(request.auth.uid)));
    const ref = db.collection('DictionarySuggestions').doc(submissionId);
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(ref);
      const limits = await Promise.all(buckets.map((bucket) => tx.get(bucket)));
      const publicSnap = termId ? await tx.get(db.collection('DictionaryEntries').doc(termId)) : null;

      let resolvedBaseRevision = raw.baseRevision ?? null;
      let resolvedBaseFields = clientBaseFields;
      if (termId) {
        const seedMatch = seed.find((item) => item.id === termId || item.slug === termId) || null;
        const liveData = publicSnap?.exists ? publicSnap.data() : seedMatch;
        const livePubRev = effectivePublishedRevision(publicSnap);
        if (resolvedBaseRevision == null) resolvedBaseRevision = livePubRev;
        if (liveData && (resolvedBaseRevision === livePubRev || !resolvedBaseFields)) {
          resolvedBaseFields = extractStructuredFields(liveData);
        }
      }
      const changedFields = proposedFields ? computeChangedFields(resolvedBaseFields, proposedFields) : [];
      if (proposedFields && changedFields.length === 0) {
        throw new HttpsError('invalid-argument', 'Modify at least one field before submitting.');
      }
      const proposal = rawProposal || summarizeStructuredProposal(changedFields, reason);

      if (existing.exists) {
        // A retry is accepted only for the same private submission identity and content.
        const data = existing.data();
        if (data.requestKey === digest(ip) && data.term === term && data.proposal === proposal) return;
        throw new HttpsError('already-exists', 'Submission ID already used.');
      }
      if (limits.some((limit) => (limit.data()?.count || 0) >= 5)) {
        throw new HttpsError('resource-exhausted', 'Please try again tomorrow.');
      }
      for (let i = 0; i < buckets.length; i++) {
        tx.set(buckets[i], {count: (limits[i].data()?.count || 0) + 1, expiresAt: new Date(at + 172800000)});
      }
      const record = {
        term, proposal, kind, recognitionConsent, publicName,
        termId,
        contributorUid: request.auth?.uid || null,
        requestKey: digest(ip), status: 'submitted', createdAt: new Date(at),
      };
      if (reason) record.reason = reason;
      if (resolvedBaseRevision != null) record.baseRevision = resolvedBaseRevision;
      if (resolvedBaseFields) record.baseFields = resolvedBaseFields;
      if (proposedFields) {
        record.proposedFields = proposedFields;
        record.changedFields = changedFields;
      }
      tx.create(ref, record);
    });
    return {id: ref.id, status: 'submitted'};
  };
}

function parseFirebaseStorageUrl(rawUrl) {
  try {
    const parsed = new URL(rawUrl);
    if (parsed.protocol !== 'https:' || parsed.hostname !== 'firebasestorage.googleapis.com') {
      return null;
    }
    const match = parsed.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
    if (!match) return null;
    const bucketName = decodeURIComponent(match[1]);
    const objectPath = decodeURIComponent(match[2]);
    if (!bucketName || !objectPath || objectPath.includes('..') || objectPath.startsWith('/')) {
      return {invalid: true};
    }
    return {bucketName, objectPath};
  } catch (_) {
    return null;
  }
}

function extractDraftStoragePath(rawUrl) {
  const parsed = parseFirebaseStorageUrl(rawUrl);
  if (!parsed || parsed.invalid) return null;
  return parsed.objectPath.startsWith('dictionary_drafts/') ? parsed.objectPath : null;
}

async function validateMediaOwnership(media, entryId, bucket, {checkDraftExists = false} = {}) {
  if (!Array.isArray(media) || media.length === 0) return;
  for (const item of media) {
    const parsed = parseFirebaseStorageUrl(item.url);
    if (!parsed) continue;
    if (parsed.invalid) {
      throw new HttpsError('invalid-argument', 'Malformed Firebase Storage media URL.');
    }
    const {bucketName, objectPath} = parsed;
    if (!bucket) {
      if (objectPath.startsWith('dictionary_drafts/')) {
        throw new HttpsError(
            'failed-precondition',
            'Draft images must be promoted to public storage before publishing.',
        );
      }
      continue;
    }
    if (bucketName !== bucket.name) {
      throw new HttpsError('invalid-argument', 'Media image belongs to an unexpected storage bucket.');
    }
    if (objectPath.startsWith('dictionary_drafts/')) {
      const draftMatch = objectPath.match(/^dictionary_drafts\/([a-z0-9-]+)\/([A-Za-z0-9._-]+)$/);
      if (!draftMatch || draftMatch[1] !== entryId) {
        throw new HttpsError('invalid-argument', 'Draft image does not belong to this Dictionary entry.');
      }
      if (checkDraftExists) {
        const srcFile = bucket.file(objectPath);
        const [exists] = await srcFile.exists();
        if (!exists) {
          throw new HttpsError('failed-precondition', 'Referenced draft image does not exist.');
        }
        const [srcMeta] = await srcFile.getMetadata();
        if (!ALLOWED_IMAGE_TYPES.has(srcMeta?.contentType)) {
          throw new HttpsError('invalid-argument', 'Draft image must be PNG, JPEG, or WebP.');
        }
      }
    } else if (objectPath.startsWith('dictionary_public/')) {
      const publicMatch = objectPath.match(/^dictionary_public\/([a-z0-9-]+)\/([A-Za-z0-9._-]+)$/);
      if (!publicMatch || publicMatch[1] !== entryId) {
        throw new HttpsError('invalid-argument', 'Public image does not belong to this Dictionary entry.');
      }
    } else {
      throw new HttpsError('invalid-argument', 'Dictionary media cannot reference unrelated storage folders.');
    }
  }
}

async function promoteDraftMedia(media, entryId, bucket) {
  if (!Array.isArray(media) || media.length === 0) return {media: [], promotedFiles: []};
  await validateMediaOwnership(media, entryId, bucket, {checkDraftExists: true});
  const promoted = [];
  const promotedFiles = [];
  for (const item of media) {
    const parsed = parseFirebaseStorageUrl(item.url);
    if (!parsed || !parsed.objectPath.startsWith('dictionary_drafts/')) {
      promoted.push(item);
      continue;
    }
    const srcFile = bucket.file(parsed.objectPath);
    const [srcMeta] = await srcFile.getMetadata();
    const ext = IMAGE_EXT_BY_TYPE[srcMeta?.contentType];
    if (!ext) {
      throw new HttpsError('invalid-argument', 'Draft image must be PNG, JPEG, or WebP.');
    }
    // Always generate a unique, immutable public filename so concurrent or failed
    // publications can never overwrite an existing published image.
    const publicPath = `dictionary_public/${entryId}/${randomUUID()}.${ext}`;
    const destFile = bucket.file(publicPath);
    await srcFile.copy(destFile);
    promotedFiles.push(destFile);
    const token = randomUUID();
    await destFile.setMetadata({
      contentType: srcMeta.contentType,
      cacheControl: 'public, max-age=31536000, immutable',
      metadata: {firebaseStorageDownloadTokens: token},
    });
    const publicUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(publicPath)}?alt=media&token=${token}`;
    promoted.push({url: publicUrl, label: item.label});
  }
  return {media: promoted, promotedFiles};
}

async function cleanupEntryDraftMedia(entryId, keepMedia, bucket) {
  if (!bucket || typeof bucket.getFiles !== 'function') return;
  const keepPaths = new Set(
      (keepMedia || [])
          .map((item) => extractDraftStoragePath(item?.url))
          .filter(Boolean),
  );
  const [files] = await bucket.getFiles({prefix: `dictionary_drafts/${entryId}/`});
  await Promise.allSettled(
      files
          .filter((file) => !keepPaths.has(file.name))
          .map((file) => file.delete()),
  );
}

async function cleanupAbandonedDraftMedia(
    db,
    bucket,
    {maxAgeMs = 7 * 24 * 60 * 60 * 1000, now = () => Date.now()} = {},
) {
  if (!bucket || typeof bucket.getFiles !== 'function') return {deleted: []};
  const [draftSnap, publicSnap, [files]] = await Promise.all([
    db.collection('DictionaryDrafts').get(),
    db.collection('DictionaryEntries').get(),
    bucket.getFiles({prefix: 'dictionary_drafts/'}),
  ]);
  const referencedPaths = new Set();
  for (const doc of [...draftSnap.docs, ...publicSnap.docs]) {
    const data = doc.data() || {};
    for (const item of (Array.isArray(data.media) ? data.media : [])) {
      const path = extractDraftStoragePath(item?.url);
      if (path) referencedPaths.add(path);
    }
  }
  const cutoff = now() - maxAgeMs;
  const deleted = [];
  for (const file of files) {
    if (referencedPaths.has(file.name)) continue;
    const createdAt = Date.parse(file.metadata?.timeCreated || '');
    if (Number.isFinite(createdAt) && createdAt > cutoff) continue;
    await file.delete();
    deleted.push(file.name);
  }
  return {deleted};
}

function editDictionary(db, {now = () => new Date(), bucket = null} = {}) {
  return async (request) => {
    requireAdmin(request);
    const raw = request.data || {};
    const action = raw.action;
    const at = now();
    const id = text(raw.id, 100, 'id', true);
    if (!/^[A-Za-z0-9-]+$/.test(id)) throw new HttpsError('invalid-argument', 'Invalid ID.');
    if (action === 'review') {
      const editedFields = validateStructuredFields(
          raw.editedFields,
          'edited fields',
          {requireDefinition: raw.editedFields != null && raw.editedFields.definition != null},
      );
      const editedProposal = raw.editedProposal != null ? text(raw.editedProposal, 4000, 'proposal', true) : null;
      const ref = db.collection('DictionarySuggestions').doc(id);
      let nextStatus = null;
      await db.runTransaction(async (tx) => {
        const snapshot = await tx.get(ref);
        if (!snapshot.exists) throw new HttpsError('not-found', 'Suggestion not found.');
        const current = snapshot.data();
        if (current.status === 'published') {
          throw new HttpsError('failed-precondition', 'Published suggestions are immutable.');
        }
        const status = raw.status != null ? raw.status : current.status;
        if (!STATUSES.includes(status) || status === 'published') {
          throw new HttpsError('invalid-argument', 'Invalid review status.');
        }
        nextStatus = status;
        const patch = {status, updatedAt: at};
        if (editedFields) {
          if (!current.originalProposedFields && current.proposedFields) {
            patch.originalProposedFields = current.proposedFields;
          }
          if (!current.originalProposal) patch.originalProposal = current.proposal;
          const changedFields = computeChangedFields(current.baseFields, editedFields);
          patch.proposedFields = editedFields;
          patch.changedFields = changedFields;
          patch.proposal = editedProposal || summarizeStructuredProposal(changedFields, current.reason || '');
          patch.editedByAdminUid = request.auth.uid;
          patch.editedByAdminAt = at;
        } else if (editedProposal) {
          if (!current.originalProposal) patch.originalProposal = current.proposal;
          patch.proposal = editedProposal;
          patch.editedByAdminUid = request.auth.uid;
          patch.editedByAdminAt = at;
        }
        tx.update(ref, patch);
        tx.create(ref.collection('AuditEvents').doc(), {
          status,
          note: text(raw.note, 2000, 'review note'),
          proposalEdited: Boolean(editedFields || editedProposal),
          at,
          actorUid: request.auth.uid,
        });
      });
      return {id, status: nextStatus};
    }
    if (!['save', 'publish'].includes(action)) throw new HttpsError('invalid-argument', 'Invalid action.');
    const entry = validateEntry(raw.entry);
    if (entry.id !== id) throw new HttpsError('invalid-argument', 'ID mismatch.');
    let promotedFiles = [];
    if (action === 'publish') {
      const promotion = await promoteDraftMedia(entry.media, id, bucket);
      entry.media = promotion.media;
      promotedFiles = promotion.promotedFiles;
    } else {
      await validateMediaOwnership(entry.media, id, bucket, {checkDraftExists: Boolean(bucket)});
    }
    const draft = db.collection('DictionaryDrafts').doc(id);
    const publicRef = db.collection('DictionaryEntries').doc(entry.slug);
    const suggestionId = text(raw.suggestionId, 100, 'suggestion ID');
    if (suggestionId && !/^[a-zA-Z0-9-]{16,100}$/.test(suggestionId)) {
      throw new HttpsError('invalid-argument', 'Invalid suggestion ID.');
    }
    try {
      await db.runTransaction(async (tx) => {
        const manifestRef = db.collection('DictionaryPublic').doc('catalogue');
        const manifest = await tx.get(manifestRef);
        const seedSnapshots = action === 'publish' && !manifest.exists ?
        await Promise.all(seed.map((item) => tx.get(db.collection('DictionaryEntries').doc(item.slug)))) : [];
        const currentDraft = await tx.get(draft);
        const currentPublic = await tx.get(publicRef);
        const sourceId = suggestionId || currentDraft.data()?.suggestionId || null;
        const suggestion = sourceId ? db.collection('DictionarySuggestions').doc(sourceId) : null;
        const contribution = suggestion ? await tx.get(suggestion) : null;
        const revision = currentDraft.data()?.revision || currentPublic.data()?.revision || 0;
        if (raw.expectedRevision !== revision) {
          throw new HttpsError('aborted', 'This entry changed. Reload before saving.');
        }
        if (currentDraft.exists && currentDraft.data().slug !== entry.slug) {
          throw new HttpsError('failed-precondition', 'Published URLs and draft slugs are stable.');
        }
        if (currentPublic.exists && currentPublic.data().id !== id) {
          throw new HttpsError('already-exists', 'This slug belongs to another meaning.');
        }
        if (suggestion && !contribution.exists) throw new HttpsError('not-found', 'Suggestion not found.');
        if (contribution && contribution.exists) {
          const contribData = contribution.data();
          const publishedRev = effectivePublishedRevision(currentPublic);
          const liveSnapshot = currentPublic.exists ? extractStructuredFields(currentPublic.data()) : null;
          const baseMismatch = typeof contribData.baseRevision === 'number' && publishedRev !== contribData.baseRevision;
          const snapshotMismatch = Boolean(
              contribData.baseFields &&
            liveSnapshot &&
            computeChangedFields(contribData.baseFields, liveSnapshot).length > 0,
          );
          const previouslyAcked = currentDraft.data()?.acknowledgedPublishedRevision === publishedRev &&
          currentDraft.data()?.suggestionId === sourceId;
          if ((baseMismatch || snapshotMismatch) && raw.acknowledgeRevisionMismatch !== true && !previouslyAcked) {
            throw new HttpsError(
                'failed-precondition',
                'Published definition changed since this suggestion was submitted. Review old, current, and proposed wording before applying.',
            );
          }
        }
        if (action === 'publish' && contribution && contribution.data().status !== 'approved') {
          throw new HttpsError('failed-precondition', 'Approve the contribution before publishing.');
        }
        const nextRevision = revision + 1;
        const publishedRev = effectivePublishedRevision(currentPublic);
        const editor = {updatedAt: at, updatedByUid: request.auth.uid};
        const data = {
          ...entry, revision: nextRevision, status: action === 'publish' ? 'published' : 'draft', ...editor,
          suggestionId: action === 'publish' ? null : sourceId,
          ...(raw.acknowledgeRevisionMismatch === true && sourceId ?
            {acknowledgedPublishedRevision: publishedRev} : {}),
        };
        tx.set(draft, data);
        tx.create(draft.collection('Revisions').doc(String(nextRevision)), data);
        if (action === 'publish') {
        // Whitelist public fields. Never spread a private suggestion or draft into public data.
          for (let index = 0; index < seedSnapshots.length; index++) {
            if (!seedSnapshots[index].exists && seed[index].slug !== entry.slug) {
              tx.create(db.collection('DictionaryEntries').doc(seed[index].slug), seed[index]);
            }
          }
          const credit = contribution?.data();
          const publicName = credit?.recognitionConsent === true ? safePublicContributorName(credit.publicName) : null;
          const priorNames = currentPublic.data()?.attributions || [];
          const attributions = [...new Set([...priorNames, ...(publicName ? [publicName] : [])])];
          tx.set(publicRef, {...entry, revision: nextRevision, status: 'published', publishedAt: at, attributions});
          tx.set(db.collection('DictionaryPublic').doc('catalogue'), {initialized: true});
          if (suggestion) {
            tx.update(suggestion, {status: 'published', entryId: id, updatedAt: at});
            tx.create(suggestion.collection('AuditEvents').doc(), {status: 'published', at, actorUid: request.auth.uid});
          }
        }
      });
    } catch (error) {
      if (promotedFiles.length > 0) {
        await Promise.allSettled(promotedFiles.map((file) => file.delete()));
      }
      throw error;
    }
    if (action === 'publish') {
      await cleanupEntryDraftMedia(id, entry.media, bucket).catch(() => {});
    }
    return {id, status: action === 'publish' ? 'published' : 'draft'};
  };
}

async function publicEntry(db, slug) {
  if (!SLUG.test(slug)) return null;
  const snapshot = await db.collection('DictionaryEntries').doc(slug).get();
  if (snapshot.exists) return snapshot.data().status === 'published' ? snapshot.data() : null;
  const manifest = await db.collection('DictionaryPublic').doc('catalogue').get();
  if (manifest.exists) {
    const aliases = await db.collection('DictionaryEntries').where('synonyms', 'array-contains', slug).limit(2).get();
    const matches = aliases.docs.map((doc) => doc.data()).filter((entry) => entry.status === 'published');
    return matches.length === 1 ? matches[0] : null;
  }
  const matches = seed.filter((entry) => entry.slug === slug || entry.synonyms.includes(slug));
  return matches.length === 1 ? matches[0] : null;
}

module.exports = {
  validateEntry, validateStructuredFields, extractStructuredFields, computeChangedFields,
  effectivePublishedRevision, parseFirebaseStorageUrl, extractDraftStoragePath,
  validateMediaOwnership, promoteDraftMedia, cleanupAbandonedDraftMedia,
  requireAdmin, submitDictionarySuggestion, editDictionary, publicEntry,
  dictionaryEmulator: process.env.FUNCTIONS_EMULATOR === 'true',
};
