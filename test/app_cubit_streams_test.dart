// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:database_repository/database_repository.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Object?> {}

// Test cubit that overrides conversation lookup to avoid wiring QuerySnapshots
class TestAppCubit extends AppCubit {
  TestAppCubit({
    required this.convMap,
    required MessagesRepository messagesRepository,
    required SkillTreeRepository skillTreeRepository,
    required ResourcesRepository resourcesRepository,
    required RiderProfileRepository riderProfileRepository,
    required HorseProfileRepository horseProfileRepository,
    required AuthenticationRepository authenticationRepository,
  }) : super(
          messagesRepository: messagesRepository,
          skillTreeRepository: skillTreeRepository,
          resourcesRepository: resourcesRepository,
          riderProfileRepository: riderProfileRepository,
          horseProfileRepository: horseProfileRepository,
          authenticationRepository: authenticationRepository,
        );

  final Map<String, Conversation> convMap;

  @override
  Conversation? getConversationById(String id) => convMap[id];
}

void main() {
  setUpAll(() {
    // Set up shared_prefs mock store for tests
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(
      Conversation(
        id: 'fallback',
        parties: const ['a', 'b'],
        partiesIds: const ['a', 'b'],
        createdBy: 'a',
        createdOn: DateTime.fromMillisecondsSinceEpoch(0),
        lastEditBy: 'a',
        lastEditDate: DateTime.fromMillisecondsSinceEpoch(0),
        recentMessage: Message(
          id: 'fallback',
          date: DateTime.fromMillisecondsSinceEpoch(0),
          sender: 'a',
          subject: 's',
          message: 'm',
          messageId: 'mid',
          recipients: const ['a', 'b'],
          senderProfilePicUrl: '',
        ),
      ),
    );
  });
  group('AppCubit stream management', () {
    late MockMessagesRepository messagesRepo;
    late MockSkillTreeRepository skillRepo;
    late MockResourcesRepository resourcesRepo;
    late MockRiderProfileRepository riderRepo;
    late MockHorseProfileRepository horseRepo;
    late MockAuthenticationRepository authRepo;

    setUp(() {
      messagesRepo = MockMessagesRepository();
      skillRepo = MockSkillTreeRepository();
      resourcesRepo = MockResourcesRepository();
      riderRepo = MockRiderProfileRepository();
      horseRepo = MockHorseProfileRepository();
      authRepo = MockAuthenticationRepository();

      // AppCubit constructor reads currentUser and starts listening to auth.user
      when(() => authRepo.currentUser).thenReturn(User.empty);
      when(() => authRepo.user).thenAnswer((_) => const Stream<User?>.empty());

      // Skill/resources fetches run on init; return empty streams to avoid noise
      when(() => skillRepo.getSkills())
          .thenAnswer((_) => const Stream<QuerySnapshot>.empty());
      when(() => skillRepo.getAllTrainingPaths()).thenAnswer(
        (_) => const Stream<QuerySnapshot<TrainingPath>>.empty(),
      );
      when(() => resourcesRepo.getResources())
          .thenAnswer((_) => const Stream<QuerySnapshot<Resource>>.empty());
    });

    test('email verification timer does not re-emit unchanged value', () async {
      await SharedPrefs().init();

      // Auth emits a non-verified user
      final authController = StreamController<User?>();
      when(() => authRepo.user).thenAnswer((_) => authController.stream);
      when(() => authRepo.currentUser).thenReturn(User.empty);

      // Avoid noise from repositories called on init
      when(() => skillRepo.getSkills())
          .thenAnswer((_) => const Stream<QuerySnapshot>.empty());
      when(() => skillRepo.getAllTrainingPaths())
          .thenAnswer((_) => const Stream<QuerySnapshot<TrainingPath>>.empty());
      when(() => resourcesRepo.getResources())
          .thenAnswer((_) => const Stream<QuerySnapshot<Resource>>.empty());

      // Email verification polling dependencies
      when(() => authRepo.reloadCurrentUser()).thenAnswer((_) async {});
      // Always not verified
      when(() => authRepo.isEmailVerified()).thenReturn(false);

      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      var trueEmits = 0;
      final sub = cubit.stream.listen((s) {
        if (s.showEmailVerification) trueEmits++;
      });

      // Emit unverified user to start the timer and initial showEmailVerification=true
      authController.add(const User(
        id: 'U',
        name: 'User',
        email: 'u@x.com',
        isGuest: false,
        emailVerified: false,
      ));

      // Let microtasks settle
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Advance time to trigger multiple timer ticks (without changing verification)
      await Future<void>.delayed(const Duration(seconds: 11));
      await Future<void>.delayed(const Duration(seconds: 11));

      // We expect only the initial true emission, not duplicates for unchanged value
      expect(trueEmits, 1);

      await sub.cancel();
      await authController.close();
    });
    test(
      'getHorseProfile cancels previous subscription when selecting a different horse',
      () async {
        await SharedPrefs().init();
        // Arrange controllers to observe onListen/onCancel
        var listenedA = 0;
        var canceledA = 0;
        final controllerA = StreamController<DocumentSnapshot<Object?>>();
        controllerA.onListen = () => listenedA++;
        controllerA.onCancel = () {
          canceledA++;
          return Future.value();
        };

        final controllerB = StreamController<DocumentSnapshot<Object?>>();

        when(() => horseRepo.getHorseProfileById(id: 'A'))
            .thenAnswer((_) => controllerA.stream);
        when(() => horseRepo.getHorseProfileById(id: 'B'))
            .thenAnswer((_) => controllerB.stream);

        final cubit = AppCubit(
          messagesRepository: messagesRepo,
          skillTreeRepository: skillRepo,
          resourcesRepository: resourcesRepo,
          riderProfileRepository: riderRepo,
          horseProfileRepository: horseRepo,
          authenticationRepository: authRepo,
        );

        // Act: first subscribe to horse A
        await cubit.getHorseProfile(id: 'A');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(listenedA, 1, reason: 'should listen to first horse stream');

        // Switch to horse B — expected: previous subscription canceled
        await cubit.getHorseProfile(id: 'B');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: first stream was canceled when switching horses
        expect(canceledA, 1,
            reason:
                'previous horse stream should be canceled when switching IDs');

        // Cleanup controllers
        await controllerA.close();
        await controllerB.close();
        // Intentionally not closing cubit here due to unrelated late subscription
      },
    );

    test(
      'auth user change cancels previous rider profile subscription',
      () async {
        await SharedPrefs().init();
        // Arrange rider profile streams A and B
        var listenedA = 0;
        var canceledA = 0;
        final profileA = StreamController<DocumentSnapshot<Object?>>();
        profileA.onListen = () => listenedA++;
        profileA.onCancel = () {
          canceledA++;
          return Future.value();
        };
        final profileB = StreamController<DocumentSnapshot<Object?>>();

        when(() => riderRepo.getRiderProfile(email: 'a@x.com'))
            .thenAnswer((_) => profileA.stream);
        when(() => riderRepo.getRiderProfile(email: 'b@x.com'))
            .thenAnswer((_) => profileB.stream);

        // Auth stream that will emit two different users
        final authController = StreamController<User?>();
        when(() => authRepo.user).thenAnswer((_) => authController.stream);
        when(() => authRepo.currentUser).thenReturn(User.empty);

        final cubit = AppCubit(
          messagesRepository: messagesRepo,
          skillTreeRepository: skillRepo,
          resourcesRepository: resourcesRepo,
          riderProfileRepository: riderRepo,
          horseProfileRepository: horseRepo,
          authenticationRepository: authRepo,
        );

        // Emit first authenticated, verified, non-guest user A
        authController.add(const User(
          id: 'A',
          name: 'User A',
          email: 'a@x.com',
          isGuest: false,
          emailVerified: true,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(listenedA, 1, reason: 'should subscribe to profile A');

        // Emit second authenticated, verified, non-guest user B
        authController.add(const User(
          id: 'B',
          name: 'User B',
          email: 'b@x.com',
          isGuest: false,
          emailVerified: true,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(canceledA, 1,
            reason:
                'previous rider profile subscription should be cancelled when user changes');

        await authController.close();
        await profileA.close();
        await profileB.close();
        // Not closing cubit to avoid unrelated late final cancellation issues
      },
    );

    test('duplicate auth user events do not re-subscribe rider profile',
        () async {
      await SharedPrefs().init();

      // Arrange: a single rider profile stream for user A
      final profileA = StreamController<DocumentSnapshot<Object?>>();
      when(() => riderRepo.getRiderProfile(email: 'a@x.com'))
          .thenAnswer((_) => profileA.stream);

      // Auth stream emits same verified user twice
      final authController = StreamController<User?>();
      when(() => authRepo.user).thenAnswer((_) => authController.stream);
      when(() => authRepo.currentUser).thenReturn(User.empty);

      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final userA = const User(
        id: 'A',
        name: 'User A',
        email: 'a@x.com',
        isGuest: false,
        emailVerified: true,
      );

      authController.add(userA);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      authController.add(userA); // duplicate
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify rider profile subscription created only once for duplicate user
      verify(() => riderRepo.getRiderProfile(email: 'a@x.com')).called(1);

      await authController.close();
      await profileA.close();
    });

    test('auth user change cancels conversations stream', () async {
      await SharedPrefs().init();

      final authController = StreamController<User?>();
      when(() => authRepo.user).thenAnswer((_) => authController.stream);
      when(() => authRepo.currentUser).thenReturn(User.empty);

      // rider profiles stream and snapshots
      final rpA = StreamController<DocumentSnapshot<Object?>>();
      final rpB = StreamController<DocumentSnapshot<Object?>>();
      when(() => riderRepo.getRiderProfile(email: 'a@x.com'))
          .thenAnswer((_) => rpA.stream);
      when(() => riderRepo.getRiderProfile(email: 'b@x.com'))
          .thenAnswer((_) => rpB.stream);
      final dsA = MockDocumentSnapshot();
      when(() => dsA.data()).thenReturn(
        RiderProfile(id: 'idA', email: 'a@x.com', name: 'A', picUrl: ''),
      );
      final dsB = MockDocumentSnapshot();
      when(() => dsB.data()).thenReturn(
        RiderProfile(id: 'idB', email: 'b@x.com', name: 'B', picUrl: ''),
      );

      // conversations stream A with cancel tracking
      var canceledConvA = 0;
      final convA = StreamController<QuerySnapshot<Object?>>();
      convA.onCancel = () {
        canceledConvA++;
        return Future.value();
      };
      when(() => messagesRepo.getConversations(userEmail: 'a@x.com'))
          .thenAnswer((_) => convA.stream);
      when(() => messagesRepo.getConversations(userEmail: 'b@x.com'))
          .thenAnswer((_) => const Stream<QuerySnapshot>.empty());

      // init cubit
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      // Emit user A and provide their profile
      authController.add(const User(
        id: 'A',
        name: 'A',
        email: 'a@x.com',
        isGuest: false,
        emailVerified: true,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      rpA.add(dsA);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Open conversations
      cubit.getConversations();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Switch to user B triggers cancellation of conversations stream
      authController.add(const User(
        id: 'B',
        name: 'B',
        email: 'b@x.com',
        isGuest: false,
        emailVerified: true,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(canceledConvA, 1,
          reason:
              'conversations list stream should be canceled when auth user changes');

      await convA.close();
      await rpA.close();
      await rpB.close();
      await authController.close();
    });

    test('logout cancels streams and clears conversation/messages state', () async {
      await SharedPrefs().init();

      // auth stream and rider profile A
      final authController = StreamController<User?>();
      when(() => authRepo.user).thenAnswer((_) => authController.stream);
      when(() => authRepo.currentUser).thenReturn(User.empty);
      when(() => authRepo.logOut()).thenAnswer((_) async {});

      final rpA = StreamController<DocumentSnapshot<Object?>>();
      when(() => riderRepo.getRiderProfile(email: 'a@x.com'))
          .thenAnswer((_) => rpA.stream);
      final dsA = MockDocumentSnapshot();
      when(() => dsA.data()).thenReturn(
        RiderProfile(id: 'idA', email: 'a@x.com', name: 'A', picUrl: ''),
      );

      // conversations stream and messages stream with cancel tracking
      var convCanceled = 0;
      final convStream = StreamController<QuerySnapshot<Object?>>();
      convStream.onCancel = () {
        convCanceled++;
        return Future.value();
      };
      when(() => messagesRepo.getConversations(userEmail: 'a@x.com'))
          .thenAnswer((_) => convStream.stream);

      var msgCanceled = 0;
      final msgStream = StreamController<QuerySnapshot<Object?>>();
      msgStream.onCancel = () {
        msgCanceled++;
        return Future.value();
      };
      when(() => messagesRepo.getMessages(conversationId: 'C'))
          .thenAnswer((_) => msgStream.stream);

      // subclass to provide conversation by id
      final cubit = TestAppCubit(
        convMap: {
          'C': Conversation(
            id: 'C',
            parties: const ['A', 'X'],
            partiesIds: const ['a@x.com', 'x@y.com'],
            createdBy: 'A',
            createdOn: DateTime.now(),
            lastEditBy: 'A',
            lastEditDate: DateTime.now(),
            recentMessage: Message(
              id: 'C',
              date: DateTime.now(),
              sender: 'A',
              subject: 'Chat',
              message: 'Hello',
              messageId: 'm',
              recipients: const ['A', 'X'],
              senderProfilePicUrl: '',
            ),
          ),
        },
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      // login A
      authController.add(const User(
        id: 'A',
        name: 'A',
        email: 'a@x.com',
        isGuest: false,
        emailVerified: true,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      rpA.add(dsA);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // open conversations and messages
      cubit.getConversations();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      when(() => messagesRepo.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          )).thenAnswer((_) async {});
      cubit.setConversation('C');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // perform logout
      await cubit.logOutRequested();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(convCanceled, 1, reason: 'conversations stream should be canceled');
      expect(msgCanceled, 1, reason: 'messages stream should be canceled');
      expect(cubit.state.conversation, isNull);
      expect(cubit.state.messages, isNull);

      await convStream.close();
      await msgStream.close();
      await rpA.close();
      await authController.close();
    });
    test('setConversation cancels previous messages stream on switch',
        () async {
      // Arrange controllers to observe onListen/onCancel of first messages stream
      var listenedA = 0;
      var canceledA = 0;
      final messagesA = StreamController<QuerySnapshot<Object?>>();
      messagesA.onListen = () => listenedA++;
      messagesA.onCancel = () {
        canceledA++;
        return Future.value();
      };
      final messagesB = StreamController<QuerySnapshot<Object?>>();

      // Stub messages repository
      when(() => messagesRepo.getMessages(conversationId: 'A'))
          .thenAnswer((_) => messagesA.stream);
      when(() => messagesRepo.getMessages(conversationId: 'B'))
          .thenAnswer((_) => messagesB.stream);
      when(() => messagesRepo.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          )).thenAnswer((_) async {});

      // Minimal conversations
      Conversation convA = Conversation(
        id: 'A',
        parties: const ['u1', 'u2'],
        partiesIds: const ['u1', 'u2'],
        createdBy: 'u1',
        createdOn: DateTime.now(),
        lastEditBy: 'u1',
        lastEditDate: DateTime.now(),
        recentMessage: Message(
          id: 'A',
          date: DateTime.now(),
          sender: 'u1',
          subject: 'Chat',
          message: 'hi',
          messageId: 'm1',
          recipients: const ['u1', 'u2'],
          senderProfilePicUrl: '',
        ),
      );

      Conversation convB = Conversation(
        id: 'B',
        parties: const ['u1', 'u3'],
        partiesIds: const ['u1', 'u3'],
        createdBy: 'u1',
        createdOn: DateTime.now(),
        lastEditBy: 'u1',
        lastEditDate: DateTime.now(),
        recentMessage: Message(
          id: 'B',
          date: DateTime.now(),
          sender: 'u1',
          subject: 'Chat',
          message: 'yo',
          messageId: 'm2',
          recipients: const ['u1', 'u3'],
          senderProfilePicUrl: '',
        ),
      );

      final cubit = TestAppCubit(
        convMap: {'A': convA, 'B': convB},
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      // Act: first open conversation A
      cubit.setConversation('A');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(listenedA, 1, reason: 'should listen to first messages stream');

      // Switch to conversation B and expect previous messages stream cancelled
      cubit.setConversation('B');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(canceledA, 1,
          reason:
              'previous messages stream should be canceled when switching conversation');

      await messagesA.close();
      await messagesB.close();
    });
  });
}
