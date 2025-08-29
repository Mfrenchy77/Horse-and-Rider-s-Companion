// ignore_for_file: prefer_const_constructors

import 'dart:async';

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

class ConversationFake extends Fake implements Conversation {}

class MessageFake extends Fake implements Message {}

class BaseListItemFake extends Fake implements BaseListItem {}

class HorseProfileFake extends Fake implements HorseProfile {}

class RiderProfileFake extends Fake implements RiderProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConversationFake());
    registerFallbackValue(MessageFake());
    registerFallbackValue(BaseListItemFake());
    registerFallbackValue(HorseProfileFake());
    registerFallbackValue(RiderProfileFake());
  });

  group('AppCubit request flows', () {
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

    test('createInstructorRequest creates conversation and message', () async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      final instructor =
          RiderProfile(id: 'i', name: 'Instructor', email: 'i@x.com');

      // seed usersProfile into cubit state
      cubit.emit(cubit.state.copyWith(usersProfile: me));

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

      await cubit.createInstructorRequest(instructorProfile: instructor);

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

      expect(cubit.state.isMessage, true);
      expect(cubit.state.errorMessage, contains('Instructor request sent'));

      // intentionally not closing cubit to avoid canceling late subscriptions
    });

    test('createStudentRequest creates conversation and message', () async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      final student = RiderProfile(id: 's', name: 'Student', email: 's@x.com');
      cubit.emit(cubit.state.copyWith(usersProfile: me));

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

      await cubit.createStudentRequest(studentProfile: student);

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

      expect(cubit.state.isMessage, true);
      expect(cubit.state.errorMessage, contains('Student request sent'));

      // intentionally not closing cubit to avoid canceling late subscriptions
    });

    test('requestToBeStudentHorse adds request when not student horse',
        () async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      final owner = RiderProfile(id: 'o', name: 'Owner', email: 'owner@x.com');
      final horse = HorseProfile(
        id: 'h1',
        name: 'Horse1',
        currentOwnerId: 'owner@x.com',
        currentOwnerName: 'Owner',
      );

      cubit.emit(
        cubit.state.copyWith(
          usersProfile: me,
          ownersProfile: owner,
          horseProfile: horse,
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

      cubit.requestToBeStudentHorse();

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

      expect(cubit.state.isMessage, true);
      expect(cubit.state.errorMessage, contains('Request to add'));

      // intentionally not closing cubit to avoid canceling late subscriptions
    });

    test('requestToBeStudentHorse removes student horse when already a student',
        () async {
      final cubit = AppCubit(
        messagesRepository: messagesRepo,
        skillTreeRepository: skillRepo,
        resourcesRepository: resourcesRepo,
        riderProfileRepository: riderRepo,
        horseProfileRepository: horseRepo,
        authenticationRepository: authRepo,
      );

      final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com')
        // seed a studentHorses entry
        ..studentHorses = [BaseListItem(id: 'h1', name: 'Horse1')];

      final horse = HorseProfile(
        id: 'h1',
        name: 'Horse1',
        currentOwnerId: 'owner@x.com',
        currentOwnerName: 'Owner',
      )..instructors = [BaseListItem(id: 'me@example.com', name: 'Me')];

      cubit.emit(cubit.state.copyWith(usersProfile: me, horseProfile: horse));

      when(
        () => horseRepo.createOrUpdateHorseProfile(
          horseProfile: any(named: 'horseProfile'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => riderRepo.createOrUpdateRiderProfile(
          riderProfile: any(named: 'riderProfile'),
        ),
      ).thenAnswer((_) async {});

      cubit.requestToBeStudentHorse();

      verify(
        () => horseRepo.createOrUpdateHorseProfile(
          horseProfile: any(named: 'horseProfile'),
        ),
      ).called(1);
      verify(
        () => riderRepo.createOrUpdateRiderProfile(
          riderProfile: any(named: 'riderProfile'),
        ),
      ).called(1);

      expect(cubit.state.isMessage, true);
      expect(cubit.state.errorMessage, contains('Removed'));

      // intentionally not closing cubit to avoid canceling late subscriptions
    });
  });
}
