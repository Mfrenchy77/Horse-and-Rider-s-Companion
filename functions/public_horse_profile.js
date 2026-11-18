/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true, "ignoreComments": true }] */

'use strict';

const PUBLIC_HORSE_COLLECTION = 'Public_Horse_Profile';

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function buildPublicHorseProfile(id, data) {
  if (!data || typeof data !== 'object') return null;
  const archiveStatus = data.archiveStatus || 'active';
  if (data.isPublic !== true || archiveStatus !== 'active') {
    return null;
  }

  const name = nonEmptyString(data.name) || 'Horse Profile';
  const payload = {
    id,
    name,
    isPublic: true,
    archiveStatus: 'active',
  };

  for (const field of [
    'breed',
    'gender',
    'color',
    'nickname',
    'locationName',
    'zipCode',
    'picUrl',
  ]) {
    const val = nonEmptyString(data[field]);
    if (val) payload[field] = val;
  }

  if (typeof data.height === 'number' && Number.isFinite(data.height) && data.height > 0) {
    payload.height = data.height;
  }

  if (data.dateOfBirth != null) {
    payload.dateOfBirth = data.dateOfBirth;
  }

  if (data.saleListing && typeof data.saleListing === 'object') {
    payload.saleListing = {
      price: typeof data.saleListing.price === 'string' ?
        data.saleListing.price.trim() :
        String(data.saleListing.price || ''),
      location: typeof data.saleListing.location === 'string' ?
        data.saleListing.location.trim() :
        '',
      description: typeof data.saleListing.description === 'string' ?
        data.saleListing.description.trim() :
        '',
    };
  }

  return payload;
}

function syncPublicHorseProfileHandler(db) {
  return async (event) => {
    const horseId = event.params?.horseId;
    if (!horseId) return;

    const afterData = event.data?.after?.exists ? event.data.after.data() : null;
    const publicPayload = buildPublicHorseProfile(horseId, afterData);
    const ref = db.collection(PUBLIC_HORSE_COLLECTION).doc(horseId);

    if (!publicPayload) {
      await ref.delete();
      return;
    }

    await ref.set(publicPayload);
  };
}

module.exports = {
  PUBLIC_HORSE_COLLECTION,
  buildPublicHorseProfile,
  syncPublicHorseProfileHandler,
};
