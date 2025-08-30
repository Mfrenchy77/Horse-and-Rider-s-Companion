// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart'
    as auth;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/user_onboarding_dialog.dart';
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

class RiderProfileFake extends Fake implements RiderProfile {}

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

    // Authentication stubs
    when(() => authRepo.currentUser).thenReturn(auth.User.empty);
    when(() => authRepo.user)
        .thenAnswer((_) => const Stream<auth.User?>.empty());

    // Stream-returning repos
    when(() => skillRepo.getSkills())
        .thenAnswer((_) => Stream.value(<Skill>[]));
    when(() => skillRepo.getAllTrainingPaths())
        .thenAnswer((_) => Stream.value(<TrainingPath>[]));
    when(() => resourcesRepo.getResources())
        .thenAnswer((_) => Stream.value(<Resource>[]));

    // Rider repo should accept a RiderProfile
    registerFallbackValue(RiderProfileFake());
    when(
      () => riderRepo.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => riderRepo.getRiderProfile(email: any(named: 'email')),
    ).thenAnswer((_) => Stream<RiderProfile?>.value(null));

    appCubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      horseProfileRepository: horseRepo,
      riderProfileRepository: riderRepo,
      authenticationRepository: authRepo,
    );
  });

  Widget buildHarness() {
    var presented = false;
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
        child: MaterialApp(
          home: Builder(
            builder: (context) => BlocListener<AppCubit, AppState>(
              listener: (context, state) async {
                final shouldShowUserOnboarding = (state.showOnboarding ||
                        (!state.isProfileSetup &&
                            state.status == AppStatus.authenticated)) &&
                    state.status == AppStatus.authenticated;
                if (!presented && shouldShowUserOnboarding) {
                  presented = true;
                  await showDialog<String?>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const UserOnboardingDialog(),
                  );
                  appCubit.completeOnboarding();
                }
              },
              child: const Scaffold(body: Center(child: Text('Home'))),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('User onboarding shows and opens Edit Profile', (tester) async {
    // Simulate a signed-in, verified user
    final signedIn = auth.User(
      id: 'u1',
      name: 'Integration User',
      email: 'integration@example.com',
      isGuest: false,
      emailVerified: true,
    );
    when(() => authRepo.currentUser).thenReturn(signedIn);
    when(() => authRepo.user).thenAnswer((_) => Stream.value(signedIn));

    // Recreate cubit after stubbing auth so initial state is authenticated
    appCubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      horseProfileRepository: horseRepo,
      riderProfileRepository: riderRepo,
      authenticationRepository: authRepo,
    );

    await tester.pumpWidget(buildHarness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Trigger onboarding flag in cubit (ensure a state change)
    appCubit.emit(appCubit.state.copyWith(showOnboarding: false));
    await tester.pump();
    appCubit.emit(appCubit.state.copyWith(showOnboarding: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // User onboarding dialog should be visible
    expect(find.byKey(const Key('user_onboarding_dialog')), findsOneWidget);

    // Tap finish to close onboarding
    final finishBtn = find.byKey(const Key('user_onboarding_finish'));
    expect(finishBtn, findsOneWidget);
    await tester.tap(finishBtn, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Onboarding flag should be cleared
    expect(appCubit.state.showOnboarding, isFalse);

    // Onboarding dialog should be gone
    expect(find.byKey(const Key('user_onboarding_dialog')), findsNothing);
  });
}
