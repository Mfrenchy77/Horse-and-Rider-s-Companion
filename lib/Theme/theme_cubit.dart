import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

enum ThemeState { light, dark }

class ThemeModeCubit extends Cubit<bool> {
  ThemeModeCubit() : super(false) {
    _loadTheme();
  }

  Future<void> toggleTheme() async {
    final isDarkTheme = SharedPrefs().isDarkMode;
    SharedPrefs().setDarkModeBool(isDark: !isDarkTheme);
    emit(!isDarkTheme);
  }

  Future<void> _loadTheme() async {
    final isDarkTheme = SharedPrefs().isDarkMode;
    emit(isDarkTheme);
  }

  ThemeData getTheme() {
    return HorseAndRidersTheme().getTheme();
  }
}
