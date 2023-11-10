// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  factory SharedPrefs() => SharedPrefs._internal();

  SharedPrefs._internal();

  // constants.dart

  static const String PREF_DARK_MODE = 'ThemeMode';
  static const String PREF_SEASONAL_MODE = 'SeasonalMode';
  static late SharedPreferences _sharedPrefs;

  Future<void> init() async {
    _sharedPrefs = await SharedPreferences.getInstance();
  }

  bool isSeasonalMode() {
    return _sharedPrefs.getBool(PREF_SEASONAL_MODE) ?? true;
  }

  void setSeasonalMode({required bool isSeasonal}) {
    _sharedPrefs.setBool(PREF_SEASONAL_MODE, isSeasonal);
  }

  bool get isDarkMode {
    if (_sharedPrefs.getString(PREF_DARK_MODE) == 'light') {
      return false;
    } else if (_sharedPrefs.getString(PREF_DARK_MODE) == 'dark') {
      return true;
    } else if (_sharedPrefs.getString(PREF_DARK_MODE) == 'system') {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } else {
      return false;
    }
  }

  void setDarkMode({required String isDark}) {
    _sharedPrefs.setString(PREF_DARK_MODE, isDark);
  }

  void setDarkModeBool({required bool isDark}) {
    _sharedPrefs.setString(PREF_DARK_MODE, isDark ? 'dark' : 'light');
  }

  String getSavedThemeMode() {
    return _sharedPrefs.getString(PREF_DARK_MODE) ?? 'light';
  }

  ThemeMode getSavedThemeModeThemeMode() {
    final themeMode = _sharedPrefs.getString(PREF_DARK_MODE) ?? 'light';
    if (themeMode == 'light') {
      return ThemeMode.light;
    } else if (themeMode == 'dark') {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }
  // void setDarkMode({required bool isDark}) {
  //   _sharedPrefs.setBool(PREF_DARK_MODE, isDark);
  //
}
