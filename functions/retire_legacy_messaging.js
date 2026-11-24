/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const DEFAULT_MODE = 'anonymize';
const LEGACY_REQUEST_TYPES = new Set([
  'INSTRUCTOR_REQUEST',
  'STUDENT_REQUEST',
  'STUDENT_HORSE_REQUEST',
  'TRANSFER_HORSE_REQUEST',
]);
const RETIRED_USER = 'Retired Legacy Account';
const RETIRED_BODY = '[Legacy message removed]';

function emailKey(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function validateRetirementEnvironment({
  dryRun = true,
  projectId = '',
  emulatorHost = process.env.FIRESTORE_EMULATOR_HOST || '',
  confirmProduction = false,
  mode = DEFAULT_MODE,
} = {}) {
  const normalizedProject = String(projectId || '').trim();
  if (!normalizedProject) {
    throw new Error('Explicit projectId is required (pass --project <id> or projectId option).');
  }
  if (!['anonymize', 'purge'].includes(mode)) {
    throw new Error(`Unsupported retirement mode "${mode}". Use "anonymize" or "purge".`);
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
    mode,
  };
}

function scrubMessagePii(msg) {
  if (!msg || typeof msg !== 'object') return msg;
  const next = {...msg};
  next.sender = RETIRED_USER;
  next.senderId = 'retired:legacy';
  next.senderProfilePicUrl = '';
  next.message = RETIRED_BODY;
  next.subject = '';
  if (Array.isArray(next.recipients)) {
    next.recipients = next.recipients.map(() => RETIRED_USER);
  }
  if (next.requestItem && typeof next.requestItem === 'object') {
    next.requestItem = {
      ...next.requestItem,
      id: 'retired:legacy',
      name: RETIRED_USER,
      imageUrl: '',
      extra: '',
    };
  }
  return next;
}

async function hasMigratedRequest(db, convId, msgId) {
  const candidates = [msgId, `${convId}_${msgId}`, `legacy_${convId}_${msgId}`].filter(Boolean);
  for (const id of candidates) {
    const snap = await db.collection('Requests').doc(id).get();
    if (snap.exists) return true;
  }
  return false;
}

async function retireLegacyMessaging(db, options = {}) {
  const {dryRun, projectId, isEmulator, mode} = validateRetirementEnvironment(options);
  const convSnap = await db.collection('Conversations').get();
  const summary = {
    projectId,
    isEmulator,
    dryRun,
    mode,
    scannedConversations: convSnap.docs.length,
    scannedMessages: 0,
    unmigratedPendingRequests: 0,
    wouldAnonymizeConversations: 0,
    wouldAnonymizeMessages: 0,
    wouldDeleteConversations: 0,
    wouldDeleteMessages: 0,
    anonymizedConversations: 0,
    anonymizedMessages: 0,
    deletedConversations: 0,
    deletedMessages: 0,
  };

  for (const convDoc of convSnap.docs) {
    const conv = convDoc.data() || {};
    const msgSnap = await convDoc.ref.collection('Messages').get();
    summary.scannedMessages += msgSnap.docs.length;

    if (mode === 'purge') {
      for (const msgDoc of msgSnap.docs) {
        const msg = msgDoc.data() || {};
        if (LEGACY_REQUEST_TYPES.has(msg.messageType) && msg.requestItem?.isSelected !== true) {
          const migrated = await hasMigratedRequest(db, convDoc.id, msg.messageId || msgDoc.id);
          if (!migrated) {
            summary.unmigratedPendingRequests += 1;
          }
        }
      }
      if (summary.unmigratedPendingRequests > 0) {
        throw new Error(
            'Refusing to purge Conversations/Messages while unmigrated pending request messages exist. ' +
            'Run backfill_requests.js first or use mode "anonymize".',
        );
      }
      summary.wouldDeleteMessages += msgSnap.docs.length;
      summary.wouldDeleteConversations += 1;
      if (!dryRun) {
        for (const msgDoc of msgSnap.docs) {
          await msgDoc.ref.delete();
          summary.deletedMessages += 1;
        }
        await convDoc.ref.delete();
        summary.deletedConversations += 1;
      }
      continue;
    }

    summary.wouldAnonymizeConversations += 1;
    summary.wouldAnonymizeMessages += msgSnap.docs.length;
    if (!dryRun) {
      for (const msgDoc of msgSnap.docs) {
        await msgDoc.ref.update(scrubMessagePii(msgDoc.data() || {}));
        summary.anonymizedMessages += 1;
      }
      const partiesCount = Array.isArray(conv.partiesIds) ?
        conv.partiesIds.length :
        (Array.isArray(conv.parties) ? conv.parties.length : 0);
      const patch = {
        partiesIds: Array.from({length: partiesCount}, (_, i) => `retired:legacy:${i}`),
        parties: Array.from({length: partiesCount}, () => RETIRED_USER),
        createdBy: RETIRED_USER,
        lastEditBy: RETIRED_USER,
        retiredAt: new Date().toISOString(),
      };
      if (conv.recentMessage && typeof conv.recentMessage === 'object') {
        patch.recentMessage = scrubMessagePii(conv.recentMessage);
      }
      await convDoc.ref.update(patch);
      summary.anonymizedConversations += 1;
    }
  }

  return summary;
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const execute = args.includes('--execute');
  const confirmProduction = args.includes('--confirm-production');
  const modeIndex = args.indexOf('--mode');
  const mode = modeIndex >= 0 && args[modeIndex + 1] ? args[modeIndex + 1] : DEFAULT_MODE;
  const projectIndex = args.indexOf('--project');
  const projectId = projectIndex >= 0 && args[projectIndex + 1] ?
    args[projectIndex + 1] :
    (process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || '');

  const admin = require('firebase-admin');
  if (!admin.apps.length) admin.initializeApp({projectId});
  retireLegacyMessaging(admin.firestore(), {
    dryRun: !execute,
    projectId,
    confirmProduction,
    mode,
  }).then((res) => {
    console.log(JSON.stringify(res, null, 2));
  }).catch((err) => {
    console.error(err?.message || err);
    process.exit(1);
  });
}

module.exports = {
  DEFAULT_MODE,
  RETIRED_BODY,
  RETIRED_USER,
  emailKey,
  retireLegacyMessaging,
  validateRetirementEnvironment,
};
