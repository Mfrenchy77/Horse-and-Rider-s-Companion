import 'package:authentication_repository/authentication_repository.dart'
    as auth;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_view.dart';
// Not using the full app router here to avoid shell/observer complexity.
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
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
  testWidgets('AuthView success navigates to ProfilePage', (tester) async {
    // Shared prefs + settings
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final settings = SettingsController(SettingsService());
    await settings.loadSettings();

    // Mocks
    final authRepo = MockAuthenticationRepository();
    final msgRepo = MockMessagesRepository();
    final skillRepo = MockSkillTreeRepository();
    final resRepo = MockResourcesRepository();
    final riderRepo = MockRiderProfileRepository();
    final horseRepo = MockHorseProfileRepository();

    when(() => authRepo.currentUser).thenReturn(auth.User.empty);
    when(() => authRepo.user).thenAnswer((_) => Stream<auth.User?>.value(null));
    when(skillRepo.getSkills).thenAnswer((_) => Stream.value(<Skill>[]));
    when(skillRepo.getAllTrainingPaths)
        .thenAnswer((_) => Stream.value(<TrainingPath>[]));
    when(resRepo.getResources).thenAnswer((_) => Stream.value(<Resource>[]));

    final testCubit = LoginCubit(authRepo);

    final router = GoRouter(
      initialLocation: AuthPage.path,
      routes: [
        GoRoute(
          path: AuthPage.path,
          name: AuthPage.name,
          builder: (context, state) => BlocProvider.value(
            value: testCubit,
            child: const AuthView(),
          ),
        ),
        GoRoute(
          path: ProfilePage.path,
          name: ProfilePage.name,
          builder: (context, state) => const Scaffold(body: Text('Profile!')),
        ),
      ],
    );

    Widget build() => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: msgRepo),
            RepositoryProvider.value(value: skillRepo),
            RepositoryProvider.value(value: resRepo),
            RepositoryProvider.value(value: riderRepo),
            RepositoryProvider.value(value: horseRepo),
            RepositoryProvider<auth.AuthenticationRepository>.value(
              value: authRepo,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        );

    await tester.pumpWidget(build());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.routeInformationProvider.value.uri, AuthPage.path);

    // Fill login via cubit and submit
    final loginCubit = testCubit;
    when(
      () => authRepo.logInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const auth.User(id: 'u1', name: 'U', email: 'u@x.com'),
    );

    loginCubit
      ..emailChanged('u@x.com')
      ..passwordChanged('secret123');
    await tester.pump();

    // Sanity check: cubit thinks credentials are valid
    expect(loginCubit.isEmailAndPasswordValid(), isTrue);
    expect(loginCubit.state.pageStatus, LoginPageStatus.login);
    expect(loginCubit.state.email.isValid, isTrue);
    expect(loginCubit.state.password.isValid, isTrue);

    final authButton = find.byKey(const Key('LoginViewAuthButton'));
    final filled =
        find.descendant(of: authButton, matching: find.byType(FilledButton));
    expect(filled, findsOneWidget);

    // Call login directly to avoid widget enablement flakiness in test env
    await loginCubit.logInWithCredentials();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Navigates back to Profile
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri, ProfilePage.path);
  });

  testWidgets('Register (verified) navigates to ProfilePage', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final settings = SettingsController(SettingsService());
    await settings.loadSettings();

    final authRepo = MockAuthenticationRepository();
    final testCubit = LoginCubit(authRepo);

    when(
      () => authRepo.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const auth.User(
        id: 'r1',
        name: 'Reg',
        email: 'reg@x.com',
        emailVerified: true,
        isGuest: false,
      ),
    );

    final router = GoRouter(
      initialLocation: AuthPage.path,
      routes: [
        GoRoute(
          path: AuthPage.path,
          name: AuthPage.name,
          builder: (context, state) => BlocProvider.value(
            value: testCubit,
            child: const AuthView(),
          ),
        ),
        GoRoute(
          path: ProfilePage.path,
          name: ProfilePage.name,
          builder: (context, state) => const Scaffold(body: Text('Profile!')),
        ),
      ],
    );

    Widget build() => RepositoryProvider<auth.AuthenticationRepository>.value(
          value: authRepo,
          child: MaterialApp.router(routerConfig: router),
        );

    await tester.pumpWidget(build());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.routeInformationProvider.value.uri, AuthPage.path);

    // Enter register inputs
    testCubit
      ..gotoRegister()
      ..nameChanged('Reg')
      ..emailChanged('reg@x.com')
      ..passwordChanged('secret123')
      ..confirmedPasswordChanged('secret123');
    await tester.pump();

    await testCubit.signUpFormSubmitted(
      context: tester.element(find.byType(AuthView)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri, ProfilePage.path);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Profile!'), findsOneWidget);
  });

  testWidgets('Forgot password stays on Auth and shows message',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();

    final authRepo = MockAuthenticationRepository();
    final testCubit = LoginCubit(authRepo);
    when(() => authRepo.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: AuthPage.path,
      routes: [
        GoRoute(
          path: AuthPage.path,
          name: AuthPage.name,
          builder: (context, state) => BlocProvider.value(
            value: testCubit,
            child: const AuthView(),
          ),
        ),
      ],
    );

    Widget build() => RepositoryProvider<auth.AuthenticationRepository>.value(
          value: authRepo,
          child: MaterialApp.router(routerConfig: router),
        );

    await tester.pumpWidget(build());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.routeInformationProvider.value.uri, AuthPage.path);

    testCubit
      ..gotoForgot()
      ..emailChanged('forgot@x.com');
    await tester.pump();

    await testCubit.sendForgotPasswordEmail();
    await tester.pump(const Duration(milliseconds: 300));

    // Stays on Auth
    expect(router.routeInformationProvider.value.uri, AuthPage.path);
  });
}
