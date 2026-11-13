// The private widget states are inspected through test-only counters.
// ignore_for_file: avoid_dynamic_calls

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_category_graph_section.dart';

void main() {
  Skill buildSkill(String id, {List<String> prerequisites = const []}) {
    return Skill(
      id: id,
      rider: true,
      position: 0,
      skillName: 'Skill $id',
      lastEditBy: 'tester',
      description: 'desc',
      lastEditDate: DateTime(2024),
      prerequisites: prerequisites,
      learningDescription: 'learn',
      proficientDescription: 'prof',
    );
  }

  testWidgets('category graph is only recomputed when skills change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final base = buildSkill('base');
    final next = buildSkill('next', prerequisites: ['base']);
    var skills = <Skill>[base, next];
    late StateSetter rebuildParent;
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SkillCategoryGraphSection(
                  category: SkillCategory.Other,
                  skills: skills,
                  onSkillSelected: (_) => selected++,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dynamic sectionState = tester.state(
      find.byType(SkillCategoryGraphSection),
    );
    final before = tester.widget<GraphView>(find.byType(GraphView));
    expect(sectionState.dataBuildCount, 1);
    expect(find.text('Skill base'), findsOneWidget);
    expect(find.text('Skill next'), findsOneWidget);

    // A fresh, equal list must not trigger a relayout.
    rebuildParent(() => skills = List<Skill>.of(skills));
    await tester.pumpAndSettle();
    expect(sectionState.dataBuildCount, 1);
    expect(identical(tester.widget<GraphView>(find.byType(GraphView)), before),
        isTrue);

    // Taps still reach the latest callback.
    await tester.tap(find.text('Skill base'));
    expect(selected, 1);

    // A different skill set rebuilds the graph and shows the new node.
    final extra = buildSkill('extra', prerequisites: ['next']);
    rebuildParent(() => skills = [...skills, extra]);
    await tester.pumpAndSettle();
    expect(sectionState.dataBuildCount, 2);
    expect(find.text('Skill extra'), findsOneWidget);
    expect(
      identical(tester.widget<GraphView>(find.byType(GraphView)), before),
      isFalse,
    );
  });
}
