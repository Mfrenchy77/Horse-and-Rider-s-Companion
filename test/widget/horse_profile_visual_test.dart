import 'dart:io';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

void main() {
  Future<void> captureHorseProfile(
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

    final now = DateTime(2026);
    final horse = HorseProfile(
      id: 'horse-valero',
      name: 'Valero',
      nickname: 'Val',
      breed: 'Andalusian',
      gender: 'Gelding',
      color: 'Bay',
      height: 162,
      dateOfBirth: DateTime(2017, 4, 12),
      locationName: 'La Mesa, California',
      currentOwnerId: 'matt@example.com',
      currentOwnerName: 'Matt French',
      saleListing: (
        price: '28000',
        location: 'San Diego, CA',
        description:
            'Well-schooled Working Equitation prospect with calm manners, '
            'flying changes, and solid trail confidence.',
      ),
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
          skillName: 'Sidepass in-hand',
          levelState: LevelState.LEARNING,
          lastEditBy: 'matt@example.com',
          lastEditDate: now,
        ),
      ],
    );

    final rider = RiderProfile(
      id: 'matt@example.com',
      email: 'matt@example.com',
      name: 'Matt French',
    );

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        usersProfile: rider,
        horseProfile: horse,
        isForRider: false,
        isGuest: false,
      ),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: mainThemeDark,
          home: RepaintBoundary(
            key: const ValueKey('horseProfileShot'),
            child: HorseProfileView(horseProfile: horse),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Valero'), findsOneWidget);
    expect(find.text('For sale'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);

    await tester.runAsync(() async {
      final boundary =
          tester.renderObject(find.byKey(const ValueKey('horseProfileShot')))
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

  testWidgets('Phase D HorseProfileView renders cleanly on desktop', (
    tester,
  ) async {
    await captureHorseProfile(
      tester,
      size: const Size(1180, 820),
      outPath:
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/phase_d_horse_profile_desktop.png',
    );
  });

  testWidgets('Phase D HorseProfileView renders cleanly on mobile', (
    tester,
  ) async {
    await captureHorseProfile(
      tester,
      size: const Size(412, 860),
      outPath:
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/phase_d_horse_profile_mobile.png',
    );
  });
}
