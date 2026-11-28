// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Skill Tree 2.0 models & Firestore mappers', () {
    final now = DateTime.utc(2026, 11, 14, 10);

    test('SkillFamily round-trips map and Firestore', () async {
      const family = SkillFamily(
        id: 'rider.mounted.lateral_movements',
        subject: SkillSubject.rider,
        realm: SkillCategory.Mounted,
        name: 'Lateral Movements',
        description: 'Moving forward and sideways along a line.',
        sortOrder: 50,
      );

      final restored = SkillFamily.fromMap(family.toMap());
      expect(restored.id, 'rider.mounted.lateral_movements');
      expect(restored.subject, SkillSubject.rider);
      expect(restored.realm, SkillCategory.Mounted);
      expect(restored.name, 'Lateral Movements');
      expect(restored.sortOrder, 50);

      final fs = FakeFirebaseFirestore();
      await fs.collection('SkillFamilies').doc(family.id).set(
            SkillFamilyFirestoreMapper.toFirestore(family),
          );
      final snap = await fs.collection('SkillFamilies').doc(family.id).get();
      final loaded = SkillFamilyFirestoreMapper.fromFirestore(snap, null);
      expect(loaded.id, family.id);
      expect(loaded.realm, SkillCategory.Mounted);
    });

    test('CurriculumSkill round-trips levels, aliases, links, and search', () async {
      final skill = CurriculumSkill(
        id: 'rider.mounted.shoulder_in',
        subject: SkillSubject.rider,
        realm: SkillCategory.Mounted,
        familyId: 'rider.mounted.lateral_movements',
        name: 'Shoulder-In',
        aliases: const ['Épaule en dedans', 'Shoulder-fore'],
        summary: 'Shoulders brought slightly inward on a straight line.',
        purpose: 'Develops bend and engagement.',
        safety: const ['Never force neck bend with the reins.'],
        availableLevels: const [
          DifficultyState.Intermediate,
          DifficultyState.Advanced,
        ],
        levels: {
          DifficultyState.Intermediate: SkillLevelDefinition(
            overview: 'Recognizable walk shoulder-in.',
            components: const [
              SkillComponent(
                title: 'Establishing bend',
                description: 'Slight uniform bend before moving off track.',
              ),
            ],
            learning: 'Short stretches at walk.',
            proficient: 'Walk shoulder-in both directions.',
            standardUpdatedAt: now,
          ),
          DifficultyState.Advanced: const SkillLevelDefinition(
            overview: 'Sustained trot shoulder-in.',
            learning: 'Trot with intermittent drift.',
            proficient: 'Full long side at trot both directions.',
          ),
        },
        relatedSkills: const [
          RelatedSkill(
            skillId: 'horse.mounted.shoulder_in',
            relation: SkillRelationType.counterpart,
          ),
          RelatedSkill(
            skillId: 'rider.mounted.leg_yield',
            relation: SkillRelationType.foundation,
            level: DifficultyState.Intermediate,
          ),
        ],
        legacyIds: const ['rider.mounted.shoulder_in'],
        sortOrder: 20,
        updatedAt: now,
        updatedBy: 'curriculum-publisher',
      );

      final restored = CurriculumSkill.fromMap(skill.toMap());
      expect(restored.hasLevel(DifficultyState.Introductory), isFalse);
      expect(restored.hasLevel(DifficultyState.Intermediate), isTrue);
      expect(restored.hasLevel(DifficultyState.Advanced), isTrue);
      expect(restored.matchesQuery('epaule'), isTrue);
      expect(restored.matchesQuery('establishing bend'), isTrue);
      expect(restored.matchesQuery('nonexistent'), isFalse);
      expect(
        restored.allResourceLookupIds,
        containsAll(['rider.mounted.shoulder_in']),
      );

      // Firestore Timestamp round-trip
      final fs = FakeFirebaseFirestore();
      final ref = fs.collection('SkillsV2').doc(skill.id);
      await ref.set(CurriculumSkillFirestoreMapper.toFirestore(skill));
      final loaded = CurriculumSkillFirestoreMapper.fromFirestore(
        await ref.get(),
        null,
      );
      expect(loaded.levels[DifficultyState.Intermediate]?.standardUpdatedAt, now.toLocal());
      expect(loaded.relatedSkills.length, 2);
    });

    test('SkillProgressRecord, SkillVerificationRecord & VerificationEvent use UIDs and independent levels', () async {
      final progress = SkillProgressRecord(
        skillId: 'rider.mounted.steering_navigation',
        subject: SkillSubject.rider,
        levels: {
          DifficultyState.Introductory: LevelProgress(
            state: LevelState.PROFICIENT,
            updatedAt: now,
            updatedByUid: 'uid-rider-1',
            updatedByName: 'Alex',
          ),
          DifficultyState.Intermediate: LevelProgress(
            state: LevelState.LEARNING,
            updatedAt: now,
            updatedByUid: 'uid-rider-1',
          ),
        },
        updatedAt: now,
      );

      final restoredProgress = SkillProgressRecord.fromMap(progress.toMap());
      expect(
        restoredProgress.highestProficientLevel(),
        DifficultyState.Introductory,
      );
      expect(
        restoredProgress.levels[DifficultyState.Intermediate]?.state,
        LevelState.LEARNING,
      );
      expect(
        restoredProgress.levels[DifficultyState.Introductory]?.updatedByUid,
        'uid-rider-1',
      );

      final verification = SkillVerificationRecord(
        skillId: 'rider.mounted.steering_navigation',
        levels: {
          DifficultyState.Introductory: LevelVerification(
            verifiedByUid: 'uid-coach-1',
            verifiedByName: 'Coach Elena',
            verifiedAt: now,
            connectionId: 'conn-123',
            eventId: 'evt-1',
          ),
        },
        updatedAt: now,
      );
      final restoredVerif =
          SkillVerificationRecord.fromMap(verification.toMap());
      expect(
        restoredVerif.highestVerifiedLevel(),
        DifficultyState.Introductory,
      );
      expect(
        restoredVerif.levels[DifficultyState.Introductory]?.verifiedState,
        LevelState.PROFICIENT,
      );

      final event = VerificationEvent(
        id: 'evt-2',
        type: VerificationEventType.revoked,
        skillId: 'rider.mounted.steering_navigation',
        skillName: 'Steering & Navigation',
        level: DifficultyState.Introductory,
        actorUid: 'uid-coach-2',
        actorName: 'Coach Sam',
        connectionId: 'conn-456',
        previousVerifiedByUid: 'uid-coach-1',
        previousVerifiedAt: now,
        reason: 'Re-assessing after time off',
        at: now,
      );
      final restoredEvent = VerificationEvent.fromMap(event.toMap());
      expect(restoredEvent.type, VerificationEventType.revoked);
      expect(restoredEvent.actorUid, 'uid-coach-2');
      expect(restoredEvent.previousVerifiedByUid, 'uid-coach-1');

      // Mapper with Firestore Timestamps
      final fs = FakeFirebaseFirestore();
      await fs
          .collection('Rider_Profile')
          .doc('uid-rider-1')
          .collection('SkillProgress')
          .doc(progress.skillId)
          .set(SkillProgressV2FirestoreMapper.progressToFirestore(progress));
      final snap = await fs
          .collection('Rider_Profile')
          .doc('uid-rider-1')
          .collection('SkillProgress')
          .doc(progress.skillId)
          .get();
      final mapped =
          SkillProgressV2FirestoreMapper.progressFromFirestore(snap, null);
      expect(mapped.skillId, progress.skillId);
      expect(mapped.updatedAt, isA<DateTime>());
    });

    test('legacy Resource.skillTreeIds resolve to merged CurriculumSkill via legacyIds', () {
      const steering = CurriculumSkill(
        id: 'rider.mounted.steering_navigation',
        subject: SkillSubject.rider,
        realm: SkillCategory.Mounted,
        familyId: 'rider.mounted.steering_bend_direction',
        name: 'Steering & Navigation',
        summary: 'Guiding lines, circles, and patterns.',
        purpose: 'Core steering.',
        availableLevels: [
          DifficultyState.Introductory,
          DifficultyState.Intermediate,
          DifficultyState.Advanced,
        ],
        levels: {
          DifficultyState.Introductory: SkillLevelDefinition(
            overview: 'Walk',
            learning: 'Learning walk',
            proficient: 'Proficient walk',
          ),
        },
        legacyIds: [
          'rider.mounted.straight_line',
          'rider.mounted.circle_20m',
          'rider.mounted.slalom',
        ],
      );

      final legacyResource = Resource(
        id: 'res-1',
        name: 'Cone Slalom Exercises',
        lastEditBy: 'coach@example.com',
        skillTreeIds: const ['rider.mounted.slalom'],
      );
      final canonicalResource = Resource(
        id: 'res-2',
        name: 'Steering Fundamentals',
        lastEditBy: 'coach@example.com',
        skillTreeIds: const ['rider.mounted.steering_navigation'],
      );
      final unrelatedResource = Resource(
        id: 'res-3',
        name: 'Grooming Guide',
        lastEditBy: 'coach@example.com',
        skillTreeIds: const ['rider.husbandry.grooming_basics'],
      );

      final lookupIds = steering.allResourceLookupIds.toSet();
      final matches = [legacyResource, canonicalResource, unrelatedResource]
          .where((r) => r.skillTreeIds.any(lookupIds.contains))
          .map((r) => r.id)
          .toList();

      expect(matches, ['res-1', 'res-2']);
    });

    test(
      'FirestoreSkillTreeV2Store normalizes Rider emails to encoded Rider_Profile docIds across progress and verifications',
      () async {
        final fs = FakeFirebaseFirestore();
        final store = FirestoreSkillTreeV2Store(firestore: fs);
        const rawEmail = 'Alex@Example.com';
        final encodedId = RiderProfileRepository.profileDocIdForEmail(rawEmail);
        expect(encodedId, 'pl1x9991xppl1666l');
        expect(
          FirestoreSkillTreeV2Store.resolveProfileDocId(
            SkillSubject.rider,
            rawEmail,
          ),
          encodedId,
        );
        expect(
          FirestoreSkillTreeV2Store.resolveProfileDocId(
            SkillSubject.rider,
            encodedId,
          ),
          encodedId,
        );
        expect(
          FirestoreSkillTreeV2Store.resolveProfileDocId(
            SkillSubject.horse,
            'horse-atlas-123',
          ),
          'horse-atlas-123',
        );

        await store.setLevelProgress(
          subject: SkillSubject.rider,
          profileDocId: rawEmail,
          skillId: 'rider.in_hand.leading',
          level: DifficultyState.Intermediate,
          state: LevelState.PROFICIENT,
          actorUid: 'uid-alex',
          actorName: 'Alex Rider',
        );

        final directSnap = await fs
            .collection('Rider_Profile')
            .doc(encodedId)
            .collection('SkillProgress')
            .doc('rider.in_hand.leading')
            .get();
        expect(directSnap.exists, isTrue);
        expect(
          (await fs
                  .collection('Rider_Profile')
                  .doc(rawEmail)
                  .collection('SkillProgress')
                  .doc('rider.in_hand.leading')
                  .get())
              .exists,
          isFalse,
        );

        final fetchedProgress = await store.fetchProgress(
          subject: SkillSubject.rider,
          profileDocId: rawEmail,
        );
        expect(
          fetchedProgress['rider.in_hand.leading']
              ?.levels[DifficultyState.Intermediate]
              ?.state,
          LevelState.PROFICIENT,
        );

        await fs
            .collection('Rider_Profile')
            .doc(encodedId)
            .collection('SkillVerifications')
            .doc('rider.in_hand.leading')
            .set({
              'skillId': 'rider.in_hand.leading',
              'levels': {
                'intermediate': {
                  'verifiedState': 'PROFICIENT',
                  'verifiedByUid': 'uid-coach',
                  'verifiedByName': 'Coach Sam',
                  'standardVersion': 2,
                },
              },
            });
        final verifs = await store.fetchVerifications(
          subject: SkillSubject.rider,
          profileDocId: rawEmail,
        );
        expect(
          verifs['rider.in_hand.leading']
              ?.levels[DifficultyState.Intermediate]
              ?.verifiedByName,
          'Coach Sam',
        );
      },
    );
  });
}
