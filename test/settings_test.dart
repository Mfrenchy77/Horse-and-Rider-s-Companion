import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
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
