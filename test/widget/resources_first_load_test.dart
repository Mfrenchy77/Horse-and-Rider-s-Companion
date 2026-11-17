import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/CommonWidgets/resource_item_placeholder.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
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
import 'package:shimmer/shimmer.dart';

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
    'First visit to Resources shows static skeletons without Shimmer, '
    'replaces them on load, and preserves cached cards on revisit',
    (tester) async {
      final controller = StreamController<List<Resource>>.broadcast();
      addTearDown(controller.close);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      when(harness.resources.getResources).thenAnswer((_) => controller.stream);

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
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Navigate from Profiles -> Resources while data is still pending.
      router.goNamed(ResourcesPage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));

      expect(find.byType(ResourceItemPlaceholder), findsWidgets);
      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(ResourcesItem), findsNothing);

      // Slow data arrives (even with a non-instant/empty image URL): cards show.
      controller.add([
        Resource(
          id: 'res-1',
          name: 'Groundwork Fundamentals',
          description: 'Clear cues for leading and yielding.',
          url: 'https://example.com/groundwork',
          lastEditBy: 'Coach',
          lastEditDate: DateTime(2026),
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ResourceItemPlaceholder), findsNothing);
      expect(find.byType(ResourcesItem), findsOneWidget);
      expect(find.text('Groundwork Fundamentals'), findsOneWidget);

      // Navigate away to Skill Tree and back to Resources: no skeleton flash.
      router.goNamed(SkillTreePage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));

      router.goNamed(ResourcesPage.name);
      await tester.pump();
      expect(find.byType(ResourceItemPlaceholder), findsNothing);
      expect(find.byType(ResourcesItem), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 280));
    },
  );

  testWidgets(
    'Resources shows empty state when catalogue is empty and retry on error '
    'on desktop with reduced motion',
    (tester) async {
      final controller = StreamController<List<Resource>>.broadcast();
      addTearDown(controller.close);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      when(harness.resources.getResources).thenAnswer((_) => controller.stream);

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

      router.goNamed(ResourcesPage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ResourceItemPlaceholder), findsWidgets);

      // Failed load shows retry state.
      controller.addError(Exception('Network error'));
      await tester.pump();
      expect(find.text('Unable to load resources'), findsOneWidget);
      expect(find.byKey(const Key('resourcesRetryButton')), findsOneWidget);

      // Retry succeeds with empty catalogue -> empty state (no skeletons).
      final retryController = StreamController<List<Resource>>.broadcast();
      addTearDown(retryController.close);
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => retryController.stream);

      await tester.tap(find.byKey(const Key('resourcesRetryButton')));
      await tester.pump();
      expect(find.byType(ResourceItemPlaceholder), findsWidgets);

      retryController.add(const []);
      await tester.pump();
      expect(find.byType(ResourceItemPlaceholder), findsNothing);
      expect(find.text('No resources yet'), findsOneWidget);
    },
  );
}
