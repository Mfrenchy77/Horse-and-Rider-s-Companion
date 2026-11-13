import 'dart:async';
import 'dart:convert';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/notifications/push_notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryAuthGateway implements AuthGateway {
  _InMemoryAuthGateway({User initialUser = User.empty})
    : _current = initialUser;

  final _controller = StreamController<User?>.broadcast();
  final Map<String, ({String password, User user})> _accounts = {};

  User _current;
  String? accessToken = 'in-memory-token';
  int resendCount = 0;
  int reloadCount = 0;
  int resetCount = 0;

  @override
  Stream<User?> get user => _controller.stream;

  @override
  User get currentUser => _current;

  void _setUser(User next) {
    _current = next;
    _controller.add(next);
  }

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw SignUpWithEmailAndPasswordFailure.fromCode('email-already-in-use');
    }
    final created = User(
      id: 'id-$email',
      name: name,
      email: email,
      isGuest: false,
    );
    _accounts[email] = (password: password, user: created);
    _setUser(created);
    return created;
  }

  @override
  Future<User?> signInAsGuest() async {
    const guest = User(
      id: 'guest',
      name: 'Guest',
      email: '',
    );
    return guest;
  }

  @override
  Future<User?> logInWithGoogle() async {
    const googleUser = User(
      id: 'google-1',
      name: 'Google Rider',
      email: 'google@example.com',
      isGuest: false,
      emailVerified: true,
    );
    _setUser(googleUser);
    return googleUser;
  }

  @override
  Future<User?> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw LogInWithEmailAndPasswordFailure.fromCode('invalid-credential');
    }
    _setUser(account.user);
    return account.user;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    resetCount++;
  }

  @override
  Stream<bool> getEmailVerificationStatus() async* {
    yield _current.emailVerified;
  }

  @override
  Future<void> resendEmailVerification() async {
    resendCount++;
  }

  @override
  Future<void> logOut() async {
    _setUser(User.empty);
  }

  @override
  Future<void> reloadCurrentUser() async {
    reloadCount++;
  }

  @override
  bool isEmailVerified() => _current.emailVerified;

  @override
  Future<String?> getAccessToken() async =>
      _current.isEmpty ? null : accessToken;

  @override
  Future<void> reauthenticateWithPassword({required String password}) async {}

  @override
  Future<void> reauthenticateWithGoogle() async {}

  Future<void> dispose() => _controller.close();
}

class _NoOpPushService implements PushNotificationService {
  @override
  Future<void> ensureRegistered(String userEmail) async {}
}

class _StubMessagesStore implements MessagesStore {
  @override
  Future<void> createOrUpdateConversation({
    required Conversation conversation,
  }) async {}

  @override
  Future<void> createOrUpdateMessage({required Message message}) async {}

  @override
  void deleteConversation({required Conversation conversation}) {}

  @override
  void deleteMessage({
    required Message messageToDelete,
    required String conversationId,
  }) {}

  @override
  Stream<List<Conversation>> getConversations({required String userEmail}) =>
      const Stream.empty();

  @override
  Stream<List<Message>> getMessages({required String conversationId}) =>
      const Stream.empty();
}

class _StubSkillTreeStore implements SkillTreeStore {
  @override
  Future<void> createOrEditSkill({required Skill skill}) async {}

  @override
  Future<void> createOrEditTrainingPath({
    required TrainingPath trainingPath,
  }) async {}

  @override
  void deleteSkill({required Skill? skill}) {}

  @override
  void deleteTrainingPath({required TrainingPath? trainingPath}) {}

  @override
  Stream<List<TrainingPath>> getAllTrainingPaths() => const Stream.empty();

  @override
  Stream<List<Skill>> getSkills() => const Stream.empty();

  @override
  Stream<List<Skill>> getSkillsForHorseSkillTree() => const Stream.empty();

  @override
  Stream<List<Skill>> getSkillsForRiderSkillTree() => const Stream.empty();

  @override
  Stream<List<Skill>> getSkillsFromCategory({required String id}) =>
      const Stream.empty();

  @override
  Stream<TrainingPath?> getTrainingPathById({required String id}) =>
      const Stream.empty();
}

class _StubResourcesStore implements ResourcesStore {
  @override
  Future<void> createArticle({required Resource resource}) async {}

  @override
  Future<void> createOrUpdateResource({required Resource resource}) async {}

  @override
  Future<void> createResourceWithServerTimestamps({
    required Resource resource,
  }) async {}

  @override
  Future<void> deleteResource({required Resource resource}) async {}

  @override
  Future<void> editResourceRating({
    required Resource resource,
    required BaseListItem userWhoRated,
  }) async {}

  @override
  Future<Resource?> getArticleById(String id) async => null;

  @override
  Stream<List<Resource>> getPublishedArticles({
    List<String> tagsFilter = const [],
  }) => const Stream.empty();

  @override
  Future<Resource?> getResourceById(String id) async => null;

  @override
  Stream<List<Resource>> getResources() => const Stream.empty();

  @override
  Stream<List<Resource>> getResourcesForSkill({required String skillId}) =>
      const Stream.empty();

  @override
  Stream<List<Resource>> getResourcesOrderedByUpdatedAt() =>
      const Stream.empty();

  @override
  String newId() => 'res-1';

  @override
  Future<Comment> rateComment({
    required String resourceId,
    required String commentId,
    required String userEmail,
    required int vote,
  }) async => throw UnimplementedError();

