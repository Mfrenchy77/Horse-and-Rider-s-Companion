// ignore_for_file: prefer_const_constructors

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

    appCubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      horseProfileRepository: horseRepo,
      riderProfileRepository: riderRepo,
      authenticationRepository: authRepo,
    );
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

  testWidgets('Onboarding shows on app boot and completes via Routes/AppView',
      (tester) async {
    final router = Routes()
        .router(settingsContoller: settingsController, appCubit: appCubit);

    await tester.pumpWidget(buildApp(router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Trigger onboarding flag in cubit;
    // NavigationView should present the dialog
    appCubit.emit(appCubit.state.copyWith(showOnboarding: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Onboarding dialog should be visible
    expect(find.byKey(const Key('onboarding_dialog')), findsOneWidget);

    // Switch to Signed In tab and press Complete Profile
    await tester.tap(find.text('Signed In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Ensure the complete profile button is visible before tapping
    final completeBtnFinder =
        find.byKey(const Key('onboarding_complete_profile_button'));
    expect(completeBtnFinder, findsOneWidget);
    await tester.ensureVisible(completeBtnFinder);
    await tester.tap(completeBtnFinder, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Fill out profile form (verify fields exist first)
    final nameField = find.byKey(const Key('complete_profile_name'));
    final emailField = find.byKey(const Key('complete_profile_email'));
    final saveBtn = find.byKey(const Key('complete_profile_save'));

    expect(nameField, findsOneWidget);
    expect(emailField, findsOneWidget);
    expect(saveBtn, findsOneWidget);

    await tester.enterText(nameField, 'Integration User');
    await tester.enterText(emailField, 'integration@example.com');
    await tester.pump();
    await tester.tap(saveBtn, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Onboarding flag should be cleared by cubit.completeProfileFromOnboarding
    expect(appCubit.state.showOnboarding, isFalse);
    expect(appCubit.state.isProfileSetup, isTrue);

    // Capture the named argument and make assertions about it
    // (and assert it was called once)
    final captured = verify(
      () => riderRepo.createOrUpdateRiderProfile(
        riderProfile: captureAny(named: 'riderProfile'),
      ),
    ).captured;
    expect(captured.length, 1);
    expect(captured, isNotEmpty);
    final rp = captured.first as RiderProfile;
    expect(rp.email, 'integration@example.com');
    expect(rp.name, 'Integration User');
  });
}
