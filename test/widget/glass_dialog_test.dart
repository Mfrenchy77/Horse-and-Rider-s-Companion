import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_level_select_confirmation_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_sort_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class _MockKeysRepository extends Mock implements KeysRepository {}

class _MockCloudRepository extends Mock implements CloudRepository {}

void main() {
  testWidgets(
    'showAppGlassDialog blurs backdrop and renders translucent surface',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      for (final theme in [
        HorseAndRidersTheme().getDarkTheme(),
        HorseAndRidersTheme().getLightTheme(),
      ]) {
        bool? confirmed;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      confirmed = await showAppGlassDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AppGlassDialog(
                          title: const Text('Delete this entry?'),
                          content: const Text(
                            'A shared entry is removed from both logbooks.',
                          ),
                          actions: [
                            AppOutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              label: 'Cancel',
                            ),
                            AppDestructiveButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              label: 'Delete',
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
        expect(find.byType(AppGlassDialog), findsOneWidget);
        expect(find.byType(AppGlassSurface), findsOneWidget);
        expect(find.text('Delete this entry?'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(confirmed, isTrue);
        expect(find.byType(AppGlassDialog), findsNothing);
      }
    },
  );

  testWidgets('showAppGlassDialog honors reduced-motion setting', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: HorseAndRidersTheme().getDarkTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAppGlassDialog<void>(
                  context: context,
                  builder: (dialogContext) => AppGlassDialog(
                    title: const Text('Reduced motion dialog'),
                    content: const Text('Instant open'),
                    actions: [
                      AppOutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        label: 'Close',
                      ),
                    ],
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    // Immediately visible with BackdropFilter when reduced motion is enabled.
    expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
    expect(find.text('Reduced motion dialog'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pump();
    expect(find.text('Reduced motion dialog'), findsNothing);
  });

  testWidgets(
    'AddLogEntryDialog renders inside AppGlassDialog and supports cancel',
    (tester) async {
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
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: rider,
          horseProfile: horse,
        ),
      );

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<HorseProfileRepository>.value(
              value: harness.horses,
            ),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: HorseAndRidersTheme().getDarkTheme(),
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showAppGlassDialog<void>(
                      context: context,
                      builder: (_) => AddLogEntryDialog(
                        usersProfile: rider,
                        horseProfile: horse,
                      ),
                    ),
                    child: const Text('Add Log'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Log'));
      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
      expect(find.byType(AppGlassDialog), findsOneWidget);
      expect(find.textContaining('Add New Log Entry'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AddLogEntryDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AddHorseDialog renders in AppGlassDialog on mobile with keyboard insets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
      );

      final keys = _MockKeysRepository();
      when(keys.getLocationApiKey).thenAnswer((_) async => '');
      when(keys.getZipCodeApiKey).thenAnswer((_) async => '');

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<KeysRepository>.value(value: keys),
            RepositoryProvider<CloudRepository>.value(
              value: _MockCloudRepository(),
            ),
            RepositoryProvider<HorseProfileRepository>.value(
              value: harness.horses,
            ),
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 700),
                viewInsets: EdgeInsets.only(bottom: 220),
              ),
              child: MaterialApp(
                theme: HorseAndRidersTheme().getDarkTheme(),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () => showAppGlassDialog<void>(
                        context: context,
                        builder: (_) => AddHorseDialog(
                          editProfile: true,
                          userProfile: rider,
                          horseProfile: horse,
                        ),
                      ),
                      child: const Text('Edit Horse'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Horse'));
      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
      expect(find.byType(AppGlassDialog), findsOneWidget);
      expect(find.text('Edit Horse: Valero'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AddHorseDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'showAppGlassDialog actually blurs pixels behind the dialog',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            theme: HorseAndRidersTheme().getDarkTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    // High-contrast 8px black/white vertical stripes in top-left.
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Row(
                        children: [
                          for (int i = 0; i < 20; i++)
                            Container(
                              width: 8,
                              height: 200,
                              color: i.isEven ? Colors.white : Colors.black,
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => showAppGlassDialog<void>(
                          context: context,
                          builder: (dialogContext) => AppGlassDialog(
                            title: const Text('Glass'),
                            content: const Text('Blur check'),
                            actions: [
                              AppOutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                label: 'Close',
                              ),
                            ],
                          ),
                        ),
                        child: const Text('Open'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final bytes = await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        return image.toByteData();
      });
      expect(bytes, isNotNull);

      // Sample row y=60 across x=20..120 (over the 8px white/black stripes).
      // If blurred strongly, adjacent pixels will be close in luminance
      // (max - min << 100); if unblurred/merely dimmed, max - min > 150.
      var minLum = 255;
      var maxLum = 0;
      const y = 60;
      for (var x = 20; x < 120; x++) {
        final offset = (y * 800 + x) * 4;
        final r = bytes!.getUint8(offset);
        if (r < minLum) minLum = r;
        if (r > maxLum) maxLum = r;
      }
      debugPrint('Backdrop pixel luminance range: min=$minLum, max=$maxLum');
      expect(maxLum - minLum, lessThan(40));
    },
  );

  testWidgets(
    'SkillSortDialog and SkillLevelSelectedConfimationDialog use glass dialog',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final skill = Skill(
        id: 'skill-1',
        skillName: 'Shoulder-in',
        difficulty: DifficultyState.Intermediate,
        rider: true,
        position: 0,
        description: 'Lateral movement',
        learningDescription: 'Learning shoulder-in',
        proficientDescription: 'Proficient shoulder-in',
        lastEditBy: 'matt@example.com',
        lastEditDate: DateTime(2026),
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          isForRider: true,
          skill: skill,
          usersProfile: RiderProfile(
            id: 'rider-1',
            email: 'matt@example.com',
            name: 'Matt French',
          ),
        ),
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: HorseAndRidersTheme().getDarkTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => showAppGlassDialog<void>(
                        context: context,
                        builder: (_) => const SkillSortDialog(),
                      ),
                      child: const Text('Sort'),
                    ),
                    ElevatedButton(
                      onPressed: () => showAppGlassDialog<void>(
                        context: context,
                        builder: (_) =>
                            const SkillLevelSelectedConfimationDialog(
                              levelState: LevelState.PROFICIENT,
                            ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      expect(find.byType(AppGlassDialog), findsOneWidget);
      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
      expect(find.text('Sort Skills'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(AppGlassDialog), findsOneWidget);
      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
      expect(find.text('Confirm Skill Level'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.byType(AppGlassDialog), findsNothing);
    },
  );

  testWidgets(
    'AddHorseDialog uses frosted density on desktop in light and dark themes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final rider = RiderProfile(
        id: 'rider-1',
        email: 'matt@example.com',
        name: 'Matt French',
      );
      final keys = _MockKeysRepository();
      when(keys.getLocationApiKey).thenAnswer((_) async => '');
      when(keys.getZipCodeApiKey).thenAnswer((_) async => '');

      for (final theme in [
        HorseAndRidersTheme().getDarkTheme(),
        HorseAndRidersTheme().getLightTheme(),
      ]) {
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<KeysRepository>.value(value: keys),
              RepositoryProvider<CloudRepository>.value(
                value: _MockCloudRepository(),
              ),
              RepositoryProvider<HorseProfileRepository>.value(
                value: harness.horses,
              ),
              RepositoryProvider<RiderProfileRepository>.value(
                value: harness.riders,
              ),
            ],
            child: BlocProvider.value(
              value: harness.cubit,
              child: MaterialApp(
                theme: theme,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () => showAppGlassDialog<void>(
                        context: context,
                        builder: (_) => AddHorseDialog(
                          editProfile: false,
                          userProfile: rider,
                          horseProfile: null,
                        ),
                      ),
                      child: const Text('Create Horse'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Create Horse'));
        await tester.pumpAndSettle();

        final dialog = tester.widget<AppGlassDialog>(
          find.byType(AppGlassDialog),
        );
        expect(dialog.density, AppGlassDensity.frosted);
        expect(dialog.maxWidth, 600);
        expect(find.text('Create New Horse Profile'), findsOneWidget);

        // Comfortable margins around floating dialog on 1280px desktop.
        final surfaceRect = tester.getRect(find.byType(AppGlassSurface));
        expect(surfaceRect.left, greaterThan(250));
        expect(1280 - surfaceRect.right, greaterThan(250));

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
