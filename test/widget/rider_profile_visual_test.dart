import 'dart:io';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

Future<void> _captureBoundary(
  WidgetTester tester,
  GlobalKey key,
  String outPath,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final file = File(outPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}

void main() {
  testWidgets(
    'RiderProfileView renders Markdown bio, horses, students, and shots',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final matt = RiderProfile(
        id: 'matt',
        email: 'matt@example.com',
        name: 'Matt French',
        locationName: 'La Mesa, California',
        isTrainer: true,
        homeUrl: 'https://horseandriderscompanion.com',
        bio:
            'Matt French is a **professional horse trainer**, instructor, and '
            '*international Working Equitation competitor* based in San Diego, '
            'California.\n\nWith more than 25 years of experience working with '
            'horses, Matt combines natural horsemanship and classical dressage '
            'to develop versatile, confident, and willing partners.',
        ownedHorses: [
          BaseListItem(id: 'valero', name: 'Valero', isCollapsed: false),
          BaseListItem(id: 'navarro', name: 'Navarro', isCollapsed: false),
          BaseListItem(
            id: 'dahlia',
            name: 'Dahlia Dark Horse',
            isCollapsed: false,
          ),
          BaseListItem(id: 'apollo', name: 'Apollo', isCollapsed: false),
        ],
        students: [
          BaseListItem(
            id: 'tester@example.com',
            name: 'Tester McTesty',
            isCollapsed: true,
          ),
        ],
        skillLevels: [
          SkillLevel(
            skillId: 's1',
            skillName: 'Turn on the Forehand',
            lastEditBy: 'Matt French',
            lastEditDate: DateTime.utc(2026),
            levelState: LevelState.PROFICIENT,
            verified: true,
          ),
        ],
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          pageStatus: AppPageStatus.loaded,
          isGuest: false,
          usersProfile: matt,
        ),
      );

      for (final entry in <String, Size>{
        'mobile': const Size(390, 900),
        'desktop': const Size(1280, 820),
      }.entries) {
        final shotKey = GlobalKey();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = entry.value;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: mainThemeDark,
              home: RepaintBoundary(
                key: shotKey,
                child: RiderProfileView(profile: matt),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Matt French'), findsOneWidget);
        expect(find.text('La Mesa, California'), findsOneWidget);
        expect(find.text('Professional Trainer'), findsOneWidget);
        expect(find.text('Valero'), findsOneWidget);
        expect(find.text('Navarro'), findsOneWidget);
        expect(find.text('Dahlia Dark Horse'), findsOneWidget);
        // 4th horse is hidden behind "View All" in the 3-card preview.
        expect(find.text('Apollo'), findsNothing);
        expect(find.text('View All'), findsOneWidget);
        expect(find.text('Tester McTesty'), findsOneWidget);
        // Markdown markers should not appear raw.
        expect(find.textContaining('**'), findsNothing);

        await _captureBoundary(
          tester,
          shotKey,
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/rider_profile_${entry.key}.png',
        );
      }

      // Verify "View All" opens all 4 owned horses.
      await tester.tap(find.text('View All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Apollo'), findsOneWidget);
    },
  );
}
