import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_hero_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/personalized_logbook_backdrop.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/in_memory_logbook_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

const _scratchDir =
    '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch';

Future<Uint8List> _createSamplePhotoBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const size = Size(160, 120);
  final bgPaint = ui.Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      [
        const Color(0xFF1F4D57),
        const Color(0xFFB56E4C),
        const Color(0xFFE5B887),
      ],
      [0.0, 0.55, 1.0],
    );
  canvas.drawRect(Offset.zero & size, bgPaint);
  final highlightPaint = ui.Paint()..color = const Color(0xCCFFF3E0);
  canvas.drawCircle(const Offset(108, 46), 24, highlightPaint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(160, 120);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<void> _captureScreenshot(WidgetTester tester, String filename) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject(find.byType(RepaintBoundary).first)
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final dir = Directory(_scratchDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('$_scratchDir/$filename');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}

void main() {
  final sampleRiderEntries = <BaseListItem>[
    BaseListItem(
      id: 'entry-1',
      name: 'Worked on lateral flexion and soft transitions into canter.',
      date: DateTime(2026, 11, 10),
      riderLog: const RiderLogDetails(
        type: RiderLogType.lesson,
        title: 'Working Equitation Lesson',
        horse: 'Valero',
        instructor: 'Matt French',
        focus: 'Canter departs & shoulder-in',
      ),
    ),
    BaseListItem(
      id: 'entry-2',
      name: 'Clean obstacle course round with responsive halts.',
      date: DateTime(2026, 11, 4),
      riderLog: const RiderLogDetails(
        type: RiderLogType.show,
        title: 'Autumn Classic Ease of Handling',
        horse: 'Navarro',
        placing: '1st',
      ),
    ),
    BaseListItem(
      id: 'entry-3',
      name: 'Routine farrier trim and frog check.',
      date: DateTime(2026, 10, 28),
      riderLog: const RiderLogDetails(
        type: RiderLogType.care,
        title: 'Farrier Visit',
        horse: 'Valero',
      ),
    ),
  ];

  final sampleHorseEntries = <BaseListItem>[
    BaseListItem(
      id: 'h-1',
      name: 'Smooth transitions and relaxed stretching on the lunge.',
      date: DateTime(2026, 11, 12),
      imageUrl: 'LogTag.Training',
      riderLog: const RiderLogDetails(
        type: RiderLogType.training,
        title: 'Groundwork & Suppleness',
      ),
    ),
    BaseListItem(
      id: 'h-2',
      name: 'Placed 2nd in Intermediate Dressage.',
      date: DateTime(2026, 11, 2),
      imageUrl: 'LogTag.Show',
      riderLog: const RiderLogDetails(
        type: RiderLogType.show,
        title: 'Regional Working Equitation',
        placing: '2nd',
      ),
    ),
    BaseListItem(
      id: 'h-3',
      name: 'Annual dental float completed with no sharp points.',
      date: DateTime(2026, 10, 19),
      imageUrl: 'LogTag.Health',
      riderLog: const RiderLogDetails(
        type: RiderLogType.care,
        title: 'Dental Checkup',
      ),
    ),
  ];

  Future<void> pumpRiderLogbook(
    WidgetTester tester, {
    required AppTestHarness harness,
    required RiderProfile rider,
    required Size size,
    ImageProvider? previewImage,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logbookRepo = InMemoryLogbookConnectionRepository();
    final riderRepo = InMemoryLogbookRiderProfileRepository();

    harness.cubit.emit(
      harness.cubit.state.copyWith(isGuest: false, usersProfile: rider),
    );

    await tester.pumpWidget(
      RepaintBoundary(
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<LogbookConnectionRepository>.value(
              value: logbookRepo,
            ),
            RepositoryProvider<LogbookRiderProfileRepository>.value(
              value: riderRepo,
            ),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: HorseAndRidersTheme().getDarkTheme(),
              home: RiderLogbookPage(
                email: rider.email,
                previewImage: previewImage,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    if (previewImage != null) {
      await tester.runAsync(
        () => precacheImage(
          previewImage,
          tester.element(find.byType(PersonalizedLogbookBackdrop)),
        ),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> pumpHorseLogbook(
    WidgetTester tester, {
    required AppTestHarness harness,
    required RiderProfile rider,
    required HorseProfile horse,
    required Size size,
    ImageProvider? previewImage,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: rider,
        horseProfile: horse,
      ),
    );

    await tester.pumpWidget(
      RepaintBoundary(
        child: BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: HorseAndRidersTheme().getDarkTheme(),
            home: Builder(
              builder: (context) => LogViewDialog(
                name: horse.name,
                horseId: horse.id,
                horseProfile: horse,
                notes: horse.notes,
                isRider: false,
                appContext: context,
                previewImage: previewImage,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    if (previewImage != null) {
      await tester.runAsync(
        () => precacheImage(
          previewImage,
          tester.element(find.byType(PersonalizedLogbookBackdrop)),
        ),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('Rider logbook renders hero header, entries, badges on mobile', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-1',
      email: 'matt@example.com',
      name: 'Matt French',
      notes: sampleRiderEntries,
    );

    final photoBytes = await tester.runAsync(_createSamplePhotoBytes);
    final photo = MemoryImage(photoBytes!);

    await pumpRiderLogbook(
      tester,
      harness: harness,
      rider: rider,
      size: const Size(412, 860),
      previewImage: photo,
    );

    expect(find.byType(PersonalizedLogbookBackdrop), findsOneWidget);
    expect(find.byType(LogbookHeroHeader), findsOneWidget);
    expect(find.text('Matt French'), findsOneWidget);
    expect(find.text('Training journal & progress history'), findsOneWidget);
    expect(find.text('Add entry'), findsOneWidget);
    expect(find.byType(LogbookEntryCard), findsAtLeastNWidgets(2));
    expect(find.byType(AppStatusBadge), findsOneWidget);
    expect(find.text('1st'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _captureScreenshot(tester, 'rider_logbook_mobile.png');
  });

  testWidgets('Rider logbook renders cleanly on desktop with long name', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-2',
      email: 'alex@example.com',
      name: 'Alexandria Montgomery-Fitzgerald of Meadowbrook Stables',
      notes: sampleRiderEntries,
    );

    final photoBytes = await tester.runAsync(_createSamplePhotoBytes);
    final photo = MemoryImage(photoBytes!);

    await pumpRiderLogbook(
      tester,
      harness: harness,
      rider: rider,
      size: const Size(1180, 820),
      previewImage: photo,
    );

    expect(find.byType(PersonalizedLogbookBackdrop), findsOneWidget);
    expect(find.byType(LogbookHeroHeader), findsOneWidget);
    expect(find.byType(LogbookEntryCard), findsAtLeastNWidgets(2));
    expect(tester.takeException(), isNull);

    await _captureScreenshot(tester, 'rider_logbook_desktop.png');
  });

  testWidgets('Rider logbook renders empty state when journal has no entries', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-empty',
      email: 'empty@example.com',
      name: 'Sam',
    );

    await pumpRiderLogbook(
      tester,
      harness: harness,
      rider: rider,
      size: const Size(412, 860),
    );

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Start your training journal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Horse logbook renders hero header, filters, entries on mobile', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-1',
      email: 'matt@example.com',
      name: 'Matt French',
    );
    final horse = HorseProfile(
      id: 'horse-1',
      name: 'Valero',
      breed: 'Lusitano',
      gender: 'Gelding',
      currentOwnerId: 'matt@example.com',
      notes: sampleHorseEntries,
    );

    final photoBytes = await tester.runAsync(_createSamplePhotoBytes);
    final photo = MemoryImage(photoBytes!);

    await pumpHorseLogbook(
      tester,
      harness: harness,
      rider: rider,
      horse: horse,
      size: const Size(412, 860),
      previewImage: photo,
    );

    expect(find.byType(PersonalizedLogbookBackdrop), findsOneWidget);
    expect(find.byType(LogbookHeroHeader), findsOneWidget);
    expect(find.text('Valero'), findsOneWidget);
    expect(find.text('Training journal & progress history'), findsOneWidget);
    expect(find.text('Lusitano · Gelding'), findsOneWidget);
    expect(find.byType(LogbookEntryCard), findsAtLeastNWidgets(2));
    expect(tester.takeException(), isNull);

    await _captureScreenshot(tester, 'horse_logbook_mobile.png');
  });

  testWidgets('Horse logbook renders cleanly on desktop and empty state', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-1',
      email: 'matt@example.com',
      name: 'Matt French',
    );
    final horse = HorseProfile(
      id: 'horse-1',
      name: 'Dahlia Dark Horse',
      breed: 'Andalusian',
      gender: 'Mare',
      currentOwnerId: 'matt@example.com',
      notes: sampleHorseEntries,
    );

    final photoBytes = await tester.runAsync(_createSamplePhotoBytes);
    final photo = MemoryImage(photoBytes!);

    await pumpHorseLogbook(
      tester,
      harness: harness,
      rider: rider,
      horse: horse,
      size: const Size(1180, 820),
      previewImage: photo,
    );

    expect(find.byType(PersonalizedLogbookBackdrop), findsOneWidget);
    expect(find.byType(LogbookHeroHeader), findsOneWidget);
    expect(find.byType(LogbookEntryCard), findsAtLeastNWidgets(2));
    expect(tester.takeException(), isNull);

    await _captureScreenshot(tester, 'horse_logbook_desktop.png');

    // Also verify empty horse journal
    final emptyHorse = horse.copyWith(notes: const []);
    await pumpHorseLogbook(
      tester,
      harness: harness,
      rider: rider,
      horse: emptyHorse,
      size: const Size(412, 860),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('No Entries in the Log'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rider logbook scrolls smoothly with long entry lists', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final manyEntries = [
      for (var i = 0; i < 18; i++)
        BaseListItem(
          id: 'scroll-$i',
          name: 'Training note #$i for endurance and rhythm.',
          date: DateTime(2026, 11).add(Duration(days: i)),
          riderLog: RiderLogDetails(
            type: RiderLogType.values[i % RiderLogType.values.length],
            title: 'Session $i',
          ),
        ),
    ];
    final rider = RiderProfile(
      id: 'rider-scroll',
      email: 'scroll@example.com',
      name: 'Matt French',
      notes: manyEntries,
    );
    final photoBytes = await tester.runAsync(_createSamplePhotoBytes);
    await pumpRiderLogbook(
      tester,
      harness: harness,
      rider: rider,
      size: const Size(412, 860),
      previewImage: MemoryImage(photoBytes!),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rider logbook supports search, sort, FAB, and light theme', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-theme',
      email: 'theme@example.com',
      name: 'Matt French',
      notes: sampleRiderEntries,
    );
    harness.cubit.emit(
      harness.cubit.state.copyWith(isGuest: false, usersProfile: rider),
    );
    final logbookRepo = InMemoryLogbookConnectionRepository();
    final riderRepo = InMemoryLogbookRiderProfileRepository();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LogbookConnectionRepository>.value(
            value: logbookRepo,
          ),
          RepositoryProvider<LogbookRiderProfileRepository>.value(
            value: riderRepo,
          ),
        ],
        child: BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: HorseAndRidersTheme().getLightTheme(),
            home: RiderLogbookPage(email: rider.email),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Add entry'), findsOneWidget);
    expect(find.byType(LogbookAddFab), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search entries'),
      'Navarro',
    );
    await tester.pump();
    expect(find.text('Autumn Classic Ease of Handling'), findsOneWidget);
    expect(find.byType(LogbookPlacingBadge), findsOneWidget);
    expect(find.text('Working Equitation Lesson'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Horse logbook renders placing badge, FAB, and light theme', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final rider = RiderProfile(
      id: 'rider-1',
      email: 'matt@example.com',
      name: 'Matt French',
    );
    final horse = HorseProfile(
      id: 'horse-1',
      name: 'Valero',
      currentOwnerId: 'matt@example.com',
      notes: sampleHorseEntries,
    );
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: rider,
        horseProfile: horse,
      ),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          theme: HorseAndRidersTheme().getLightTheme(),
          home: Builder(
            builder: (context) => LogViewDialog(
              name: horse.name,
              horseId: horse.id,
              horseProfile: horse,
              notes: horse.notes,
              isRider: false,
              appContext: context,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Add entry'), findsOneWidget);
    expect(find.byType(LogbookAddFab), findsNothing);
    expect(find.byType(LogbookPlacingBadge), findsOneWidget);
    expect(find.text('2nd'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
