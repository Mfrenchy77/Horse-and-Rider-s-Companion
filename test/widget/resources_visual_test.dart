import 'dart:io';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_view.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

void main() {
  Future<void> captureResources(
    WidgetTester tester, {
    required Size size,
    required String outPath,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final harness = await AppTestHarness.create();
    addTearDown(harness.close);

    final now = DateTime.now();
    final resources = <Resource>[
      Resource(
        id: 'r1',
        name: 'Turn on the Forehand - Part 2',
        url: 'https://debbylush.co.uk/turn-on-the-forehand',
        description:
            'Once you have your start and stop controls established, you can '
            'then start with sideways controls.',
        lastEditBy: 'mfrench77@gmail.com',
        lastEditDate: now,
        rating: 4,
        skillTreeIds: const ['s1'],
        usersWhoRated: [BaseListItem(id: 'u1', isSelected: true)],
      ),
      Resource(
        id: 'r2',
        name: 'Introducing Leg Yields From the Ground',
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        description:
            'Clear step-by-step groundwork progression for teaching lateral '
            'responsiveness.',
        lastEditBy: 'coach@example.com',
        lastEditDate: now.subtract(const Duration(days: 5)),
        rating: 9,
      ),
      Resource(
        id: 'r3',
        name: 'Tack Fit: What to Look For',
        type: ResourceType.article,
        authorName: 'Matt French',
        description:
            'How to evaluate saddle balance, gullet clearance, and rider '
            'alignment before your next ride.',
        lastEditBy: 'matt@example.com',
        lastEditDate: now.subtract(const Duration(days: 12)),
        rating: 7,
      ),
    ];

    final skills = <Skill>[
      Skill(
        id: 's1',
        skillName: 'Sidepass in-hand',
        category: SkillCategory.In_Hand,
        description: 'Move sideways cleanly.',
        learningDescription: 'Keep rhythm even.',
        proficientDescription: 'Light cue response.',
        rider: true,
        position: 0,
        lastEditBy: 'matt@example.com',
        lastEditDate: now,
      ),
    ];

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        resources: resources,
        allSkills: skills,
        isGuest: false,
      ),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: ResourceLayoutScope(
          layout: ResourceLayout.vertical,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: mainThemeDark,
            home: const RepaintBoundary(
              key: ValueKey('resourcesShot'),
              child: ResourcesView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Turn on the Forehand - Part 2'), findsOneWidget);
    expect(find.text('Tack Fit: What to Look For'), findsOneWidget);

    await tester.runAsync(() async {
      final boundary =
          tester.renderObject(find.byKey(const ValueKey('resourcesShot')))
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File(outPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    });
  }

  testWidgets('Phase C Resources renders cleanly on desktop (3 columns)', (
    tester,
  ) async {
    await captureResources(
      tester,
      size: const Size(1200, 800),
      outPath:
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/phase_c_resources_desktop.png',
    );
  });

  testWidgets('Phase C Resources renders cleanly on mobile (1 column)', (
    tester,
  ) async {
    await captureResources(
      tester,
      size: const Size(412, 860),
      outPath:
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/phase_c_resources_mobile.png',
    );
  });
}
