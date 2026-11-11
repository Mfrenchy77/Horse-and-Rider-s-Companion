import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
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
  ResourceLayout _resourceLayout = ResourceLayout.vertical;
  SkillTreeLayout _skillTreeLayout = SkillTreeLayout.library;

  // Allow Widgets to read the user's preferred ThemeMode.
  ThemeMode get darkMode => _darkMode;
  bool get seasonalMode => _seasonalMode;
  ThemeData get theme => HorseAndRidersTheme().getLightTheme();
  ThemeData get darkTheme => HorseAndRidersTheme().getDarkTheme();
  bool get isHands => _isHands;
  bool get isPounds => _isPounds;
  ResourceLayout get resourceLayout => _resourceLayout;
  SkillTreeLayout get skillTreeLayout => _skillTreeLayout;
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
      _resourceLayout = _settingsService.getResourceLayout();
      _skillTreeLayout = _settingsService.getSkillTreeLayout();
      notifyListeners();
    } catch (e) {
      // Handle the error, log it, or show a user-friendly message
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> updateResourceLayout(ResourceLayout? layout) async {
    if (layout == null || layout == _resourceLayout) return;
    _resourceLayout = layout;
    notifyListeners();
    await _settingsService.updateResourceLayout(layout);
  }

  Future<void> updateSkillTreeLayout(SkillTreeLayout? layout) async {
    if (layout == null || layout == _skillTreeLayout) return;
    _skillTreeLayout = layout;
    notifyListeners();
    await _settingsService.updateSkillTreeLayout(layout);
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
