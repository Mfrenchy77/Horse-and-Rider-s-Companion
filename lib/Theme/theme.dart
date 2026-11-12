import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

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
  ThemeData getLightTheme() => _withCardGradient(_lightTheme());
  ThemeData getDarkTheme() => _withCardGradient(_darkTheme());

  static final _gradientThemes = Expando<ThemeData>();

  ThemeData _withCardGradient(ThemeData theme) =>
      _gradientThemes[theme] ??= theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          CardGradientTheme.fromTheme(theme),
        ],
      );

  ThemeData _lightTheme() {
    // Use cached season (computed once per day) to avoid repeatedly
    // computing the season on every rebuild.
    final themeSeasons = getThemeSeason();

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

  ThemeData _darkTheme() {
    // Use cached season (computed once per day) to avoid repeatedly
    // computing the season on every rebuild.
    final themeSeasons = getThemeSeason();
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

  /// returns true if the theme is dark
  bool isDarkTheme() {
    return SharedPrefs().isDarkMode;
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
    } else if (month == 12) {
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

/// pulic facing method to get the current theme season
ThemeSeasons getThemeSeason() {
  // Cache season per day so frequent rebuilds don't repeatedly compute the
  // season or generate logging. This function is intentionally cheap and
  // returns the cached value for any calls during the same day.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Use top-level cache variables.
  if (_cachedSeasonDate != null && _cachedSeason != null) {
    if (_cachedSeasonDate == today) {
      return _cachedSeason!;
    }
  }
  final season = HorseAndRidersTheme._getSeason(now.month, now.day);
  _cachedSeason = season;
  _cachedSeasonDate = today;
  return season;
}

// Top-level cache for the computed season (cleared when day changes).
DateTime? _cachedSeasonDate;
ThemeSeasons? _cachedSeason;

///   Main Theme

final mainThemeLight = ThemeData(
  colorSchemeSeed: Colors.blueGrey,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConst.mainPrimaryLight,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: ColorConst.mainPrimaryLight,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey,
  ),
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: ColorConst.mainPrimaryLight,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
  ),
  scaffoldBackgroundColor: const Color.fromARGB(255, 224, 228, 226),
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.mainPrimaryLight,
  ),
  cardColor: const Color.fromARGB(255, 186, 200, 197),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.mainBackgroundLight,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.mainBackgroundLight,
  ),
);

final mainThemeDark = ThemeData(
  brightness: Brightness.dark,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: ColorConst.mainAccentDark,
        brightness: Brightness.dark,
      ).copyWith(
        primary: ColorConst.mainAccentDark,
        onPrimary: ColorConst.mainPrimaryDark,
        secondary: ColorConst.mainHighlightDark,
        onSecondary: ColorConst.mainPrimaryDark,
        surface: ColorConst.mainBackgroundDark,
        onSurface: ColorConst.darkForeground,
        outline: ColorConst.dividerDarkBlueGrey,
        outlineVariant: ColorConst.dividerDarkBlueGrey,
        secondaryContainer: ColorConst.cardDarkBlueGrey,
        onSecondaryContainer: ColorConst.darkForeground,
      ),
  primaryColor: ColorConst.mainPrimaryDark,
  chipTheme: ChipThemeData(
    color: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return ColorConst.mainPrimaryDark;
      }
      return states.contains(WidgetState.selected)
          ? ColorConst.dividerDarkBlueGrey
          : ColorConst.cardDarkBlueGrey;
    }),
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color:
            states.contains(WidgetState.selected) &&
                !states.contains(WidgetState.disabled)
            ? ColorConst.mainAccentDark
            : ColorConst.dividerDarkBlueGrey,
      ),
    ),
    labelStyle: TextStyle(
      color: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? ColorConst.darkMuted
            : ColorConst.darkForeground,
      ),
    ),
    checkmarkColor: ColorConst.mainAccentDark,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? ColorConst.mainPrimaryDark
            : null,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? ColorConst.darkMuted.withValues(alpha: .65)
            : null,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: ColorConst.mainAccentDark,
    foregroundColor: ColorConst.mainPrimaryDark,
  ),
  scaffoldBackgroundColor: Colors.transparent,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConst.mainPrimaryDark,
    indicatorColor: ColorConst.mainAccentDark,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return IconThemeData(
        color: isSelected
            ? ColorConst.mainPrimaryDark
            : ColorConst.darkForeground,
      );
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      return TextStyle(
        color: states.contains(WidgetState.selected)
            ? ColorConst.darkForeground
            : ColorConst.darkMuted,
      );
    }),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: ColorConst.mainPrimaryDark,
    indicatorColor: ColorConst.mainAccentDark,
    unselectedIconTheme: IconThemeData(color: ColorConst.darkMuted),
    selectedLabelTextStyle: TextStyle(color: ColorConst.darkForeground),
    unselectedLabelTextStyle: TextStyle(color: ColorConst.darkMuted),
    selectedIconTheme: IconThemeData(
      color: ColorConst.mainPrimaryDark,
      size: 30,
    ),
  ),
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: ColorConst.darkForeground, fontSize: 20),
    iconTheme: IconThemeData(color: ColorConst.darkForeground),
    toolbarTextStyle: TextStyle(color: ColorConst.darkForeground),
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  cardColor: ColorConst.cardDark,
  cardTheme: const CardThemeData(color: ColorConst.cardDark),
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.mainBackgroundDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.mainBackgroundDark,
  ),
);

