import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/firebase_dictionary_store.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_sync.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMessagesRepository extends Mock implements MessagesRepository {}

class _MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class _MockResourcesRepository extends Mock implements ResourcesRepository {}

class _MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class _MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class _MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class _CountingV2Store implements SkillTreeV2Store {
  _CountingV2Store() {
    const levelDef = SkillLevelDefinition(
      overview: 'Balanced posture.',
      learning: 'Develops feel in walk.',
      proficient: 'Maintains independent seat.',
    );
    _families = [
      const SkillFamily(
        id: 'fam-rider',
        subject: SkillSubject.rider,
        realm: SkillCategory.Mounted,
        name: 'Position',
        description: 'Rider balance and alignment.',
        sortOrder: 1,
      ),
      const SkillFamily(
        id: 'fam-horse',
        subject: SkillSubject.horse,
        realm: SkillCategory.In_Hand,
        name: 'Leading',
        description: 'Ground manners and leading.',
        sortOrder: 2,
      ),
    ];
    _skills = [
      const CurriculumSkill(
        id: 'sk-rider-1',
        name: 'Balanced Seat',
        subject: SkillSubject.rider,
        realm: SkillCategory.Mounted,
        familyId: 'fam-rider',
        summary: 'Centered seat at the walk.',
        purpose: 'Establish independent rider balance.',
        availableLevels: [
          DifficultyState.Introductory,
          DifficultyState.Intermediate,
        ],
        levels: {
          DifficultyState.Introductory: levelDef,
          DifficultyState.Intermediate: levelDef,
        },
      ),
      const CurriculumSkill(
        id: 'sk-horse-1',
        name: 'Quiet Halter',
        subject: SkillSubject.horse,
        realm: SkillCategory.In_Hand,
        familyId: 'fam-horse',
        summary: 'Accepts halter calmly.',
        purpose: 'Safe everyday handling.',
        availableLevels: [DifficultyState.Introductory],
        levels: {DifficultyState.Introductory: levelDef},
      ),
    ];
  }

  late final List<SkillFamily> _families;
  late final List<CurriculumSkill> _skills;
  final Map<String, Map<String, SkillProgressRecord>> _progress = {};

  int fetchFamiliesCalls = 0;
  int fetchSkillsCalls = 0;
  int fetchProgressCalls = 0;
  int fetchVerificationsCalls = 0;
  int fetchEventsCalls = 0;
  int setProgressCalls = 0;

  @override
  Future<List<SkillFamily>> fetchFamilies() async {
    fetchFamiliesCalls++;
    return _families;
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() async {
    fetchSkillsCalls++;
    return _skills;
  }

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    fetchProgressCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return Map<String, SkillProgressRecord>.from(
      _progress['${subject.name}:$profileDocId'] ?? const {},
    );
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    fetchVerificationsCalls++;
    return const {};
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    fetchEventsCalls++;
    return const [];
  }

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) async {
    setProgressCalls++;
  }
}

