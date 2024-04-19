// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A singleton class that abstracts `SharedPreferences` operations
/// to persist user preferences across app launches.
class SharedPrefs {
  /// Factory constructor to return the same instance of [SharedPrefs].
  factory SharedPrefs() => SharedPrefs._internal();

  /// Private constructor for the singleton pattern.
  SharedPrefs._internal();

  /// Constants to use as keys for storing preferences.
  static const String PREF_DARK_MODE = 'ThemeMode';
  static const String PREF_SEASONAL_MODE = 'SeasonalMode';
  static const String PREF_IS_FIRST_LAUNCH = 'IsFirstLaunch';
  static const String PREF_SHOW_ONBOARDING = 'ShowOnboarding';
  static const String PREF_HEIGHT_PREFERENCE = 'HeightPreference';
  static const String PREF_WEIGHT_PREFERENCE = 'WeightPreference';

  /// The instance of [SharedPreferences] used for
  ///  storing and retrieving preferences.
  static late SharedPreferences _sharedPrefs;

  /// Initializes the [SharedPreferences] instance asynchronously.
  /// This method needs to be called before
  /// accessing other [SharedPrefs] methods.
  Future<void> init() async {
    _sharedPrefs = await SharedPreferences.getInstance();
  }

  /// Retrieves the user's preference for seasonal mode.
  /// Returns `true` if seasonal mode is enabled, `false` otherwise.
  /// Defaults to `true` if the preference has not been set.
  bool isSeasonalMode() {
    return _sharedPrefs.getBool(PREF_SEASONAL_MODE) ?? false;
  }

  /// Sets the user's preference for seasonal mode.
  void setSeasonalMode({required bool isSeasonal}) {
    _sharedPrefs.setBool(PREF_SEASONAL_MODE, isSeasonal);
  }

  /// Retrieves the user's preference for showing the onboarding screen.
  /// Returns `true` if the onboarding screen should be shown, `false`
  ///  otherwise defaults to `true` if the preference has not been set.
  bool showOnboarding() {
    return _sharedPrefs.getBool(PREF_SHOW_ONBOARDING) ?? true;
  }

  /// Sets the user's preference for showing the onboarding screen.
  void setShowOnboarding({required bool show}) {
    _sharedPrefs.setBool(PREF_SHOW_ONBOARDING, show);
  }

  /// Retrieves the user's preference for the first launch of the app.
  /// Returns `true` if the app is being launched for the first time, `false`
  ///  otherwise defaults to `true` if the preference has not been set.
  /// This preference is set to `false` after the first launch.
  bool isFirstLaunch() {
    return _sharedPrefs.getBool(PREF_IS_FIRST_LAUNCH) ?? true;
  }

  /// Sets the user's preference for the first launch of the app.
  /// This preference is set to `false` after the first launch.
  /// Defaults to `true` if the preference has not been set.
  /// Returns `true` if the app is being launched for the first time,
  ///  `false` otherwise defaults to `true` if the preference has not been set.
  void setFirstLaunch({required bool isFirst}) {
    _sharedPrefs.setBool(PREF_IS_FIRST_LAUNCH, isFirst);
  }

  /// Determines if the dark mode is enabled based on the user's preference.
  /// Returns `true` for dark mode, `false`
  /// for light mode, and follows system theme if set to `system`.
  bool get isDarkMode {
    final themePref = _sharedPrefs.getString(PREF_DARK_MODE);
    switch (themePref) {
      case 'light':
        return false;
      case 'dark':
        return true;
      case 'system':
        return SchedulerBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
      default:
        return false;
    }
  }

  /// Sets the dark mode preference as a string value.
  void setDarkMode({required String isDark}) {
    _sharedPrefs.setString(PREF_DARK_MODE, isDark);
  }

  /// Sets the dark mode preference as a boolean value.
  void setDarkModeBool({required bool isDark}) {
    _sharedPrefs.setString(PREF_DARK_MODE, isDark ? 'dark' : 'light');
  }

  /// Retrieves the saved theme mode preference as a string.
  /// Defaults to 'light' if no preference has been set.
  String getSavedThemeMode() {
    return _sharedPrefs.getString(PREF_DARK_MODE) ?? 'light';
  }

  /// Converts the saved theme mode preference to a [ThemeMode] enum.
  ThemeMode getSavedThemeModeThemeMode() {
    final themeMode = getSavedThemeMode();
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Sets the User's Preference as [bool] for "Hands" or "Centimeters"
  /// for viewing the horses height. Default is "Hands".
  void setHeightPreference({required bool isHands}) {
    _sharedPrefs.setBool(PREF_HEIGHT_PREFERENCE, isHands);
  }

  /// Retrieves the user's preference for viewing the horse's height.
  /// Returns `true` if the user prefers to view the height in hands,
  /// `false` if the user prefers to view the height in centimeters.
  /// Defaults to `true` if the preference has not been set.
  bool get isHeightInHands {
    return _sharedPrefs.getBool(PREF_HEIGHT_PREFERENCE) ?? true;
  }

  /// Sets the User's Preference as [bool] for "Pounds" or "Kilograms"
  /// for viewing the horses weight. Default is "Pounds".
  void setWeightPreference({required bool isPounds}) {
    _sharedPrefs.setBool(PREF_WEIGHT_PREFERENCE, isPounds);
  }

  /// Retrieves the user's preference for viewing the horse's weight.
  /// Returns `true` if the user prefers to view the weight in pounds,
  /// `false` if the user prefers to view the weight in kilograms.
  /// Defaults to `true` if the preference has not been set.
  bool get isWeightInPounds {
    return _sharedPrefs.getBool(PREF_WEIGHT_PREFERENCE) ?? true;
  }
}
