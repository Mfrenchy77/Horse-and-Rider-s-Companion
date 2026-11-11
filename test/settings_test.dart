import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsController controller;
  late SharedPrefs prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = SharedPrefs();
    await prefs.init();
    controller = SettingsController(SettingsService());
    await controller.loadSettings();
  });
  tearDown(() => controller.dispose());

  test('loads initial preferences', () {
    expect(controller.darkMode, ThemeMode.dark);
    expect(controller.seasonalMode, isFalse);
    expect(controller.isHands, isTrue);
    expect(controller.isPounds, isTrue);
    expect(prefs.isFirstLaunch(), isTrue);
    expect(prefs.showOnboarding(), isTrue);
  });

  for (final mode in ThemeMode.values) {
    test('persists and reloads ${mode.name} theme', () async {
      await controller.updateThemeMode(mode);
      await controller.loadSettings();
      expect(controller.darkMode, mode);
      expect(prefs.getSavedThemeModeThemeMode(), mode);
    });
  }
  test('unchanged and null themes do not notify', () async {
    var count = 0;
    controller.addListener(() => count++);
    await controller.updateThemeMode(null);
    await controller.updateThemeMode(ThemeMode.dark);
    expect(count, 0);
    await controller.updateThemeMode(ThemeMode.light);
    expect(count, 1);
  });
  test('season and units persist across controller reloads', () async {
    await controller.updateSeasonalMode();
    await controller.updateHorseHeightUnit();
    await controller.updateHorseWeightUnit();
    await controller.loadSettings();
    expect(controller.seasonalMode, isTrue);
    expect(controller.isHands, isFalse);
    expect(controller.isPounds, isFalse);
    await controller.updateHorseHeightUnit();
    await controller.updateHorseWeightUnit();
    expect(prefs.isHeightInHands, isTrue);
    expect(prefs.isWeightInPounds, isTrue);
  });
  test(
    'resource layout defaults to vertical and restores both choices',
    () async {
      expect(controller.resourceLayout, ResourceLayout.vertical);
      for (final layout in [
        ResourceLayout.horizontal,
        ResourceLayout.vertical,
      ]) {
        await controller.updateResourceLayout(layout);
        final restored = SettingsController(SettingsService());
        await restored.loadSettings();
        expect(restored.resourceLayout, layout);
        restored.dispose();
      }
    },
  );
  testWidgets('Settings offers and remembers all three Skill Tree layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    expect(controller.skillTreeLayout, SkillTreeLayout.library);
    await tester.pumpWidget(
      MaterialApp(home: SettingsView(controller: controller)),
    );
    final dropdown = find.byKey(const Key('skillTreeLayoutSetting'));
    await tester.ensureVisible(dropdown);
    for (final layout in [
      SkillTreeLayout.progressBoard,
      SkillTreeLayout.expandInPlace,
      SkillTreeLayout.library,
    ]) {
      final selected = find.descendant(
        of: dropdown,
        matching: find.text(controller.skillTreeLayout.label),
      );
      await tester.ensureVisible(selected);
      await tester.pumpAndSettle();
      await tester.tap(selected);
      await tester.pumpAndSettle();
      for (final option in SkillTreeLayout.values) {
        expect(find.text(option.label), findsWidgets);
      }
      await tester.tap(find.text(layout.label).last);
      await tester.pumpAndSettle();
      expect(controller.skillTreeLayout, layout);
      final restored = SettingsController(SettingsService());
      await restored.loadSettings();
      expect(restored.skillTreeLayout, layout);
      restored.dispose();
    }
  });
  test('onboarding and first-launch flags round trip', () {
    prefs
      ..setFirstLaunch(isFirst: false)
      ..setShowOnboarding(show: false);
    expect(prefs.isFirstLaunch(), isFalse);
    expect(prefs.showOnboarding(), isFalse);
  });
  test('theme follows platform brightness when system is selected', () {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    prefs.setDarkMode(isDark: 'system');
    dispatcher.platformBrightnessTestValue = Brightness.light;
    expect(prefs.isDarkMode, isFalse);
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    expect(prefs.isDarkMode, isTrue);
  });
}
