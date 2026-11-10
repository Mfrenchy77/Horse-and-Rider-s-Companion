import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuth extends Mock implements AuthenticationRepository {}

class MockSkills extends Mock implements SkillTreeRepository {}

class MockResources extends Mock implements ResourcesRepository {}

class MockRiders extends Mock implements RiderProfileRepository {}

class MockHorses extends Mock implements HorseProfileRepository {}

class MockMessages extends Mock implements MessagesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppCubit cubit;
  late MockSkills skills;
  late MockRiders riders;
  late StreamController<List<Resource>> resources;
  late StreamController<List<TrainingPath>> paths;
  final date = DateTime.utc(2025);
  Skill skill(
    String id,
    String name, {
    List<String> prerequisites = const [],
  }) => Skill(
    id: id,
    skillName: name,
    rider: true,
    position: 0,
    lastEditBy: 'r@example.com',
    description: '',
    learningDescription: '',
    proficientDescription: '',
    lastEditDate: date,
    prerequisites: prerequisites,
  );
  TrainingPath path(String name) => TrainingPath(
    id: 'path',
    name: name,
    description: '',
    skills: [],
    skillNodes: [],
    isForRider: true,
    createdBy: 'Rider',
    createdById: 'r@example.com',
    createdAt: date,
    lastEditBy: 'Rider',
    lastEditDate: date,
  );
  final rider = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');

  setUpAll(() => registerFallbackValue(rider));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final auth = MockAuth();
    skills = MockSkills();
    final repo = MockResources();
    riders = MockRiders();
    resources = StreamController<List<Resource>>.broadcast();
    paths = StreamController<List<TrainingPath>>.broadcast();
    when(() => auth.currentUser).thenReturn(User.empty);
    when(() => auth.user).thenAnswer((_) => const Stream.empty());
    when(skills.getSkills).thenAnswer((_) => const Stream.empty());
    when(skills.getAllTrainingPaths).thenAnswer((_) => paths.stream);
    when(repo.getResources).thenAnswer((_) => resources.stream);
    when(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    ).thenAnswer((_) async {});
    cubit = AppCubit(
      authenticationRepository: auth,
      skillTreeRepository: skills,
      resourcesRepository: repo,
      riderProfileRepository: riders,
      horseProfileRepository: MockHorses(),
      messagesRepository: MockMessages(),
    );
  });
  tearDown(() async {
    await cubit.close();
    await resources.close();
    await paths.close();
  });

  test(
    'skill search trims whitespace, ignores case and sorts alphabetically',
    () {
      cubit
        ..emit(
          cubit.state.copyWith(
            allSkills: [skill('2', 'Zebra'), skill('1', 'Basic care'), null],
          ),
        )
        ..skillSearchQueryChanged(searchQuery: ' CARE ');
      expect(cubit.state.sortedSkills.map((s) => s?.id), ['1']);
      cubit.skillSearchQueryChanged(searchQuery: '');
      expect(cubit.state.sortedSkills.map((s) => s?.id), ['1', '2']);
      cubit.skillSearchQueryChanged(searchQuery: 'missing');
      expect(cubit.state.sortedSkills, isEmpty);
    },
  );
  test('resource search tolerates unnamed legacy records', () {
    cubit
      ..emit(
        cubit.state.copyWith(
          resources: [
            Resource(id: 'old'),
            Resource(id: 'new', name: 'Training Guide'),
          ],
        ),
      )
      ..resourceSearchQueryChanged(searchQuery: ' GUIDE ');
    expect(cubit.state.searchList, ['Training Guide']);
  });
  test('guest cannot edit absent or unauthored catalog records', () {
    expect(cubit.canEditSkill(null), isFalse);
    expect(cubit.canEditResource(Resource(id: 'r')), isFalse);
    expect(cubit.canEditTrainingPath(path('Path')), isFalse);
  });
  test(
    'training path creator can edit even when last editor is a display name',
    () {
      cubit.emit(cubit.state.copyWith(usersProfile: rider));
      expect(cubit.canEditTrainingPath(path('Path')), isTrue);
      expect(cubit.canEditSkill(skill('s', 'Skill')), isTrue);
      expect(
        cubit.canEditResource(Resource(id: 'r', authorId: rider.email)),
        isTrue,
      );
    },
  );
  test(
    'resource stream applies rating changes without an edit timestamp change',
    () async {
      cubit.loadResourcesIfNeeded();
      resources.add([Resource(id: 'r', rating: 1, lastEditDate: date)]);
      await Future<void>.delayed(Duration.zero);
      resources.add([Resource(id: 'r', rating: 2, lastEditDate: date)]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.resources.single.rating, 2);
    },
  );
  test('resource stream refreshes the open comment page', () async {
    cubit.loadResourcesIfNeeded();
    Comment commentWithRating(int rating) => Comment(
      id: 'comment',
      user: BaseListItem(id: 'author@example.com'),
      date: date,
      rating: rating,
      comment: 'Helpful advice',
      parentId: null,
      editedDate: null,
      resourceId: 'resource',
      usersWhoRated: const [],
    );
    resources.add([
      Resource(id: 'resource', comments: [commentWithRating(0)]),
    ]);
    await Future<void>.delayed(Duration.zero);
    cubit.getResourceById('resource');

    resources.add([
      Resource(id: 'resource', comments: [commentWithRating(1)]),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.getResourceById('resource')?.comments?.single.rating, 1);
    expect(cubit.state.resourceComments.single.rating, 1);
  });
  test('does not subscribe to disabled training paths at startup', () {
    verifyNever(skills.getAllTrainingPaths);
    expect(cubit.state.trainingPaths, isEmpty);
  });

  // Retained for when training-path loading is restored.
  //   test('training path stream applies edits to existing IDs', () async {
  //     paths.add([path('Original')]);
  //     await Future<void>.delayed(Duration.zero);
  //     paths.add([path('Updated')]);
  //     await Future<void>.delayed(Duration.zero);
  //     expect(cubit.state.trainingPaths.single?.name, 'Updated');
  //   });
  for (final sort in ResourcesSortStatus.values) {
    test(
      // ignore: lines_longer_than_80_chars
      'resource sort ${sort.name} tolerates null metadata without mutating input',
      () {
        final input = <Resource?>[
          Resource(id: 'a'),
          null,
          Resource(id: 'b', rating: 5, lastEditDate: date),
        ];
        cubit.emit(
          cubit.state.copyWith(resourcesSortStatus: sort, usersProfile: rider),
        );
        final result = cubit.sortResources(input);
        expect(result, everyElement(isA<Resource>()));
        expect(input.map((r) => r?.id), ['a', null, 'b']);
      },
    );
  }
  test(
    'saving a resource works with a new profile and preserves original data',
    () async {
      final profile = RiderProfile(
        id: 'r',
        name: 'Rider',
        email: 'r@example.com',
      );
      cubit.emit(cubit.state.copyWith(usersProfile: profile));
      await cubit.saveResource(
        resource: Resource(id: 'resource', name: 'Guide'),
      );
      final saved =
          verify(
                () => riders.createOrUpdateRiderProfile(
                  riderProfile: captureAny(named: 'riderProfile'),
                ),
              ).captured.single
              as RiderProfile;
      expect(saved.savedResourcesList, ['resource']);
      expect(profile.savedResourcesList, isEmpty);
    },
  );
  // Retained for when prerequisite checks are restored.
  //   test('prerequisites require proficiency', () {
  //     cubit.emit(
  //       cubit.state.copyWith(
  //         isForRider: true,
  //         usersProfile: rider,
  //         allSkills: [
  //           skill('s1', 'Basics'),
  //           skill('s2', 'Advanced', prerequisites: ['s1']),
  //         ],
  //       ),
  //     );
  //     expect(cubit.hasUnmetPrerequisites('s1'), isFalse);
  //     expect(cubit.hasUnmetPrerequisites('s2'), isTrue);
  //     expect(cubit.hasUnmetPrerequisites('missing'), isFalse);
  //   });
}