void main() {
  test('AppCubit defers legacy Skills subscription until requested', () async {
    SharedPreferences.setMockInitialValues({});
    final messages = _MockMessagesRepository();
    final skills = _MockSkillTreeRepository();
    final resources = _MockResourcesRepository();
    final riders = _MockRiderProfileRepository();
    final horses = _MockHorseProfileRepository();
    final auth = _MockAuthenticationRepository();

    when(() => auth.currentUser).thenReturn(User.empty);
    when(() => auth.user).thenAnswer((_) => const Stream<User?>.empty());
    when(
      skills.getSkills,
    ).thenAnswer((_) => const Stream<List<Skill>>.empty());

    final cubit = AppCubit(
      messagesRepository: messages,
      skillTreeRepository: skills,
      resourcesRepository: resources,
      riderProfileRepository: riders,
      horseProfileRepository: horses,
      authenticationRepository: auth,
    );
    await Future<void>.delayed(Duration.zero);

    verifyNever(skills.getSkills);
    cubit.ensureLegacySkillsLoaded();
    verify(skills.getSkills).called(1);
    await cubit.close();
  });

  test(
    'FirebaseDictionaryStore skips collection read when manifest matches',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('DictionaryPublic').doc('catalogue').set({
        'initialized': true,
        'version': 3,
      });
      await db.collection('DictionaryEntries').doc('half-halt').set({
        'id': 'half-halt',
        'slug': 'half-halt',
        'term': 'Half Halt',
        'definition': 'Rebalancing cue.',
        'status': 'published',
        'contextual': true,
      });

      final store = FirebaseDictionaryStore(firestore: db);
      final initial = await store.loadPublishedEntriesVersioned();
      expect(initial.entries, hasLength(1));
      expect(initial.version, 3);

      // Add a second doc WITHOUT bumping manifest version: matching cache
      // skips scanning DictionaryEntries completely.
      await db.collection('DictionaryEntries').doc('sidepass').set({
        'id': 'sidepass',
        'slug': 'sidepass',
        'term': 'Sidepass',
        'definition': 'Lateral movement.',
        'status': 'published',
        'contextual': true,
      });
      final cachedHit = await store.loadPublishedEntriesVersioned(
        cachedEntries: initial.entries,
        cachedVersion: initial.version,
        cachedUpdatedAtMs: initial.updatedAtMs,
      );
      expect(identical(cachedHit.entries, initial.entries), isTrue);

      // Bumping manifest version triggers a fresh collection load.
      await db.collection('DictionaryPublic').doc('catalogue').update({
        'version': 4,
      });
      final updated = await store.loadPublishedEntriesVersioned(
        cachedEntries: cachedHit.entries,
        cachedVersion: cachedHit.version,
      );
      expect(updated.entries, hasLength(2));
      expect(updated.version, 4);
    },
  );

  test(
    'FirestoreSkillTreeV2Store bounds events to 20 and caches snapshot',
    () async {
      final db = FakeFirebaseFirestore();
      for (var i = 0; i < 30; i++) {
        await db
            .collection('Rider_Profile')
            .doc('rider@example.com')
            .collection('SkillVerificationEvents')
            .doc('evt-$i')
            .set({
              'type': 'verified',
              'skillId': 'sk-1',
              'skillName': 'Seat',
              'level': 'Basic',
              'actorUid': 'coach-1',
              'actorName': 'Coach',
              'connectionId': 'conn-1',
              'at': Timestamp.fromDate(DateTime.utc(2026, 1, 1 + i)),
            });
      }
      final store = FirestoreSkillTreeV2Store(firestore: db);
      final events = await store.fetchVerificationEvents(
        subject: SkillSubject.rider,
        profileDocId: 'rider@example.com',
      );
      expect(events, hasLength(20));
      expect(events.first.id, 'evt-29');

      // RiderProfileRepository createOrUpdateRiderProfile merges safely.
      final repo = RiderProfileRepository(firestore: db);
      await repo.createOrUpdateRiderProfile(
        riderProfile: RiderProfile(
          id: 'rider@example.com',
          email: 'rider@example.com',
          name: 'Old',
        ),
      );
      final seededSnap = await db.collection('Rider_Profile').get();
      expect(seededSnap.docs, hasLength(1));
      final seededDocRef = seededSnap.docs.single.reference;
      await seededDocRef.set({
        'ownerUid': 'uid-server-managed',
      }, SetOptions(merge: true));

      await repo.createOrUpdateRiderProfile(
        riderProfile: RiderProfile(
          id: 'rider@example.com',
          email: 'rider@example.com',
          name: 'New',
        ),
      );
      final raw = await seededDocRef.get();
      expect(raw.data()?['name'], 'New');
      expect(raw.data()?['ownerUid'], 'uid-server-managed');
    },
  );

  test(
    'SkillTreeV2Cubit deduplicates sync, caches switches, and optimizes writes',
    () async {
      final store = _CountingV2Store();
      final cubit = SkillTreeV2Cubit(
        repository: SkillTreeV2Repository(store: store),
      );

      await cubit.initialize(
        initialSubject: SkillSubject.rider,
        profileDocId: 'rider@example.com',
      );
      expect(store.fetchFamiliesCalls, 1);
      expect(store.fetchSkillsCalls, 1);
      expect(store.fetchProgressCalls, 1);

      // Concurrent duplicate syncProfile for horse shares one in-flight read.
      await Future.wait([
        cubit.syncProfile(subject: SkillSubject.horse, profileDocId: 'horse-1'),
        cubit.syncProfile(subject: SkillSubject.horse, profileDocId: 'horse-1'),
      ]);
      expect(store.fetchProgressCalls, 2);
      expect(store.fetchVerificationsCalls, 2);
      expect(store.fetchEventsCalls, 2);

      // Switching back to Rider hits per-profile cache with 0 extra reads.
      await cubit.switchProfileContext(
        subject: SkillSubject.rider,
        profileDocId: 'rider@example.com',
      );
      expect(store.fetchProgressCalls, 2);

      // Self-assessment updates locally without re-reading subcollections.
      final ok = await cubit.setSelfAssessment(
        skillId: 'sk-rider-1',
        level: DifficultyState.Introductory,
        levelState: LevelState.LEARNING,
        profileDocId: 'rider@example.com',
        actorUid: 'uid-1',
      );
      expect(ok, isTrue);
      expect(store.setProgressCalls, 1);
      expect(store.fetchProgressCalls, 2);
      expect(store.fetchVerificationsCalls, 2);
      expect(store.fetchEventsCalls, 2);
      expect(
        cubit
            .state
            .progressBySkillId['sk-rider-1']
            ?.levels[DifficultyState.Introductory]
            ?.state,
        LevelState.LEARNING,
      );
      expect(SkillTreeV2Sync.lastUpdatedSubject, SkillSubject.rider);
      expect(SkillTreeV2Sync.lastUpdatedProfileDocId, 'rider@example.com');
      await cubit.close();
    },
  );
}
