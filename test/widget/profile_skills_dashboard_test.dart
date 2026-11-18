import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

class _PermissionDeniedV2Store implements SkillTreeV2Store {
  @override
  Future<List<SkillFamily>> fetchFamilies() async => const [];

  @override
  Future<List<CurriculumSkill>> fetchSkills() async => const [];

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    throw Exception('permission-denied');
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    throw Exception('permission-denied');
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async => const [];

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store v2Store;
  late List<CurriculumSkill> allCurriculumSkills;

  setUpAll(() async {
    v2Store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    allCurriculumSkills = await v2Store.fetchSkills();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
  });

  group('buildProfileSkillsDashboard', () {
    test('distinguishes unique skill counts from level counts and keeps '
        'verification independent', () {
      final riderSkills = allCurriculumSkills
          .where((s) => s.subject == SkillSubject.rider)
          .toList();
      final multiLevelSkill = riderSkills.firstWhere(
        (s) => s.availableLevels.length >= 2,
      );
      final otherSkill = riderSkills.firstWhere(
        (s) => s.id != multiLevelSkill.id,
      );

      final dashboard = buildProfileSkillsDashboard(
        subject: SkillSubject.rider,
        allSkills: allCurriculumSkills,
        progressBySkill: {
          multiLevelSkill.id: SkillProgressRecord(
            skillId: multiLevelSkill.id,
            subject: SkillSubject.rider,
            levels: {
              multiLevelSkill.availableLevels[0]: LevelProgress(
                state: LevelState.PROFICIENT,
                updatedAt: DateTime.utc(2026, 11),
              ),
              multiLevelSkill.availableLevels[1]: LevelProgress(
                state: LevelState.PROFICIENT,
                updatedAt: DateTime.utc(2026, 11, 2),
              ),
            },
          ),
          otherSkill.id: SkillProgressRecord(
            skillId: otherSkill.id,
            subject: SkillSubject.rider,
            levels: {
              otherSkill.availableLevels.first: LevelProgress(
                state: LevelState.LEARNING,
                updatedAt: DateTime.utc(2026, 11, 3),
              ),
            },
          ),
        },
        verificationsBySkill: {
          multiLevelSkill.id: SkillVerificationRecord(
            skillId: multiLevelSkill.id,
            levels: {
              multiLevelSkill.availableLevels[0]: LevelVerification(
                verifiedByName: 'Coach Sam',
                verifiedAt: DateTime.utc(2026, 11, 4),
              ),
            },
          ),
        },
      );

      expect(dashboard.proficientSkillCount, 1);
      expect(dashboard.proficientLevelCount, 2);
      expect(dashboard.verifiedSkillCount, 1);
      expect(dashboard.verifiedLevelCount, 1);
      expect(dashboard.learningSkillCount, 1);
      expect(dashboard.learningLevelCount, 1);
      expect(
        dashboard.suggestion?.kind,
        SuggestedNextKind.continueLearning,
      );
      expect(dashboard.suggestion?.skill.id, otherSkill.id);
    });

    test(
      'recommends next available level after Proficient and then same-family '
      'unstarted skill using real curriculum IDs',
      () {
      final horseSkills =
          allCurriculumSkills
              .where(
                (s) =>
                    s.subject == SkillSubject.horse &&
                    s.status == CurriculumSkillStatus.active,
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final target = horseSkills.firstWhere(
        (s) =>
            s.availableLevels.length >= 2 &&
            horseSkills.any(
              (other) => other.id != s.id && other.familyId == s.familyId,
            ),
      );

      // Only Introductory is Proficient -> suggests next available level.
      final nextLevelDash = buildProfileSkillsDashboard(
        subject: SkillSubject.horse,
        allSkills: allCurriculumSkills,
        progressBySkill: {
          target.id: SkillProgressRecord(
            skillId: target.id,
            subject: SkillSubject.horse,
            levels: {
              target.availableLevels.first: LevelProgress(
                state: LevelState.PROFICIENT,
                updatedAt: DateTime.utc(2026, 11, 5),
              ),
            },
          ),
        },
        verificationsBySkill: const {},
      );

      expect(
        nextLevelDash.suggestion?.kind,
        SuggestedNextKind.nextAvailableLevel,
      );
      expect(nextLevelDash.suggestion?.skill.id, target.id);
      expect(nextLevelDash.suggestion?.level, target.availableLevels[1]);

      // All available levels Proficient -> suggests unstarted same-family
      // skill.
      final sameFamilyDash = buildProfileSkillsDashboard(
        subject: SkillSubject.horse,
        allSkills: allCurriculumSkills,
        progressBySkill: {
          target.id: SkillProgressRecord(
            skillId: target.id,
            subject: SkillSubject.horse,
            levels: {
              for (final lvl in target.availableLevels)
                lvl: LevelProgress(
                  state: LevelState.PROFICIENT,
                  updatedAt: DateTime.utc(2026, 11, 5),
                ),
            },
          ),
        },
        verificationsBySkill: const {},
      );

      expect(
        sameFamilyDash.suggestion?.kind,
        SuggestedNextKind.sameFamilySkill,
      );
      expect(sameFamilyDash.suggestion?.skill.familyId, target.familyId);
      expect(sameFamilyDash.suggestion?.skill.id, isNot(target.id));
    });

    test(
      'maps legacy skillLevels onto V2 dashboard when V2 progress is empty',
      () {
      final legacyTarget = allCurriculumSkills.firstWhere(
        (s) => s.subject == SkillSubject.rider && s.legacyIds.isNotEmpty,
      );
      final progress = <String, SkillProgressRecord>{};
      final verifs = <String, SkillVerificationRecord>{};

      mergeLegacySkillLevelsIntoV2(
        subject: SkillSubject.rider,
        legacySkillLevels: [
          SkillLevel(
            skillId: legacyTarget.legacyIds.first,
            skillName: legacyTarget.name,
            lastEditBy: 'Coach Sam',
            lastEditDate: DateTime.utc(2026, 11, 5),
            levelState: LevelState.PROFICIENT,
            verified: true,
          ),
        ],
        legacyCatalog: const [],
        v2Skills: allCurriculumSkills,
        progressBySkill: progress,
        verificationsBySkill: verifs,
      );

      final dash = buildProfileSkillsDashboard(
        subject: SkillSubject.rider,
        allSkills: allCurriculumSkills,
        progressBySkill: progress,
        verificationsBySkill: verifs,
      );
      expect(dash.proficientLevelCount, 1);
      expect(dash.verifiedLevelCount, 1);
      expect(dash.proficientEntries.single.skill.id, legacyTarget.id);
    });
  });

  testWidgets(
    'ProfileSkills dashboard caps Learning/Proficient previews, opens View All '
    'dialogs, and renders cleanly on mobile and desktop',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);

      final riderSkills =
          allCurriculumSkills
              .where(
                (s) =>
                    s.subject == SkillSubject.rider &&
                    s.status == CurriculumSkillStatus.active,
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Seed 6 Learning skills and 7 Proficient skills.
      for (var i = 0; i < 6; i++) {
        await repo.setLevelProgress(
          subject: SkillSubject.rider,
          profileDocId: 'alex@example.com',
          skillId: riderSkills[i].id,
          level: riderSkills[i].availableLevels.first,
          state: LevelState.LEARNING,
          actorUid: 'uid-alex',
        );
      }
      for (var i = 6; i < 13; i++) {
        await repo.setLevelProgress(
          subject: SkillSubject.rider,
          profileDocId: 'alex@example.com',
          skillId: riderSkills[i].id,
          level: riderSkills[i].availableLevels.first,
          state: LevelState.PROFICIENT,
          actorUid: 'uid-alex',
        );
      }

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex',
            email: 'alex@example.com',
            emailVerified: true,
          ),
          isGuest: false,
        ),
      );

      for (final size in const [Size(390, 844), Size(1280, 900)]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          RepositoryProvider<SkillTreeV2Repository>.value(
            value: repo,
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp(
                theme: mainThemeDark,
                home: const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: ProfileSkills(
                      skillLevels: null,
                      subject: SkillSubject.rider,
                      profileDocId: 'alex@example.com',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byKey(const Key('profileSkillsSummary')), findsOneWidget);
        expect(find.text('6 Learning'), findsOneWidget);
        expect(find.text('6 skills · 6 levels'), findsOneWidget);
        expect(find.text('7 Proficient'), findsOneWidget);
        expect(find.text('7 skills · 7 levels'), findsOneWidget);
        expect(find.text('0 Verified'), findsOneWidget);
        expect(
          find.byKey(const Key('profileSkillsLearningViewAll')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('profileSkillsProficientViewAll')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('profileSkillsSuggestedNext')),
          findsOneWidget,
        );
      }

      // Open Learning View All -> shows all 6 items.
      await tester.tap(find.byKey(const Key('profileSkillsLearningViewAll')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('profileSkillsAllDialog')), findsOneWidget);
      final learningAllSkill = riderSkills[5];
      expect(
        find.byKey(
          Key(
            'profileSkillAll_${learningAllSkill.id}_'
            '${learningAllSkill.availableLevels.first.name}',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Open Proficient View All -> shows all 7 items.
      final profViewAll = find.byKey(
        const Key('profileSkillsProficientViewAll'),
      );
      await tester.ensureVisible(profViewAll);
      await tester.tap(profViewAll);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('profileSkillsAllDialog')), findsOneWidget);
      final profAllSkill = riderSkills[12];
      expect(
        find.byKey(
          Key(
            'profileSkillAll_${profAllSkill.id}_'
            '${profAllSkill.availableLevels.first.name}',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'New user empty state includes Explore Skill Tree action and permission '
    'denial does not show error banner or leak private progress',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final deniedRepo = SkillTreeV2Repository(
        store: _PermissionDeniedV2Store(),
      );

      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: deniedRepo,
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: const Scaffold(
                body: ProfileSkills(
                  skillLevels: null,
                  subject: SkillSubject.horse,
                  profileDocId: 'private-horse-1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('profileSkillsRetryButton')), findsNothing);
      expect(find.byKey(const Key('profileSkillsEmptyState')), findsOneWidget);
      expect(find.text('Explore Skill Tree'), findsOneWidget);
    },
  );
}
