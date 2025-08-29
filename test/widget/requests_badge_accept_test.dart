// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/requests_badge_button.dart';
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

class TestAppCubit extends AppCubit {
  TestAppCubit({
    required super.messagesRepository,
    required super.skillTreeRepository,
    required super.resourcesRepository,
    required super.riderProfileRepository,
    required super.horseProfileRepository,
    required super.authenticationRepository,
  });

  Message? lastAccepted;

  @override
  Future<void> acceptRequest({
    required Message message,
    required BuildContext context,
  }) async {
    lastAccepted = message;
    emit(state.copyWith(acceptStatus: AcceptStatus.accepted));
  }
}

void main() {
  group('RequestsBadgeButton Accept flow', () {
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

    testWidgets('tap Accept in sheet calls acceptRequest', (tester) async {
      final cubit = TestAppCubit(
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
        id: 'c1',
        date: DateTime.now(),
        sender: 'Other',
        senderId: 'other@x.com',
        senderProfilePicUrl: 'example.com/profile_pics/other.png',
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
          home: BlocProvider<AppCubit>.value(
            value: cubit,
            child: Scaffold(
              appBar: AppBar(),
              body: const Center(child: RequestsBadgeButton()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the sheet (call onPressed directly to avoid hit-test issues)
      final iconFinder = find.byKey(const Key('RequestsIconButton'));
      final icon = tester.widget<IconButton>(iconFinder);
      icon.onPressed?.call();
      await tester.pumpAndSettle();

      // Tap the Accept button
      await tester.tap(find.byKey(const Key('Accept_m100')));
      await tester.pumpAndSettle();

      expect(cubit.lastAccepted?.messageId, 'm100');
      expect(cubit.state.acceptStatus, AcceptStatus.accepted);

      // Sheet should be dismissed and a SnackBar should show
      expect(find.byKey(const Key('Accept_m100')), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
