import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
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
    'Main section navigation slides horizontally with fade and keeps '
    'navigation shell stationary on mobile and desktop',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
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

      // Mobile layout: NavigationBar stays outside BranchSlideContainer.
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
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(BranchSlideContainer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BranchSlideContainer),
          matching: find.byType(NavigationBar),
        ),
        findsNothing,
      );

      // Navigate Profiles (0) -> Skill Tree (1) -> Resources (2) -> Skill Tree.
      router.goNamed(SkillTreePage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      var slides = tester
          .widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .toList();
      expect(slides[0].offset, const Offset(-1, 0));
      expect(slides[1].offset, Offset.zero);
      expect(slides[2].offset, const Offset(1, 0));
      expect(slides[1].duration, const Duration(milliseconds: 240));

      router.goNamed(ResourcesPage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      slides = tester
          .widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .toList();
      expect(slides[0].offset, const Offset(-1, 0));
      expect(slides[1].offset, const Offset(-1, 0));
      expect(slides[2].offset, Offset.zero);

      router.goNamed(SkillTreePage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      slides = tester
          .widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .toList();
      expect(slides[1].offset, Offset.zero);
      expect(slides[2].offset, const Offset(1, 0));

      // Desktop layout: NavigationRail stays outside BranchSlideContainer.
      tester.view.physicalSize = const Size(1280, 860);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(BranchSlideContainer),
          matching: find.byType(NavigationRail),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Direct deep link opens skill and reduced motion sets zero-duration '
    'branch transitions',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
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

      router.go('/SkillTree?skillId=rider.in_hand.leading');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(
        find.byKey(const Key('skillDetailV2_rider.in_hand.leading')),
        findsOneWidget,
      );
      final slides = tester
          .widgetList<AnimatedSlide>(find.byType(AnimatedSlide))
          .toList();
      expect(slides.first.duration, Duration.zero);
      final opacities = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .toList();
      expect(opacities.first.duration, Duration.zero);
    },
  );
}