  @override
  Future<void> setArticleStatus({
    required String id,
    required ResourceStatus status,
  }) async {}

  @override
  Future<void> updateArticleContent({
    required String id,
    String? title,
    String? description,
    String? content,
    List<String>? tags,
    String? coverImageUrl,
  }) async {}

  @override
  Future<void> updateSkillLinks({
    required String id,
    required Set<String> added,
    required Set<String> removed,
  }) async {}
}

class _StubRiderProfileStore implements RiderProfileStore {
  @override
  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  }) async {}

  @override
  Future<void> createOrUpdateRiderProfile({
    required RiderProfile riderProfile,
  }) async {}

  @override
  Future<void> deleteRiderProfile({required String email}) async {}

  @override
  Stream<RiderProfile?> getProfileByName({required String name}) =>
      const Stream.empty();

  @override
  Stream<List<RiderProfile>> getProfilesByName({required String name}) =>
      const Stream.empty();

  @override
  Stream<List<RiderProfile>> getProfilesByZipcode({required String zipcode}) =>
      const Stream.empty();

  @override
  Stream<RiderProfile?> getRiderProfile({required String email}) =>
      Stream.value(
        RiderProfile(id: 'u1', name: 'Alex', email: email),
      );

  @override
  Future<RiderProfile?> getRiderProfileByEmail({
    required String email,
    bool serverOnly = false,
  }) async => null;

  @override
  Future<void> saveContact({
    required String email,
    required BaseListItem contact,
    required bool add,
  }) async {}

  @override
  Future<void> saveRiderLogEntry({
    required String email,
    required BaseListItem entry,
    required bool isEdit,
  }) async {}
}

class _StubHorseProfileStore implements HorseProfileStore {
  @override
  Future<void> createOrUpdateHorseProfile({
    required HorseProfile horseProfile,
  }) async {}

  @override
  Future<void> deleteHorseProfile({required String id}) async {}

  @override
  Stream<List<HorseProfile>> getAllUsersHorses({required List<String>? ids}) =>
      const Stream.empty();

  @override
  Stream<List<HorseProfile>> getHorseByName({required String name}) =>
      const Stream.empty();

  @override
  Stream<List<HorseProfile>> getHorseByNickName({required String nickName}) =>
      const Stream.empty();

  @override
  Stream<List<HorseProfile>> getHorseByZipCode({required String zipCode}) =>
      const Stream.empty();

  @override
  Stream<HorseProfile?> getHorseProfile({required String? id}) =>
      const Stream.empty();

  @override
  Stream<HorseProfile?> getHorseProfileById({required String id}) =>
      const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthGateway backend independence', () {
    test(
      'LoginCubit authenticates and resets password via AuthGateway',
      () async {
        final auth = _InMemoryAuthGateway();
        addTearDown(auth.dispose);

        await auth.signUp(
          name: 'Alex',
          email: 'alex@example.com',
          password: 'Secret123!',
        );
        expect(auth.currentUser.email, 'alex@example.com');

        await auth.logOut();
        expect(auth.currentUser, User.empty);

        final cubit = LoginCubit(auth);
        addTearDown(cubit.close);

        cubit
          ..emailChanged('alex@example.com')
          ..passwordChanged('WrongPass1!');
        await cubit.logInWithCredentials();
        expect(cubit.state.status, FormStatus.failure);

        cubit.passwordChanged('Secret123!');
        await cubit.logInWithCredentials();
        expect(cubit.state.status, FormStatus.success);

        await cubit.sendForgotPasswordEmail();
        expect(auth.resetCount, 1);

        await cubit.logInWithGoogle();
        expect(auth.currentUser.email, 'google@example.com');
      },
    );

    test('AppCubit tracks auth stream and sign-out via AuthGateway', () async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefs().init();
      final auth = _InMemoryAuthGateway();
      addTearDown(auth.dispose);

      final appCubit = AppCubit(
        messagesRepository: _StubMessagesStore(),
        skillTreeRepository: _StubSkillTreeStore(),
        resourcesRepository: _StubResourcesStore(),
        riderProfileRepository: _StubRiderProfileStore(),
        horseProfileRepository: _StubHorseProfileStore(),
        authenticationRepository: auth,
        pushNotificationService: _NoOpPushService(),
      );
      addTearDown(appCubit.close);

      await auth.logInWithGoogle();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(appCubit.state.status, AppStatus.authenticated);
      expect(appCubit.state.user.email, 'google@example.com');

      await appCubit.logOutRequested();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(appCubit.state.status, AppStatus.unauthenticated);
      expect(appCubit.state.user, User.empty);
    });

    test(
      'ConnectionRepository reads bearer token from injected AuthGateway',
      () async {
        final auth = _InMemoryAuthGateway(
          initialUser: const User(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
            isGuest: false,
            emailVerified: true,
          ),
        );
        addTearDown(auth.dispose);

        final repo = ConnectionRepository(
          authGateway: auth,
          projectId: 'test-project',
        );

        String? capturedAuthHeader;
        await http.runWithClient(
          () async {
            final result = await repo.submit({'action': 'ping'});
            expect(result['ok'], isTrue);
          },
          () => MockClient((request) async {
            capturedAuthHeader = request.headers['Authorization'];
            return http.Response(
              jsonEncode({'result': {'ok': true}}),
              200,
            );
          }),
        );

        expect(capturedAuthHeader, 'Bearer in-memory-token');
      },
    );
  });
}
