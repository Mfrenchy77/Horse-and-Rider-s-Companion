'use strict';

const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {after, before, test} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, updateDoc, where,
} = require('firebase/firestore');

let environment;
const email = 'owner@example.com';
const verified = {email, email_verified: true};

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-horse-rules',
    firestore: {rules: readFileSync(join(__dirname, 'firestore.rules'), 'utf8')},
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'Rider_Profile/owner'), {email, name: 'Owner'}),
      setDoc(doc(db, 'Horse_Profile/atlas'), {
        currentOwnerId: email, name: 'Atlas', instructors: [],
      }),
      setDoc(doc(db, 'CoachingConnections/link'), {
        participantUids: ['owner', 'coach'], status: 'pending',
      }),
      setDoc(doc(db, 'SharedRidingEntries/ride'), {riderUid: 'owner', horseId: 'atlas'}),
    ]);
  });
});

after(async () => environment?.cleanup());

test('guest can read profiles while only the verified owner can change them', async () => {
  const guest = environment.unauthenticatedContext().firestore();
  const owner = environment.authenticatedContext('owner', verified).firestore();
  const other = environment.authenticatedContext('other', {
    email: 'other@example.com', email_verified: true,
  }).firestore();
  const unverified = environment.authenticatedContext('owner', {
    ...verified, email_verified: false,
  }).firestore();
  await assertSucceeds(getDoc(doc(guest, 'Horse_Profile/atlas')));
  await assertSucceeds(updateDoc(doc(owner, 'Rider_Profile/owner'), {name: 'New name'}));
  await assertSucceeds(updateDoc(doc(owner, 'Horse_Profile/atlas'), {name: 'Atlas II'}));
  await assertFails(updateDoc(doc(other, 'Rider_Profile/owner'), {name: 'Changed'}));
  await assertFails(updateDoc(doc(unverified, 'Horse_Profile/atlas'), {name: 'Changed'}));
  await assertFails(updateDoc(doc(other, 'Horse_Profile/atlas'), {instructors: [{id: 'other@example.com'}]}));
  await assertFails(updateDoc(doc(owner, 'Horse_Profile/atlas'), {currentOwnerId: 'NONE'}));
  await assertFails(deleteDoc(doc(owner, 'Horse_Profile/atlas')));
  await assertFails(updateDoc(doc(owner, 'Horse_Profile/atlas'), {archiveStatus: 'archived'}));
  for (const field of ['saleListing', 'transferRequestId', 'ownershipVersion']) {
    await assertFails(updateDoc(doc(owner, 'Horse_Profile/atlas'), {[field]: 'client value'}));
  }
  await assertFails(updateDoc(doc(owner, 'Rider_Profile/owner'), {ownershipRosterVersion: 'client value'}));
  await assertFails(updateDoc(doc(owner, 'Rider_Profile/owner'), {archivedHorses: [{id: 'atlas'}]}));
});

test('coaching and journal queries enforce verified membership and block all client writes', async () => {
  const guest = environment.unauthenticatedContext().firestore();
  const owner = environment.authenticatedContext('owner', verified).firestore();
  const coach = environment.authenticatedContext('coach', {email_verified: true}).firestore();
  const unverified = environment.authenticatedContext('owner').firestore();
  await assertSucceeds(getDocs(query(
    collection(owner, 'CoachingConnections'), where('participantUids', 'array-contains', 'owner'),
  )));
  await assertSucceeds(getDocs(query(
    collection(owner, 'SharedRidingEntries'), where('riderUid', '==', 'owner'),
  )));
  await assertSucceeds(getDoc(doc(coach, 'CoachingConnections/link')));
  await assertFails(getDoc(doc(guest, 'CoachingConnections/link')));
  await assertFails(getDoc(doc(unverified, 'CoachingConnections/link')));
  await assertFails(getDoc(doc(coach, 'SharedRidingEntries/ride')));
  await assertFails(getDocs(collection(owner, 'SharedRidingEntries')));
  await assertFails(setDoc(doc(owner, 'CoachingConnections/new'), {participantUids: ['owner']}));
  await assertFails(updateDoc(doc(owner, 'CoachingConnections/link'), {status: 'accepted'}));
  await assertFails(setDoc(doc(owner, 'SharedRidingEntries/new'), {riderUid: 'owner'}));
  await assertFails(updateDoc(doc(owner, 'SharedRidingEntries/ride'), {horseId: 'other-horse'}));
});


