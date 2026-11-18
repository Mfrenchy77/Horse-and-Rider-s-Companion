import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/resources_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/skill_tree_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/tutorial_selector_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

Future<void> _pumpFrames(
  WidgetTester tester, {
  int count = 12,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store v2Store;

  setUpAll(() async {
    registerFallbackValue(Resource());
    v2Store = await const AssetCurriculumV2Loader().loadInMemoryStore();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
  });

  testWidgets(
    'Skill Tree Tutorial walks all 11 steps on narrow mobile with reduced '
    'motion and completes without modifying progress',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => harness.resources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((_) => Stream.value(const []));

      final rider = RiderProfile(
        id: 'alex@example.com',
        email: 'alex@example.com',
        name: 'Alex Rider',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex Rider',
            email: 'alex@example.com',
            emailVerified: true,
          ),
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
      tester.view.physicalSize = const Size(360, 640);
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
              RepositoryProvider<SkillTreeV2Repository>.value(value: repo),
            ],
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 640),
                  disableAnimations: true,
                ),
                child: MaterialApp.router(
                  theme: mainThemeDark,
                  routerConfig: router,
                ),
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      // Start Skill Tree Tutorial from root navigator context.
      final navContext = tester.element(find.byType(Navigator).first);
      // ignore: unawaited_futures
      SkillTreeSpotlightTour.start(
        navContext,
        settleDelay: Duration.zero,
      );
      await _pumpFrames(tester);

      const expectedTitles = [
        'Rider and Horse Skills',
        'Categories',
        'Skill Families',
        'Individual Skills',
        'Skill Description',
        'Difficulty Levels',
        'Learning and Proficient Criteria',
        'Self-Assessment',
        'Instructor Verification',
        'Learning Aids & Related Resources',
        'Suggest Improvements',
      ];

      for (var i = 0; i < expectedTitles.length; i++) {
        final card = find.byKey(Key('skillTreeTourStepCard_$i'));
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.text(expectedTitles[i])),
          findsOneWidget,
        );
        // Verify controls remain inside 640px viewport.
        final nextRect = tester.getRect(
          find.byKey(const Key('skillTreeTourNextButton')),
        );
        expect(nextRect.bottom, lessThanOrEqualTo(640 - 88));

        await tester.tap(find.byKey(const Key('skillTreeTourNextButton')));
        await _pumpFrames(tester);
      }

      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.skillTree,
          userKey: 'alex@example.com',
        ),
        isTrue,
      );
      // Ensure no progress was written during the tour.
      final saved = await repo.fetchProgress(
        subject: SkillSubject.rider,
        profileDocId: 'alex@example.com',
      );
      expect(saved, isEmpty);
    },
  );

  testWidgets(
    'Resources Tutorial walks all 7 steps including Community Ratings, '
    'Associated Skills, and Comments on desktop and mobile',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => harness.resources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((_) => Stream.value(const []));

      final sampleResource = Resource(
        id: 'res-1',
        name: 'Balanced Halt Guide',
        url: 'https://example.com/halt',
        description: 'Practical exercises for a calm, square halt.',
        lastEditBy: 'Coach Sam',
        lastEditDate: DateTime.utc(2026, 11),
        skillTreeIds: const ['rider.mounted.halt'],
        usersWhoRated: const [],
        comments: [
          Comment(
            id: 'c-1',
            parentId: '',
            resourceId: 'res-1',
            comment: 'Great tips!',
            user: BaseListItem(
              id: 'alex@example.com',
              name: 'Alex Rider',
              isCollapsed: true,
            ),
            date: DateTime.utc(2026, 11, 2),
            editedDate: DateTime.utc(2026, 11, 2),
            rating: 0,
            usersWhoRated: const [],
          ),
        ],
      );

      when(
        harness.resources.getResources,
      ).thenAnswer((_) => Stream.value([sampleResource]));

      final rider = RiderProfile(
        id: 'alex@example.com',
        email: 'alex@example.com',
        name: 'Alex Rider',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex Rider',
            email: 'alex@example.com',
            emailVerified: true,
          ),
          usersProfile: rider,
          resources: [sampleResource],
          hasResourceCatalogue: true,
          isGuest: false,
          isProfileSetup: true,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

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
              RepositoryProvider<SkillTreeV2Repository>.value(value: repo),
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
      await _pumpFrames(tester);

      final navContext = tester.element(find.byType(Navigator).first);
      // ignore: unawaited_futures
      ResourcesSpotlightTour.start(
        navContext,
        settleDelay: Duration.zero,
      );
      await _pumpFrames(tester, count: 16);

      const expectedTitles = [
        'Resource Library',
        'Sorting and Filtering',
        'Open a Resource',
        'Community Ratings',
        'Associated Skills',
        'Comments and Discussion',
        'Contribute to the Library',
      ];

      for (var i = 0; i < expectedTitles.length; i++) {
        final card = find.byKey(Key('resourcesTourStepCard_$i'));
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.text(expectedTitles[i])),
          findsOneWidget,
        );
        // Verify the tooltip card and Next/Finish button stay inside viewport.
        final cardRect = tester.getRect(card);
        expect(cardRect.top, greaterThanOrEqualTo(0));
        expect(cardRect.bottom, lessThanOrEqualTo(900));
        final nextBtn = find.byKey(const Key('resourcesTourNextButton'));
        expect(nextBtn, findsOneWidget);
        expect(tester.getRect(nextBtn).bottom, lessThanOrEqualTo(900));
        await tester.tap(nextBtn);
        await _pumpFrames(tester, count: 16);
      }

      // Verify no ratings or comments were submitted during the tour.
      verifyNever(
        () => harness.resources.createOrUpdateResource(
          resource: any<Resource>(named: 'resource'),
        ),
      );

      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.resources,
          userKey: 'alex@example.com',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'TutorialSelectorDialog launches Skill Tree (with Next/Back/Skip) '
    'and Resources tutorials',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => harness.resources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((_) => Stream.value(const []));

      final rider = RiderProfile(
        id: 'alex@example.com',
        email: 'alex@example.com',
        name: 'Alex Rider',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex Rider',
            email: 'alex@example.com',
            emailVerified: true,
          ),
          usersProfile: rider,
          isGuest: false,
          isProfileSetup: true,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

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
              RepositoryProvider<SkillTreeV2Repository>.value(value: repo),
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
      await _pumpFrames(tester);

      final navContext = tester.element(find.byType(Navigator).first);
      // ignore: unawaited_futures
      TutorialSelectorDialog.show(navContext);
      await _pumpFrames(tester);

      expect(find.byKey(const Key('tutorialSelectorDialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tutorialSelectSkillTree')));
      await _pumpFrames(tester, count: 16);

      expect(
        find.byKey(const Key('skillTreeTourStepCard_0')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('skillTreeTourNextButton')));
      await _pumpFrames(tester, count: 16);
      expect(
        find.byKey(const Key('skillTreeTourStepCard_1')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('skillTreeTourBackButton')));
      await _pumpFrames(tester, count: 16);
      expect(
        find.byKey(const Key('skillTreeTourStepCard_0')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('skillTreeTourSkipButton')));
      await _pumpFrames(tester, count: 16);
      expect(find.byKey(const Key('skillTreeTourStepCard_0')), findsNothing);

      final navContext2 = tester.element(find.byType(Navigator).first);
      // ignore: unawaited_futures
      TutorialSelectorDialog.show(navContext2);
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('tutorialSelectResources')));
      await _pumpFrames(tester, count: 16);
      expect(
        find.byKey(const Key('resourcesTourStepCard_0')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('resourcesTourSkipButton')));
      await _pumpFrames(tester, count: 16);
      expect(find.byKey(const Key('resourcesTourStepCard_0')), findsNothing);
    },
  );

  testWidgets(
    'Resources Tutorial on narrow mobile (390x844) in guest mode keeps all '
    '7 tooltip cards and navigation controls inside viewport',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);

      final sampleResource = Resource(
        id: 'res-mobile',
        name: 'Groundwork Basics',
        url: 'https://example.com/groundwork',
        description: 'Clear cues on the ground for calm communication.',
        lastEditBy: 'Coach Sam',
        lastEditDate: DateTime.utc(2026, 11),
        skillTreeIds: const ['rider.mounted.halt'],
        usersWhoRated: const [],
        comments: const [],
      );

      when(
        harness.resources.getResources,
      ).thenAnswer((_) => Stream.value([sampleResource]));
      when(
        () => harness.resources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((_) => Stream.value(const []));

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: User.empty,
          resources: [sampleResource],
          hasResourceCatalogue: true,
          isGuest: true,
          isProfileSetup: false,
          status: AppStatus.unauthenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      addTearDown(settings.dispose);

      final router = Routes().router(
        settingsContoller: settings,
        appCubit: harness.cubit,
      );
      addTearDown(router.dispose);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
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
              RepositoryProvider<SkillTreeV2Repository>.value(value: repo),
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
      await _pumpFrames(tester);

      final navContext = tester.element(find.byType(Navigator).first);
      // ignore: unawaited_futures
      ResourcesSpotlightTour.start(
        navContext,
        settleDelay: Duration.zero,
      );
      await _pumpFrames(tester, count: 16);

      for (var i = 0; i < 7; i++) {
        final card = find.byKey(Key('resourcesTourStepCard_$i'));
        expect(card, findsOneWidget);
        final cardRect = tester.getRect(card);
        expect(cardRect.top, greaterThanOrEqualTo(0));
        expect(cardRect.bottom, lessThanOrEqualTo(844));
        if (i == 3) {
          expect(
            find.descendant(
              of: card,
              matching: find.textContaining('Signed-in members can rate'),
            ),
            findsOneWidget,
          );
        }
        final nextBtn = find.byKey(const Key('resourcesTourNextButton'));
        expect(nextBtn, findsOneWidget);
        expect(tester.getRect(nextBtn).bottom, lessThanOrEqualTo(844));
        await tester.tap(nextBtn);
        await _pumpFrames(tester, count: 16);
      }
    },
  );
}
