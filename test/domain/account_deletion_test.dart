import 'dart:async';
import 'dart:convert';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/MainPages/Delete/firebase_account_deletion_repository.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/notifications/push_notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway(this._current);

  final _controller = StreamController<User?>.broadcast();
  User _current;
  bool loggedOut = false;
  bool reauthPasswordCalled = false;
  bool reauthGoogleCalled = false;
  ReauthenticationFailure? reauthError;

  @override
  Stream<User?> get user => _controller.stream;

  @override
  User get currentUser => _current;

  @override
  Future<String?> getAccessToken() async => _current.isEmpty ? null : 'tok-1';

  @override
  Future<void> logOut() async {
    loggedOut = true;
    _current = User.empty;
    _controller.add(User.empty);
  }

  @override
  Future<void> reauthenticateWithPassword({required String password}) async {
    reauthPasswordCalled = true;
    if (reauthError != null) throw reauthError!;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    reauthGoogleCalled = true;
    if (reauthError != null) throw reauthError!;
  }

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<User?> signInAsGuest() => throw UnimplementedError();

  @override
  Future<User?> logInWithGoogle() => throw UnimplementedError();

  @override
  Future<User?> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Stream<bool> getEmailVerificationStatus() => Stream.value(true);

  @override
  Future<void> resendEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  bool isEmailVerified() => _current.emailVerified;

  Future<void> dispose() => _controller.close();
}

class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  _FakeAccountDeletionRepository(this._handler);

  final Future<AccountDeletionResult> Function() _handler;
  int calls = 0;

  @override
  Future<AccountDeletionResult> deleteCurrentAccount() {
    calls++;
    return _handler();
  }
}

class _NoOpPushService implements PushNotificationService {
  @override
  Future<void> ensureRegistered(String userEmail) async {}
}

