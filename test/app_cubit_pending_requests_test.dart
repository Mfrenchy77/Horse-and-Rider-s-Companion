// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('AppCubit pending requests', () {
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

      when(() => authRepo.currentUser).thenReturn(User.empty);
      when(() => authRepo.user).thenAnswer((_) => const Stream<User?>.empty());

      when(() => skillRepo.getSkills())
          .thenAnswer((_) => const Stream<List<Skill>>.empty());
      when(() => skillRepo.getAllTrainingPaths())
          .thenAnswer((_) => const Stream<List<TrainingPath>>.empty());
      when(() => resourcesRepo.getResources())
          .thenAnswer((_) => const Stream<List<Resource>>.empty());
    });

    test('pendingRequestCount and conversations computed correctly', () {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      cubit.emit(cubit.state.copyWith(usersProfile: me));

      // 1) Pending instructor request from Other
      final msg1 = Message(
        id: 'c1',
        date: DateTime.now(),
        senderProfilePicUrl: 'example.com/profile_pics/other.png',
        sender: 'Other',
        senderId: 'other@x.com',
        subject: 'Instructor Request',
        message: 'Other has requested to be your Instructor',
        messageId: 'm1',
        recipients: const ['Me', 'Other'],
        messageType: MessageType.INSTRUCTOR_REQUEST,
        requestItem: BaseListItem(id: 'other@x.com', isSelected: false),
      );
      final c1 = Conversation(
        id: 'c1',
        parties: ['Me', 'Other'],
        partiesIds: ['me@example.com', 'other@x.com'],
        createdBy: 'Other',
        createdOn: DateTime.now(),
        lastEditBy: 'Other',
        lastEditDate: DateTime.now(),
        recentMessage: msg1,
      );

      // 2) Accepted request (should not count)
      final msg2 = Message(
        senderProfilePicUrl: 'example.com/profile_pics/another.png',
        id: 'c2',
        date: DateTime.now(),
        sender: 'Another',
        senderId: 'another@x.com',
        subject: 'Student Request',
        message: 'Another has requested to be your Student',
        messageId: 'm2',
        recipients: const ['Me', 'Another'],
        messageType: MessageType.STUDENT_REQUEST,
        requestItem: BaseListItem(id: 'another@x.com', isSelected: true),
      );
      final c2 = Conversation(
        id: 'c2',
        parties: ['Me', 'Another'],
        partiesIds: ['me@example.com', 'another@x.com'],
        createdBy: 'Another',
        createdOn: DateTime.now(),
        lastEditBy: 'Another',
        lastEditDate: DateTime.now(),
        recentMessage: msg2,
      );

      // 3) Non-request chat (should not count)
      final msg3 = Message(
        senderProfilePicUrl: 'example.com/profile_pics/other.png',
        id: 'c3',
        date: DateTime.now(),
        sender: 'Other',
        senderId: 'other@x.com',
        subject: 'Chat',
        message: 'Hello',
        messageId: 'm3',
        recipients: const ['Me', 'Other'],
      );
      final c3 = Conversation(
        id: 'c3',
        parties: ['Me', 'Other'],
        partiesIds: ['me@example.com', 'other@x.com'],
        createdBy: 'Other',
        createdOn: DateTime.now(),
        lastEditBy: 'Other',
        lastEditDate: DateTime.now(),
        recentMessage: msg3,
      );

      // 4) Pending Student Horse request
      final msg4 = Message(
        senderProfilePicUrl: 'example.com/profile_pics/owner.png',
        id: 'c4',
        date: DateTime.now(),
        sender: 'Owner',
        senderId: 'owner@x.com',
        subject: 'Student Horse Request',
        message: 'Add Horse1 as student horse',
        messageId: 'm4',
        recipients: const ['Me', 'Owner'],
        messageType: MessageType.STUDENT_HORSE_REQUEST,
        requestItem: BaseListItem(id: 'h1', isSelected: false),
      );
      final c4 = Conversation(
        id: 'c4',
        parties: ['Me', 'Owner'],
        partiesIds: ['me@example.com', 'owner@x.com'],
        createdBy: 'Owner',
        createdOn: DateTime.now(),
        lastEditBy: 'Owner',
        lastEditDate: DateTime.now(),
        recentMessage: msg4,
      );

      // 5) Request initiated by current user (should not count)
      final msg5 = Message(
        senderProfilePicUrl: 'example.com/profile_pics/me.png',
        id: 'c5',
        date: DateTime.now(),
        sender: 'Me',
        senderId: 'me@example.com',
        subject: 'Instructor Request',
        message: 'Me requested',
        messageId: 'm5',
        recipients: const ['Me', 'Other'],
        messageType: MessageType.INSTRUCTOR_REQUEST,
        requestItem: BaseListItem(id: 'other@x.com', isSelected: false),
      );
      final c5 = Conversation(
        id: 'c5',
        parties: ['Me', 'Other'],
        partiesIds: ['me@example.com', 'other@x.com'],
        createdBy: 'Me',
        createdOn: DateTime.now(),
        lastEditBy: 'Me',
        lastEditDate: DateTime.now(),
        recentMessage: msg5,
      );

      cubit.emit(
        cubit.state.copyWith(
          conversations: [c1, c2, c3, c4, c5],
        ),
      );

      expect(cubit.pendingRequestCount(), 2);
      final pending = cubit.pendingRequestConversations();
      expect(pending.map((e) => e.id), containsAll(['c1', 'c4']));
      expect(pending.map((e) => e.id), isNot(contains('c2')));
      expect(pending.map((e) => e.id), isNot(contains('c3')));
      expect(pending.map((e) => e.id), isNot(contains('c5')));
    });
  });
}
