import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

/// A service that stores and retrieves user settings.
class SettingsService {
  Future<ThemeMode> getSystemThemeMode() async => ThemeMode.system;

  /// Loads the User's preferred ThemeMode from local or remote storage.
  ThemeMode getSavedDarkMode() {
    final themeMode = SharedPrefs().getSavedThemeMode();
    if (themeMode == 'light') {
      return ThemeMode.light;
    } else if (themeMode == 'dark') {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }

  /// Loads the User's preferred seasonalMode from local or remote storage.
  bool getSeasonalMode() {
    return SharedPrefs().isSeasonalMode();
  }

  /// Persists the user's preferred ThemeMode to local storage.
  Future<void> updateDarkMode(ThemeMode theme) async {
    // Use the shared_preferences package to persist settings locally or the
    if (theme == ThemeMode.system) {
      SharedPrefs().setDarkMode(isDark: 'system');
      debugPrint('ThemeMode.system');
    } else if (theme == ThemeMode.light) {
      SharedPrefs().setDarkMode(isDark: 'light');
      debugPrint('ThemeMode.light');
    } else if (theme == ThemeMode.dark) {
      SharedPrefs().setDarkMode(isDark: 'dark');
      debugPrint('ThemeMode.dark');
    } else {
      debugPrint('ThemeMode.else');
    }
  }

  ///Persists the users perfered perefernce for seasonal mode to local storage
  Future<void> updateSeasonalMode() async {
    SharedPrefs().setSeasonalMode(isSeasonal: !SharedPrefs().isSeasonalMode());

    debugPrint(
      'Seasonal Mode settings service: ${SharedPrefs().isSeasonalMode()}',
    );
  }

  ThemeData getThemeMode() {
    return HorseAndRidersTheme().getTheme();
  }
}
