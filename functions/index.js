/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true, "ignoreComments": true }] */

'use strict';

const {onCall, onRequest} = require('firebase-functions/v2/https');
const {onDocumentCreated, onDocumentWritten} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
try { admin.app(); } catch { admin.initializeApp(); }
const logger = require('firebase-functions/logger');
const {connectionHandler} = require('./connections');
const {accountDeletionHandler, DEFAULT_ADMIN_ACCOUNT_EMAIL} = require('./account_deletion');
const {submitSuggestionHandler, reviewSuggestionHandler} = require('./suggestions');
const {
  saveCurriculumDraftHandler,
  discardCurriculumDraftHandler,
} = require('./curriculum_drafts');
const {
  publishCurriculumDraftHandler,
  abortFailedPublicationHandler,
  rollbackCurriculumRevisionHandler,
} = require('./curriculum_revisions');
const {sharePreviewHandler} = require('./share_preview');
const {
  submitDictionarySuggestion,
  editDictionary,
  dictionaryEmulator,
  cleanupAbandonedDraftMedia,
} = require('./dictionary');
const {defineSecret} = require('firebase-functions/params');
const dictionaryRateSecret = defineSecret('DICTIONARY_RATE_SECRET');

exports.submitDictionarySuggestion = onCall(
    {region: 'us-central1', enforceAppCheck: !dictionaryEmulator, secrets: [dictionaryRateSecret]},
    (request) => submitDictionarySuggestion(admin.firestore(), {
      secret: dictionaryRateSecret.value(),
      requireAppCheck: !dictionaryEmulator,
      bucket: admin.storage().bucket(),
    })(request),
);

exports.editDictionary = onCall(
    {region: 'us-central1'},
    (request) => editDictionary(
        admin.firestore(),
        {bucket: admin.storage().bucket()},
    )(request),
);

const {
  createInvitationHandler,
  getInvitationPreviewHandler,
  redeemInvitationHandler,
  listMyInvitationsHandler,
  revokeInvitationHandler,
} = require('./invitations');
const {syncPublicHorseProfileHandler} = require('./public_horse_profile');
const {syncPublicRiderProfileHandler} = require('./public_rider_profile');

exports.createInvitation = onCall(
    {region: 'us-central1'},
    (request) => createInvitationHandler(admin.firestore())(request),
);

exports.getInvitationPreview = onCall(
    {region: 'us-central1'},
    (request) => getInvitationPreviewHandler(admin.firestore())(request),
);

exports.redeemInvitation = onCall(
    {region: 'us-central1'},
    (request) => redeemInvitationHandler(admin.firestore(), admin.auth())(request),
);

exports.listMyInvitations = onCall(
    {region: 'us-central1'},
    (request) => listMyInvitationsHandler(admin.firestore())(request),
);

exports.revokeInvitation = onCall(
    {region: 'us-central1'},
    (request) => revokeInvitationHandler(admin.firestore())(request),
);

exports.coachingConnection = onCall(
    {region: 'us-central1'},
    (request) => connectionHandler(admin.firestore(), admin.auth())(request),
);

exports.requestAccountDeletion = onCall(
    {region: 'us-central1'},
    (request) => accountDeletionHandler(
        admin.firestore(),
        admin.auth(),
        admin.storage().bucket(),
        {adminEmail: process.env.ADMIN_ACCOUNT_EMAIL || DEFAULT_ADMIN_ACCOUNT_EMAIL},
    )(request),
);

exports.submitSkillTreeSuggestion = onCall(
    {region: 'us-central1'},
    (request) => submitSuggestionHandler(admin.firestore())(request),
);

exports.reviewSkillTreeSuggestion = onCall(
    {region: 'us-central1'},
    (request) => reviewSuggestionHandler(admin.firestore())(request),
);

exports.saveSkillTreeCurriculumDraft = onCall(
    {region: 'us-central1'},
    (request) => saveCurriculumDraftHandler(admin.firestore())(request),
);

exports.discardSkillTreeCurriculumDraft = onCall(
    {region: 'us-central1'},
    (request) => discardCurriculumDraftHandler(admin.firestore())(request),
);

exports.publishSkillTreeCurriculumDraft = onCall(
    {region: 'us-central1', timeoutSeconds: 120},
    (request) => publishCurriculumDraftHandler(admin.firestore(), {
      publishingEnabled: process.env.CURRICULUM_PUBLISHING_ENABLED === 'true',
    })(request),
);

exports.rollbackSkillTreeCurriculumRevision = onCall(
    {region: 'us-central1', timeoutSeconds: 120},
    (request) => rollbackCurriculumRevisionHandler(admin.firestore(), {
      publishingEnabled: process.env.CURRICULUM_PUBLISHING_ENABLED === 'true',
    })(request),
);

exports.abortSkillTreeCurriculumPublication = onCall(
    {region: 'us-central1'},
    (request) => abortFailedPublicationHandler(admin.firestore(), {
      publishingEnabled: process.env.CURRICULUM_PUBLISHING_ENABLED === 'true',
    })(request),
);

