// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

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

  group('LoginCubit basics', () {
    test('initial state', () {
      expect(cubit.state.status, FormStatus.initial);
      expect(cubit.state.pageStatus, LoginPageStatus.login);
    });

    blocTest<LoginCubit, LoginState>(
      'togglePasswordVisible toggles boolean',
      build: () => cubit,
      act: (c) => c.togglePasswordVisible(),
      expect: () => [
        isA<LoginState>().having((s) => s.isPasswordVisible, 'visible', true),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'navigation updates pageStatus',
      build: () => cubit,
      act: (c) {
        c
          ..gotoRegister()
          ..gotoForgot()
          ..gotoLogin();
      },
      expect: () => [
        isA<LoginState>()
            .having((s) => s.pageStatus, 'register', LoginPageStatus.register),
        isA<LoginState>()
            .having((s) => s.pageStatus, 'forgot', LoginPageStatus.forgot),
        isA<LoginState>()
            .having((s) => s.pageStatus, 'login', LoginPageStatus.login),
      ],
    );
  });

  group('Login with credentials', () {
    blocTest<LoginCubit, LoginState>(
      'emits submitting -> success (+message) -> cleared on success',
      build: () {
        when(
          () => authRepo.logInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const User(id: '1', name: 'Sam', email: 's@e.com'),
        );
        return cubit;
      },
      act: (c) async {
        c
          ..emailChanged('sam@example.com')
          ..passwordChanged('secret123');
        await c.logInWithCredentials();
      },
      skip: 2, // skip emailChanged + passwordChanged emissions
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'success', FormStatus.success)
            .having((s) => s.isMessage, 'isMessage', true)
            .having((s) => s.message, 'msg', startsWith('Welcome')),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
      verify: (_) {
        verify(
          () => authRepo.logInWithEmailAndPassword(
            email: 'sam@example.com',
            password: 'secret123',
          ),
        ).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'emits submitting -> failure (+error) -> cleared on failure',
      build: () {
        when(
          () => authRepo.logInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const LogInWithEmailAndPasswordFailure('Wrong password'));
        return cubit;
      },
      act: (c) async {
        c
          ..emailChanged('sam@example.com')
          ..passwordChanged('bad');
        await c.logInWithCredentials();
      },
      skip: 2, // skip emailChanged + passwordChanged emissions
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'failure', FormStatus.failure)
            .having((s) => s.isError, 'isError', true)
            .having((s) => s.message, 'err', contains('Wrong password')),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
    );
  });

  group('Register', () {
    blocTest<LoginCubit, LoginState>(
      'success path when email verified',
      build: () {
        when(
          () => authRepo.signUp(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const User(
            id: '42',
            name: 'Ava',
            email: 'ava@example.com',
            emailVerified: true,
            isGuest: false,
          ),
        );
        return cubit;
      },
      act: (c) async {
        c
          ..gotoRegister()
          ..nameChanged('Ava')
          ..emailChanged('ava@example.com')
          ..passwordChanged('secret123')
          ..confirmedPasswordChanged('secret123');
        await c.signUpFormSubmitted(context: _MockBuildContext());
      },
      // skip: gotoRegister + nameChanged + emailChanged
      // + passwordChanged + confirmedPasswordChanged
      skip: 5,
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'success', FormStatus.success)
            .having((s) => s.isMessage, 'message', true)
            .having((s) => s.message, 'msg', contains('Welcome Ava')),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
      verify: (_) {
        verify(
          () => authRepo.signUp(
            name: 'Ava',
            email: 'ava@example.com',
            password: 'secret123',
          ),
        ).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'success path when email NOT verified (shows verify message)',
      build: () {
        when(
          () => authRepo.signUp(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const User(
            id: '42',
            name: 'Ava',
            email: 'ava@example.com',
            isGuest: false,
          ),
        );
        return cubit;
      },
      act: (c) async {
        c
          ..gotoRegister()
          ..nameChanged('Ava')
          ..emailChanged('ava@example.com')
          ..passwordChanged('secret123')
          ..confirmedPasswordChanged('secret123');
        await c.signUpFormSubmitted(context: _NoopBuildContext());
      },
      skip: 5,
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'success', FormStatus.success)
            .having((s) => s.isMessage, 'message', true)
            .having(
              (s) => s.message,
              'msg',
              contains('please check your email'),
            ),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
    );
  });

  group('Forgot password', () {
    blocTest<LoginCubit, LoginState>(
      'emits submitting -> message + reset to login -> cleared',
      build: () {
        when(() => authRepo.forgotPassword(email: any(named: 'email')))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (c) async {
        c
          ..gotoForgot()
          ..emailChanged('forgot@example.com');
        await c.sendForgotPasswordEmail();
      },
      skip: 2, // skip gotoForgot + emailChanged emissions
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.isMessage, 'message', true)
            .having((s) => s.forgotEmailSent, 'flag', true)
            .having((s) => s.pageStatus, 'back to login', LoginPageStatus.login)
            .having((s) => s.status, 'status reset', FormStatus.initial),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
      verify: (_) {
        verify(() => authRepo.forgotPassword(email: 'forgot@example.com'))
            .called(1);
      },
    );
  });

  group('Google and Guest', () {
    blocTest<LoginCubit, LoginState>(
      'logInWithGoogle success -> success + message then cleared',
      build: () {
        when(() => authRepo.logInWithGoogle()).thenAnswer(
          (_) async => const User(id: 'g', name: 'GUser', email: 'g@x.com'),
        );
        return cubit;
      },
      act: (c) async => c.logInWithGoogle(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'success', FormStatus.success)
            .having((s) => s.isMessage, 'message', true),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
      verify: (_) {
        verify(() => authRepo.logInWithGoogle()).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'logInAsGuest success -> success + message then cleared',
      build: () {
        when(() => authRepo.signInAsGuest()).thenAnswer(
          (_) async => const User(
            id: 'guest',
            name: 'Guest',
            email: '',
          ),
        );
        return cubit;
      },
      act: (c) async => c.logInAsGuest(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'submitting', FormStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'success', FormStatus.success)
            .having((s) => s.isMessage, 'message', true)
            .having((s) => s.isGuest, 'guest flag', true),
        isA<LoginState>()
            .having((s) => s.isMessage, 'cleared message', false)
            .having((s) => s.isError, 'cleared error', false),
      ],
      verify: (_) {
        verify(() => authRepo.signInAsGuest()).called(1);
      },
    );
  });
}

// Simple mock BuildContext for testing.
class _MockBuildContext extends Mock implements BuildContext {}

// No-op BuildContext for tests where context is not used.
class _NoopBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
