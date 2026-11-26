/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true, "ignoreComments": true }] */

'use strict';

const PUBLIC_RIDER_COLLECTION = 'Public_Rider_Profile';

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function sanitizeBaseListItems(items) {
  if (!Array.isArray(items)) return null;
  const out = [];
  for (const item of items) {
    if (!item || typeof item !== 'object') continue;
    const id = nonEmptyString(item.id);
    if (!id) continue;
    const entry = {id};
    const name = nonEmptyString(item.name);
    if (name) entry.name = name;
    const imageUrl = nonEmptyString(item.imageUrl);
    if (imageUrl) entry.imageUrl = imageUrl;
    if (typeof item.isCollapsed === 'boolean') {
      entry.isCollapsed = item.isCollapsed;
    }
    out.push(entry);
  }
  return out;
}

/**
 * Builds a sanitized public directory projection for a Rider_Profile document.
 *
 * Strictly excludes private fields: notes (rider logbook), savedProfilesList
 * (contacts), archivedHorses, messagesList, savedResourcesList, ownerUid,
 * instructorUids, editor, subscription metadata, and ownershipRosterVersion.
 *
 * @param {string} docId Firestore document ID in Rider_Profile.
 * @param {object|null} data Raw Rider_Profile document data.
 * @return {object|null} Sanitized payload or null if the source doc is missing.
 */
function buildPublicRiderProfile(docId, data) {
  if (!data || typeof data !== 'object') return null;

  const email = nonEmptyString(data.email);
  const name = nonEmptyString(data.name) || 'Rider';
  if (!email) return null;

  const payload = {
    id: nonEmptyString(data.id) || docId,
    name,
    email: email.toLowerCase(),
  };

  for (const field of [
    'bio',
    'picUrl',
    'homeUrl',
    'locationName',
    'cityName',
    'stateName',
    'stateIso',
    'countryName',
    'countryIso',
    'zipCode',
  ]) {
    const val = nonEmptyString(data[field]);
    if (val) payload[field] = val;
  }

  if (typeof data.isTrainer === 'boolean') {
    payload.isTrainer = data.isTrainer;
  }

  for (const listField of [
    'ownedHorses',
    'instructors',
    'students',
    'studentHorses',
  ]) {
    const sanitized = sanitizeBaseListItems(data[listField]);
    if (sanitized && sanitized.length > 0) {
      payload[listField] = sanitized;
    }
  }

  return payload;
}

function stableSerialize(value) {
  if (value === null || value === undefined) return 'null';
  if (typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableSerialize(item)).join(',')}]`;
  }
  const keys = Object.keys(value)
      .filter((key) => value[key] !== undefined)
      .sort();
  return `{${keys.map((key) => `${JSON.stringify(key)}:${stableSerialize(value[key])}`).join(',')}}`;
}

function syncPublicRiderProfileHandler(db) {
  return async (event) => {
    const riderId = event.params?.riderId;
    if (!riderId) return;

    const afterData = event.data?.after?.exists ? event.data.after.data() : null;
    const publicPayload = buildPublicRiderProfile(riderId, afterData);

    if (event.data?.before !== undefined) {
      const beforeData = event.data.before?.exists ? event.data.before.data() : null;
      const beforePayload = buildPublicRiderProfile(riderId, beforeData);
      if (stableSerialize(beforePayload) === stableSerialize(publicPayload)) {
        return;
      }
    }

    const ref = db.collection(PUBLIC_RIDER_COLLECTION).doc(riderId);

    if (!publicPayload) {
      await ref.delete();
      return;
    }

    await ref.set(publicPayload);
  };
}

module.exports = {
  PUBLIC_RIDER_COLLECTION,
  buildPublicRiderProfile,
  syncPublicRiderProfileHandler,
};
