// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/forgot_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/login_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/register_view.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

Widget _wrap(Widget child, LoginCubit cubit) {
  return MaterialApp(
    home: BlocProvider<LoginCubit>.value(
      value: cubit,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockAuthenticationRepository authRepo;
  late LoginCubit cubit;

  setUp(() {
    authRepo = MockAuthenticationRepository();
    cubit = LoginCubit(authRepo);
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('Login button calls logInWithEmailAndPassword', (tester) async {
    when(
      () => authRepo.logInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const User(id: '1', name: 'User', email: 'user@example.com'),
    );

    await tester.pumpWidget(_wrap(loginView(), cubit));

    // Provide valid credentials via cubit (simpler than typing through fields).
    cubit
      ..emailChanged('user@example.com')
      ..passwordChanged('secret123');
    await tester.pump();

    await tester.tap(find.byKey(const Key('LoginViewAuthButton')));
    await tester.pump();

    verify(
      () => authRepo.logInWithEmailAndPassword(
        email: 'user@example.com',
        password: 'secret123',
      ),
    ).called(1);
  });

  testWidgets('Forgot link updates cubit to forgot page', (tester) async {
    await tester.pumpWidget(_wrap(loginView(), cubit));

    await tester.tap(find.byKey(const Key('LoginViewForgotPasswordLink')));
    await tester.pump();

    expect(cubit.state.pageStatus, LoginPageStatus.forgot);
  });

  testWidgets('Forgot view sends reset email', (tester) async {
    when(() => authRepo.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(forgotView(), cubit));

    cubit
      ..gotoForgot()
      ..emailChanged('reset@example.com');
    await tester.pump();

    await tester.tap(find.byKey(const Key('ForgotViewAuthButton')));
    await tester.pump();

    verify(() => authRepo.forgotPassword(email: 'reset@example.com')).called(1);
  });

  testWidgets('Register view submits sign up', (tester) async {
    when(
      () => authRepo.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const User(
        id: '2',
        name: 'Ava',
        email: 'ava@example.com',
        emailVerified: true,
        isGuest: false,
      ),
    );

    await tester.pumpWidget(_wrap(registerView(), cubit));

    cubit
      ..gotoRegister()
      ..nameChanged('Ava')
      ..emailChanged('ava@example.com')
      ..passwordChanged('secret123')
      ..confirmedPasswordChanged('secret123');
    await tester.pump();

    await tester.tap(find.byKey(const Key('RegisterViewAuthButton')));
    await tester.pump();

    verify(
      () => authRepo.signUp(
        name: 'Ava',
        email: 'ava@example.com',
        password: 'secret123',
      ),
    ).called(1);
  });

  testWidgets('Register button disabled when passwords do not match',
      (tester) async {
    await tester.pumpWidget(_wrap(registerView(), cubit));

    cubit
      ..gotoRegister()
      ..nameChanged('Ava')
      ..emailChanged('ava@example.com')
      ..passwordChanged('secret123')
      ..confirmedPasswordChanged('different');
    await tester.pump();

    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Register button re-disables after password changed',
      (tester) async {
    await tester.pumpWidget(_wrap(registerView(), cubit));

    cubit
      ..gotoRegister()
      ..nameChanged('Ava')
      ..emailChanged('ava@example.com')
      ..passwordChanged('secret123')
      ..confirmedPasswordChanged('secret123');
    await tester.pump();

    // Initially enabled (all valid and passwords match)
    var btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNotNull);

    // Change the original password -> should invalidate confirmation
    cubit.passwordChanged('newpassword');
    await tester.pump();

    btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Forgot button disabled until email is valid', (tester) async {
    await tester.pumpWidget(_wrap(forgotView(), cubit));

    cubit.gotoForgot();
    await tester.pump();

    // Initially invalid (empty email)
    var btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);

    // Enter invalid email -> still disabled
    cubit.emailChanged('invalid');
    await tester.pump();
    btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);

    // Enter valid email -> enabled
    cubit.emailChanged('valid@example.com');
    await tester.pump();
    btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Google login button triggers logInWithGoogle', (tester) async {
    when(() => authRepo.logInWithGoogle()).thenAnswer(
      (_) async => const User(id: 'g', name: 'G', email: 'g@x.com'),
    );

    await tester.pumpWidget(_wrap(loginView(), cubit));

    await tester.tap(find.byKey(const Key('LoginViewGoogleLoginButton')));
    await tester.pump();

    verify(() => authRepo.logInWithGoogle()).called(1);
  });

  testWidgets('Sign in as Guest triggers signInAsGuest', (tester) async {
    when(() => authRepo.signInAsGuest()).thenAnswer(
      (_) async => const User(
        id: 'guest',
        name: 'Guest',
        email: '',
      ),
    );

    await tester.pumpWidget(_wrap(loginView(), cubit));

    await tester.tap(find.text('Sign in as Guest'));
    await tester.pump();

    verify(() => authRepo.signInAsGuest()).called(1);
  });
}
