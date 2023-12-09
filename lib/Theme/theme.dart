import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:horseandriderscompanion/utils/MyConstants/COLOR_CONST.dart';

enum ThemeSeasons {
  main,
  halloween,
  christmas,
  easter,
  spring,
  summer,
  autumn,
  winter,
}

class HorseAndRidersTheme {
  ThemeData getLightTheme() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;
    final themeSeasons = _getSeason(month, day);

    if (SharedPrefs().isSeasonalMode()) {
      switch (themeSeasons) {
        case ThemeSeasons.main:
          return mainThemeLight;
        case ThemeSeasons.halloween:
          return halloweenTheme;
        case ThemeSeasons.christmas:
          return christmasTheme;
        case ThemeSeasons.easter:
          return easterTheme;
        case ThemeSeasons.spring:
          return springTheme;
        case ThemeSeasons.summer:
          return summerTheme;
        case ThemeSeasons.autumn:
          return autumnTheme;
        case ThemeSeasons.winter:
          return winterTheme;
      }
    } else {
      return mainThemeLight;
    }
  }

  ThemeData getDarkTheme() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;
    final themeSeasons = _getSeason(month, day);
    if (SharedPrefs().isSeasonalMode()) {
      switch (themeSeasons) {
        case ThemeSeasons.main:
          return mainThemeDark;
        case ThemeSeasons.halloween:
          return halloweenThemeDark;
        case ThemeSeasons.christmas:
          return christmasThemeDark;
        case ThemeSeasons.easter:
          return easterThemeDark;
        case ThemeSeasons.spring:
          return springThemeDark;
        case ThemeSeasons.summer:
          return summerThemeDark;
        case ThemeSeasons.autumn:
          return autumnThemeDark;
        case ThemeSeasons.winter:
          return winterThemeDark;
      }
    } else {
      return mainThemeDark;
    }
  }

  ThemeData getTheme() {
    final isDarkTheme = SharedPrefs().isDarkMode;
    if (isDarkTheme) {
      return getDarkTheme();
    } else {
      return getLightTheme();
    }
  }

  static ThemeSeasons _getSeason(int month, int day) {
    if (month == 10) {
      debugPrint('Halloween');
      return ThemeSeasons.halloween;
    } else if (month == 1) {
      debugPrint('Christmas');
      return ThemeSeasons.christmas;
    } else if (month == 3 && day >= 22 || month == 4 && day <= 15) {
      debugPrint('Easter');
      return ThemeSeasons.easter;
    } else if (month == 12 || month < 3) {
      debugPrint('Winter');
      return ThemeSeasons.winter;
    } else if (month >= 3 && month < 6) {
      debugPrint('Spring');
      return ThemeSeasons.spring;
    } else if (month >= 6 && month < 9) {
      debugPrint('Summer');
      return ThemeSeasons.summer;
    } else if (month >= 9 && month < 12) {
      debugPrint('Autumn');
      return ThemeSeasons.autumn;
    }
    // Default to main if the month is somehow out of range
    return ThemeSeasons.main;
  }
}

///   Main Theme

final mainThemeLight = ThemeData(
  //colorSchemeSeed: Colors.blueGrey,
  primarySwatch: Colors.blueGrey,
  scaffoldBackgroundColor: ColorConst.mainBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.mainPrimaryLight,
  ),
  cardColor: ColorConst.mainBackgroundLight,
  dialogBackgroundColor: ColorConst.mainBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.mainBackgroundLight,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: ColorConst.mainPrimaryLight,
    secondary: ColorConst.mainAccentLight,
    background: ColorConst.mainBackgroundLight,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.mainBackgroundDark,
    unselectedItemColor: ColorConst.mainBackgroundLight,
    backgroundColor: ColorConst.mainPrimaryLight,
  ),
);

final mainThemeDark = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorConst.cardDark,
  brightness: Brightness.dark,
  // colorSchemeSeed: Colors.blueGrey,
  scaffoldBackgroundColor: const Color.fromARGB(255, 44, 44, 44),
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.cardDark,
  ),
  cardColor: ColorConst.cardDark,
  cardTheme: const CardTheme(
    color: ColorConst.cardDark,
  ),
  dialogBackgroundColor: ColorConst.mainBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.mainBackgroundDark,
  ),
  // colorScheme: ColorScheme.fromSwatch().copyWith(
  //   brightness: Brightness.dark,
  //   primary: ColorConst.mainBackgroundDark,
  //   secondary: ColorConst.mainAccentDark,
  //   background: ColorConst.mainBackgroundDark,
  // ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.mainAccentDark,
    unselectedItemColor: ColorConst.mainBackgroundDark,
    backgroundColor: ColorConst.cardDark,
  ),
);

///     Spring Theme

