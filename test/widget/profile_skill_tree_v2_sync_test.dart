import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

class _FailingThenRecoveringV2Store implements SkillTreeV2Store {
  _FailingThenRecoveringV2Store(this._delegate);

  final InMemorySkillTreeV2Store _delegate;
  bool shouldFail = true;

  @override
  Future<List<SkillFamily>> fetchFamilies() => _delegate.fetchFamilies();

  @override
  Future<List<CurriculumSkill>> fetchSkills() => _delegate.fetchSkills();

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    if (shouldFail) throw Exception('network-error');
    return _delegate.fetchProgress(
      subject: subject,
      profileDocId: profileDocId,
    );
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    if (shouldFail) throw Exception('network-error');
    return _delegate.fetchVerifications(
      subject: subject,
      profileDocId: profileDocId,
    );
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) => _delegate.fetchVerificationEvents(
    subject: subject,
    profileDocId: profileDocId,
  );

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) => _delegate.setLevelProgress(
    subject: subject,
    profileDocId: profileDocId,
    skillId: skillId,
    level: level,
    state: state,
    actorUid: actorUid,
    actorName: actorName,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store v2Store;
  late SkillTreeV2Repository v2Repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    v2Store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    v2Repo = SkillTreeV2Repository(store: v2Store);
  });

  testWidgets(
    'Profile -> Skill Tree 2.0 -> self-assessment syncs back to Rider Profile '
    'and keeps Rider and Horse progress isolated',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      const riderEmail = 'alex@example.com';
      final rider = RiderProfile(
        id: riderEmail,
        email: riderEmail,
        name: 'Alex Rider',
      );
      const authUser = User(
        id: 'uid-alex',
        name: 'Alex Rider',
        email: riderEmail,
        emailVerified: true,
      );

      // Seed a separate Horse skill so we confirm Rider Profile does not merge
      // horse progress.
      await v2Repo.setLevelProgress(
        subject: SkillSubject.horse,
        profileDocId: 'horse-atlas',
        skillId: 'horse.in_hand.leading',
        level: DifficultyState.Introductory,
        state: LevelState.PROFICIENT,
        actorUid: authUser.id,
        actorName: rider.name,
      );
      // Seed an instructor verification on a Rider skill.
      v2Store.applyVerificationLocally(
        subject: SkillSubject.rider,
        profileDocId: riderEmail,
        skillId: 'rider.husbandry.grooming',
        skillName: 'Daily Grooming & Care',
        level: DifficultyState.Introductory,
        verified: true,
        coachUid: 'uid-coach',
        coachName: 'Coach Sam',
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: authUser,
          usersProfile: rider,
          isGuest: false,
          isProfileSetup: true,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => harness.resources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((_) => const Stream.empty());

      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      addTearDown(settings.dispose);

      final router = Routes().router(
        settingsContoller: settings,
        appCubit: harness.cubit,
      );
      addTearDown(router.dispose);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ResourcesRepository>.value(
                value: harness.resources,
              ),
              RepositoryProvider<SkillTreeV2Repository>.value(value: v2Repo),
            ],
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp.router(
                theme: mainThemeDark,
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Rider Profile shows Verified V2 skill, and NOT the horse skill.
      expect(find.byKey(const Key('profileSkillsV2List')), findsOneWidget);
      expect(
        find.byKey(
          const Key('profileSkillV2_rider.husbandry.grooming_Introductory'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 Verified'), findsOneWidget);
      expect(
        find.byKey(
          const Key('profileSkillV2_horse.in_hand.leading_Introductory'),
        ),
        findsNothing,
      );

      // Tap recorded skill -> opens Skill Tree 2.0 on that exact skill.
      await tester.tap(
        find.byKey(
          const Key('profileSkillV2_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(
        find.byKey(const Key('skillDetailV2_rider.husbandry.grooming')),
        findsOneWidget,
      );

      // Record a new self-assessment on Intermediate level of Grooming.
      final intermediateChip = find.byKey(
        const Key('levelTab_rider.husbandry.grooming_Intermediate'),
      );
      await tester.ensureVisible(intermediateChip);
      await tester.tap(intermediateChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final learningButton = find.byKey(
        const Key('assessLearning_rider.husbandry.grooming_Intermediate'),
      );
      await tester.ensureVisible(learningButton);
      await tester.tap(learningButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Return to Profile -> newly recorded Learning state is reflected!
      router.go('/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(
        find.byKey(
          const Key('profileSkillV2_rider.husbandry.grooming_Intermediate'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 Learning'), findsOneWidget);
    },
  );

  testWidgets(
    'Horse Profile shows only that horse’s Skill Tree 2.0 progress and '
    'handles error retry cleanly',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      const ownerEmail = 'owner@example.com';
      final owner = RiderProfile(
        id: ownerEmail,
        email: ownerEmail,
        name: 'Owner',
      );
      const authUser = User(
        id: 'uid-owner',
        name: 'Owner',
        email: ownerEmail,
        emailVerified: true,
      );
      final atlas = HorseProfile(
        id: 'horse-atlas',
        name: 'Atlas',
        currentOwnerId: ownerEmail,
        currentOwnerName: 'Owner',
      );

      await v2Repo.setLevelProgress(
        subject: SkillSubject.horse,
        profileDocId: 'horse-atlas',
        skillId: 'horse.in_hand.leading',
        level: DifficultyState.Introductory,
        state: LevelState.PROFICIENT,
        actorUid: authUser.id,
        actorName: owner.name,
      );
      await v2Repo.setLevelProgress(
        subject: SkillSubject.horse,
        profileDocId: 'horse-other',
        skillId: 'horse.in_hand.haltering',
        level: DifficultyState.Introductory,
        state: LevelState.LEARNING,
        actorUid: authUser.id,
        actorName: owner.name,
      );

      final flakyStore = _FailingThenRecoveringV2Store(v2Store);
      final flakyRepo = SkillTreeV2Repository(store: flakyStore);

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: authUser,
          usersProfile: owner,
          horseProfile: atlas,
          isGuest: false,
          isForRider: false,
        ),
      );

      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: flakyRepo,
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: HorseProfileView(horseProfile: atlas),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Error state offers Retry.
      final retryButton = find.byKey(const Key('profileSkillsRetryButton'));
      expect(retryButton, findsOneWidget);

      // Recover and retry -> Atlas shows only its own Proficient skill.
      flakyStore.shouldFail = false;
      await tester.ensureVisible(retryButton);
      await tester.tap(retryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(
          const Key('profileSkillV2_horse.in_hand.leading_Introductory'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('profileSkillV2_horse.in_hand.haltering_Introductory'),
        ),
        findsNothing,
      );
      expect(find.text('1 Proficient'), findsOneWidget);
    },
  );

  testWidgets(
    'ProfileSkills falls back to historical legacy skillLevels when V2 has no '
    'recorded progress yet',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final legacySkill = Skill(
        id: 'legacy-1',
        skillName: 'Halt',
        description: 'Balanced halt',
        learningDescription: 'Learning halt',
        proficientDescription: 'Proficient halt',
        position: 0,
        rider: true,
        lastEditBy: 'admin@example.com',
        lastEditDate: DateTime(2025),
      );
      final legacyLevel = SkillLevel(
        skillId: 'legacy-1',
        skillName: 'Halt',
        levelState: LevelState.LEARNING,
        lastEditBy: 'legacy-rider@example.com',
        lastEditDate: DateTime(2025),
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          allSkills: [legacySkill],
          isGuest: false,
        ),
      );

      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: v2Repo,
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: Scaffold(
                body: ProfileSkills(
                  skillLevels: [legacyLevel],
                  subject: SkillSubject.rider,
                  profileDocId: 'legacy-rider@example.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Halt'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
    },
  );
}
