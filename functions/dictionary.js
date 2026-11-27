/* eslint-disable require-jsdoc */
'use strict';

const {createHmac, randomUUID} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {safePublicContributorName} = require('./suggestions');
const seed = require('./dictionary_seed.json');

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const KINDS = [
  'new_term',
  'missing_term',
  'definition',
  'correction',
  'improvement',
  'regional_usage',
  'related_term',
  'image_contribution',
];
const STATUSES = [
  'submitted',
  'under_review',
  'needs_clarification',
  'partially_approved',
  'approved',
  'rejected',
  'published',
];
const EMAIL_PATTERN = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i;
const ALLOWED_IMAGE_TYPES = new Set(['image/png', 'image/jpeg', 'image/webp']);
const IMAGE_TYPES = new Set(['illustrative', 'photograph', 'diagram']);
const IMAGE_DECISIONS = new Set(['pending', 'approved', 'rejected']);
const TEXT_DECISIONS = new Set(['pending', 'approved', 'rejected']);
const MAX_SUBMITTED_IMAGES = 3;
const MAX_DICTIONARY_IMAGE_BYTES = 10 * 1024 * 1024;
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
      if (!item || typeof item !== 'object') {
        throw new HttpsError('invalid-argument', 'Invalid media item.');
      }
      const url = text(item.url, 2048, 'media URL', true);
      if (!/^https:\/\//.test(url)) throw new HttpsError('invalid-argument', 'HTTPS media required.');
      const imageType = item.imageType ? text(item.imageType, 24, 'image type') : 'illustrative';
      if (!IMAGE_TYPES.has(imageType)) {
        throw new HttpsError('invalid-argument', 'Invalid image type.');
      }
      const explanation = text(item.explanation, 600, 'image explanation');
      const attribution = item.attribution ? safePublicContributorName(item.attribution) : null;
      if (item.attribution && !attribution) {
        throw new HttpsError('invalid-argument', 'Invalid image attribution.');
      }
      const normalized = {url, label: text(item.label, 120, 'media label', true)};
      if (imageType !== 'illustrative') normalized.imageType = imageType;
      if (explanation) normalized.explanation = explanation;
      if (attribution) normalized.attribution = attribution;
      return normalized;
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

function parseSubmissionStoragePath(rawUrl, expectedUid = null, expectedSubmissionId = null) {
  const parsed = parseFirebaseStorageUrl(rawUrl);
  if (!parsed || parsed.invalid) return null;
  const match = parsed.objectPath.match(/^dictionary_submissions\/([^/]+)\/([A-Za-z0-9-]+)\/([A-Za-z0-9._-]+)$/);
  if (!match) return null;
  const [, uid, submissionId] = match;
  if (expectedUid && uid !== expectedUid) return null;
  if (expectedSubmissionId && submissionId !== expectedSubmissionId) return null;
  return {bucketName: parsed.bucketName, objectPath: parsed.objectPath, uid, submissionId};
}

function profileId(email) {
  return email.replaceAll('.', '666').replaceAll('@', '999')
      .replaceAll('f', '5').replaceAll('e', '1').replaceAll('g', '2')
      .replaceAll('m', '').replaceAll('a', 'p').replaceAll('i', 'a')
      .replaceAll('co', 'l');
}

function safeSnapshotDisplayName(rawName) {
  if (typeof rawName !== 'string') return null;
  const trimmed = rawName.trim();
  if (!trimmed || trimmed.length > 80) return null;
  return trimmed;
}

function safeSnapshotEmail(rawEmail) {
  if (typeof rawEmail !== 'string') return null;
  const trimmed = rawEmail.trim();
  if (!trimmed || trimmed.length > 254 || !trimmed.includes('@')) return null;
  return trimmed;
}

function safePublicAttributionName(rawName, uid = null) {
  const safe = safePublicContributorName(rawName);
  if (!safe) return null;
  if (safe.toLowerCase() === 'guest') return null;
  if (uid && safe === uid) return null;
  return safe;
}

function extractContributorProfileFields(snap, uid) {
  if (!snap || !snap.exists) return null;
  const data = typeof snap.data === 'function' ? snap.data() : null;
  if (!data || typeof data !== 'object') return null;
  if (data.ownerUid && uid && data.ownerUid !== uid) return null;
  return {
    name: safeSnapshotDisplayName(data.name),
    email: safeSnapshotEmail(data.email),
  };
}

async function lookupRiderProfileForContributor(db, {uid, email} = {}) {
  if (!db || typeof db.collection !== 'function') return {name: null, email: null};
  const profilesCol = db.collection('Rider_Profile');
  if (email) {
    try {
      const directSnap = await profilesCol.doc(profileId(email.toLowerCase())).get();
      const extracted = extractContributorProfileFields(directSnap, uid);
      if (extracted) return extracted;
    } catch (_) {
      // Ignore profile lookup errors; fallback below may still resolve.
    }
  }
  if (uid && typeof profilesCol.where === 'function') {
    try {
      const qs = await profilesCol.where('ownerUid', '==', uid).limit(1).get();
      const doc = Array.isArray(qs?.docs) ? qs.docs[0] : null;
      const extracted = extractContributorProfileFields(doc ? {...doc, exists: true} : null, uid);
      if (extracted) return extracted;
    } catch (_) {
      // Ignore missing index/query support in partial mocks.
    }
  }
  return {name: null, email: null};
}

async function resolveContributorIdentity(db, auth, {uid, token} = {}) {
  const tokenEmail = safeSnapshotEmail(token?.email);
  const tokenDisplayName = safeSnapshotDisplayName(token?.name);
  let profile = await lookupRiderProfileForContributor(db, {uid, email: tokenEmail});
  let authEmail = null;
  let authDisplayName = null;

  if (auth && typeof auth.getUser === 'function' && uid && (!tokenEmail || (!profile.name && !tokenDisplayName))) {
    try {
      const userRecord = await auth.getUser(uid);
      authEmail = safeSnapshotEmail(userRecord?.email);
      authDisplayName = safeSnapshotDisplayName(userRecord?.displayName);
      if (!profile.name && authEmail && authEmail.toLowerCase() !== (tokenEmail || '').toLowerCase()) {
        const directSnap = await db.collection('Rider_Profile').doc(profileId(authEmail.toLowerCase())).get();
        const extracted = extractContributorProfileFields(directSnap, uid);
        if (extracted) profile = extracted;
      }
    } catch (_) {
      // Ignore auth/user-not-found or transient errors cleanly.
    }
  }

  const displayName = profile.name || tokenDisplayName || authDisplayName || null;
  const email = tokenEmail || authEmail || profile.email || null;
  const source = profile.name ? 'profile' : ((tokenDisplayName || authDisplayName) ? 'auth' : 'none');
  return {uid, displayName, email, source};
}

function safeAttributionList(rawAttributions, uid = null) {
  if (!Array.isArray(rawAttributions) || rawAttributions.length > 50) {
    throw new HttpsError('invalid-argument', 'Invalid attributions list.');
  }
  const cleaned = [];
  const seen = new Set();
  for (const item of rawAttributions) {
    const safe = safePublicAttributionName(item, uid);
    if (!safe) {
      throw new HttpsError('invalid-argument', 'Public attributions must not contain emails, UIDs, or blanks.');
    }
    if (!seen.has(safe)) {
      seen.add(safe);
      cleaned.push(safe);
    }
  }
  return cleaned;
}

function summarizeSubmittedMediaProposal(submittedImages, reason) {
  const count = submittedImages.length;
  const base = count === 1 ? 'Submitted 1 educational image.' : `Submitted ${count} educational images.`;
  return reason ? `${base} Note: ${reason}` : base;
}

function submitDictionarySuggestion(
    db,
    {secret, now = () => Date.now(), requireAppCheck = true, bucket = null, auth = null} = {},
) {
  return async (request) => {
    if (requireAppCheck && !request.app) throw new HttpsError('unauthenticated', 'App verification required.');
    if (!request.auth || !request.auth.uid || request.auth.token?.email_verified !== true) {
      throw new HttpsError(
          'unauthenticated',
          'Sign in with a verified email address to contribute to the Dictionary.',
      );
    }
    const uid = request.auth.uid;
    const raw = request.data || {};
    if (raw.website) throw new HttpsError('invalid-argument', 'Invalid submission.');
    const term = text(raw.term, 120, 'term', true);
    const kind = raw.kind;
    if (!KINDS.includes(kind)) throw new HttpsError('invalid-argument', 'Invalid contribution type.');
    const termId = text(raw.termId, 100, 'term ID');
    if (termId && !SLUG.test(termId)) throw new HttpsError('invalid-argument', 'Invalid term ID.');
    if (kind === 'image_contribution' && !termId) {
      throw new HttpsError('invalid-argument', 'Target term ID is required for image contributions.');
    }
    const reason = text(raw.reason, 2000, 'reason');
    const requireDef = Boolean(
        (termId && raw.proposedFields != null) || (kind === 'new_term' && raw.proposedFields != null),
    );
    const proposedFields = validateStructuredFields(
        raw.proposedFields,
        'proposed fields',
        {requireDefinition: requireDef},
    );
    const categories = raw.categories == null ? [] : strings(raw.categories, 'categories', 6);
    const clientBaseFields = validateStructuredFields(raw.baseFields, 'base fields');
    if (raw.baseRevision != null && (!Number.isInteger(raw.baseRevision) || raw.baseRevision < 0)) {
      throw new HttpsError('invalid-argument', 'Invalid base revision.');
    }
    const submissionId = text(raw.submissionId, 64, 'submission ID', true);
    if (!/^[a-zA-Z0-9-]{16,64}$/.test(submissionId)) {
      throw new HttpsError('invalid-argument', 'Invalid submission ID.');
    }
    const rawImages = raw.submittedImages == null ? [] : raw.submittedImages;
    if (!Array.isArray(rawImages) || rawImages.length > MAX_SUBMITTED_IMAGES) {
      throw new HttpsError(
          'invalid-argument',
          `You may attach at most ${MAX_SUBMITTED_IMAGES} images per submission.`,
      );
    }
    if (kind === 'image_contribution' && rawImages.length === 0) {
      throw new HttpsError('invalid-argument', 'Attach at least one image to contribute.');
    }
    const rightsConfirmed = raw.rightsConfirmed === true;
    if (rawImages.length > 0 && !rightsConfirmed) {
      throw new HttpsError(
          'invalid-argument',
          'Confirm contributor rights and display permission before submitting images.',
      );
    }
    const submittedImages = [];
    const seenPaths = new Set();
    const seenHashes = new Set();
    for (const img of rawImages) {
      if (!img || typeof img !== 'object' || Array.isArray(img)) {
        throw new HttpsError('invalid-argument', 'Invalid submitted image.');
      }
      const imgId = text(img.id, 64, 'image ID', true);
      if (!/^[A-Za-z0-9_-]{4,64}$/.test(imgId)) {
        throw new HttpsError('invalid-argument', 'Invalid image ID.');
      }
      const url = text(img.url, 2048, 'image URL', true);
      const parsedPath = parseSubmissionStoragePath(url, uid, submissionId);
      if (!parsedPath) {
        throw new HttpsError(
            'invalid-argument',
            'Submitted images must come from your own private contribution upload.',
        );
      }
      if (bucket && parsedPath.bucketName !== bucket.name) {
        throw new HttpsError('invalid-argument', 'Submitted image belongs to an unexpected storage bucket.');
      }
      if (bucket) {
        const file = bucket.file(parsedPath.objectPath);
        const [exists] = await file.exists();
        if (!exists) {
          throw new HttpsError('failed-precondition', 'Uploaded submission image does not exist.');
        }
        const [meta] = await file.getMetadata();
        if (!ALLOWED_IMAGE_TYPES.has(meta?.contentType)) {
          throw new HttpsError('invalid-argument', 'Submitted image must be PNG, JPEG, or WebP.');
        }
        const size = Number(meta?.size || 0);
        if (!Number.isFinite(size) || size <= 0 || size > MAX_DICTIONARY_IMAGE_BYTES) {
          throw new HttpsError('invalid-argument', 'Submitted image exceeds 10 MB limit.');
        }
      }
      const caption = text(img.caption, 120, 'image caption');
      const explanation = text(img.explanation, 600, 'image explanation');
      const imageType = img.imageType ? text(img.imageType, 24, 'image type') : 'illustrative';
      if (!IMAGE_TYPES.has(imageType)) {
        throw new HttpsError('invalid-argument', 'Invalid image type.');
      }
      const sha256 = text(img.sha256, 64, 'image checksum').toLowerCase();
      if (sha256 && !/^[a-f0-9]{64}$/.test(sha256)) {
        throw new HttpsError('invalid-argument', 'Invalid image checksum.');
      }
      if (EMAIL_PATTERN.test(`${caption} ${explanation}`)) {
        throw new HttpsError('invalid-argument', 'Image captions and explanations must not contain email addresses.');
      }
      if (seenPaths.has(parsedPath.objectPath) || (sha256 && seenHashes.has(sha256))) {
        continue;
      }
      seenPaths.add(parsedPath.objectPath);
      if (sha256) seenHashes.add(sha256);
      const item = {
        id: imgId,
        url,
        storagePath: parsedPath.objectPath,
        caption,
        explanation,
        imageType,
        reviewStatus: 'pending',
      };
      if (sha256) item.sha256 = sha256;
      submittedImages.push(item);
    }

    const proposalRequired = !proposedFields && submittedImages.length === 0;
    const rawProposal = text(raw.proposal, 4000, 'proposal', proposalRequired);
    if (EMAIL_PATTERN.test(`${term} ${rawProposal} ${reason} ${categories.join(' ')}`)) {
      throw new HttpsError('invalid-argument', 'Public contributions must not contain email addresses.');
    }
    const recognitionConsent = raw.recognitionConsent === true;
    if (!secret) throw new HttpsError('failed-precondition', 'Submission protection is not configured.');
    const identity = await resolveContributorIdentity(db, auth, {uid, token: request.auth.token});
    const serverPublicName = safePublicAttributionName(identity.displayName, uid);
    let publicName = null;
    if (recognitionConsent) {
      if (serverPublicName) {
        publicName = serverPublicName;
      } else if (raw.publicName != null && String(raw.publicName).trim() !== '') {
        const fallbackName = safePublicAttributionName(raw.publicName, uid);
        if (!fallbackName) {
          throw new HttpsError(
              'invalid-argument',
              'Public attribution name must be a display name without an email address.',
          );
        }
        publicName = fallbackName;
      }
    }
    const at = now();
    const ip = request.rawRequest?.ip || '';
    if (!ip) throw new HttpsError('invalid-argument', 'Missing request address.');
    // Daily keyed hashes avoid storing IP addresses and rotate limiter identities.
    const day = Math.floor(at / 86400000);
    const digest = (value) => createHmac('sha256', secret).update(day + ':' + value).digest('hex');
    const buckets = [
      db.collection('DictionaryRateLimits').doc(digest('ip:' + ip)),
      db.collection('DictionaryRateLimits').doc(digest(uid)),
    ];
    const ref = db.collection('DictionarySuggestions').doc(submissionId);
    const modRef = db.collection('DictionaryContributorModeration').doc(uid);
    await db.runTransaction(async (tx) => {
      const moderationSnap = await tx.get(modRef);
      if (moderationSnap.exists && moderationSnap.data()?.suspended === true) {
        throw new HttpsError(
            'permission-denied',
            'Your Dictionary contribution privileges are currently suspended.',
        );
      }
      const existing = await tx.get(ref);
      const limits = await Promise.all(buckets.map((limitDoc) => tx.get(limitDoc)));
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
      const changedFields = termId && proposedFields ?
        computeChangedFields(resolvedBaseFields, proposedFields) :
        [];
      if (termId && proposedFields && changedFields.length === 0 && submittedImages.length === 0) {
        throw new HttpsError('invalid-argument', 'Modify at least one field or attach an image before submitting.');
      }
      let proposal = rawProposal;
      if (!proposal) {
        if (kind === 'image_contribution') {
          proposal = summarizeSubmittedMediaProposal(submittedImages, reason);
        } else if (kind === 'new_term' && proposedFields?.definition) {
          proposal = proposedFields.definition;
        } else {
          proposal = summarizeStructuredProposal(changedFields, reason);
        }
      }

      if (existing.exists) {
        // A retry is accepted only for the same private submission identity and content.
        const data = existing.data();
        if (data.contributorUid === uid && data.term === term && data.proposal === proposal) return;
        throw new HttpsError('already-exists', 'Submission ID already used.');
      }
      if (limits.some((limit) => (limit.data()?.count || 0) >= 5)) {
        throw new HttpsError('resource-exhausted', 'Please try again tomorrow.');
      }
      for (let i = 0; i < buckets.length; i++) {
        tx.set(buckets[i], {count: (limits[i].data()?.count || 0) + 1, expiresAt: new Date(at + 172800000)});
      }
      const createdDate = new Date(at);
      const record = {
        term, proposal, kind, recognitionConsent, publicName,
        termId,
        contributorUid: uid,
        contributorSnapshot: {
          displayName: identity.displayName,
          email: identity.email,
          source: identity.source,
          capturedAt: createdDate,
        },
        requestKey: digest(ip),
        status: 'submitted',
        textDecision: kind === 'image_contribution' ? 'rejected' : 'pending',
        rightsConfirmed,
        createdAt: createdDate,
      };
      if (reason) record.reason = reason;
      if (categories.length > 0) record.categories = categories;
      if (submittedImages.length > 0) record.submittedImages = submittedImages;
      if (resolvedBaseRevision != null) record.baseRevision = resolvedBaseRevision;
      if (resolvedBaseFields) record.baseFields = resolvedBaseFields;
      if (proposedFields) {
        record.proposedFields = proposedFields;
        if (changedFields.length > 0) record.changedFields = changedFields;
      }
      tx.create(ref, record);
    });
    return {id: ref.id, status: 'submitted', imageCount: submittedImages.length};
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

function approvedSubmissionPathMap(suggestionData) {
  const approved = new Map();
  if (!suggestionData || !Array.isArray(suggestionData.submittedImages)) return approved;
  for (const img of suggestionData.submittedImages) {
    if (img && img.reviewStatus === 'approved' && img.storagePath) {
      approved.set(img.storagePath, img);
    }
  }
  return approved;
}

async function deleteStoragePathsSafely(bucket, paths) {
  if (!bucket || !Array.isArray(paths) || paths.length === 0) return;
  await Promise.allSettled(
      paths.map(async (objectPath) => {
        try {
          await bucket.file(objectPath).delete();
        } catch (_) {
          // Already deleted or unavailable; ignore during best-effort cleanup.
        }
      }),
  );
}

async function validateMediaOwnership(
    media,
    entryId,
    bucket,
    {checkDraftExists = false, approvedSubmissionPaths = new Map()} = {},
) {
  if (!Array.isArray(media) || media.length === 0) return;
  for (const item of media) {
    const parsed = parseFirebaseStorageUrl(item.url);
    if (!parsed) continue;
    if (parsed.invalid) {
      throw new HttpsError('invalid-argument', 'Malformed Firebase Storage media URL.');
    }
    const {bucketName, objectPath} = parsed;
    if (!bucket) {
      if (objectPath.startsWith('dictionary_drafts/') || objectPath.startsWith('dictionary_submissions/')) {
        throw new HttpsError(
            'failed-precondition',
            'Draft and submitted images must be promoted to public storage before publishing.',
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
    } else if (objectPath.startsWith('dictionary_submissions/')) {
      if (!approvedSubmissionPaths.has(objectPath)) {
        throw new HttpsError(
            'failed-precondition',
            'Submitted images must be individually approved before publishing.',
        );
      }
      if (checkDraftExists) {
        const srcFile = bucket.file(objectPath);
        const [exists] = await srcFile.exists();
        if (!exists) {
          throw new HttpsError('failed-precondition', 'Approved submission image does not exist.');
        }
        const [srcMeta] = await srcFile.getMetadata();
        if (!ALLOWED_IMAGE_TYPES.has(srcMeta?.contentType)) {
          throw new HttpsError('invalid-argument', 'Submitted image must be PNG, JPEG, or WebP.');
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

async function promoteDraftMedia(
    media,
    entryId,
    bucket,
    {approvedSubmissionPaths = new Map(), contributorCredit = null} = {},
) {
  if (!Array.isArray(media) || media.length === 0) return {media: [], promotedFiles: []};
  await validateMediaOwnership(media, entryId, bucket, {
    checkDraftExists: true,
    approvedSubmissionPaths,
  });
  const promotedFiles = [];
  const tasks = media.map(async (item) => {
    const parsed = parseFirebaseStorageUrl(item.url);
    const isDraft = Boolean(parsed && parsed.objectPath.startsWith('dictionary_drafts/'));
    const isApprovedSubmission = Boolean(parsed && parsed.objectPath.startsWith('dictionary_submissions/'));
    if (!parsed || (!isDraft && !isApprovedSubmission)) {
      return item;
    }
    const srcFile = bucket.file(parsed.objectPath);
    const [srcMeta] = await srcFile.getMetadata();
    const ext = IMAGE_EXT_BY_TYPE[srcMeta?.contentType];
    if (!ext) {
      throw new HttpsError('invalid-argument', 'Uploaded image must be PNG, JPEG, or WebP.');
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
    const publishedItem = {url: publicUrl, label: item.label};
    if (item.imageType && item.imageType !== 'illustrative') {
      publishedItem.imageType = item.imageType;
    }
    if (item.explanation) {
      publishedItem.explanation = item.explanation;
    }
    if (isApprovedSubmission) {
      // Only attribute community-contributed images when explicit consent was granted.
      if (contributorCredit) {
        publishedItem.attribution = item.attribution || contributorCredit;
      }
    } else if (item.attribution) {
      publishedItem.attribution = item.attribution;
    }
    return publishedItem;
  });
  let promoted;
  try {
    promoted = await Promise.all(tasks);
  } catch (err) {
    if (promotedFiles.length > 0) {
      await Promise.allSettled(promotedFiles.map((file) => file.delete()));
    }
    throw err;
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
  const [draftSnap, publicSnap, suggestionSnap, [draftFiles], [submissionFiles]] = await Promise.all([
    db.collection('DictionaryDrafts').get(),
    db.collection('DictionaryEntries').get(),
    db.collection('DictionarySuggestions').get(),
    bucket.getFiles({prefix: 'dictionary_drafts/'}),
    bucket.getFiles({prefix: 'dictionary_submissions/'}),
  ]);
  const referencedPaths = new Set();
  for (const doc of [...draftSnap.docs, ...publicSnap.docs]) {
    const data = doc.data() || {};
    for (const item of (Array.isArray(data.media) ? data.media : [])) {
      const path = extractDraftStoragePath(item?.url);
      if (path) referencedPaths.add(path);
    }
  }
  for (const doc of suggestionSnap.docs) {
    const data = doc.data() || {};
    if (data.status === 'rejected' || data.status === 'published') continue;
    for (const img of (Array.isArray(data.submittedImages) ? data.submittedImages : [])) {
      if (img?.reviewStatus !== 'rejected' && img?.storagePath) {
        referencedPaths.add(img.storagePath);
      }
    }
  }
  const cutoff = now() - maxAgeMs;
  const deleted = [];
  for (const file of [...draftFiles, ...submissionFiles]) {
    if (referencedPaths.has(file.name)) continue;
    const createdAt = Date.parse(file.metadata?.timeCreated || '');
    if (Number.isFinite(createdAt) && createdAt > cutoff) continue;
    await file.delete();
    deleted.push(file.name);
  }
  return {deleted};
}

function normalizeImageDecisionsInput(rawDecisions) {
  if (rawDecisions == null) return null;
  const list = Array.isArray(rawDecisions) ?
    rawDecisions :
    Object.entries(rawDecisions).map(([id, value]) => ({id, ...(value || {})}));
  const byId = new Map();
  for (const decision of list) {
    if (!decision || typeof decision !== 'object') {
      throw new HttpsError('invalid-argument', 'Invalid image decision.');
    }
    const imgId = text(decision.id, 64, 'image ID', true);
    const status = text(decision.status, 24, 'image review status', true);
    if (!IMAGE_DECISIONS.has(status)) {
      throw new HttpsError('invalid-argument', 'Invalid image review status.');
    }
    const normalized = {id: imgId, status};
    if (decision.caption != null) {
      normalized.caption = text(decision.caption, 120, 'image caption');
    }
    if (decision.explanation != null) {
      normalized.explanation = text(decision.explanation, 600, 'image explanation');
    }
    if (decision.imageType != null) {
      const imgType = text(decision.imageType, 24, 'image type', true);
      if (!IMAGE_TYPES.has(imgType)) {
        throw new HttpsError('invalid-argument', 'Invalid image type.');
      }
      normalized.imageType = imgType;
    }
    if (decision.reviewNote != null) {
      normalized.reviewNote = text(decision.reviewNote, 500, 'image review note');
    }
    if (EMAIL_PATTERN.test(`${normalized.caption || ''} ${normalized.explanation || ''} ${normalized.reviewNote || ''}`)) {
      throw new HttpsError('invalid-argument', 'Image metadata must not contain email addresses.');
    }
    byId.set(imgId, normalized);
  }
  return byId;
}

async function resolveContributorsBatch(db, auth, rawUids) {
  if (!Array.isArray(rawUids) || rawUids.length > 50) {
    throw new HttpsError('invalid-argument', 'Provide up to 50 contributor UIDs.');
  }
  const uniqueUids = [];
  const seen = new Set();
  for (const rawUid of rawUids) {
    if (typeof rawUid !== 'string') continue;
    const trimmed = rawUid.trim();
    if (!trimmed || trimmed.length > 128 || seen.has(trimmed)) continue;
    seen.add(trimmed);
    uniqueUids.push(trimmed);
  }
  if (uniqueUids.length === 0) return {};

  const authByUid = new Map();
  if (auth) {
    if (typeof auth.getUsers === 'function') {
      try {
        const res = await auth.getUsers(uniqueUids.map((uid) => ({uid})));
        for (const userRecord of (res?.users || [])) {
          if (userRecord?.uid) authByUid.set(userRecord.uid, userRecord);
        }
      } catch (_) {
        // Fallback below handles partial auth lookup failures cleanly.
      }
    } else if (typeof auth.getUser === 'function') {
      const results = await Promise.allSettled(uniqueUids.map((uid) => auth.getUser(uid)));
      for (let i = 0; i < uniqueUids.length; i++) {
        if (results[i].status === 'fulfilled' && results[i].value) {
          authByUid.set(uniqueUids[i], results[i].value);
        }
      }
    }
  }

  const resolvedEntries = await Promise.all(uniqueUids.map(async (uid) => {
    const authRecord = authByUid.get(uid) || null;
    const authEmail = safeSnapshotEmail(authRecord?.email);
    const authDisplayName = safeSnapshotDisplayName(authRecord?.displayName);
    const profile = await lookupRiderProfileForContributor(db, {uid, email: authEmail});
    const displayName = profile.name || authDisplayName || null;
    const email = authEmail || profile.email || null;
    const source = profile.name ? 'profile' : (authDisplayName ? 'auth' : 'none');
    return [uid, {uid, displayName, email, source, resolved: true}];
  }));
  return Object.fromEntries(resolvedEntries);
}

function editDictionary(db, {now = () => new Date(), bucket = null, auth = null} = {}) {
  return async (request) => {
    requireAdmin(request);
    const raw = request.data || {};
    const action = raw.action;
    if (action === 'resolve_contributors') {
      const contributors = await resolveContributorsBatch(db, auth, raw.uids);
      return {contributors};
    }
    const at = now();
    if (action === 'suspend_contributor' || action === 'restore_contributor') {
      const targetUid = text(raw.uid, 128, 'contributor UID', true);
      if (targetUid.includes('/') || targetUid === '.' || targetUid === '..') {
        throw new HttpsError('invalid-argument', 'Invalid contributor UID.');
      }
      if (action === 'suspend_contributor' && targetUid === request.auth.uid) {
        throw new HttpsError(
            'failed-precondition',
            'Administrators cannot suspend their own Dictionary privileges.',
        );
      }
      const isSuspend = action === 'suspend_contributor';
      const reason = text(raw.reason, 1000, 'moderation reason', isSuspend);
      if (EMAIL_PATTERN.test(reason)) {
        throw new HttpsError('invalid-argument', 'Moderation reason must not contain email addresses.');
      }
      const modRef = db.collection('DictionaryContributorModeration').doc(targetUid);
      await db.runTransaction(async (tx) => {
        const currentSnap = await tx.get(modRef);
        const current = currentSnap.exists ? currentSnap.data() : {};
        tx.set(modRef, {
          uid: targetUid,
          suspended: isSuspend,
          status: isSuspend ? 'suspended' : 'active',
          reason,
          suspendedAt: isSuspend ? at : (current.suspendedAt || null),
          suspendedByUid: isSuspend ? request.auth.uid : (current.suspendedByUid || null),
          restoredAt: isSuspend ? (current.restoredAt || null) : at,
          restoredByUid: isSuspend ? (current.restoredByUid || null) : request.auth.uid,
          updatedAt: at,
          updatedByUid: request.auth.uid,
        });
        tx.create(modRef.collection('AuditEvents').doc(), {
          action: isSuspend ? 'suspend' : 'restore',
          suspended: isSuspend,
          reason,
          at,
          actorUid: request.auth.uid,
          targetUid,
        });
      });
      return {
        uid: targetUid,
        suspended: isSuspend,
        status: isSuspend ? 'suspended' : 'active',
      };
    }
    const id = text(raw.id, 100, 'id', true);
    if (!/^[A-Za-z0-9-]+$/.test(id)) throw new HttpsError('invalid-argument', 'Invalid ID.');
    if (action === 'review') {
      const editedFields = validateStructuredFields(
          raw.editedFields,
          'edited fields',
          {requireDefinition: raw.editedFields != null && raw.editedFields.definition != null},
      );
      const editedProposal = raw.editedProposal != null ? text(raw.editedProposal, 4000, 'proposal', true) : null;
      const requestedTextDecision = raw.textDecision != null ?
        text(raw.textDecision, 24, 'text decision', true) :
        null;
      if (requestedTextDecision && !TEXT_DECISIONS.has(requestedTextDecision)) {
        throw new HttpsError('invalid-argument', 'Invalid text decision.');
      }
      if (raw.recognitionConsent !== undefined && typeof raw.recognitionConsent !== 'boolean') {
        throw new HttpsError('invalid-argument', 'Invalid recognition consent.');
      }
      const decisionMap = normalizeImageDecisionsInput(raw.imageDecisions);
      const ref = db.collection('DictionarySuggestions').doc(id);
      let nextStatus = null;
      let pathsToDelete = [];
      await db.runTransaction(async (tx) => {
        const snapshot = await tx.get(ref);
        if (!snapshot.exists) throw new HttpsError('not-found', 'Suggestion not found.');
        const current = snapshot.data();
        if (current.status === 'published') {
          throw new HttpsError('failed-precondition', 'Published suggestions are immutable.');
        }
        const currentImages = Array.isArray(current.submittedImages) ? current.submittedImages : [];
        let updatedImages = currentImages.map((img) => ({...img}));
        if (decisionMap) {
          const validIds = new Set(currentImages.map((img) => img.id));
          for (const targetId of decisionMap.keys()) {
            if (!validIds.has(targetId)) {
              throw new HttpsError('invalid-argument', `Unknown submitted image ID: ${targetId}`);
            }
          }
          updatedImages = updatedImages.map((img) => {
            const dec = decisionMap.get(img.id);
            if (!dec) return img;
            const next = {
              ...img,
              reviewStatus: dec.status,
              reviewedAt: at,
              reviewedByUid: request.auth.uid,
            };
            if (dec.caption !== undefined) next.caption = dec.caption;
            if (dec.explanation !== undefined) next.explanation = dec.explanation;
            if (dec.imageType !== undefined) next.imageType = dec.imageType;
            if (dec.reviewNote !== undefined) next.reviewNote = dec.reviewNote;
            return next;
          });
        }
        if (raw.status === 'rejected') {
          updatedImages = updatedImages.map((img) => ({
            ...img,
            reviewStatus: 'rejected',
            reviewedAt: at,
            reviewedByUid: request.auth.uid,
          }));
        }

        const textDecision = requestedTextDecision ||
          (raw.status === 'approved' ? 'approved' : raw.status === 'rejected' ? 'rejected' : (current.textDecision || 'pending'));

        let status = raw.status != null ? raw.status : current.status;
        if (raw.status == null && (decisionMap || requestedTextDecision)) {
          const hasText = current.kind !== 'image_contribution' &&
            Boolean(current.proposedFields || current.proposal || current.kind === 'new_term');
          const allDecisions = [
            ...(hasText ? [textDecision] : []),
            ...updatedImages.map((img) => img.reviewStatus || 'pending'),
          ];
          const approvedCount = allDecisions.filter((d) => d === 'approved').length;
          const rejectedCount = allDecisions.filter((d) => d === 'rejected').length;
          if (approvedCount > 0 && approvedCount === allDecisions.length) {
            status = 'approved';
          } else if (approvedCount > 0) {
            status = 'partially_approved';
          } else if (rejectedCount > 0 && rejectedCount === allDecisions.length) {
            status = 'rejected';
          } else {
            status = 'under_review';
          }
        }
        if (!STATUSES.includes(status) || status === 'published') {
          throw new HttpsError('invalid-argument', 'Invalid review status.');
        }
        nextStatus = status;
        const patch = {
          status,
          textDecision,
          updatedAt: at,
        };
        const hasAttributionUpdate = raw.recognitionConsent !== undefined || raw.publicName !== undefined;
        if (hasAttributionUpdate) {
          const nextConsent = raw.recognitionConsent !== undefined ?
            raw.recognitionConsent === true :
            current.recognitionConsent === true;
          let nextPublicName = null;
          if (nextConsent) {
            if (raw.publicName !== undefined) {
              if (raw.publicName != null && String(raw.publicName).trim() !== '') {
                nextPublicName = safePublicAttributionName(raw.publicName, current.contributorUid);
                if (!nextPublicName) {
                  throw new HttpsError(
                      'invalid-argument',
                      'Public attribution name must be a display name without an email address.',
                  );
                }
              }
            } else {
              nextPublicName = safePublicAttributionName(
                  current.publicName || current.contributorSnapshot?.displayName,
                  current.contributorUid,
              );
            }
          }
          patch.recognitionConsent = nextConsent;
          patch.publicName = nextPublicName;
        }
        if (currentImages.length > 0) {
          patch.submittedImages = updatedImages;
          pathsToDelete = updatedImages
              .filter((img) => img.reviewStatus === 'rejected' && img.storagePath)
              .map((img) => img.storagePath);
        }
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
          textDecision,
          imageDecisions: updatedImages.map((img) => ({
            id: img.id,
            status: img.reviewStatus || 'pending',
          })),
          note: text(raw.note, 2000, 'review note'),
          proposalEdited: Boolean(editedFields || editedProposal),
          ...(hasAttributionUpdate ? {attributionUpdated: true} : {}),
          at,
          actorUid: request.auth.uid,
        });
      });
      await deleteStoragePathsSafely(bucket, pathsToDelete);
      return {id, status: nextStatus};
    }
    if (action === 'approve_and_publish') {
      const reviewNote = text(raw.note, 2000, 'review note');
      const heroImageId = text(raw.heroImageId, 120, 'hero image ID');
      const decisionMap = normalizeImageDecisionsInput(raw.imageDecisions);
      const suggestionRef = db.collection('DictionarySuggestions').doc(id);
      const suggestionSnap = await suggestionRef.get();
      if (!suggestionSnap.exists) {
        throw new HttpsError('not-found', 'Suggestion not found.');
      }
      const current = suggestionSnap.data();
      if (current.status === 'published') {
        throw new HttpsError('failed-precondition', 'This submission has already been published.');
      }
      if (current.status === 'rejected') {
        throw new HttpsError('failed-precondition', 'Rejected submissions cannot be published directly.');
      }
      if (current.rightsConfirmed !== true) {
        throw new HttpsError(
            'failed-precondition',
            'Contributor rights confirmation is required before publishing images.',
        );
      }
      const targetId = text(current.termId, 100, 'term ID', true);
      if (!SLUG.test(targetId)) {
        throw new HttpsError('invalid-argument', 'Invalid target term ID.');
      }
      const currentImages = Array.isArray(current.submittedImages) ? current.submittedImages : [];
      if (currentImages.length === 0) {
        throw new HttpsError('failed-precondition', 'No submitted images found on this contribution.');
      }
      if (decisionMap) {
        const validIds = new Set(currentImages.map((img) => img.id));
        for (const targetImgId of decisionMap.keys()) {
          if (!validIds.has(targetImgId)) {
            throw new HttpsError('invalid-argument', `Unknown submitted image ID: ${targetImgId}`);
          }
        }
      }
      const updatedImages = currentImages.map((img) => {
        const dec = decisionMap?.get(img.id);
        const nextStatus = dec?.status || (img.reviewStatus === 'rejected' ? 'rejected' : 'approved');
        if (nextStatus === 'pending') {
          throw new HttpsError('invalid-argument', 'Decide approve or reject for every submitted image.');
        }
        const next = {
          ...img,
          reviewStatus: nextStatus,
          reviewedAt: at,
          reviewedByUid: request.auth.uid,
        };
        if (dec?.caption !== undefined) next.caption = dec.caption;
        if (dec?.explanation !== undefined) next.explanation = dec.explanation;
        if (dec?.imageType !== undefined) next.imageType = dec.imageType;
        if (dec?.reviewNote !== undefined) next.reviewNote = dec.reviewNote;
        return next;
      });
      const approvedImages = updatedImages.filter((img) => img.reviewStatus === 'approved');
      const rejectedImages = updatedImages.filter((img) => img.reviewStatus === 'rejected');
      if (approvedImages.length === 0) {
        throw new HttpsError('invalid-argument', 'Approve at least one image before publishing.');
      }

      const draft = db.collection('DictionaryDrafts').doc(targetId);
      const seedMatch = seed.find((item) => item.id === targetId || item.slug === targetId) || null;
      const preDraft = await draft.get();
      const targetSlug = preDraft.data()?.slug || seedMatch?.slug || targetId;
      const publicRef = db.collection('DictionaryEntries').doc(targetSlug);
      const prePublic = await publicRef.get();
      const baseEntry = prePublic.exists ?
        prePublic.data() :
        (preDraft.exists ? preDraft.data() : seedMatch);
      if (!baseEntry) {
        throw new HttpsError('not-found', 'Target Dictionary entry not found.');
      }

      const existingMedia = Array.isArray(baseEntry.media) ? baseEntry.media : [];
      const contributorCredit = current.recognitionConsent === true ?
        safePublicAttributionName(current.publicName, current.contributorUid) :
        null;
      const approvedMediaItems = approvedImages.map((img) => {
        const item = {
          url: img.url,
          label: (img.caption || '').trim() || baseEntry.term || current.term,
        };
        if (img.imageType && img.imageType !== 'illustrative') {
          item.imageType = img.imageType;
        }
        if (img.explanation) {
          item.explanation = img.explanation;
        }
        if (contributorCredit) {
          item.attribution = contributorCredit;
        }
        return {id: img.id, item};
      });

      let combinedMedia;
      if (heroImageId.startsWith('submitted:')) {
        const chosenId = heroImageId.slice('submitted:'.length);
        const heroMatch = approvedMediaItems.find((entryItem) => entryItem.id === chosenId);
        if (!heroMatch) {
          throw new HttpsError('invalid-argument', 'Selected hero image must be an approved submitted image.');
        }
        combinedMedia = [
          heroMatch.item,
          ...existingMedia,
          ...approvedMediaItems.filter((entryItem) => entryItem.id !== chosenId).map((e) => e.item),
        ];
      } else if (heroImageId.startsWith('existing:')) {
        const idx = Number.parseInt(heroImageId.slice('existing:'.length), 10);
        if (!Number.isInteger(idx) || idx < 0 || idx >= existingMedia.length) {
          throw new HttpsError('invalid-argument', 'Selected existing hero image index is invalid.');
        }
        combinedMedia = [
          existingMedia[idx],
          ...existingMedia.filter((_, i) => i !== idx),
          ...approvedMediaItems.map((e) => e.item),
        ];
      } else {
        combinedMedia = [
          ...existingMedia,
          ...approvedMediaItems.map((e) => e.item),
        ];
      }
      if (combinedMedia.length > 8) {
        throw new HttpsError(
            'invalid-argument',
            'Publishing these images would exceed the 8-image limit on this entry.',
        );
      }

      const entry = validateEntry({
        ...baseEntry,
        id: targetId,
        slug: targetSlug,
        media: combinedMedia,
      });
      const approvedSubmissionPaths = approvedSubmissionPathMap({submittedImages: approvedImages});
      const promotion = await promoteDraftMedia(entry.media, targetId, bucket, {
        approvedSubmissionPaths,
        contributorCredit,
      });
      entry.media = promotion.media;
      const promotedFiles = promotion.promotedFiles;
      const cleanupPaths = updatedImages.map((img) => img?.storagePath).filter(Boolean);
      let nextRevision = 0;

      try {
        await db.runTransaction(async (tx) => {
          const manifestRef = db.collection('DictionaryPublic').doc('catalogue');
          const manifest = await tx.get(manifestRef);
          const seedSnapshots = !manifest.exists ?
            await Promise.all(seed.map((item) => tx.get(db.collection('DictionaryEntries').doc(item.slug)))) :
            [];
          const txDraft = await tx.get(draft);
          const txPublic = await tx.get(publicRef);
          const txSuggestion = await tx.get(suggestionRef);
          if (!txSuggestion.exists) {
            throw new HttpsError('not-found', 'Suggestion not found.');
          }
          if (txSuggestion.data().status === 'published') {
            throw new HttpsError('failed-precondition', 'This submission has already been published.');
          }
          const revision = txDraft.data()?.revision || txPublic.data()?.revision || 0;
          const isUnmodifiedSeededPublic = !txDraft.exists &&
            txPublic.exists &&
            !txPublic.data()?.publishedAt &&
            (txPublic.data()?.revision || 0) === 1;
          const matchesRevision = raw.expectedRevision === revision ||
            (isUnmodifiedSeededPublic && raw.expectedRevision === 0);
          if (raw.expectedRevision != null && !matchesRevision) {
            throw new HttpsError('aborted', 'This entry changed. Reload before publishing.');
          }
          if (txPublic.exists && txPublic.data().id !== targetId) {
            throw new HttpsError('already-exists', 'This slug belongs to another meaning.');
          }

          nextRevision = revision + 1;
          const editor = {updatedAt: at, updatedByUid: request.auth.uid};
          const draftData = {
            ...entry,
            revision: nextRevision,
            status: 'published',
            ...editor,
            suggestionId: null,
          };
          tx.set(draft, draftData);
          tx.create(draft.collection('Revisions').doc(String(nextRevision)), draftData);

          for (let index = 0; index < seedSnapshots.length; index++) {
            if (!seedSnapshots[index].exists && seed[index].slug !== entry.slug) {
              tx.create(db.collection('DictionaryEntries').doc(seed[index].slug), seed[index]);
            }
          }
          const priorNames = txPublic.data()?.attributions || [];
          const attributions = [...new Set([...priorNames, ...(contributorCredit ? [contributorCredit] : [])])];
          tx.set(publicRef, {
            ...entry,
            revision: nextRevision,
            status: 'published',
            publishedAt: at,
            attributions,
          });
          tx.set(manifestRef, {
            initialized: true,
            version: (manifest.data()?.version || 0) + 1,
            updatedAt: at,
          }, {merge: true});

          const decisionStatus = rejectedImages.length > 0 ? 'partially_approved' : 'approved';
          tx.update(suggestionRef, {
            status: 'published',
            textDecision: current.textDecision || 'rejected',
            submittedImages: updatedImages,
            entryId: targetId,
            heroImageId: heroImageId || null,
            updatedAt: at,
          });
          tx.create(suggestionRef.collection('AuditEvents').doc(), {
            status: decisionStatus,
            textDecision: current.textDecision || 'rejected',
            imageDecisions: updatedImages.map((img) => ({
              id: img.id,
              status: img.reviewStatus,
            })),
            heroImageId: heroImageId || null,
            note: reviewNote,
            at,
            actorUid: request.auth.uid,
          });
          tx.create(suggestionRef.collection('AuditEvents').doc(), {
            status: 'published',
            entryId: targetId,
            publishedImageCount: approvedImages.length,
            rejectedImageCount: rejectedImages.length,
            note: reviewNote,
            at: new Date(at.getTime() + 1),
            actorUid: request.auth.uid,
          });
        });
      } catch (error) {
        if (promotedFiles.length > 0) {
          await Promise.allSettled(promotedFiles.map((file) => file.delete()));
        }
        throw error;
      }

      await cleanupEntryDraftMedia(targetId, entry.media, bucket).catch(() => {});
      await deleteStoragePathsSafely(bucket, cleanupPaths);
      return {
        id: targetId,
        suggestionId: id,
        status: 'published',
        revision: nextRevision,
        publishedImageCount: approvedImages.length,
        rejectedImageCount: rejectedImages.length,
      };
    }
    if (!['save', 'publish'].includes(action)) throw new HttpsError('invalid-argument', 'Invalid action.');
    const entry = validateEntry(raw.entry);
    if (entry.id !== id) throw new HttpsError('invalid-argument', 'ID mismatch.');
    const draft = db.collection('DictionaryDrafts').doc(id);
    const publicRef = db.collection('DictionaryEntries').doc(entry.slug);
    const suggestionId = text(raw.suggestionId, 100, 'suggestion ID');
    if (suggestionId && !/^[a-zA-Z0-9-]{16,100}$/.test(suggestionId)) {
      throw new HttpsError('invalid-argument', 'Invalid suggestion ID.');
    }
    const preDraftSnap = await draft.get();
    const preSourceId = suggestionId || preDraftSnap.data()?.suggestionId || null;
    const preContribSnap = preSourceId ?
      await db.collection('DictionarySuggestions').doc(preSourceId).get() :
      null;
    const preContribData = preContribSnap?.exists ? preContribSnap.data() : null;
    const approvedSubmissionPaths = approvedSubmissionPathMap(preContribData);
    const contributorCredit = preContribData?.recognitionConsent === true ?
      safePublicAttributionName(preContribData.publicName, preContribData.contributorUid) :
      null;

    let promotedFiles = [];
    if (action === 'publish') {
      const promotion = await promoteDraftMedia(entry.media, id, bucket, {
        approvedSubmissionPaths,
        contributorCredit,
      });
      entry.media = promotion.media;
      promotedFiles = promotion.promotedFiles;
    } else {
      await validateMediaOwnership(entry.media, id, bucket, {
        checkDraftExists: Boolean(bucket),
        approvedSubmissionPaths,
      });
    }
    let cleanupSubmissionPaths = [];
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
        if (
          action === 'publish' &&
          contribution &&
          !['approved', 'partially_approved'].includes(contribution.data().status)
        ) {
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
          const publicName = credit?.recognitionConsent === true ?
            safePublicAttributionName(credit.publicName, credit.contributorUid) :
            null;
          const priorNames = raw.entry?.attributions !== undefined ?
            safeAttributionList(raw.entry.attributions, credit?.contributorUid) :
            (currentPublic.data()?.attributions || []);
          const attributions = [...new Set([...priorNames, ...(publicName ? [publicName] : [])])];
          tx.set(publicRef, {...entry, revision: nextRevision, status: 'published', publishedAt: at, attributions});
          tx.set(manifestRef, {
            initialized: true,
            version: (manifest.data()?.version || 0) + 1,
            updatedAt: at,
          }, {merge: true});
          if (suggestion) {
            if (Array.isArray(credit?.submittedImages)) {
              cleanupSubmissionPaths = credit.submittedImages
                  .map((img) => img?.storagePath)
                  .filter(Boolean);
            }
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
      await deleteStoragePathsSafely(bucket, cleanupSubmissionPaths);
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
  parseSubmissionStoragePath, validateMediaOwnership, promoteDraftMedia, cleanupAbandonedDraftMedia,
  requireAdmin, submitDictionarySuggestion, editDictionary, publicEntry, resolveContributorIdentity,
  dictionaryEmulator: process.env.FUNCTIONS_EMULATOR === 'true',
};
