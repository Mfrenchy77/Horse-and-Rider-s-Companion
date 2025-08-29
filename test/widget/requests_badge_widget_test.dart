// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/requests_badge_button.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
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
  group('RequestsBadgeButton widget', () {
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

    testWidgets('shows badge with count', (tester) async {
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

      final reqMsg = Message(
        senderProfilePicUrl: 'example.com/profile_pics/other.png',
        id: 'c1',
        date: DateTime.now(),
        sender: 'Other',
        senderId: 'other@x.com',
        subject: 'Instructor Request',
        message: 'Please add as instructor',
        messageId: 'm100',
        recipients: const ['Me', 'Other'],
        messageType: MessageType.INSTRUCTOR_REQUEST,
        requestItem: BaseListItem(id: 'other@x.com', isSelected: false),
      );
      final conv = Conversation(
        id: 'c1',
        parties: ['Me', 'Other'],
        partiesIds: ['me@example.com', 'other@x.com'],
        createdBy: 'Other',
        createdOn: DateTime.now(),
        lastEditBy: 'Other',
        lastEditDate: DateTime.now(),
        recentMessage: reqMsg,
      );

      cubit.emit(cubit.state.copyWith(conversations: [conv]));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              appBar: AppBar(actions: const [RequestsBadgeButton()]),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge icon should be visible since we have one pending request
      final reqBtn = find.widgetWithIcon(IconButton, Icons.notifications);
      expect(reqBtn, findsOneWidget);
      // Badge count should display '1'
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('hides badge when no pending requests', (tester) async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );
      final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      cubit.emit(
        cubit.state.copyWith(usersProfile: me, conversations: const []),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              appBar: AppBar(actions: const [RequestsBadgeButton()]),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // The wrapper widget is present but renders nothing;
      //ensure the icon is absent
      expect(find.byTooltip('Requests'), findsNothing);
    });
  });
}
