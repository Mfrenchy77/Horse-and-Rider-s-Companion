'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  PUBLIC_HORSE_COLLECTION,
  buildPublicHorseProfile,
  syncPublicHorseProfileHandler,
} = require('../public_horse_profile');

test('buildPublicHorseProfile includes only approved public fields', () => {
  const result = buildPublicHorseProfile('horse-1', {
    id: 'horse-1',
    name: 'Starlight',
    isPublic: true,
    archiveStatus: 'active',
    breed: 'Quarter Horse',
    gender: 'Mare',
    color: 'Bay',
    height: 158,
    locationName: 'Austin, TX',
    picUrl: 'https://example.com/starlight.jpg',
    saleListing: {
      price: '9500',
      location: 'Austin, TX',
      description: 'Calm trail partner.',
    },
    currentOwnerId: 'owner@example.com',
    currentOwnerName: 'Secret Owner',
    ownerUid: 'uid-owner',
    purchasePrice: 12000,
    notes: [{id: 'n1', name: 'Private vet note'}],
    instructors: [{id: 'trainer@example.com', name: 'Trainer Bob'}],
    skillLevels: [{skillId: 's1', levelState: 'PROFICIENT'}],
    transferRequestId: 'req-1',
  });

  assert.deepEqual(result, {
    id: 'horse-1',
    name: 'Starlight',
    isPublic: true,
    archiveStatus: 'active',
    breed: 'Quarter Horse',
    gender: 'Mare',
    color: 'Bay',
    locationName: 'Austin, TX',
    picUrl: 'https://example.com/starlight.jpg',
    height: 158,
    saleListing: {
      price: '9500',
      location: 'Austin, TX',
      description: 'Calm trail partner.',
    },
  });
});

test('buildPublicHorseProfile returns null for private, archived, or deleted horses', () => {
  assert.equal(buildPublicHorseProfile('h1', null), null);
  assert.equal(buildPublicHorseProfile('h1', {name: 'Private', isPublic: false}), null);
  assert.equal(buildPublicHorseProfile('h1', {name: 'Default'}), null);
  assert.equal(
      buildPublicHorseProfile('h1', {name: 'Archived', isPublic: true, archiveStatus: 'archived'}),
      null,
  );
  assert.equal(
      buildPublicHorseProfile('h1', {name: 'Deceased', isPublic: true, archiveStatus: 'deceased'}),
      null,
  );
});

test('syncPublicHorseProfileHandler writes public projection and deletes when private/archived', async () => {
  const store = new Map();
  const db = {
    collection(name) {
      assert.equal(name, PUBLIC_HORSE_COLLECTION);
      return {
        doc(id) {
          return {
            async set(payload) {
              store.set(id, payload);
            },
            async delete() {
              store.delete(id);
            },
          };
        },
      };
    },
  };

  const handler = syncPublicHorseProfileHandler(db);

  await handler({
    params: {horseId: 'h1'},
    data: {
      after: {
        exists: true,
        data: () => ({
          name: 'Starlight',
          isPublic: true,
          archiveStatus: 'active',
          currentOwnerId: 'owner@example.com',
          purchasePrice: 5000,
        }),
      },
    },
  });
  assert.equal(store.has('h1'), true);
  assert.equal(store.get('h1').currentOwnerId, undefined);
  assert.equal(store.get('h1').purchasePrice, undefined);

  await handler({
    params: {horseId: 'h1'},
    data: {
      after: {
        exists: true,
        data: () => ({
          name: 'Starlight',
          isPublic: false,
          archiveStatus: 'active',
        }),
      },
    },
  });
  assert.equal(store.has('h1'), false);
});

test('syncPublicHorseProfileHandler skips redundant writes when public projection is unchanged', async () => {
  let setCount = 0;
  let deleteCount = 0;
  const db = {
    collection() {
      return {
        doc() {
          return {
            async set() {
              setCount += 1;
            },
            async delete() {
              deleteCount += 1;
            },
          };
        },
      };
    },
  };
  const handler = syncPublicHorseProfileHandler(db);

  await handler({
    params: {horseId: 'h1'},
    data: {
      before: {
        exists: true,
        data: () => ({
          name: 'Starlight',
          isPublic: true,
          archiveStatus: 'active',
          notes: [{id: 'n1', name: 'Before private note'}],
        }),
      },
      after: {
        exists: true,
        data: () => ({
          name: 'Starlight',
          isPublic: true,
          archiveStatus: 'active',
          notes: [{id: 'n2', name: 'Updated private note'}],
        }),
      },
    },
  });

  await handler({
    params: {horseId: 'h2'},
    data: {
      before: {
        exists: true,
        data: () => ({
          name: 'Private Horse',
          isPublic: false,
          notes: [{id: 'a'}],
        }),
      },
      after: {
        exists: true,
        data: () => ({
          name: 'Private Horse',
          isPublic: false,
          notes: [{id: 'b'}],
        }),
      },
    },
  });

  assert.equal(setCount, 0);
  assert.equal(deleteCount, 0);
});