test('the callable preserves shared lessons across archive, restore and transfer', async () => {
  const {initializeApp, deleteApp} = require('firebase-admin/app');
  const {getFirestore} = require('firebase-admin/firestore');
  const {connectionHandler} = require('../functions/connections');
  const app = initializeApp({projectId: 'demo-horse-rules'}, 'coaching-rules-test');
  const db = getFirestore(app);
  const rider = 'rider@example.com';
  const coach = 'coach@example.com';
  const riderRef = db.doc('Rider_Profile/rad1r9991xppl1666l');
  const horseRef = db.doc('Horse_Profile/lesson-horse');
  const handler = connectionHandler(db, {
    getUserByEmail: async (email) => ({uid: email.split('@')[0], email}),
  });
  const call = (email, data) => handler({
    auth: {uid: email.split('@')[0], token: {email, email_verified: true}},
    data,
  });

  try {
    await Promise.all([
      riderRef.set({email: rider, name: 'Rider', ownedHorses: [{id: 'lesson-horse'}]}),
      db.doc('Rider_Profile/lpch9991xppl1666l').set({email: coach, name: 'Coach', isTrainer: true}),
      horseRef.set({name: 'Lesson horse', currentOwnerId: rider}),
    ]);
    const {id} = await call(coach, {
      action: 'send', kind: 'rider', learnerEmail: rider, coachEmail: coach,
    });
    const {version} = (await db.doc(`CoachingConnections/${id}`).get()).data();
    await call(rider, {action: 'accept', id, version});
    await call(coach, {
      action: 'record', id, version, recordId: 'one',
      notes: 'Lesson on transitions', horseId: 'lesson-horse',
    });
    const riderClient = environment.authenticatedContext('rider', {
      email: rider, email_verified: true,
    }).firestore();
    const journal = await assertSucceeds(getDocs(query(
      collection(riderClient, 'SharedRidingEntries'), where('riderUid', '==', 'rider'),
    )));
    const history = await call(rider, {action: 'horseHistory', horseId: 'lesson-horse'});
    const assert = require('node:assert/strict');
    assert.equal(journal.size, 1);
    assert.equal(history.entries[0].id, journal.docs[0].data().note.id);
    const archive = {action: 'setHorseArchive', horseId: 'lesson-horse'};
    await call(rider, {...archive, archiveStatus: 'archived'});
    const archived = (await riderRef.get()).data();
    assert.deepEqual(archived.ownedHorses, []);
    assert.equal(archived.archivedHorses[0].id, 'lesson-horse');
    assert.equal((await horseRef.get()).data().currentOwnerId, rider);
    await assertSucceeds(updateDoc(doc(riderClient, riderRef.path), {name: 'Edited rider'}));
    await call(rider, {...archive, archiveStatus: 'active'});
    assert.equal((await riderRef.get()).data().ownedHorses[0].id, 'lesson-horse');
    assert.equal((await getDocs(query(
      collection(riderClient, 'SharedRidingEntries'), where('riderUid', '==', 'rider'),
    ))).size, 1);
    const buyer = 'other@example.com';
    const buyerRef = db.doc('Rider_Profile/oth1r9991xppl1666l');
    await buyerRef.set({email: buyer, name: 'Buyer'});
    await call(rider, {
      action: 'setSaleListing', horseId: 'lesson-horse',
      listing: {price: '$5000 USD', location: 'Bend', description: 'School horse'},
    });
    const guest = environment.unauthenticatedContext().firestore();
    assert.equal((await getDoc(doc(guest, horseRef.path))).data().saleListing.price, '$5000 USD');
    const pending = await call(rider, {
      action: 'sendTransfer', horseId: 'lesson-horse', recipientEmail: buyer,
    });
    const transferRef = db.doc(`CoachingConnections/${pending.id}`);
    const transfer = (await transferRef.get()).data();
    const buyerClient = environment.authenticatedContext('other', {
      email: buyer, email_verified: true,
    }).firestore();
    await assertSucceeds(getDoc(doc(buyerClient, transferRef.path)));
    await assertFails(getDoc(doc(guest, transferRef.path)));
    await assertFails(updateDoc(doc(buyerClient, transferRef.path), {status: 'accepted'}));
    const staleRider = (await riderRef.get()).data();
    await call(buyer, {action: 'accept', id: pending.id, version: transfer.version});
    const transferred = (await horseRef.get()).data();
    assert.equal(transferred.currentOwnerId, buyer);
    assert.equal(transferred.saleListing, null);
    assert.deepEqual((await riderRef.get()).data().ownedHorses, []);
    assert.equal((await buyerRef.get()).data().ownedHorses[0].id, 'lesson-horse');
    assert.equal((await call(buyer, {action: 'horseHistory', horseId: 'lesson-horse'})).entries[0].id,
      history.entries[0].id);
    await assertFails(setDoc(doc(riderClient, riderRef.path), staleRider));
    await assertFails(updateDoc(doc(riderClient, horseRef.path), {name: 'Old owner update'}));
    await assertSucceeds(updateDoc(doc(buyerClient, horseRef.path), {name: 'New owner update'}));
  } finally {
    await deleteApp(app);
  }
});

