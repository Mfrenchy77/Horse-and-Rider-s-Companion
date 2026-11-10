import 'package:authentication_repository/authentication_repository.dart'
    as auth;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/MainPages/About/about_page.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/messages_list_page.dart';
import 'package:horseandriderscompanion/MainPages/Privacy%20Policy/privacy_policy_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_web_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthenticationRepository extends Mock
    implements auth.AuthenticationRepository {}

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

void main() {
  late MockAuthenticationRepository authRepo;
  late MockMessagesRepository messagesRepo;
  late MockSkillTreeRepository skillRepo;
  late MockResourcesRepository resourcesRepo;
  late MockRiderProfileRepository riderRepo;
  late MockHorseProfileRepository horseRepo;
  late AppCubit appCubit;
  late SettingsController settingsController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    settingsController = SettingsController(SettingsService());
    await settingsController.loadSettings();

    authRepo = MockAuthenticationRepository();
    messagesRepo = MockMessagesRepository();
    skillRepo = MockSkillTreeRepository();
    resourcesRepo = MockResourcesRepository();
    riderRepo = MockRiderProfileRepository();
    horseRepo = MockHorseProfileRepository();

    when(() => authRepo.currentUser).thenReturn(auth.User.empty);
    when(() => authRepo.user).thenAnswer((_) => Stream<auth.User?>.value(null));

    when(
      () => skillRepo.getSkills(),
    ).thenAnswer((_) => Stream.value(<Skill>[]));
    when(
      () => skillRepo.getAllTrainingPaths(),
    ).thenAnswer((_) => Stream.value(<TrainingPath>[]));
    when(
      () => resourcesRepo.getResources(),
    ).thenAnswer((_) => Stream.value(<Resource>[]));

    when(
      () => resourcesRepo.getResourcesForSkill(skillId: any(named: 'skillId')),
    ).thenAnswer((_) => Stream.value(<Resource>[]));

    appCubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      horseProfileRepository: horseRepo,
      riderProfileRepository: riderRepo,
      authenticationRepository: authRepo,
    );
  });

  tearDown(() async {
    await appCubit.close();
    settingsController.dispose();
  });

  Widget buildApp(GoRouter router) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: messagesRepo),
        RepositoryProvider.value(value: skillRepo),
        RepositoryProvider<ResourcesRepository>.value(value: resourcesRepo),
        RepositoryProvider.value(value: riderRepo),
        RepositoryProvider.value(value: horseRepo),
        RepositoryProvider<auth.AuthenticationRepository>.value(
          value: authRepo,
        ),
      ],
      child: BlocProvider.value(
        value: appCubit,
        child: AppView(settingsController: settingsController, router: router),
      ),
    );
  }

  final locations = <String, String>{
    AuthPage.name: '/SignIn',
    ProfilePage.name: '/',
    SettingsView.name: '/Settings',
    MessagesPage.name: '/Messages',
    PrivacyPolicyPage.name: '/PrivacyPolicy',
    AboutPage.name: '/About',
    DeletePage.name: '/Delete',
    SkillTreePage.name: '/SkillTree',
    SkillTreeView.skillsListName: '/SkillTree/Skills',
    ResourcesPage.name: '/Resources',
  };
  for (final entry in locations.entries) {
    test('public URL for ${entry.key} remains ${entry.value}', () {
      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);
      expect(router.namedLocation(entry.key), entry.value);
      expect(
        router.configuration.findMatch(Uri.parse(entry.value)).isError,
        isFalse,
      );
    });
  }
  for (final entry in <String, Map<String, String>>{
    HorseProfilePage.name: {HorseProfilePage.pathParams: 'Horse ID+1'},
    ViewingProfilePage.name: {
      ViewingProfilePage.pathParams: 'rider+tag@example.com',
    },
    MessagePage.name: {MessagePage.pathParams: 'conversation/with spaces'},
    SkillTreeView.skillLevelName: {SkillTreeView.skillPathParam: 'Skill::one'},
    ResourceCommentPage.name: {
      ResourceCommentPage.pathParams: 'resource?part=1',
    },
    EmailVerificationDialog.name: {
      EmailVerificationDialog.pathParms: 'rider+tag@example.com',
    },
    ResourceWebPage.name: {
      ResourceWebPage.urlPathParams:
          'https://stable.example/a/b?q=horse%20care&x=1#guide',
      ResourceWebPage.titlePathParams: 'Horse & Rider / Guide',
    },
  }.entries) {
    test('deep-link parameters round trip for ${entry.key}', () {
      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);
      final location = router.namedLocation(
        entry.key,
        pathParameters: entry.value,
      );
      final match = router.configuration.findMatch(Uri.parse(location));
      expect(match.isError, isFalse);
      expect(match.pathParameters, entry.value);
    });
  }

  testWidgets(
    'skill detail opens from a profile and returns to the skill list',
    (tester) async {
      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();
      final skill = Skill(
        id: 's1',
        skillName: 'Leading',
        rider: true,
        position: 0,
        lastEditBy: 'editor',
        lastEditDate: DateTime.utc(2025),
        description: 'Leading safely',
        learningDescription: 'Practice',
        proficientDescription: 'Reliable',
      );
      appCubit.emit(
        appCubit.state.copyWith(allSkills: [skill], sortedSkills: [skill]),
      );
      router.goNamed(
        SkillTreeView.skillLevelName,
        pathParameters: {SkillTreeView.skillPathParam: skill.id},
      );
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.isError, isFalse);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/SkillTree/Skills/Skill:s1',
      );
      expect(appCubit.state.index, 1);
      expect(appCubit.state.skill?.id, 's1');
      expect(
        appCubit.state.skillTreeNavigation,
        SkillTreeNavigation.SkillLevel,
      );
      expect(find.text('Leading'), findsWidgets);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/SkillTree/Skills',
      );
      expect(appCubit.state.skillTreeNavigation, SkillTreeNavigation.SkillList);
    },
  );

  testWidgets(
    'an unknown skill URL does not display the previously selected skill',
    (tester) async {
      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();
      final skill = Skill(
        id: 'old',
        skillName: 'Old skill',
        rider: true,
        position: 0,
        lastEditBy: 'editor',
        lastEditDate: DateTime.utc(2025),
        description: '',
        learningDescription: '',
        proficientDescription: '',
      );
      appCubit.emit(appCubit.state.copyWith(allSkills: [skill], skill: skill));
      router.goNamed(
        SkillTreeView.skillLevelName,
        pathParameters: {SkillTreeView.skillPathParam: 'missing'},
      );
      await tester.pumpAndSettle();
      expect(appCubit.state.skill, isNull);
      expect(find.text('Skill Not Found'), findsOneWidget);
      expect(find.text('Old skill'), findsNothing);
    },
  );

  testWidgets('Routes initial location shows ProfilePage (guest)', (
    tester,
  ) async {
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Expect initial location to be the profile branch
    expect(router.routeInformationProvider.value.uri.path, ProfilePage.path);
    // Guest profile should be visible by default
    expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);
  });

  testWidgets('training-path deep links are disabled', (tester) async {
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(buildApp(router));
    await tester.pump();

    for (final path in [
      '/SkillTree/TrainingPaths',
      '/SkillTree/TrainingPaths/TrainingPath::old-path',
    ]) {
      router.go(path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(router.routerDelegate.currentConfiguration.isError, isTrue);
      expect(find.text('Training Paths'), findsNothing);
      expect(find.byKey(const Key('createTrainingPathButton')), findsNothing);
    }
  });

  testWidgets('Branch navigation via AppCubit index changes', (tester) async {
    Future<void> pumpNavigation() async {
      // Resources intentionally use a loading placeholder with a repeating
      // animation. Wait for route updates and branch slides, not all tickers.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    }

    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    await tester.pumpWidget(buildApp(router));
    await pumpNavigation();

    // Start on Profile
    expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);

    // Go to Skill Tree (index 1)
    appCubit.changeIndex(1);
    await pumpNavigation();
    expect(router.routeInformationProvider.value.uri.path, SkillTreePage.path);
    expect(find.byKey(const Key('skillTreeView')), findsOneWidget);

    // Go to Resources (index 2)
    appCubit.changeIndex(2);
    await pumpNavigation();
    expect(router.routeInformationProvider.value.uri.path, ResourcesPage.path);
    expect(find.byKey(const Key('resourcesView')), findsOneWidget);

    // Back to Profile (index 0)
    appCubit.changeIndex(0);
    await pumpNavigation();
    expect(router.routeInformationProvider.value.uri.path, ProfilePage.path);
    expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);

    // Let any branch slide timers complete to avoid pending timers
    await tester.pump(const Duration(milliseconds: 400));
  });
}