class _EmptyMessagesStore implements MessagesStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptySkillTreeStore implements SkillTreeStore {
  @override
  Stream<List<Skill>> getSkills() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyResourcesStore implements ResourcesStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyRiderProfileStore implements RiderProfileStore {
  @override
  Stream<RiderProfile?> getRiderProfile({required String email}) =>
      Stream.value(RiderProfile(id: email, name: 'Rider', email: email));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyHorseProfileStore implements HorseProfileStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppCubit _buildCubit({
  required AuthGateway auth,
  required AccountDeletionRepository deletionRepo,
}) {
  return AppCubit(
    messagesRepository: _EmptyMessagesStore(),
    skillTreeRepository: _EmptySkillTreeStore(),
    resourcesRepository: _EmptyResourcesStore(),
    riderProfileRepository: _EmptyRiderProfileStore(),
    horseProfileRepository: _EmptyHorseProfileStore(),
    authenticationRepository: auth,
    accountDeletionRepository: deletionRepo,
    pushNotificationService: _NoOpPushService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'isFirstLaunch': false});
    await SharedPrefs().init();
  });

  test(
    'AppCubit handles requiresRecentLogin, reauthenticates, then deletes',
    () async {
      const user = User(
        id: 'u1',
        email: 'rider@example.com',
        name: 'Rider',
        isGuest: false,
        emailVerified: true,
      );
      final auth = _FakeAuthGateway(user);
      var requireReauth = true;
      final deletionRepo = _FakeAccountDeletionRepository(() async {
        if (requireReauth) {
          return const AccountDeletionResult(
            status: AccountDeletionStatus.requiresRecentLogin,
            message: 'Please reauthenticate.',
          );
        }
        return const AccountDeletionResult(
          status: AccountDeletionStatus.completed,
          message: 'Account Deleted',
        );
      });

      final cubit = _buildCubit(auth: auth, deletionRepo: deletionRepo);
      addTearDown(() async {
        await cubit.close();
        await auth.dispose();
      });

      cubit.emailChanged('rider@example.com');
      await cubit.deleteAccount();

      expect(
        cubit.state.accountDeletionStatus,
        AccountDeletionUiStatus.requiresRecentLogin,
      );
      expect(cubit.state.status, AppStatus.authenticated);
      expect(auth.loggedOut, isFalse);

      requireReauth = false;
      await cubit.reauthenticateForDeletionWithPassword('secret123');

      expect(auth.reauthPasswordCalled, isTrue);
      expect(deletionRepo.calls, 2);
      expect(
        cubit.state.accountDeletionStatus,
        AccountDeletionUiStatus.completed,
      );
      expect(cubit.state.status, AppStatus.unauthenticated);
      expect(cubit.state.user, User.empty);
      expect(auth.loggedOut, isTrue);
    },
  );

  test('AppCubit keeps user signed in on AccountDeletionFailure', () async {
    const user = User(
      id: 'u1',
      email: 'rider@example.com',
      name: 'Rider',
      isGuest: false,
      emailVerified: true,
    );
    final auth = _FakeAuthGateway(user);
    final deletionRepo = _FakeAccountDeletionRepository(
      () async => throw const AccountDeletionFailure('Backend busy'),
    );

    final cubit = _buildCubit(auth: auth, deletionRepo: deletionRepo);
    addTearDown(() async {
      await cubit.close();
      await auth.dispose();
    });

    cubit.emailChanged('rider@example.com');
    await cubit.deleteAccount();

    expect(cubit.state.accountDeletionStatus, AccountDeletionUiStatus.failure);
    expect(cubit.state.accountDeletionError, 'Backend busy');
    expect(cubit.state.status, AppStatus.authenticated);
    expect(auth.loggedOut, isFalse);
  });

  test(
    'FirebaseAccountDeletionRepository parses completed and reauth responses',
    () async {
      const user = User(
        id: 'u1',
        name: 'Rider',
        email: 'rider@example.com',
        isGuest: false,
        emailVerified: true,
      );
      final auth = _FakeAuthGateway(user);
      addTearDown(auth.dispose);

      var mode = 'reauth';
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer tok-1');
        if (mode == 'reauth') {
          return http.Response(
            jsonEncode({
              'error': {
                'status': 'FAILED_PRECONDITION',
                'message': 'Recent login required',
                'details': {'code': 'requires-recent-login'},
              },
            }),
            400,
          );
        }
        return http.Response(
          jsonEncode({
            'result': {'status': 'completed'},
          }),
          200,
        );
      });

      final repo = FirebaseAccountDeletionRepository(
        authGateway: auth,
        projectId: 'demo-horse-rules',
        httpClient: mockClient,
      );

      final reauthResult = await repo.deleteCurrentAccount();
      expect(reauthResult.status, AccountDeletionStatus.requiresRecentLogin);

      mode = 'ok';
      final okResult = await repo.deleteCurrentAccount();
      expect(okResult.status, AccountDeletionStatus.completed);
    },
  );

  testWidgets('DeletePage shows reauth UI and closes only on completion', (
    tester,
  ) async {
    const user = User(
      id: 'u1',
      email: 'rider@example.com',
      name: 'Rider',
      isGuest: false,
      emailVerified: true,
    );
    final auth = _FakeAuthGateway(user);
    var requireReauth = true;
    final deletionRepo = _FakeAccountDeletionRepository(() async {
      if (requireReauth) {
        return const AccountDeletionResult(
          status: AccountDeletionStatus.requiresRecentLogin,
          message: 'Please reauthenticate.',
        );
      }
      return const AccountDeletionResult(
        status: AccountDeletionStatus.completed,
      );
    });
    final cubit = _buildCubit(auth: auth, deletionRepo: deletionRepo);
    addTearDown(() async {
      await cubit.close();
      await auth.dispose();
    });

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const DeletePage(),
                ),
                child: const Text('Open Delete'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'rider@example.com');
    await tester.pump();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Password'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);

    requireReauth = false;
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.ensureVisible(find.text('Verify Password'));
    await tester.tap(find.text('Verify Password'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account'), findsNothing);
  });
}