test('DeletionJobs cannot be read or written by clients', async () => {
  const owner = environment.authenticatedContext('owner', verified).firestore();
  const guest = environment.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(owner, 'DeletionJobs/owner')));
  await assertFails(setDoc(doc(owner, 'DeletionJobs/owner'), {status: 'pending'}));
  await assertFails(getDoc(doc(guest, 'DeletionJobs/owner')));
});

test('Skill Tree 2.0 rules enforce UID ownership, valid levels, server-only verifications, and audit privacy', async () => {
  const ownerCtx = environment.authenticatedContext('uid-rider-v2', {
    email: 'v2rider@example.com', email_verified: true,
  });
  const coachCtx = environment.authenticatedContext('uid-coach-v2', {
    email: 'v2coach@example.com', email_verified: true,
  });
  const otherCtx = environment.authenticatedContext('uid-other-v2', {
    email: 'v2other@example.com', email_verified: true,
  });
  const ownerDb = ownerCtx.firestore();
  const coachDb = coachCtx.firestore();
  const otherDb = otherCtx.firestore();
  const guestDb = environment.unauthenticatedContext().firestore();

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await Promise.all([
      setDoc(doc(db, 'SkillFamilies/rider.mounted.lateral_movements'), {
        id: 'rider.mounted.lateral_movements', subject: 'rider', realm: 'Mounted', name: 'Lateral Movements',
      }),
      setDoc(doc(db, 'SkillsV2/rider.mounted.shoulder_in'), {
        id: 'rider.mounted.shoulder_in',
        subject: 'rider',
        status: 'active',
        availableLevels: ['intermediate', 'advanced'],
      }),
      setDoc(doc(db, 'Rider_Profile/v2rider'), {
        email: 'v2rider@example.com', ownerUid: 'uid-rider-v2', name: 'V2 Rider',
      }),
      setDoc(doc(db, 'Horse_Profile/v2horse'), {
        currentOwnerId: 'v2rider@example.com', ownerUid: 'uid-rider-v2', name: 'V2 Horse',
      }),
      setDoc(doc(db, 'CoachingConnections/conn-v2'), {
        status: 'accepted',
        kind: 'rider',
        learnerUid: 'uid-rider-v2',
        coachUid: 'uid-coach-v2',
        participantUids: ['uid-rider-v2', 'uid-coach-v2'],
      }),
      setDoc(doc(db, 'Rider_Profile/v2rider/SkillVerifications/rider.mounted.shoulder_in'), {
        skillId: 'rider.mounted.shoulder_in',
        levels: {intermediate: {verifiedState: 'PROFICIENT', verifiedByUid: 'uid-coach-v2'}},
      }),
      setDoc(doc(db, 'Rider_Profile/v2rider/SkillVerificationEvents/evt-v2-1'), {
        id: 'evt-v2-1',
        type: 'verified',
        skillId: 'rider.mounted.shoulder_in',
        level: 'intermediate',
        actorUid: 'uid-coach-v2',
        connectionId: 'conn-v2',
      }),
    ]);
  });

  // 1. SkillFamilies and SkillsV2 are public-read, admin-write only
  await assertSucceeds(getDoc(doc(guestDb, 'SkillsV2/rider.mounted.shoulder_in')));
  await assertFails(setDoc(doc(ownerDb, 'SkillsV2/rider.mounted.shoulder_in'), {id: 'x'}));
  await assertFails(setDoc(doc(ownerDb, 'SkillFamilies/f1'), {id: 'f1'}));

  // 2. ownerUid cannot be forged or changed on profiles, and editor cannot be self-granted
  await assertFails(updateDoc(doc(ownerDb, 'Rider_Profile/v2rider'), {ownerUid: 'uid-other-v2'}));
  await assertFails(updateDoc(doc(ownerDb, 'Rider_Profile/v2rider'), {editor: true}));
  await assertFails(updateDoc(doc(ownerDb, 'Horse_Profile/v2horse'), {ownerUid: 'uid-other-v2'}));

  // 3. Valid SkillProgress write by UID owner succeeds
  await assertSucceeds(setDoc(
    doc(ownerDb, 'Rider_Profile/v2rider/SkillProgress/rider.mounted.shoulder_in'),
    {
      skillId: 'rider.mounted.shoulder_in',
      subject: 'rider',
      schemaVersion: 2,
      levels: {
        intermediate: {state: 'PROFICIENT', updatedByUid: 'uid-rider-v2'},
      },
    },
  ));

  // 4. Rejects unavailable level ('introductory' on Shoulder-In), VERIFIED state, or wrong subject/UID
  await assertFails(setDoc(
    doc(ownerDb, 'Rider_Profile/v2rider/SkillProgress/rider.mounted.shoulder_in'),
    {
      skillId: 'rider.mounted.shoulder_in',
      subject: 'rider',
      schemaVersion: 2,
      levels: {
        introductory: {state: 'LEARNING', updatedByUid: 'uid-rider-v2'},
      },
    },
  ));
  await assertFails(setDoc(
    doc(ownerDb, 'Rider_Profile/v2rider/SkillProgress/rider.mounted.shoulder_in'),
    {
      skillId: 'rider.mounted.shoulder_in',
      subject: 'rider',
      schemaVersion: 2,
      levels: {
        intermediate: {state: 'VERIFIED', updatedByUid: 'uid-rider-v2'},
      },
    },
  ));
  await assertFails(setDoc(
    doc(otherDb, 'Rider_Profile/v2rider/SkillProgress/rider.mounted.shoulder_in'),
    {
      skillId: 'rider.mounted.shoulder_in',
      subject: 'rider',
      schemaVersion: 2,
      levels: {
        intermediate: {state: 'LEARNING', updatedByUid: 'uid-other-v2'},
      },
    },
  ));
  await assertFails(setDoc(
    doc(ownerDb, 'Horse_Profile/v2horse/SkillProgress/rider.mounted.shoulder_in'),
    {
      skillId: 'rider.mounted.shoulder_in',
      subject: 'horse',
      schemaVersion: 2,
      levels: {
        intermediate: {state: 'LEARNING', updatedByUid: 'uid-rider-v2'},
      },
    },
  ));

  // 5. Client cannot forge or delete SkillVerifications or SkillVerificationEvents
  await assertFails(setDoc(
    doc(ownerDb, 'Rider_Profile/v2rider/SkillVerifications/rider.mounted.shoulder_in'),
    {skillId: 'rider.mounted.shoulder_in', levels: {}},
  ));
  await assertFails(deleteDoc(
    doc(ownerDb, 'Rider_Profile/v2rider/SkillVerifications/rider.mounted.shoulder_in'),
  ));
  await assertFails(setDoc(
    doc(coachDb, 'Rider_Profile/v2rider/SkillVerificationEvents/evt-fake'),
    {type: 'verified'},
  ));

  // 6. Audit events are readable by owner and accepted coach, but denied to guest/other
  await assertSucceeds(getDoc(doc(ownerDb, 'Rider_Profile/v2rider/SkillVerificationEvents/evt-v2-1')));
  await assertSucceeds(getDoc(doc(coachDb, 'Rider_Profile/v2rider/SkillVerificationEvents/evt-v2-1')));
  await assertFails(getDoc(doc(guestDb, 'Rider_Profile/v2rider/SkillVerificationEvents/evt-v2-1')));
  await assertFails(getDoc(doc(otherDb, 'Rider_Profile/v2rider/SkillVerificationEvents/evt-v2-1')));
});

