// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('MessagesRepository + AppCubit integration (Fake Firestore)', () {
    late FakeFirebaseFirestore fake;
    late MessagesRepository messagesRepo;
    late MockSkillTreeRepository skillRepo;
    late MockResourcesRepository resourcesRepo;
    late MockRiderProfileRepository riderRepo;
    late MockHorseProfileRepository horseRepo;
    late MockAuthenticationRepository authRepo;

    setUp(() {
      fake = FakeFirebaseFirestore();
      messagesRepo = MessagesRepository(firestore: fake);
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

    test('loads conversations and messages for selected conversation',
        () async {
      const convId = 'conv_1';
      const meEmail = 'me@example.com';
      const otherEmail = 'other@example.com';

      // Seed two messages (including a pending instructor request)
      final m1 = Message(
        id: convId,
        date: DateTime.now().subtract(const Duration(minutes: 2)),
        sender: 'Me',
        senderId: meEmail,
        subject: 'Chat',
        message: 'Hello',
        messageId: 'm1',
        recipients: const ['Me', 'Other'],
        senderProfilePicUrl: 'u/me.png',
      );
      final m2 = Message(
        id: convId,
        date: DateTime.now().subtract(const Duration(minutes: 1)),
        sender: 'Other',
        senderId: otherEmail,
        subject: 'Instructor Request',
        message: 'Other requested Me as Instructor',
        messageId: 'm2',
        recipients: const ['Me', 'Other'],
        senderProfilePicUrl: 'u/other.png',
        messageType: MessageType.INSTRUCTOR_REQUEST,
        requestItem: BaseListItem(id: otherEmail, isSelected: false),
      );

      // Seed conversation with recentMessage
      final conv = Conversation(
        id: convId,
        parties: const ['Me', 'Other'],
        partiesIds: [meEmail, otherEmail],
        createdBy: 'Me',
        createdOn: DateTime.now(),
        lastEditBy: 'Me',
        lastEditDate: DateTime.now(),
        recentMessage: m2,
      );
      await messagesRepo.createOrUpdateConversation(conversation: conv);

      await messagesRepo.createOrUpdateMessage(message: m1);
      await messagesRepo.createOrUpdateMessage(message: m2);

      // Cubit with fake-backed repo
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      // Seed current user
      final me = RiderProfile(id: 'me', name: 'Me', email: meEmail);
      cubit
        ..emit(cubit.state.copyWith(usersProfile: me))

      // Load connection requests backed by legacy Conversations/Messages
        ..getConversations();
      // wait until requests are fetched
      await cubit.stream.firstWhere((s) => s.connectionRequests != null);
      expect(cubit.state.connectionRequests?.length, 1);
      expect(cubit.state.connectionRequests?.first.id, convId);
    });
  });
}
