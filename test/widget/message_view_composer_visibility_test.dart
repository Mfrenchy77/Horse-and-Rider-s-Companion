// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_text_field.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/message_view.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
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

void main() {
  group('MessageView composer visibility', () {
    late MockMessagesRepository messagesRepo;
    late MockSkillTreeRepository skillRepo;
    late MockResourcesRepository resourcesRepo;
    late MockRiderProfileRepository riderRepo;
    late MockHorseProfileRepository horseRepo;
    late MockAuthenticationRepository authRepo;

    setUp(() async {
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

      // Initialize SharedPrefs for MessageItem
      //and other widgets that depend on it
      // Use the in-memory mock store
      // Avoid importing SharedPrefs directly here to keep this file focused
      // on the view logic; SharedPreferences provides a mock init.
      // ignore: invalid_use_of_internal_member

      TestWidgetsFlutterBinding.ensureInitialized();
      // shared_preferences uses a static in-memory
      // instance when mock values are set
      // ignore: avoid_redundant_argument_values
      SharedPreferences.setMockInitialValues({});
      await SharedPrefs().init();
    });

    testWidgets('composer hidden for non-support conversations',
        (tester) async {
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

      final msg = Message(
        senderProfilePicUrl: 'example.com/profile_pics/other.png',
        id: 'c1',
        date: DateTime.now(),
        sender: 'Other',
        senderId: 'other@x.com',
        subject: 'Chat',
        message: 'Hello',
        messageId: 'm1',
        recipients: const ['Me', 'Other'],
      );
      final conv = Conversation(
        id: 'c1',
        parties: ['Me', 'Other'],
        partiesIds: ['me@example.com', 'other@x.com'],
        createdBy: 'Other',
        createdOn: DateTime.now(),
        lastEditBy: 'Other',
        lastEditDate: DateTime.now(),
        recentMessage: msg,
      );
      cubit.emit(cubit.state.copyWith(conversation: conv));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const MessageView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MessageTextField), findsNothing);
    });

    testWidgets('composer shown for support conversations', (tester) async {
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

      final msg = Message(
        senderProfilePicUrl: 'example.com/profile_pics/me.png',
        id: 'c2',
        date: DateTime.now(),
        sender: 'Me',
        senderId: 'me@example.com',
        subject: 'Support Message',
        message: 'Help',
        messageId: 'm2',
        recipients: const ['Me', "Horse & Rider's Companion"],
        messageType: MessageType.SUPPORT,
      );
      final conv = Conversation(
        id: 'c2',
        parties: ['Me', "Horse & Rider's Companion"],
        partiesIds: ['me@example.com', 'support@h&r'],
        createdBy: 'Me',
        createdOn: DateTime.now(),
        lastEditBy: 'Me',
        lastEditDate: DateTime.now(),
        recentMessage: msg,
      );
      cubit.emit(cubit.state.copyWith(conversation: conv));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const MessageView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MessageTextField), findsOneWidget);
    });
  });
}