test('Legacy Skills require editor claim and Resources protect ownership while preserving ratings', async () => {
  const editorDb = environment.authenticatedContext('ed-1', {
    email: 'ed1@example.com', email_verified: true, editor: true,
  }).firestore();
  const userDb = environment.authenticatedContext('u-1', {
    email: 'u1@example.com', email_verified: true,
  }).firestore();
  const otherDb = environment.authenticatedContext('u-2', {
    email: 'u2@example.com', email_verified: true,
  }).firestore();

  await assertFails(setDoc(doc(userDb, 'Skills/s1'), {id: 's1', skillName: 'Hacked'}));
  await assertSucceeds(setDoc(doc(editorDb, 'Skills/s1'), {id: 's1', skillName: 'Valid'}));

  await assertSucceeds(setDoc(doc(userDb, 'Resources/r1'), {
    id: 'r1', name: 'Guide', lastEditBy: 'u1@example.com', comments: [],
  }));
  await assertFails(deleteDoc(doc(otherDb, 'Resources/r1')));
  await assertFails(updateDoc(doc(otherDb, 'Resources/r1'), {name: 'Hijacked'}));
  await assertFails(updateDoc(doc(userDb, 'Resources/r1'), {lastEditBy: 'u2@example.com'}));
  await assertFails(updateDoc(doc(otherDb, 'Resources/r1'), {comments: 'not-a-list'}));
  await assertSucceeds(updateDoc(doc(otherDb, 'Resources/r1'), {comments: [{id: 'c1'}]}));
  await assertSucceeds(setDoc(doc(otherDb, 'Resources/r1/usersWhoRated/u-2'), {helpful: true}));
  await assertFails(setDoc(doc(otherDb, 'Resources/r1/usersWhoRated/u-1'), {helpful: false}));
});

