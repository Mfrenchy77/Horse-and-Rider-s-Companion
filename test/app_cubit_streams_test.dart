// ignore_for_file: prefer_const_constructors, cascade_invocations

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
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

      // AppCubit constructor reads currentUser
      // and starts listening to auth.user
      when(() => authRepo.currentUser).thenReturn(User.empty);
      when(() => authRepo.user).thenAnswer((_) => const Stream<User?>.empty());

      // Skill/resources fetches run on init; return empty streams to avoid noise
      when(() => skillRepo.getSkills())
          .thenAnswer((_) => const Stream<List<Skill>>.empty());
      when(() => skillRepo.getAllTrainingPaths())
          .thenAnswer((_) => const Stream<List<TrainingPath>>.empty());
      when(() => resourcesRepo.getResources())
          .thenAnswer((_) => const Stream<List<Resource>>.empty());
    });

    test(
      'getHorseProfile cancels previous'
      ' subscription when selecting a different horse',
      () async {
        // Arrange controllers to observe onListen/onCancel
        var listenedA = 0;
        var canceledA = 0;
        final controllerA = StreamController<HorseProfile?>();
        controllerA.onListen = () => listenedA++;
        controllerA.onCancel = () {
          canceledA++;
          return Future.value();
        };

        final controllerB = StreamController<HorseProfile?>();

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
        expect(
          canceledA,
          1,
          reason: 'previous horse stream should'
              ' be canceled when switching IDs',
        );

        // Cleanup controllers
        await controllerA.close();
        await controllerB.close();
        // Intentionally not closing cubit
        //here due to unrelated late subscription
      },
    );
  });
}