///     Spring Theme

final springTheme = ThemeData(
  colorSchemeSeed: ColorConst.springPrimaryLight,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.springAccentLight,
    backgroundColor: ColorConst.springPrimaryLight,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
  ),
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.springAccentLight,
    backgroundColor: ColorConst.springPrimaryLight,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
  ),
  scaffoldBackgroundColor: ColorConst.springBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.springPrimaryLight,
  ),
  cardColor: ColorConst.springBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.springBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.springBackgroundLight,
  ),
);

final springThemeDark = ThemeData(
  colorSchemeSeed: ColorConst.springPrimaryDark,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.springAccentDark,
    backgroundColor: ColorConst.springPrimaryDark,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
  ),
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.springAccentDark,
    backgroundColor: ColorConst.springPrimaryDark,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.springBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.springPrimaryDark,
  ),
  cardColor: ColorConst.springBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.springBackgroundDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.springBackgroundDark,
  ),
);

///   Summer Theme

final summerTheme = ThemeData(
  colorSchemeSeed: ColorConst.summerPrimaryLight,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConst.summerPrimaryLight,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    indicatorColor: ColorConst.summerAccentLight,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    indicatorColor: ColorConst.summerAccentLight,
    backgroundColor: ColorConst.summerPrimaryLight,
    unselectedIconTheme: IconThemeData(color: Colors.white),
    selectedLabelTextStyle: TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.white),
    selectedIconTheme: IconThemeData(color: Colors.white, size: 30),
  ),
  scaffoldBackgroundColor: ColorConst.summerBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.summerPrimaryLight,
  ),
  cardColor: ColorConst.summerBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.summerBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.summerBackgroundLight,
  ),
);

final summerThemeDark = ThemeData(
  brightness: Brightness.dark,
  colorSchemeSeed: ColorConst.summerPrimaryDark,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConst.summerPrimaryDark,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
  ),
  navigationRailTheme: const NavigationRailThemeData(),
  scaffoldBackgroundColor: ColorConst.summerBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.summerPrimaryDark,
  ),
  cardColor: ColorConst.summerBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.summerBackgroundDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.summerBackgroundDark,
  ),
);

///   Autumn Theme
final autumnTheme = ThemeData(
  colorSchemeSeed: ColorConst.fallPrimaryLight,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConst.fallPrimaryLight,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    indicatorColor: ColorConst.fallAccentLight,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    indicatorColor: ColorConst.fallAccentLight,
    backgroundColor: ColorConst.fallPrimaryLight,
    unselectedIconTheme: IconThemeData(color: Colors.white),
    selectedLabelTextStyle: TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.white),
    selectedIconTheme: IconThemeData(color: Colors.white, size: 30),
  ),
  scaffoldBackgroundColor: ColorConst.fallBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.fallPrimaryLight,
  ),
  cardColor: ColorConst.fallBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.fallBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.fallBackgroundLight,
  ),
);

final autumnThemeDark = ThemeData(
  colorSchemeSeed: ColorConst.fallPrimaryDark,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.fallBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.fallPrimaryLight,
  ),
  cardColor: ColorConst.fallPrimaryDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.fallPrimaryDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.fallPrimaryDark,
  ),
);