test('Horse SkillProgress ownership follows ownerUid transfer and revokes old owner access', async () => {
  const oldOwnerDb = environment.authenticatedContext('uid-old', {
    email: 'old@example.com', email_verified: true,
  }).firestore();
  const newOwnerDb = environment.authenticatedContext('uid-new', {
    email: 'new@example.com', email_verified: true,
  }).firestore();

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await Promise.all([
      setDoc(doc(db, 'SkillsV2/horse.mounted.walk'), {
        id: 'horse.mounted.walk',
        subject: 'horse',
        status: 'active',
        availableLevels: ['introductory', 'intermediate'],
      }),
      setDoc(doc(db, 'Horse_Profile/xfer-horse'), {
        currentOwnerId: 'new@example.com',
        ownerUid: 'uid-new',
        name: 'Transferred Horse',
      }),
    ]);
  });

  await assertFails(setDoc(
    doc(oldOwnerDb, 'Horse_Profile/xfer-horse/SkillProgress/horse.mounted.walk'),
    {
      skillId: 'horse.mounted.walk',
      subject: 'horse',
      schemaVersion: 2,
      levels: {introductory: {state: 'PROFICIENT', updatedByUid: 'uid-old'}},
    },
  ));
  await assertSucceeds(setDoc(
    doc(newOwnerDb, 'Horse_Profile/xfer-horse/SkillProgress/horse.mounted.walk'),
    {
      skillId: 'horse.mounted.walk',
      subject: 'horse',
      schemaVersion: 2,
      levels: {introductory: {state: 'PROFICIENT', updatedByUid: 'uid-new'}},
    },
  ));
});
