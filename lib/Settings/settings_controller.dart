import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService _settingsService;

  // Make ThemeMode a private variable so it is not updated directly without
  // also persisting the changes with the SettingsService.
  late ThemeMode _darkMode;
  late bool _seasonalMode;
  // Allow Widgets to read the user's preferred ThemeMode.
  ThemeMode get darkMode => _darkMode;
  bool get seasonalMode => _seasonalMode;
  ThemeData get theme => HorseAndRidersTheme().getLightTheme();
  ThemeData get darkTheme => HorseAndRidersTheme().getDarkTheme();

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    _darkMode = _settingsService.getSavedDarkMode();
    _seasonalMode = _settingsService.getSeasonalMode();

    // Important! Inform listeners a change has occurred.
    notifyListeners();
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) {
      return;
    }
    // Do not perform any work if new and old ThemeMode are identical
    else if (newThemeMode == _darkMode) {
      return;
    }

    // Otherwise, store the new ThemeMode in memory
    else {
      _darkMode = newThemeMode;

      // Persist the changes to a local database or the internet using the
      // SettingService.
      await _settingsService.updateDarkMode(newThemeMode);
      // Important! Inform listeners a change has occurred.
      notifyListeners();
    }
  }

  ///Updare and persist the seasonal mode based on the user's selection
  void updateSeasonalMode() {
    _settingsService.updateSeasonalMode();
    notifyListeners();
  }
}
