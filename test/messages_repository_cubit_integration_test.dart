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

      // Seed conversation
      final conv = Conversation(
        id: convId,
        parties: const ['Me', 'Other'],
        partiesIds: [meEmail, otherEmail],
        createdBy: 'Me',
        createdOn: DateTime.now(),
        lastEditBy: 'Me',
        lastEditDate: DateTime.now(),
        recentMessage: null,
      );
      await messagesRepo.createOrUpdateConversation(conversation: conv);

      // Seed two messages
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
        subject: 'Chat',
        message: 'Hi back',
        messageId: 'm2',
        recipients: const ['Me', 'Other'],
        senderProfilePicUrl: 'u/other.png',
      );

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

        // Load conversations
        ..getConversations();
      // wait until conversations are fetched
      await cubit.stream.firstWhere((s) => s.conversations != null);
      expect(cubit.state.conversations?.length, 1);
      expect(cubit.state.conversations?.first.id, convId);

      // Select conversation -> should start listening to messages
      cubit.setConversation(convId);
      await cubit.stream.firstWhere(
        (s) => s.messages != null && (s.messages?.isNotEmpty ?? false),
      );

      final msgs = cubit.state.messages!;
      expect(msgs.length, 2);
      // Should be ordered oldest->newest then
      //reversed in cubit (so latest first)
      expect(msgs.first.message, 'Hi back');
      expect(msgs.last.message, 'Hello');
    });
  });
}
