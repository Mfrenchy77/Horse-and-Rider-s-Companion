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

  late bool _isHands;
  late bool _isPounds;

  // Allow Widgets to read the user's preferred ThemeMode.
  ThemeMode get darkMode => _darkMode;
  bool get seasonalMode => _seasonalMode;
  ThemeData get theme => HorseAndRidersTheme().getLightTheme();
  ThemeData get darkTheme => HorseAndRidersTheme().getDarkTheme();
  bool get isHands => _isHands;
  bool get isPounds => _isPounds;
  bool get onBoardingStatus => _settingsService.getOnboardingStatus();

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    try {
      _darkMode = _settingsService.getSavedDarkMode();
      _seasonalMode = _settingsService.getSeasonalMode();
      _isHands = _settingsService.getHorseHeightUnit();
      _isPounds = _settingsService.getHorseWeightUnit();
      notifyListeners();
    } catch (e) {
      // Handle the error, log it, or show a user-friendly message
      debugPrint('Error loading settings: $e');
    }
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) {
      return;
    } else if (newThemeMode == _darkMode) {
      return;
    } else {
      _darkMode = newThemeMode;

      // Persist the changes to a local database or the internet using the
      // SettingService.
      await _settingsService.updateDarkMode(newThemeMode);
      // Important! Inform listeners a change has occurred.
      notifyListeners();
    }
  }

  ///Update and persist the seasonal mode based on the user's selection
  Future<void> updateSeasonalMode() async {
    _seasonalMode = !_seasonalMode; // Toggle the current value
    await _settingsService.updateSeasonalMode();
    notifyListeners();
  }

  /// Update and persist the user's preferred unit for displaying horse's height
  Future<void> updateHorseHeightUnit() async {
    // Toggle the current value
    _isHands = !_isHands;
    await _settingsService.updateHorseHeightUnit(isHands: _isHands);
    notifyListeners();
  }

  /// Update and persist the user's preferred unit for displaying horse's weight
  Future<void> updateHorseWeightUnit() async {
    // Toggle the current value
    _isPounds = !_isPounds;
    await _settingsService.updateHorseWeightUnit(isPounds: _isPounds);
    notifyListeners();
  }

  /// Update and persist the onboarding status
  Future<void> updateOnboardingStatus() async {
    await _settingsService.updateOnboardingStatus();
    notifyListeners();
  }


}
