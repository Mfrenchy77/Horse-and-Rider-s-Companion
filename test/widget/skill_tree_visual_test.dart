import 'dart:io';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

void main() {
  testWidgets(
    'Phase B SkillTreeView renders modernized midnight-teal UI cleanly', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1180, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime(2026);
    final skills = <Skill>[
      Skill(
        id: 's1',
        skillName: 'Lead at the walk',
        category: SkillCategory.In_Hand,
        description: 'Walk calmly beside the horse on a loose lead.',
        learningDescription: 'Keep consistent spacing at the shoulder.',
        proficientDescription: 'Halt and turn smoothly on light cues.',
        rider: true,
        position: 0,
        lastEditBy: 'matt@example.com',
        lastEditDate: now,
      ),
      Skill(
        id: 's2',
        skillName: 'Balanced seat at the trot',
        difficulty: DifficultyState.Intermediate,
        description: 'Maintain an independent, elastic seat.',
        learningDescription: 'Keep heels down and shoulders relaxed.',
        proficientDescription: 'Follow the horse motion effortlessly.',
        rider: true,
        position: 1,
        lastEditBy: 'matt@example.com',
        lastEditDate: now,
      ),
      Skill(
        id: 's3',
        skillName: 'Groundwork Yielding',
        category: SkillCategory.Husbandry,
        description: 'Yield hindquarters and forequarters softly.',
        learningDescription: 'Ask with light energy and release on the step.',
        proficientDescription: 'Softly yield from a whisper of a cue.',
        rider: true,
        position: 2,
        lastEditBy: 'matt@example.com',
        lastEditDate: now,
      ),
    ];

    final profile = RiderProfile(
      id: 'matt@example.com',
      email: 'matt@example.com',
      name: 'Matt French',
      skillLevels: [
        SkillLevel(
          skillId: 's1',
          skillName: 'Lead at the walk',
          levelState: LevelState.PROFICIENT,
          lastEditBy: 'matt@example.com',
          lastEditDate: now,
        ),
        SkillLevel(
          skillId: 's2',
          skillName: 'Balanced seat at the trot',
          levelState: LevelState.LEARNING,
          lastEditBy: 'matt@example.com',
          lastEditDate: now,
        ),
      ],
    );

    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    when(
      () => harness.resources.getResourcesForSkill(
        skillId: any(named: 'skillId'),
      ),
    ).thenAnswer((_) => Stream.value(const []));
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        allSkills: skills,
        sortedSkills: skills,
        usersProfile: profile,
        isGuest: false,
        skill: skills.first,
        skillTreeNavigation: SkillTreeNavigation.SkillLevel,
      ),
    );

    await tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: harness.resources,
        child: BlocProvider.value(
          value: harness.cubit,
          child: SkillTreeLayoutScope(
            layout: SkillTreeLayout.library,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: mainThemeDark,
              home: const RepaintBoundary(
                key: ValueKey('skillTreeShot'),
                child: SkillTreeView(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundaryFinder = find.byKey(const ValueKey('skillTreeShot'));
    expect(boundaryFinder, findsOneWidget);
    expect(find.text('Rider Skills'), findsOneWidget);
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('Lead at the walk'), findsWidgets);

    await tester.runAsync(() async {
      final boundary =
          tester.renderObject(boundaryFinder) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File(
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/phase_b_skill_tree.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    });
  });
}
