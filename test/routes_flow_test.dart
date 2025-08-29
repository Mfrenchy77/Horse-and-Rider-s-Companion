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
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
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

    when(() => skillRepo.getSkills())
        .thenAnswer((_) => Stream.value(<Skill>[]));
    when(() => skillRepo.getAllTrainingPaths())
        .thenAnswer((_) => Stream.value(<TrainingPath>[]));
    when(() => resourcesRepo.getResources())
        .thenAnswer((_) => Stream.value(<Resource>[]));

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
    // Do not close AppCubit here; close() expects late-initialized
    // subscriptions which aren’t always set in these tests.
  });

  Widget buildApp(GoRouter router) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: messagesRepo),
        RepositoryProvider.value(value: skillRepo),
        RepositoryProvider.value(value: resourcesRepo),
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

  testWidgets('Routes initial location shows ProfilePage (guest)',
      (tester) async {
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Expect initial location to be the profile branch
    expect(router.routeInformationProvider.value.uri, ProfilePage.path);
    // Guest profile should be visible by default
    expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);
  });

  testWidgets('Branch navigation via AppCubit index changes', (tester) async {
    final router = Routes().router(
      settingsContoller: settingsController,
      appCubit: appCubit,
    );
    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Start on Profile
    expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);

    // Go to Skill Tree (index 1)
    appCubit.changeIndex(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri, SkillTreePage.path);
    expect(find.byKey(const Key('skillTreeView')), findsOneWidget);

    // Go to Resources (index 2)
    appCubit.changeIndex(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri, ResourcesPage.path);
    expect(find.byKey(const Key('resourcesView')), findsOneWidget);

    // Back to Profile (index 0)
    appCubit.changeIndex(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri, ProfilePage.path);
    expect(find.byKey(const Key('GuestProfileView')), findsOneWidget);

    // Let any branch slide timers complete to avoid pending timers
    await tester.pump(const Duration(milliseconds: 400));
  });
}