final springTheme = ThemeData(
  primarySwatch: Colors.lightGreen,
  scaffoldBackgroundColor: ColorConst.springBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.springPrimaryLight,
  ),
  cardColor: ColorConst.springBackgroundLight,
  dialogBackgroundColor: ColorConst.springBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.springBackgroundLight,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: ColorConst.springPrimaryLight,
    secondary: ColorConst.springAccentLight,
    background: ColorConst.springBackgroundLight,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.springAccentLight,
    unselectedItemColor: ColorConst.springBackgroundLight,
    backgroundColor: ColorConst.springPrimaryLight,
  ),
);

final springThemeDark = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.springBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.springPrimaryDark,
  ),
  cardColor: ColorConst.springBackgroundDark,
  dialogBackgroundColor: ColorConst.springBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.springBackgroundDark,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.dark,
    primary: ColorConst.springPrimaryDark,
    secondary: ColorConst.springAccentDark,
    background: ColorConst.springBackgroundDark,
  ),
  primarySwatch: Colors.green,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.springAccentDark,
    unselectedItemColor: ColorConst.springBackgroundDark,
    backgroundColor: ColorConst.springPrimaryDark,
  ),
);

///   Summer Theme

final summerTheme = ThemeData(
  // useMaterial3: true,
  scaffoldBackgroundColor: ColorConst.summerBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.summerPrimaryLight,
  ),
  cardColor: ColorConst.summerBackgroundLight,
  dialogBackgroundColor: ColorConst.summerBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.summerBackgroundLight,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: ColorConst.summerPrimaryLight,
    secondary: ColorConst.summerAccentLight,
    background: ColorConst.summerBackgroundLight,
  ),
  primarySwatch: Colors.yellow,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.summerAccentLight,
    unselectedItemColor: ColorConst.summerBackgroundLight,
    backgroundColor: ColorConst.summerPrimaryLight,
  ),
);

final summerThemeDark = ThemeData(
  // useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.summerBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.summerPrimaryDark,
  ),
  cardColor: ColorConst.summerBackgroundDark,
  dialogBackgroundColor: ColorConst.summerBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.summerBackgroundDark,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.dark,
    primary: ColorConst.summerPrimaryDark,
    secondary: ColorConst.summerAccentDark,
    background: ColorConst.summerBackgroundDark,
  ),
  primarySwatch: Colors.yellow,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.summerAccentDark,
    unselectedItemColor: ColorConst.summerBackgroundDark,
    backgroundColor: ColorConst.summerPrimaryDark,
  ),
);

///   Autumn Theme
final autumnTheme = ThemeData(
  scaffoldBackgroundColor: ColorConst.fallBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.fallPrimaryLight,
  ),
  cardColor: ColorConst.fallBackgroundLight,
  dialogBackgroundColor: ColorConst.fallBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.fallBackgroundLight,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: ColorConst.fallPrimaryLight,
    secondary: ColorConst.fallAccentLight,
    background: ColorConst.fallBackgroundLight,
  ),
  primarySwatch: Colors.orange,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.fallAccentLight,
    unselectedItemColor: ColorConst.fallBackgroundLight,
    backgroundColor: ColorConst.fallPrimaryLight,
  ),
);

final autumnThemeDark = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorConst.fallPrimaryDark,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.fallBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.fallPrimaryLight,
  ),
  cardColor: ColorConst.fallPrimaryDark,
  dialogBackgroundColor: ColorConst.fallPrimaryDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.fallPrimaryDark,
  ),
  // colorScheme: ColorScheme.fromSwatch().copyWith(
  //   brightness: Brightness.dark,
  //   primary: ColorConst.fallPrimaryLight,
  //   secondary: ColorConst.fallAccentDark,
  //   background: ColorConst.fallBackgroundDark,
  // ),
  //primarySwatch: Colors.orange,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.fallAccentDark,
    unselectedItemColor: ColorConst.fallBackgroundDark,
    backgroundColor: ColorConst.fallPrimaryDark,
  ),
);

///   Winter Theme
final winterTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorConst.winterPrimaryDark,
  scaffoldBackgroundColor: ColorConst.winterBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.winterPrimaryLight,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: ColorConst.winterPrimaryLight,
  ),
 
  cardColor: ColorConst.winterPrimaryLight,
  dialogBackgroundColor: ColorConst.winterBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.winterBackgroundLight,
  ),
  // colorScheme: ColorScheme.fromSwatch().copyWith(
  //   brightness: Brightness.light,
  //   primary: ColorConst.winterPrimaryLight,
  //   secondary: ColorConst.winterAccentLight,
  //   background: ColorConst.winterBackgroundLight,
  // ),
 // primarySwatch: Colors.blue,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.winterBackgroundDark,
    unselectedItemColor: ColorConst.winterBackgroundLight,
    backgroundColor: ColorConst.winterPrimaryLight,
  ),
);

