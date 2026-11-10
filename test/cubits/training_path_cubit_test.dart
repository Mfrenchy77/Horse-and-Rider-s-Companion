import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/Cubit/create_training_path_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:mocktail/mocktail.dart';

class MockSkillRepository extends Mock implements SkillTreeRepository {}

void main() {
  final date = DateTime.utc(2025);
  final skills = List.generate(
    3,
    (i) => Skill(
      id: 's$i',
      skillName: 'Skill $i',
      rider: true,
      position: i,
      lastEditBy: 'editor',
      lastEditDate: date,
      category: SkillCategory.Other,
      description: '',
      learningDescription: '',
      proficientDescription: '',
    ),
  );
  final user = RiderProfile(id: 'u', name: 'Rider', email: 'r@example.com');
  late MockSkillRepository repo;
  late CreateTrainingPathCubit cubit;
  setUpAll(() {
    registerFallbackValue(
      TrainingPath(
        id: 'fallback',
        name: '',
        skills: [],
        createdBy: '',
        createdAt: date,
        isForRider: true,
        skillNodes: [],
        lastEditBy: '',
        createdById: '',
        description: '',
        lastEditDate: date,
      ),
    );
  });
  setUp(() {
    repo = MockSkillRepository();
    cubit = CreateTrainingPathCubit(
      trainingPathRepository: repo,
      allSkills: skills,
      isForRider: true,
      user: user,
    );
  });
  tearDown(() => cubit.close());

  test('starts with all skills available', () {
    expect(cubit.state.availableSkills, skills);
    expect(cubit.state.rootNodes, isEmpty);
    expect(cubit.state.childNodes, isEmpty);
  });
  test('selecting skills moves them from the pool into roots and children', () {
    cubit.skillNodeSelected(skillName: 'Skill 0');
    final root = cubit.state.rootNodes.single;
    cubit.createOrDeleteChildSkillNode(parentNode: root, skillName: 'Skill 1');
    expect(cubit.state.childNodes[root.id]?.single.skillId, 's1');
    expect(cubit.state.availableSkills.map((s) => s.id), ['s2']);
  });
  test(
    'removing a root restores every descendant and leaves no orphan nodes',
    () {
      cubit.skillNodeSelected(skillName: 'Skill 0');
      final root = cubit.state.rootNodes.single;
      cubit.createOrDeleteChildSkillNode(
        parentNode: root,
        skillName: 'Skill 1',
      );
      final child = cubit.state.childNodes[root.id]!.single;
      cubit
        ..createOrDeleteChildSkillNode(parentNode: child, skillName: 'Skill 2')
        ..removeNode(root);
      expect(cubit.state.rootNodes, isEmpty);
      expect(cubit.state.childNodes, isEmpty);
      expect(
        cubit.state.availableSkills.map((s) => s.id),
        unorderedEquals(['s0', 's1', 's2']),
      );
    },
  );
  test('toggling a child restores it to the pool', () {
    cubit.skillNodeSelected(skillName: 'Skill 0');
    final root = cubit.state.rootNodes.single;
    cubit
      ..createOrDeleteChildSkillNode(parentNode: root, skillName: 'Skill 1')
      ..createOrDeleteChildSkillNode(parentNode: root, skillName: 'Skill 1');
    expect(cubit.state.childNodes[root.id] ?? [], isEmpty);
    expect(cubit.state.availableSkills.map((s) => s.id), contains('s1'));
  });
  test('invalid form does not write', () async {
    await cubit.createOrEditTrainingPath();
    expect(cubit.state.status, FormStatus.failure);
    verifyZeroInteractions(repo);
  });
  test('saved skill list contains skill IDs and preserves the graph', () async {
    when(
      () => repo.createOrEditTrainingPath(
        trainingPath: any(named: 'trainingPath'),
      ),
    ).thenAnswer((_) async {});
    cubit
      ..trainingPathNameChanged(name: 'Starter')
      ..trainingPathDescriptionChanged(description: 'A learning path')
      ..skillNodeSelected(skillName: 'Skill 0')
      ..createOrDeleteChildSkillNode(
        parentNode: cubit.state.rootNodes.single,
        skillName: 'Skill 1',
      );
    await cubit.createOrEditTrainingPath();
    final saved =
        verify(
              () => repo.createOrEditTrainingPath(
                trainingPath: captureAny(named: 'trainingPath'),
              ),
            ).captured.single
            as TrainingPath;
    expect(saved.skills, ['s0', 's1']);
    expect(saved.skillNodes, hasLength(2));
    expect(saved.createdById, user.email);
    expect(cubit.state.status, FormStatus.success);
  });
  test('failed save reports failure', () async {
    when(
      () => repo.createOrEditTrainingPath(
        trainingPath: any(named: 'trainingPath'),
      ),
    ).thenAnswer((_) async => throw Exception('offline'));
    cubit
      ..trainingPathNameChanged(name: 'Starter')
      ..trainingPathDescriptionChanged(description: 'A path');
    await cubit.createOrEditTrainingPath();
    expect(cubit.state.status, FormStatus.failure);
  });
}
