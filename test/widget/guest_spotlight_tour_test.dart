import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:overmark/overmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SkillTreeV2Repository v2Repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final v2Store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    v2Repo = SkillTreeV2Repository(store: v2Store);
  });

  testWidgets(
    'Guest Spotlight Tour walks through Skill Tree and Resources via '
    'highlighted nav controls on desktop and supports Back/Done',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: true,
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
      tester.view.physicalSize = const Size(1280, 860);
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

      // Tour does not auto-trigger.
      expect(Overmark.isShowing, isFalse);
      expect(find.byKey(const Key('tourStepCard_0')), findsNothing);

      // Start tour from GuestTutorialButton.
      await tester.tap(find.byKey(const Key('GuestTutorialButton')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(Overmark.isShowing, isTrue);
      expect(find.byKey(const Key('tourStepCard_0')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('tourStepCard_0')),
          matching: find.text('Explore Skill Tree'),
        ),
        findsOneWidget,
      );

      // Tap the highlighted Skill Tree navigation destination to advance.
      try {
        await tester.tapAt(
          tester.getCenter(find.byKey(GuestSpotlightTour.skillTreeNavKey)),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }

        expect(find.byKey(const Key('tourStepCard_1')), findsOneWidget);
        expect(find.text('Families & Skills'), findsOneWidget);

        // Back returns to Step 1, Next advances again.
        await tester.tap(find.byKey(const Key('tourBackButton')));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        expect(find.byKey(const Key('tourStepCard_0')), findsOneWidget);

        await tester.tap(find.byKey(const Key('tourNextButton')));
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        expect(find.byKey(const Key('tourStepCard_1')), findsOneWidget);

        // Next -> Step 3 (Discover Resources).
        await tester.tap(find.byKey(const Key('tourNextButton')));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        expect(find.byKey(const Key('tourStepCard_2')), findsOneWidget);
        expect(find.text('Discover Resources'), findsOneWidget);

        // Tap the highlighted Resources navigation destination to advance.
        await tester.tapAt(
          tester.getCenter(find.byKey(GuestSpotlightTour.resourcesNavKey)),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }

        expect(find.byKey(const Key('tourStepCard_3')), findsOneWidget);
        expect(find.text('You’re Ready to Explore'), findsOneWidget);

        // Done finishes tour and leaves visitor on Resources.
        await tester.tap(find.byKey(const Key('tourNextButton')));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
        expect(Overmark.isShowing, isFalse);
        expect(
          router.routeInformationProvider.value.uri.path,
          ResourcesPage.path,
        );
      } finally {
        if (Overmark.isShowing) {
          GuestSpotlightTour.controller.skip();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    },
  );

  testWidgets(
    'Guest Spotlight Tour works on mobile with reduced motion, supports Skip, '
    'and leaves direct deep links unaffected',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: true,
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
      tester.view.physicalSize = const Size(420, 840);
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
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      try {
        await tester.tap(find.byKey(const Key('GuestTutorialButton')));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(Overmark.isShowing, isTrue);
        expect(find.byKey(const Key('tourStepCard_0')), findsOneWidget);

        // Mobile BottomNavigationBar tap-through advances Step 0 -> Step 1.
        await tester.tapAt(
          tester.getCenter(find.byKey(GuestSpotlightTour.skillTreeNavKey)),
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
        expect(find.byKey(const Key('tourStepCard_1')), findsOneWidget);

        await tester.tap(find.byKey(const Key('tourSkipButton')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(Overmark.isShowing, isFalse);

        // Direct deep links remain unaffected.
        router.go('/SkillTree?skillId=rider.in_hand.leading');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(
          find.byKey(const Key('skillDetailV2_rider.in_hand.leading')),
          findsOneWidget,
        );
        expect(Overmark.isShowing, isFalse);
      } finally {
        if (Overmark.isShowing) {
          GuestSpotlightTour.controller.skip();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    },
  );

  testWidgets(
    'Guest Spotlight Tour skips a missing target cleanly without trapping '
    'the user',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: true,
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

      final emptyV2Repo = SkillTreeV2Repository(
        store: InMemorySkillTreeV2Store(),
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
      tester.view.physicalSize = const Size(1280, 800);
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
              RepositoryProvider<SkillTreeV2Repository>.value(
                value: emptyV2Repo,
              ),
            ],
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp.router(
                theme: mainThemeDark,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      try {
        final ctx = tester.element(
          find.byKey(const Key('GuestTutorialButton')),
        );
        // Start with a short readinessTimeout so the unmounted family target
        // times out promptly and Overmark skips Step 1 -> Step 2.
        // ignore: unawaited_futures
        GuestSpotlightTour.start(
          ctx,
          branchSettleDelay: Duration.zero,
          readinessTimeout: const Duration(milliseconds: 120),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.byKey(const Key('tourStepCard_0')), findsOneWidget);

        await tester.tap(find.byKey(const Key('tourNextButton')));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        // Step 1 (skillTreeFamilyKey) is absent in emptyV2Repo, so Overmark
        // skips directly to Step 2 (Discover Resources).
        expect(find.byKey(const Key('tourStepCard_2')), findsOneWidget);

        await tester.tap(find.byKey(const Key('tourSkipButton')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(Overmark.isShowing, isFalse);
      } finally {
        if (Overmark.isShowing) {
          GuestSpotlightTour.controller.skip();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    },
  );
}