final winterThemeDark = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: ColorConst.winterPrimaryDark,

  ),
  
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: ColorConst.winterPrimaryDark,
    
  ),
  colorSchemeSeed: ColorConst.winterPrimaryLight,
  scaffoldBackgroundColor: ColorConst.winterBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.winterPrimaryDark,
  ),
  cardColor: ColorConst.winterBackgroundDark,
  dialogBackgroundColor: ColorConst.winterBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.winterBackgroundDark,
  ),
  // colorScheme: ColorScheme.fromSwatch().copyWith(
  //   brightness: Brightness.dark,
  //   primary: ColorConst.winterPrimaryDark,
  //   secondary: ColorConst.winterAccentDark,
  //   background: ColorConst.winterBackgroundDark,
  // ),
 // primarySwatch: Colors.blue,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.winterBackgroundDark,
    backgroundColor: ColorConst.winterPrimaryDark,
  ),
);

///   Halloween Theme

final halloweenTheme = ThemeData(
  scaffoldBackgroundColor: ColorConst.halloweenBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.halloweenPrimaryLight,
  ),
  cardColor: ColorConst.halloweenBackgroundLight,
  dialogBackgroundColor: ColorConst.halloweenBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.halloweenBackgroundLight,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: ColorConst.halloweenPrimaryLight,
    secondary: ColorConst.halloweenAccentLight,
    background: ColorConst.halloweenBackgroundLight,
  ),
  primarySwatch: Colors.deepOrange,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.halloweenBackgroundDark,
    unselectedItemColor: ColorConst.halloweenBackgroundLight,
    backgroundColor: ColorConst.halloweenPrimaryLight,
  ),
);

final halloweenThemeDark = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.halloweenBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.halloweenPrimaryDark,
  ),
  cardColor: ColorConst.halloweenBackgroundDark,
  dialogBackgroundColor: ColorConst.halloweenBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.halloweenBackgroundDark,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.dark,
    primary: ColorConst.halloweenPrimaryDark,
    secondary: ColorConst.halloweenAccentDark,
    background: ColorConst.halloweenBackgroundDark,
  ),
  primarySwatch: Colors.deepOrange,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.halloweenBackgroundLight,
    unselectedItemColor: ColorConst.halloweenBackgroundDark,
    backgroundColor: ColorConst.halloweenPrimaryDark,
  ),
);

///   Christmas Theme

final christmasTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorConst.christmasPrimaryLight,
  scaffoldBackgroundColor: const Color.fromARGB(255, 219, 216, 216),
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.christmasPrimaryLight,
  ),
  cardColor: ColorConst.christmasBackgroundLight,
  dialogBackgroundColor: ColorConst.christmasBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.christmasBackgroundLight,
  ),
  // colorScheme: ColorScheme.fromSwatch().copyWith(
  //   brightness: Brightness.light,
  //   primary: ColorConst.christmasPrimaryLight,
  //   secondary: ColorConst.christmasAccentLight,
  //   background: ColorConst.christmasBackgroundLight,
  // ),
  //primarySwatch: Colors.red,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.christmasAccentLight,
    unselectedItemColor: ColorConst.christmasBackgroundLight,
    backgroundColor: ColorConst.christmasPrimaryLight,
  ),
);

final christmasThemeDark = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorConst.christmasPrimaryDark,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.christmasBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.christmasPrimaryDark,
  ),
  cardColor: ColorConst.christmasBackgroundDark,
  dialogBackgroundColor: ColorConst.christmasBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.christmasBackgroundDark,
  ),
  // colorScheme: ColorScheme.fromSwatch().copyWith(
  //   brightness: Brightness.dark,
  //   primary: ColorConst.christmasPrimaryDark,
  //   secondary: ColorConst.christmasAccentDark,
  //   background: ColorConst.christmasBackgroundDark,
  // ),
  //primarySwatch: Colors.red,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.christmasAccentDark,
    unselectedItemColor: ColorConst.christmasBackgroundDark,
    backgroundColor: ColorConst.christmasPrimaryDark,
  ),
);

///   Easter Theme

final easterTheme = ThemeData(
  //colorSchemeSeed: Colors.blue,
  scaffoldBackgroundColor: ColorConst.easterBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.easterPrimaryLight,
  ),
  cardColor: ColorConst.easterBackgroundLight,
  dialogBackgroundColor: ColorConst.easterBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.easterBackgroundLight,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: ColorConst.easterPrimaryLight,
    secondary: ColorConst.easterAccentLight,
    background: ColorConst.easterBackgroundLight,
  ),
  primarySwatch: Colors.lightBlue,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.easterAccentLight,
    unselectedItemColor: ColorConst.easterBackgroundLight,
    backgroundColor: ColorConst.easterPrimaryLight,
  ),
);

final easterThemeDark = ThemeData(
  // colorSchemeSeed: Colors.yellow,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.easterBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    color: ColorConst.easterPrimaryDark,
  ),
  cardColor: ColorConst.easterBackgroundDark,
  dialogBackgroundColor: ColorConst.easterBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.easterBackgroundDark,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.dark,
    primary: ColorConst.easterPrimaryDark,
    secondary: ColorConst.easterAccentDark,
    background: ColorConst.easterBackgroundDark,
  ),
  primarySwatch: Colors.lightBlue,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: ColorConst.easterAccentDark,
    unselectedItemColor: ColorConst.easterBackgroundDark,
    backgroundColor: ColorConst.easterPrimaryDark,
  ),
);
