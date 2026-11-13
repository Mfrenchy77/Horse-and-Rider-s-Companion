/* eslint-disable require-jsdoc */
'use strict';

const LEGACY_TYPE_TO_KIND = Object.freeze({
  INSTRUCTOR_REQUEST: 'instructor',
  STUDENT_REQUEST: 'student',
  STUDENT_HORSE_REQUEST: 'studentHorse',
  TRANSFER_HORSE_REQUEST: 'transferHorse',
});

function emailKey(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function normalizePartiesIds(conv, message, senderEmail) {
  const fromConv = Array.isArray(conv?.partiesIds) ?
    conv.partiesIds.map(emailKey).filter(Boolean) : [];
  if (fromConv.length > 0) return Array.from(new Set(fromConv));
  const fromMsg = Array.isArray(message?.recipientsIds) ?
    message.recipientsIds.map(emailKey).filter(Boolean) : [];
  const combined = [senderEmail, ...fromMsg].filter(Boolean);
  return Array.from(new Set(combined));
}

function resolveLegacyStatus(message) {
  if (message?.requestItem?.isSelected === true) return 'accepted';
  const raw = typeof message?.status === 'string' ? message.status.trim().toLowerCase() : '';
  if (raw === 'accepted' || raw === 'declined' || raw === 'cancelled' || raw === 'dismissed') {
    return raw;
  }
  return 'pending';
}

function validateBackfillEnvironment({
  dryRun = true,
  projectId = '',
  emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '',
  confirmProduction = false,
} = {}) {
  const normalizedProject = String(projectId || '').trim();
  if (!normalizedProject) {
    throw new Error('Explicit projectId is required (pass --project <id> or projectId option).');
  }
  if (!dryRun && !emulatorHost && confirmProduction !== true) {
    throw new Error(
        'Refusing non-emulator writes without explicit authorization (confirmProduction: true / --confirm-production).',
    );
  }
  return {
    dryRun: Boolean(dryRun),
    projectId: normalizedProject,
    isEmulator: Boolean(emulatorHost),
  };
}

function deterministicLegacyDocId(convId, messageId) {
  return `legacy_${convId}_${messageId}`;
}

function directDocId(convId, messageId) {
  return `${convId}_${messageId}`;
}

function mapLegacyMessageToRequest({convId, conv = {}, messageId, message = {}}) {
  const kind = LEGACY_TYPE_TO_KIND[message.messageType];
  if (!kind) return null;

  const partiesIds = normalizePartiesIds(conv, message, emailKey(message.senderId));
  const parties = Array.isArray(conv.parties) && conv.parties.length > 0 ?
    conv.parties.filter((p) => typeof p === 'string') :
    (Array.isArray(message.recipients) ? message.recipients.filter((p) => typeof p === 'string') : []);

  let senderEmail = emailKey(message.senderId);
  if (!senderEmail && message.sender && parties.length > 0) {
    const idx = parties.findIndex((p) => p === message.sender);
    if (idx >= 0 && partiesIds[idx]) senderEmail = partiesIds[idx];
  }

  const recipientEmail = partiesIds.find((e) => e !== senderEmail) || '';
  const senderName = typeof message.sender === 'string' ? message.sender : '';
  const recipientName = parties.find((p) => p !== senderName) || '';
  const isHorseKind = kind === 'studentHorse' || kind === 'transferHorse';
  const status = resolveLegacyStatus(message);
  const createdAt = message.date || conv.lastEditDate || new Date();
  const docId = deterministicLegacyDocId(convId, messageId);
  const requestItem = message.requestItem && typeof message.requestItem === 'object' ? message.requestItem : null;

  return {
    id: docId,
    messageId: String(message.messageId || messageId || ''),
    kind,
    senderEmail,
    senderName,
    senderPicUrl: message.senderProfilePicUrl || null,
    recipientEmail,
    recipientName,
    title: message.subject || '',
    summary: message.message || '',
    parties,
    partiesIds,
    createdAt,
    updatedAt: createdAt,
    status,
    isAccepted: status === 'accepted',
    migratedFromLegacy: true,
    legacyConvId: convId,
    legacyMessageId: messageId,
    ...(isHorseKind ? {
      horseId: requestItem?.id || null,
      horseName: requestItem?.name || null,
      horsePicUrl: requestItem?.imageUrl || null,
      horseOwnerId: requestItem?.parentId || null,
      horseOwnerName: requestItem?.message || null,
    } : {}),
  };
}

function emptyReport(env) {
  return {
    dryRun: env.dryRun,
    projectId: env.projectId,
    isEmulator: env.isEmulator,
    processedConversations: 0,
    processedMessages: 0,
    matchedRequests: 0,
    created: 0,
    wouldCreate: 0,
    skippedExisting: 0,
    skippedNonRequest: 0,
    skippedChangedConcurrently: 0,
    lastConvId: null,
    countsByKind: {instructor: 0, student: 0, studentHorse: 0, transferHorse: 0},
    countsByStatus: {pending: 0, accepted: 0, declined: 0, cancelled: 0, dismissed: 0},
    reconciliation: {
      legacyPendingTotal: 0,
      requestsPendingTotal: 0,
      legacyPendingByUser: {},
      requestsPendingByUser: {},
      mismatchedUsers: [],
    },
  };
}

function incrementUserPending(map, email) {
  if (!email) return;
  map[email] = (map[email] || 0) + 1;
}

async function computeReconciliation(db, legacyPendingByUser, legacyPendingTotal) {
  const reqSnap = await db.collection('Requests').get();
  const requestsPendingByUser = {};
  let requestsPendingTotal = 0;

  for (const doc of reqSnap.docs) {
    const data = doc.data() || {};
    if ((data.status || 'pending') !== 'pending') continue;
    requestsPendingTotal += 1;
    const recipient = emailKey(data.recipientEmail);
    if (recipient) {
      incrementUserPending(requestsPendingByUser, recipient);
    }
  }

  const allUsers = new Set([
    ...Object.keys(legacyPendingByUser),
    ...Object.keys(requestsPendingByUser),
  ]);
  const mismatchedUsers = [];
  for (const user of Array.from(allUsers).sort()) {
    const legacyCount = legacyPendingByUser[user] || 0;
    const requestsCount = requestsPendingByUser[user] || 0;
    if (legacyCount !== requestsCount) {
      mismatchedUsers.push({email: user, legacyPending: legacyCount, requestsPending: requestsCount});
    }
  }

  return {
    legacyPendingTotal,
    requestsPendingTotal,
    legacyPendingByUser,
    requestsPendingByUser,
    mismatchedUsers,
  };
}

async function backfillRequests(db, options = {}) {
  const env = validateBackfillEnvironment(options);
  const batchSize = options.batchSize ?? 100;
  const onProgress = typeof options.onProgress === 'function' ? options.onProgress : null;
  const maxConversations = options.maxConversations ?? Infinity;
  let startAfterConvId = options.startAfterConvId || null;

  const report = emptyReport(env);
  const legacyPendingByUser = {};
  let legacyPendingTotal = 0;

  while (report.processedConversations < maxConversations) {
    let query = db.collection('Conversations').orderBy('__name__').limit(batchSize);
    if (startAfterConvId) {
      query = query.startAfter(startAfterConvId);
    }
    const convSnap = await query.get();
    if (convSnap.empty) break;

    for (const convDoc of convSnap.docs) {
      if (report.processedConversations >= maxConversations) break;
      const convId = convDoc.id;
      const conv = convDoc.data() || {};
      report.processedConversations += 1;
      report.lastConvId = convId;

      const msgSnap = await convDoc.ref.collection('Messages').get();
      for (const msgDoc of msgSnap.docs) {
        report.processedMessages += 1;
        const messageId = msgDoc.id;
        const mapped = mapLegacyMessageToRequest({
          convId,
          conv,
          messageId,
          message: msgDoc.data() || {},
        });
        if (!mapped) {
          report.skippedNonRequest += 1;
          continue;
        }

        report.matchedRequests += 1;
        report.countsByKind[mapped.kind] = (report.countsByKind[mapped.kind] || 0) + 1;
        report.countsByStatus[mapped.status] = (report.countsByStatus[mapped.status] || 0) + 1;
        if (mapped.status === 'pending') {
          legacyPendingTotal += 1;
          incrementUserPending(legacyPendingByUser, mapped.recipientEmail);
        }

        const legacyRef = db.collection('Requests').doc(mapped.id);
        const directRef = db.collection('Requests').doc(directDocId(convId, messageId));

        if (env.dryRun) {
          const [legacySnap, directSnap] = await Promise.all([legacyRef.get(), directRef.get()]);
          if (legacySnap.exists || directSnap.exists) {
            report.skippedExisting += 1;
          } else {
            report.wouldCreate += 1;
          }
          continue;
        }

        const outcome = await db.runTransaction(async (tx) => {
          const [freshMsg, freshLegacy, freshDirect] = await Promise.all([
            tx.get(msgDoc.ref),
            tx.get(legacyRef),
            tx.get(directRef),
          ]);
          if (!freshMsg.exists) return 'changed';
          const freshMapped = mapLegacyMessageToRequest({
            convId,
            conv,
            messageId,
            message: freshMsg.data() || {},
          });
          if (!freshMapped) return 'changed';
          if (freshLegacy.exists || freshDirect.exists) return 'exists';
          tx.set(legacyRef, freshMapped);
          return 'created';
        });

        if (outcome === 'created') report.created += 1;
        else if (outcome === 'exists') report.skippedExisting += 1;
        else report.skippedChangedConcurrently += 1;
      }

      if (onProgress) onProgress({...report});
    }

    startAfterConvId = convSnap.docs[convSnap.docs.length - 1].id;
    if (convSnap.docs.length < batchSize) break;
  }

  report.reconciliation = await computeReconciliation(db, legacyPendingByUser, legacyPendingTotal);
  return report;
}

function parseCliArgs(argv) {
  const args = {
    dryRun: true,
    projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || '',
    confirmProduction: false,
    startAfterConvId: null,
    batchSize: 100,
  };
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    if (flag === '--execute') args.dryRun = false;
    else if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--confirm-production') args.confirmProduction = true;
    else if (flag === '--project' && argv[i + 1]) args.projectId = argv[++i];
    else if (flag === '--start-after' && argv[i + 1]) args.startAfterConvId = argv[++i];
    else if (flag === '--batch-size' && argv[i + 1]) args.batchSize = Number(argv[++i]) || 100;
  }
  return args;
}

if (require.main === module) {
  const admin = require('firebase-admin');
  const args = parseCliArgs(process.argv.slice(2));
  validateBackfillEnvironment(args);
  if (!admin.apps.length) {
    admin.initializeApp({projectId: args.projectId});
  }
  backfillRequests(admin.firestore(), args)
      .then((report) => {
        console.log(JSON.stringify(report, null, 2));
      })
      .catch((err) => {
        console.error(err.message || err);
        process.exit(1);
      });
}

module.exports = {
  LEGACY_TYPE_TO_KIND,
  backfillRequests,
  deterministicLegacyDocId,
  directDocId,
  mapLegacyMessageToRequest,
  parseCliArgs,
  validateBackfillEnvironment,
};
