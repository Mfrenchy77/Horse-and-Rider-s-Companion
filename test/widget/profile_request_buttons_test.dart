// Widget tests for profile request buttons

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/student_horse_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/instructor_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/student_request.button.dart';
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

class ConversationFake extends Fake implements Conversation {}

class MessageFake extends Fake implements Message {}

class BaseListItemFake extends Fake implements BaseListItem {}

class RiderProfileFake extends Fake implements RiderProfile {}

class HorseProfileFake extends Fake implements HorseProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConversationFake());
    registerFallbackValue(MessageFake());
    registerFallbackValue(BaseListItemFake());
    registerFallbackValue(RiderProfileFake());
    registerFallbackValue(HorseProfileFake());
  });

  group('Profile request buttons', () {
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

    testWidgets('InstructorRequestButton visible and sends message',
        (tester) async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final users = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      final viewing = RiderProfile(id: 'v', name: 'View', email: 'v@x.com')
        ..isTrainer = true;

      cubit.emit(
        cubit.state.copyWith(
          usersProfile: users,
          viewingProfile: viewing,
          isViewing: true,
          isGuest: false,
        ),
      );

      when(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => messagesRepo.createOrUpdateMessage(
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(body: InstructorRequestButton(profile: viewing)),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // find by key for resilience to label changes
      expect(
        find.byKey(const Key('instructor_request_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('instructor_request_button')));
      await tester.pumpAndSettle();

      verify(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).called(1);
      verify(
        () => messagesRepo.createOrUpdateMessage(
          message: any(named: 'message'),
        ),
      ).called(1);
    });

    testWidgets('StudentRequestButton visible and sends message',
        (tester) async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final users = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com')
        ..isTrainer = true;
      final viewing = RiderProfile(id: 'v', name: 'View', email: 'v@x.com')
        ..instructors = [];

      cubit.emit(
        cubit.state.copyWith(
          usersProfile: users,
          viewingProfile: viewing,
          isViewing: true,
          isGuest: false,
        ),
      );

      when(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => messagesRepo.createOrUpdateMessage(
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(body: StudentRequestButton(profile: viewing)),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('student_request_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('student_request_button')));
      await tester.pumpAndSettle();

      verify(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).called(1);
      verify(
        () => messagesRepo.createOrUpdateMessage(
          message: any(named: 'message'),
        ),
      ).called(1);
    });

    testWidgets('StudentHorseRequestButton visible and sends message',
        (tester) async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final users = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com')
        ..isTrainer = true;
      final owner = RiderProfile(id: 'o', name: 'Owner', email: 'owner@x.com');
      final horse = HorseProfile(
        id: 'h1',
        name: 'Horse1',
        currentOwnerId: 'owner@x.com',
        currentOwnerName: 'Owner',
      );

      cubit.emit(
        cubit.state.copyWith(
          usersProfile: users,
          ownersProfile: owner,
          horseProfile: horse,
          isForRider: false,
          isGuest: false,
        ),
      );

      when(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => messagesRepo.createOrUpdateMessage(
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const Scaffold(body: StudentHorseRequestButton()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('student_horse_request_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('student_horse_request_button')));
      await tester.pumpAndSettle();

      verify(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).called(1);
      verify(
        () => messagesRepo.createOrUpdateMessage(
          message: any(named: 'message'),
        ),
      ).called(1);
    });
  });
}
