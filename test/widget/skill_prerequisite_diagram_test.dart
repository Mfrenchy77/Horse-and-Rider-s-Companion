// The private diagram state is inspected through test-only counters.
// ignore_for_file: avoid_dynamic_calls

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';
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

  group('SkillPrerequisiteDiagram layout caching', () {
    late Skill base;
    late Skill focus;
    late Skill advanced;
    late List<Skill?> skills;
    late StateSetter rebuildParent;
    late Map<String, SkillLevel> levels;
    late Skill current;
    late List<Skill?> currentSkills;

    setUp(() {
      base = buildSkill('base');
      focus = buildSkill('focus', prerequisites: ['base']);
      advanced = buildSkill('advanced', prerequisites: ['focus']);
      skills = [base, focus, advanced];
      current = focus;
      currentSkills = skills;
      levels = {};
    });

    Future<void> pumpDiagram(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SkillPrerequisiteDiagram(
                  skill: current,
                  allSkills: currentSkills,
                  skillLevelsById: levels,
                  onSkillSelected: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    dynamic diagramState(WidgetTester tester) =>
        tester.state(find.byType(SkillPrerequisiteDiagram));

    GraphView graphView(WidgetTester tester) =>
        tester.widget<GraphView>(find.byType(GraphView));

    testWidgets('zoom and reset reuse the same graph and GraphView', (
      tester,
    ) async {
      await pumpDiagram(tester);
      final before = graphView(tester);
      final state = diagramState(tester);
      expect(state.graphBuildCount, 1);
      expect(state.graphViewBuildCount, 1);

      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reset view'));
      await tester.pumpAndSettle();

      expect(identical(graphView(tester), before), isTrue);
      expect(state.graphBuildCount, 1);
      expect(state.graphViewBuildCount, 1);
      expect(find.text('Skill focus'), findsOneWidget);
    });

    testWidgets('unrelated parent rebuilds do not relayout the graph', (
      tester,
    ) async {
      await pumpDiagram(tester);
      final before = graphView(tester);

      // Same skills in a fresh list and a fresh (equal) levels map.
      rebuildParent(() {
        currentSkills = List<Skill?>.of(skills);
        levels = <String, SkillLevel>{};
      });
      await tester.pumpAndSettle();

      expect(identical(graphView(tester), before), isTrue);
      expect(diagramState(tester).graphBuildCount, 1);
    });

    testWidgets('changing skills or progress recomputes as expected', (
      tester,
    ) async {
      // The test font (Ahem) is much wider than the real UI font, so status
      // pills overflow the fixed-width node here. Ignore only that artifact.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await pumpDiagram(tester);
      final state = diagramState(tester);

      // Progress change recreates only the GraphView (nodes show new status).
      rebuildParent(() {
        levels = {
          'focus': SkillLevel(
            skillId: 'focus',
            skillName: 'Skill focus',
            lastEditBy: 'tester',
            lastEditDate: DateTime(2024),
            levelState: LevelState.PROFICIENT,
          ),
        };
      });
      await tester.pumpAndSettle();
      expect(state.graphBuildCount, 1);
      expect(state.graphViewBuildCount, 2);

      // In-place mutation of a level is still picked up on the next build.
      levels['focus']!.levelState = LevelState.LEARNING;
      rebuildParent(() {});
      await tester.pumpAndSettle();
      expect(state.graphViewBuildCount, 3);

      // A different skill graph recomputes the layout inputs.
      final extra = buildSkill('extra', prerequisites: ['advanced']);
      rebuildParent(() {
        currentSkills = [...skills, extra];
      });
      await tester.pumpAndSettle();
      expect(state.graphBuildCount, 2);
      expect(find.text('Skill extra'), findsOneWidget);

      // Selecting another skill recomputes too.
      rebuildParent(() => current = advanced);
      await tester.pumpAndSettle();
      expect(state.graphBuildCount, 3);
    });
  });
}
