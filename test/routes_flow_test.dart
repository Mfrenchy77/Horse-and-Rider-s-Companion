import 'dart:async';

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

  testWidgets('the rail returns from a profile skill to the same horse', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(buildApp(router));
    await tester.pumpAndSettle();

    final skill = Skill(
      id: 'leading',
      rider: false,
      position: 0,
      skillName: 'Lead politely',
      lastEditBy: null,
      description: 'Lead with a slack rope.',
      lastEditDate: null,
      learningDescription: null,
      proficientDescription: null,
    );
    final horse = HorseProfile(
      id: 'atlas',
      name: 'Atlas',
      skillLevels: [
        SkillLevel(
          skillId: skill.id,
          skillName: skill.skillName,
          lastEditBy: null,
          lastEditDate: null,
          levelState: LevelState.PROFICIENT,
        ),
      ],
    );
    appCubit.emit(
      appCubit.state.copyWith(
        isGuest: false,
        horseProfile: horse,
        allSkills: [skill],
        sortedSkills: [skill],
      ),
    );
    router.goNamed(
      HorseProfilePage.name,
      pathParameters: {HorseProfilePage.pathParams: horse.id},
    );
    await tester.pumpAndSettle();
    expect(find.text('Atlas'), findsOneWidget);

    for (var visit = 0; visit < 2; visit++) {
      await tester.tap(find.widgetWithText(ListTile, skill.skillName));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
      expect(find.text('Lead with a slack rope.'), findsOneWidget);

      await tester.tap(find.text('Horse Profile'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        0,
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        '/Horse_Profile/atlas',
      );
      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Lead with a slack rope.'), findsNothing);
    }
  });

  testWidgets('a linked skill resource opens on the Resources rail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1250, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    addTearDown(router.dispose);
    final resource = Resource(
      id: 'guide',
      name: 'Leading guide',
      skillTreeIds: ['s1'],
    );
    when(
      () => resourcesRepo.getResourcesForSkill(skillId: 's1'),
    ).thenAnswer((_) => Stream.value([resource]));
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
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
    final guide = find.text('Leading guide');
    await tester.ensureVisible(guide);
    await tester.tap(guide);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/Resources/Comments/guide',
    );
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );
    expect(find.text('Resource Comment Page'), findsOneWidget);
    expect(find.text('Leading guide'), findsWidgets);
    verifyNever(() => resourcesRepo.getResourceById('guide'));
  });

  testWidgets('a missing resource URL shows a result instead of spinning', (
    tester,
  ) async {
    when(
      () => resourcesRepo.getResourceById('missing'),
    ).thenAnswer((_) async => null);
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(buildApp(router));
    await tester.pumpAndSettle();
    router.goNamed(
      ResourceCommentPage.name,
      pathParameters: {ResourceCommentPage.pathParams: 'missing'},
    );
    await tester.pumpAndSettle();
    expect(find.text('This resource could not be found.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

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

  testWidgets('old Messages links return to Profile', (tester) async {
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(buildApp(router));
    for (final path in ['/Messages', '/Messages/Message/old-thread']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, ProfilePage.path);
      expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);
    }
    verifyNever(
      () => messagesRepo.getConversations(userEmail: any(named: 'userEmail')),
    );
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

  testWidgets(
    'nested navigation from a viewed rider to their horse and back '
    'preserves the viewed rider before returning to the user profile',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final signedInRider = RiderProfile(
        id: 'me',
        name: 'Signed In Rider',
        email: 'me@example.com',
        students: [
          BaseListItem(
            id: 'student@example.com',
            name: 'Alex Student',
            isCollapsed: true,
          ),
        ],
      );
      final viewedRider = RiderProfile(
        id: 'student@example.com',
        name: 'Alex Student',
        email: 'student@example.com',
        ownedHorses: [
          BaseListItem(
            id: 'starlight',
            name: 'Starlight',
            isCollapsed: false,
          ),
        ],
      );
      final horse = HorseProfile(
        id: 'starlight',
        name: 'Starlight',
        currentOwnerId: viewedRider.email,
        currentOwnerName: viewedRider.name,
      );

      when(
        () => riderRepo.getRiderProfile(email: viewedRider.email),
      ).thenAnswer((_) => Stream.value(viewedRider));
      when(
        () => horseRepo.getHorseProfileById(id: horse.id),
      ).thenAnswer((_) => Stream.value(horse));

      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);

      appCubit.emit(
        appCubit.state.copyWith(
          isGuest: false,
          usersProfile: signedInRider,
          isForRider: true,
          isViewing: false,
        ),
      );

      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // 1. Start on the user's own profile page.
      expect(find.text('Signed In Rider'), findsOneWidget);
      expect(appCubit.state.viewingProfile, isNull);
      expect(appCubit.state.horseProfile, isNull);

      // 2. Tap the student ProfileCard to open ViewingProfilePage.
      await tester.tap(find.text('Alex Student'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ViewingProfileView')), findsOneWidget);
      expect(appCubit.state.isViewing, isTrue);
      expect(appCubit.state.isForRider, isTrue);
      expect(appCubit.state.viewingProfile?.email, viewedRider.email);
      expect(appCubit.state.horseProfile, isNull);
      expect(appCubit.determineCurrentProfile()?.email, viewedRider.email);

      // 3. Tap the student's horse ProfileCard to open HorseProfilePage.
      await tester.tap(find.text('Starlight'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('horseProfileView')), findsOneWidget);
      expect(appCubit.state.isForRider, isFalse);
      expect(appCubit.state.isViewing, isFalse);
      expect(appCubit.state.horseProfile?.id, horse.id);
      // Parent viewingProfile remains cached while viewing the horse.
      expect(appCubit.state.viewingProfile?.email, viewedRider.email);

      // 4. Press Back from HorseProfilePage -> returns to ViewingProfilePage.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ViewingProfileView')), findsOneWidget);
      expect(find.text('Alex Student'), findsOneWidget);
      expect(appCubit.state.horseProfile, isNull);
      expect(appCubit.state.horseId, isEmpty);
      expect(appCubit.state.isViewing, isTrue);
      expect(appCubit.state.isForRider, isTrue);
      expect(appCubit.state.viewingProfile?.email, viewedRider.email);
      expect(appCubit.determineCurrentProfile()?.email, viewedRider.email);

      // 5. Press Back from ViewingProfilePage -> returns to user's ProfilePage.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Signed In Rider'), findsOneWidget);
      expect(appCubit.state.viewingProfile, isNull);
      expect(appCubit.state.horseProfile, isNull);
      expect(appCubit.state.isViewing, isFalse);
      expect(appCubit.state.isForRider, isTrue);
      expect(appCubit.determineCurrentProfile()?.email, signedInRider.email);
    },
  );

  testWidgets(
    'nested navigation from a horse profile to its owner and back '
    'preserves the horse before returning to the user profile',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final signedInRider = RiderProfile(
        id: 'me',
        name: 'Signed In Rider',
        email: 'me@example.com',
        studentHorses: [
          BaseListItem(
            id: 'starlight',
            name: 'Starlight',
            isCollapsed: false,
          ),
        ],
      );
      final ownerRider = RiderProfile(
        id: 'owner@example.com',
        name: 'Owner Rider',
        email: 'owner@example.com',
      );
      final horse = HorseProfile(
        id: 'starlight',
        name: 'Starlight',
        currentOwnerId: ownerRider.email,
        currentOwnerName: ownerRider.name,
      );

      when(
        () => riderRepo.getRiderProfile(email: ownerRider.email),
      ).thenAnswer((_) => Stream.value(ownerRider));
      when(
        () => horseRepo.getHorseProfileById(id: horse.id),
      ).thenAnswer((_) => Stream.value(horse));

      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);

      appCubit.emit(
        appCubit.state.copyWith(
          isGuest: false,
          usersProfile: signedInRider,
          isForRider: true,
          isViewing: false,
        ),
      );

      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // 1. Tap the student horse ProfileCard to open HorseProfilePage.
      await tester.tap(find.text('Starlight'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('horseProfileView')), findsOneWidget);
      expect(appCubit.state.isForRider, isFalse);
      expect(appCubit.state.isViewing, isFalse);
      expect(appCubit.state.horseProfile?.id, horse.id);
      expect(appCubit.state.viewingProfile, isNull);

      // 2. Tap the horse's owner button to open ViewingProfilePage.
      await tester.tap(find.byKey(const Key('currentOwner')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ViewingProfileView')), findsOneWidget);
      expect(find.text('Owner Rider'), findsOneWidget);
      expect(appCubit.state.isViewing, isTrue);
      expect(appCubit.state.isForRider, isTrue);
      expect(appCubit.state.viewingProfile?.email, ownerRider.email);
      // Parent horseProfile remains cached while viewing the owner.
      expect(appCubit.state.horseProfile?.id, horse.id);

      // 3. Press Back from ViewingProfilePage -> returns to HorseProfilePage.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('horseProfileView')), findsOneWidget);
      expect(find.text('Starlight'), findsOneWidget);
      expect(appCubit.state.viewingProfile, isNull);
      expect(appCubit.state.viewingProfielEmail, isEmpty);
      expect(appCubit.state.isViewing, isFalse);
      expect(appCubit.state.isForRider, isFalse);
      expect(appCubit.state.horseProfile?.id, horse.id);

      // 4. Press Back from HorseProfilePage -> returns to user's ProfilePage.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Signed In Rider'), findsOneWidget);
      expect(appCubit.state.horseProfile, isNull);
      expect(appCubit.state.viewingProfile, isNull);
      expect(appCubit.state.horseId, isEmpty);
      expect(appCubit.state.isViewing, isFalse);
      expect(appCubit.state.isForRider, isTrue);
    },
  );

  testWidgets(
    'ResourceCommentPage and SkillTreeView manage route state via lifecycle '
    'and observers without re-emitting on rebuilds',
    (tester) async {
      final resource = Resource(
        id: 'res-1',
        name: 'Groundwork Basics',
        skillTreeIds: const [],
      );
      when(
        () => resourcesRepo.getResources(),
      ).thenAnswer((_) => Stream.value([resource]));

      final router = Routes().router(
        settingsContoller: settingsController,
        appCubit: appCubit,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      router.goNamed(ResourcesPage.name);
      await tester.pumpAndSettle();
      expect(appCubit.state.pageStatus, AppPageStatus.resourceList);

      unawaited(
        router.pushNamed(
          ResourceCommentPage.name,
          pathParameters: {ResourceCommentPage.pathParams: resource.id!},
        ),
      );
      await tester.pumpAndSettle();
      expect(appCubit.state.pageStatus, AppPageStatus.resource);
      expect(appCubit.state.resource?.id, resource.id);

      // Popping ResourceCommentPage triggers routeObserverResources.onPop
      // and clears the active resource.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(appCubit.state.pageStatus, AppPageStatus.resourceList);
      expect(appCubit.state.resource, isNull);
    },
  );

  testWidgets(
    'scoped buildWhen guards prevent unrelated AppCubit emissions from '
    'rebuilding ProfilePage while preserving relevant updates',
    (tester) async {
      final rider = RiderProfile(
        id: 'rider-1',
        email: 'rider@example.com',
        name: 'Initial Rider',
      );
      appCubit.emit(
        appCubit.state.copyWith(
          isGuest: false,
          pageStatus: AppPageStatus.profile,
          usersProfile: rider,
        ),
      );

      var profileBuildCount = 0;
      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return BlocBuilder<AppCubit, AppState>(
                  buildWhen: (previous, current) =>
                      previous.pageStatus != current.pageStatus ||
                      previous.isGuest != current.isGuest ||
                      previous.usersProfile != current.usersProfile,
                  builder: (context, state) {
                    profileBuildCount++;
                    return const ProfilePage();
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(profileBuildCount, 1);
      expect(find.text('Initial Rider'), findsOneWidget);

      // Unrelated state changes must not trigger a ProfilePage rebuild.
      appCubit.emit(
        appCubit.state.copyWith(
          commentSortState: CommentSortState.Best,
          categorySortState: CategorySortState.Mounted,
          resourcesSortStatus: ResourcesSortStatus.oldest,
        ),
      );
      await tester.pump();
      expect(profileBuildCount, 1);

      // Relevant profile change must trigger a rebuild and show updated name.
      appCubit.emit(
        appCubit.state.copyWith(
          usersProfile: rider.copyWith(name: 'Updated Rider'),
        ),
      );
      await tester.pumpAndSettle();
      expect(profileBuildCount, 2);
      expect(find.text('Updated Rider'), findsOneWidget);
    },
  );
}
