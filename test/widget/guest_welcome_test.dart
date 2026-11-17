import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
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
    'GuestProfile renders wordmark, welcome card, and responsive Explore cards '
    'with navigation to Skill Tree and Resources',
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

      // 1. Desktop layout: side-by-side Explore cards.
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

      expect(find.byType(GuestProfile), findsOneWidget);
      expect(find.byKey(const Key('guestAppBarWordmark')), findsOneWidget);
      expect(find.byType(AppTitle), findsOneWidget);
      expect(find.text('Welcome'), findsNothing);
      expect(find.byKey(const Key('GuestSearchButton')), findsOneWidget);
      expect(find.byKey(const Key('GuestTutorialButton')), findsOneWidget);
      expect(find.byKey(const Key('guestWelcomeCard')), findsOneWidget);
      expect(
        find.text('Welcome to Horse & Rider’s Companion'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('guestCreateAccount')), findsOneWidget);
      expect(find.byKey(const Key('guestSignIn')), findsOneWidget);

      final skillsCard = find.byKey(const Key('guestExploreSkillTreeCard'));
      final resourcesCard = find.byKey(const Key('guestExploreResourcesCard'));
      expect(skillsCard, findsOneWidget);
      expect(resourcesCard, findsOneWidget);

      // Side-by-side on desktop (same top Y, Resources to the right).
      expect(
        tester.getTopLeft(skillsCard).dy,
        tester.getTopLeft(resourcesCard).dy,
      );
      expect(
        tester.getTopLeft(resourcesCard).dx,
        greaterThan(tester.getTopLeft(skillsCard).dx),
      );

      // Tap Explore Skill Tree -> navigates to /SkillTree.
      await tester.tap(skillsCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(
        router.routeInformationProvider.value.uri.path,
        SkillTreePage.path,
      );

      // Return to GuestProfile on mobile layout: stacked Explore cards.
      tester.view.physicalSize = const Size(420, 840);
      router.goNamed(ProfilePage.name);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));

      expect(
        tester.getTopLeft(resourcesCard).dy,
        greaterThan(tester.getBottomLeft(skillsCard).dy),
      );

      // Tap Explore Resources -> navigates to /Resources.
      await tester.ensureVisible(resourcesCard);
      await tester.tap(resourcesCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(
        router.routeInformationProvider.value.uri.path,
        ResourcesPage.path,
      );
    },
  );
}