exports.sharePreview = onRequest(
    {region: 'us-central1', timeoutSeconds: 15, memory: '256MiB'},
    sharePreviewHandler(admin.firestore()),
);

exports.syncPublicHorseProfile = onDocumentWritten(
    {document: 'Horse_Profile/{horseId}', region: 'us-central1'},
    syncPublicHorseProfileHandler(admin.firestore()),
);

exports.syncPublicRiderProfile = onDocumentWritten(
    {document: 'Rider_Profile/{riderId}', region: 'us-central1'},
    syncPublicRiderProfileHandler(admin.firestore()),
);

exports.cleanupAbandonedDictionaryDraftMedia = onSchedule(
    {schedule: 'every sunday 04:00', timeZone: 'UTC', region: 'us-central1'},
    async () => {
      const result = await cleanupAbandonedDraftMedia(
          admin.firestore(),
          admin.storage().bucket(),
      );
      logger.info('Cleaned up abandoned dictionary draft media', {
        deletedCount: result.deleted.length,
      });
    },
);

/** ------------------------------------------------------------------------ */
/** Link preview & image resolution (heavy parsers lazy-loaded per call)     */
/** ------------------------------------------------------------------------ */

let previewMetaFn = null;
let fetchReadableFn = null;
let resolveImageFn = null;

function getPreviewMetaFn() {
  if (!previewMetaFn) {
    const {createPreviewMetaHandler} = require('./link_preview');
    previewMetaFn = createPreviewMetaHandler({
      verifyIdToken: (token) => admin.auth().verifyIdToken(token),
      fetchFn: (...args) => fetch(...args),
      logger,
    });
  }
  return previewMetaFn;
}

function getFetchReadableFn() {
  if (!fetchReadableFn) {
    const {createFetchReadableHandler} = require('./link_preview');
    fetchReadableFn = createFetchReadableHandler({
      verifyIdToken: (token) => admin.auth().verifyIdToken(token),
      fetchFn: (...args) => fetch(...args),
      logger,
    });
  }
  return fetchReadableFn;
}

function getResolveImageFn() {
  if (!resolveImageFn) {
    const {createResolveImageHandler} = require('./link_preview');
    resolveImageFn = createResolveImageHandler({
      fetchFn: (...args) => fetch(...args),
      logger,
    });
  }
  return resolveImageFn;
}

exports.previewMeta = onRequest(
    {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB'},
    (req, res) => getPreviewMetaFn()(req, res),
);

exports.fetchReadable = onRequest(
    {region: 'us-central1', timeoutSeconds: 25, memory: '512MiB'},
    (req, res) => getFetchReadableFn()(req, res),
);

exports.resolveImage = onRequest(
    {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB'},
    (req, res) => getResolveImageFn()(req, res),
);

/** ------------------------------------------------------------------------ */
/** Messaging Notifications                                                  */
/** ------------------------------------------------------------------------ */

async function sendPush(tokens, payload) {
  if (!tokens || tokens.length === 0) return;
  try {
    const msg = {
      notification: {title: payload.title, body: payload.body},
      data: Object.fromEntries(Object.entries(payload.data || {}).map(([k, v]) => [String(k), String(v)])),
      tokens: Array.from(new Set(tokens)),
    };
    await admin.messaging().sendEachForMulticast(msg);
  } catch (e) {
    logger.error('FCM send error', e);
  }
}

async function sendEmail(emails, mail) {
  if (!emails || emails.length === 0) return;
  // TODO: Integrate a provider (SendGrid/Mailgun) and set API key env.
  logger.info('Email notification stub skipped', {
    recipientCount: emails.length,
    hasSubject: Boolean(mail && mail.subject),
  });
}

exports.onRequestCreated = onDocumentCreated(
    'Requests/{requestId}',
    async (event) => {
      try {
        const snap = event.data;
        if (!snap) return;
        const req = snap.data() || {};
        const requestId = event.params.requestId;

        if (req.status !== 'pending') return;
        if (req.migratedFromLegacy === true) return;

        const partiesIds = Array.isArray(req.partiesIds) ? req.partiesIds : [];
        const senderEmail = String(req.senderEmail || req.senderId || '').trim().toLowerCase();

        const recipients = partiesIds
            .map((e) => String(e).trim().toLowerCase())
            .filter((e) => e && e !== senderEmail);
        if (recipients.length === 0) return;

        const tokenFetches = recipients.map(async (email) => {
          const col = admin.firestore()
              .collection('RiderProfiles')
              .doc(email)
              .collection('tokens');
          const qs = await col.get();
          return qs.docs.map((d) => (d.data() && d.data().token) || d.id).filter(Boolean);
        });
        const tokens = (await Promise.all(tokenFetches)).flat();

        const title = req.title || req.subject || 'New Request';
        const body = req.summary || req.message || `${req.senderName || req.sender || 'Someone'} sent you a request`;
        await sendPush(tokens, {title, body, data: {requestId}});
        await sendEmail(recipients, {subject: title, text: body});
      } catch (e) {
        logger.error('onRequestCreated error', e);
      }
    },
);