///   Winter Theme
final winterTheme = ThemeData(
  colorSchemeSeed: ColorConst.winterPrimaryDark,
  scaffoldBackgroundColor: ColorConst.winterBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.winterPrimaryLight,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: ColorConst.winterPrimaryLight,
    selectedIconTheme: IconThemeData(color: Colors.white),
    unselectedIconTheme: IconThemeData(color: Colors.white),
    selectedLabelTextStyle: TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.white),
  ),
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.cardDark,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.winterPrimaryLight,
  ),
  cardColor: ColorConst.winterPrimaryLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.winterBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.winterBackgroundLight,
  ),
);

final winterThemeDark = ThemeData(
  brightness: Brightness.dark,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConst.winterPrimaryDark,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
  ),
  navigationRailTheme: const NavigationRailThemeData(),
  colorSchemeSeed: ColorConst.winterPrimaryLight,
  scaffoldBackgroundColor: ColorConst.winterBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.winterPrimaryDark,
  ),
  cardColor: ColorConst.winterBackgroundDark,
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.winterBackgroundDark,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.winterBackgroundDark,
  ),
);

///   Halloween Theme

final halloweenTheme = ThemeData(
  colorSchemeSeed: ColorConst.halloweenPrimaryLight,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.halloweenAccentLight,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.halloweenPrimaryLight,
  ),
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.halloweenAccentLight,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
    backgroundColor: ColorConst.halloweenPrimaryLight,
  ),
  scaffoldBackgroundColor: ColorConst.halloweenBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.halloweenPrimaryLight,
  ),
  cardColor: ColorConst.halloweenBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.halloweenBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.halloweenBackgroundLight,
  ),
);

final halloweenThemeDark = ThemeData(
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.halloweenAccentDark,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.halloweenPrimaryDark,
  ),
  colorSchemeSeed: ColorConst.halloweenPrimaryDark,
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.halloweenAccentDark,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
    backgroundColor: ColorConst.halloweenPrimaryDark,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.halloweenBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.halloweenPrimaryDark,
  ),
  cardColor: ColorConst.halloweenBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.halloweenBackgroundDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.halloweenBackgroundDark,
  ),
);

///   Christmas Theme

final christmasTheme = ThemeData(
  colorSchemeSeed: ColorConst.christmasPrimaryLight,
  scaffoldBackgroundColor: const Color.fromARGB(255, 219, 216, 216),
  navigationDrawerTheme: const NavigationDrawerThemeData(
    backgroundColor: ColorConst.christmasBackgroundLight,
  ),
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.christmasAccentLight,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.christmasPrimaryLight,
  ),
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.christmasAccentLight,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
    backgroundColor: ColorConst.christmasPrimaryLight,
  ),
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.christmasPrimaryLight,
  ),
  cardColor: ColorConst.christmasBackgroundLight,
  secondaryHeaderColor: ColorConst.christmasPrimaryLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.christmasBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.christmasBackgroundLight,
  ),
);

final christmasThemeDark = ThemeData(
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.christmasAccentDark,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.christmasPrimaryDark,
  ),
  colorSchemeSeed: ColorConst.christmasPrimaryDark,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.christmasBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.christmasPrimaryDark,
  ),
  cardColor: ColorConst.christmasBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.christmasBackgroundDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.christmasBackgroundDark,
  ),
);

///   Easter Theme

final easterTheme = ThemeData(
  colorSchemeSeed: Colors.blue,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.easterAccentLight,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.easterPrimaryLight,
  ),
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.easterAccentLight,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
    backgroundColor: ColorConst.easterPrimaryLight,
  ),
  scaffoldBackgroundColor: ColorConst.easterBackgroundLight,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.easterPrimaryLight,
  ),
  cardColor: ColorConst.easterBackgroundLight,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.easterBackgroundLight,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.easterBackgroundLight,
  ),
);

final easterThemeDark = ThemeData(
  colorSchemeSeed: Colors.yellow,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ColorConst.easterAccentDark,
    iconTheme: WidgetStateProperty.all(
      const IconThemeData(color: Colors.white),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
    backgroundColor: ColorConst.easterPrimaryDark,
  ),
  navigationRailTheme: NavigationRailThemeData(
    indicatorColor: ColorConst.easterAccentDark,
    unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
    selectedLabelTextStyle: const TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
    backgroundColor: ColorConst.easterPrimaryDark,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ColorConst.easterBackgroundDark,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ColorConst.easterPrimaryDark,
  ),
  cardColor: ColorConst.easterBackgroundDark,
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorConst.easterBackgroundDark,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: ColorConst.easterBackgroundDark,
  ),
);
