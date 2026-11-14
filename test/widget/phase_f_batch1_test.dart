import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/form_page_body.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

const _scratchDir =
    '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch';

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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
  });

  testWidgets(
    'OceanCoralAppDialog renders scrollable content without overflow',
    (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: HorseAndRidersTheme().getDarkTheme(),
        home: Scaffold(
          body: OceanCoralAppDialog(
            scrollable: true,
            title: const Text('Sample Dialog'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 12; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Field $i'),
                    ),
                  ),
              ],
            ),
            actions: [
              AppOutlinedButton(label: 'Cancel', onPressed: () {}),
              AppPrimaryButton(label: 'Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OceanCoralSurface), findsOneWidget);
    expect(find.text('Sample Dialog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FormPageBody uses AppScaffoldBackdrop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: HorseAndRidersTheme().getDarkTheme(),
        home: const Scaffold(
          body: FormPageBody(
            maxWidth: 600,
            child: AppSurfaceCard(child: Text('Form Content')),
          ),
        ),
      ),
    );
    expect(find.byType(AppScaffoldBackdrop), findsOneWidget);
    expect(find.text('Form Content'), findsOneWidget);
  });

  testWidgets('SettingsView renders cards and controls on mobile and desktop', (
    tester,
  ) async {
    final controller = SettingsController(SettingsService());
    await controller.loadSettings();
    addTearDown(controller.dispose);

    for (final entry in {
      'settings_mobile.png': const Size(412, 860),
      'settings_desktop.png': const Size(1180, 820),
    }.entries) {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: HorseAndRidersTheme().getDarkTheme(),
            home: SettingsView(controller: controller),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AppScaffoldBackdrop), findsOneWidget);
      expect(find.byType(AppSurfaceCard), findsNWidgets(2));
      expect(find.byKey(const Key('skillTreeLayoutSetting')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _captureScreenshot(tester, entry.key);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('DeletePage renders AppGlassDialog on mobile and desktop', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);

    for (final entry in {
      'delete_dialog_mobile.png': const Size(412, 860),
      'delete_dialog_desktop.png': const Size(1180, 820),
    }.entries) {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        RepaintBoundary(
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: HorseAndRidersTheme().getDarkTheme(),
              home: const Scaffold(
                body: AppScaffoldBackdrop(
                  child: Center(child: DeletePage()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AppGlassDialog), findsOneWidget);
      expect(find.byType(AppFeedbackBanner), findsOneWidget);
      expect(find.byType(AppDestructiveButton), findsOneWidget);
      expect(find.byType(AppOutlinedButton), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _captureScreenshot(tester, entry.key);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
