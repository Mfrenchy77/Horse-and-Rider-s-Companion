import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_prerequisite_diagram.dart';

void main() {
  Skill buildSkill(
    String id, {
    List<String> prerequisites = const [],
    DifficultyState difficulty = DifficultyState.Introductory,
    bool rider = true,
  }) {
    return Skill(
      id: id,
      rider: rider,
      position: 0,
      skillName: 'Skill $id',
      lastEditBy: 'tester',
      description: 'desc',
      lastEditDate: DateTime(2024),
      prerequisites: prerequisites,
      learningDescription: 'learn',
      proficientDescription: 'prof',
      difficulty: difficulty,
    );
  }

  group('SkillPrerequisiteGraphBuilder', () {
    test('collects ancestors and base skills', () {
      final base = buildSkill('base');
      final mid = buildSkill('mid', prerequisites: ['base']);
      final target = buildSkill('target', prerequisites: ['mid']);

      final data = SkillPrerequisiteGraphBuilder(
        skill: target,
        allSkills: [target, mid, base],
      ).build();

      expect(data.skillById.keys, containsAll(['base', 'mid', 'target']));
      expect(data.baseSkillIds, contains('base'));
      expect(
        data.edges,
        containsAll(
          [
            const SkillPrerequisiteEdge('base', 'mid'),
            const SkillPrerequisiteEdge('mid', 'target'),
          ],
        ),
      );
      expect(data.depthBySkillId['base'], 0);
      expect(data.depthBySkillId['mid'], 1);
      expect(data.depthBySkillId['target'], 2);
      expect(data.directPrerequisiteIds, contains('mid'));
      expect(data.hasDiagram, isTrue);
    });

    test('ignores missing prerequisite skills gracefully', () {
      final target = buildSkill('target', prerequisites: ['missing']);
      final unrelated = buildSkill('other');

      final data = SkillPrerequisiteGraphBuilder(
        skill: target,
        allSkills: [target, unrelated],
      ).build();

      expect(data.skillById.keys, contains('target'));
      expect(data.skillById.keys, isNot(contains('missing')));
      expect(data.edges, isEmpty);
      expect(data.hasDiagram, isFalse);
    });

    test('collects dependent skills when enabled', () {
      final base = buildSkill('base');
      final focus = buildSkill('focus', prerequisites: ['base']);
      final advanced = buildSkill('advanced', prerequisites: ['focus']);
      final mastery = buildSkill('mastery', prerequisites: ['advanced']);

      final data = SkillPrerequisiteGraphBuilder(
        skill: focus,
        allSkills: [base, focus, advanced, mastery],
        includeDependents: true,
      ).build();

      expect(
        data.skillById.keys,
        containsAll(['base', 'focus', 'advanced', 'mastery']),
      );
      expect(data.descendantSkillIds, containsAll(['advanced', 'mastery']));
      expect(data.downstreamDepthBySkillId['focus'], 0);
      expect(data.downstreamDepthBySkillId['advanced'], 1);
      expect(data.downstreamDepthBySkillId['mastery'], 2);
      expect(
        data.edges,
        containsAll(
          [
            const SkillPrerequisiteEdge('base', 'focus'),
            const SkillPrerequisiteEdge('focus', 'advanced'),
            const SkillPrerequisiteEdge('advanced', 'mastery'),
          ],
        ),
      );
    });
  });
}
