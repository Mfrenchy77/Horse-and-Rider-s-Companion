import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/classic_blue_gray.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
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
  ThemeData getLightTheme() => _theme(isDark: false);
  ThemeData getDarkTheme() => _theme(isDark: true);

  static final _gradientThemes = Expando<ThemeData>();
  static final _cachedThemes = <(ThemeSeasons, bool), ThemeData>{};

  ThemeData _withCardGradient(ThemeData theme) {
    if (theme.extension<CardGradientTheme>() != null) return theme;
    return _gradientThemes[theme] ??= theme.copyWith(
      extensions: [
        ...theme.extensions.values,
        CardGradientTheme.fromTheme(theme),
      ],
    );
  }

  ThemeData _theme({required bool isDark}) {
    final season = SharedPrefs().isSeasonalMode()
        ? getThemeSeason()
        : ThemeSeasons.main;
    return _cachedThemes[(season, isDark)] ??= _withCardGradient(
      switch (season) {
        ThemeSeasons.main => isDark ? mainThemeDark : mainThemeLight,
        ThemeSeasons.halloween => isDark ? halloweenThemeDark : halloweenTheme,
        ThemeSeasons.christmas => isDark ? christmasThemeDark : christmasTheme,
        ThemeSeasons.easter => isDark ? easterThemeDark : easterTheme,
        ThemeSeasons.spring => isDark ? springThemeDark : springTheme,
        ThemeSeasons.summer => isDark ? summerThemeDark : summerTheme,
        ThemeSeasons.autumn => isDark ? autumnThemeDark : autumnTheme,
        ThemeSeasons.winter => isDark ? winterThemeDark : winterTheme,
      },
    );
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
  colorScheme: ColorScheme.fromSeed(seedColor: ClassicBlueGray.coral).copyWith(
    primary: ClassicBlueGray.coral,
    onPrimary: Colors.white,
    primaryContainer: ClassicBlueGray.selected,
    onPrimaryContainer: ClassicBlueGray.selectedInk,
    secondary: ClassicBlueGray.goldInk,
    onSecondary: Colors.white,
    secondaryContainer: ClassicBlueGray.gold,
    onSecondaryContainer: ClassicBlueGray.goldInk,
    surface: ClassicBlueGray.surface,
    surfaceDim: ClassicBlueGray.surfaceHighest,
    surfaceBright: ClassicBlueGray.surface,
    surfaceContainerLowest: ClassicBlueGray.surface,
    surfaceContainerLow: ClassicBlueGray.surfaceLow,
    surfaceContainer: ClassicBlueGray.canvas,
    surfaceContainerHigh: ClassicBlueGray.surfaceHigh,
    surfaceContainerHighest: ClassicBlueGray.surfaceHighest,
    onSurface: ClassicBlueGray.ink,
    onSurfaceVariant: ClassicBlueGray.muted,
    outline: ClassicBlueGray.muted,
    outlineVariant: ClassicBlueGray.outline,
  ),
  primaryColor: ClassicBlueGray.chromeStart,
  extensions: const [
    CardGradientTheme(gradient: ClassicBlueGray.card),
    SurfaceGradients(
      background: ClassicBlueGray.background,
      chrome: ClassicBlueGray.appBar,
      rail: ClassicBlueGray.rail,
      surface: ClassicBlueGray.card,
    ),
  ],
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ClassicBlueGray.chromeStart,
    indicatorColor: ClassicBlueGray.selected,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? ClassicBlueGray.selectedInk
            : Colors.white,
      ),
    ),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(color: Colors.white),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: ClassicBlueGray.chromeStart,
    selectedItemColor: ClassicBlueGray.selected,
    unselectedItemColor: Colors.white,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: ClassicBlueGray.chromeStart,
    indicatorColor: ClassicBlueGray.selected,
    unselectedIconTheme: IconThemeData(color: Colors.white),
    selectedLabelTextStyle: TextStyle(color: Colors.white),
    unselectedLabelTextStyle: TextStyle(color: Colors.white),
    selectedIconTheme: IconThemeData(
      color: ClassicBlueGray.selectedInk,
      size: 30,
    ),
  ),
  scaffoldBackgroundColor: Colors.transparent,
  appBarTheme: const AppBarTheme(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(color: Colors.white),
    backgroundColor: ClassicBlueGray.chromeStart,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: ClassicBlueGray.surface,
    selectedColor: ClassicBlueGray.selected,
    side: const BorderSide(color: ClassicBlueGray.outline),
    checkmarkColor: ClassicBlueGray.selectedInk,
    labelStyle: TextStyle(
      color: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? ClassicBlueGray.muted
            : states.contains(WidgetState.selected)
            ? ClassicBlueGray.selectedInk
            : ClassicBlueGray.ink,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: ClassicBlueGray.coral,
    foregroundColor: Colors.white,
  ),
  cardColor: ClassicBlueGray.surface,
  cardTheme: const CardThemeData(color: ClassicBlueGray.surface),
  dialogTheme: const DialogThemeData(backgroundColor: ClassicBlueGray.surface),
  drawerTheme: const DrawerThemeData(backgroundColor: ClassicBlueGray.surface),
);

final mainThemeDark = ThemeData(
  brightness: Brightness.dark,
  extensions: const [
    SurfaceGradients(
      background: OceanCoralGradients.background,
      rail: OceanCoralGradients.rail,
      surface: OceanCoralGradients.surface,
    ),
  ],
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
        error: ColorConst.errorDarkBlueGrey,
        onError: Colors.white,
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
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: ColorConst.mainPrimaryDark,
    selectedItemColor: ColorConst.mainAccentDark,
    unselectedItemColor: ColorConst.darkMuted,
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
  drawerTheme: const DrawerThemeData(backgroundColor: AppTokens.midnightMid),
  dialogTheme: DialogThemeData(
    backgroundColor: AppTokens.midnightMid,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      side: const BorderSide(color: AppTokens.cardBorderDark),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppTokens.midnightMid,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusXl),
      ),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: AppTokens.midnightCardTop,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      side: const BorderSide(color: AppTokens.cardBorderDark),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppTokens.midnightCardTop,
    contentTextStyle: const TextStyle(color: AppTokens.primaryTextDark),
    actionTextColor: AppTokens.coralAccent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      side: const BorderSide(color: AppTokens.cardBorderDark),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppTokens.midnightInputFill,
    labelStyle: const TextStyle(color: AppTokens.secondaryTextDark),
    hintStyle: TextStyle(
      color: AppTokens.secondaryTextDark.withValues(alpha: 0.7),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      borderSide: const BorderSide(color: AppTokens.cardBorderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      borderSide: const BorderSide(color: AppTokens.cardBorderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      borderSide: const BorderSide(color: AppTokens.coralAccent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      borderSide: const BorderSide(color: ColorConst.errorDarkBlueGrey),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTokens.primaryTextDark,
      side: const BorderSide(color: AppTokens.midnightButtonBorder),
      minimumSize: const Size(
        AppTokens.minTouchTarget,
        AppTokens.minTouchTarget,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppTokens.coralAccent,
      minimumSize: const Size(
        AppTokens.minTouchTarget,
        AppTokens.minTouchTarget,
      ),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    indicatorColor: AppTokens.coralAccent,
    labelColor: AppTokens.primaryTextDark,
    unselectedLabelColor: AppTokens.secondaryTextDark,
  ),
  dividerTheme: const DividerThemeData(
    color: AppTokens.cardBorderDark,
    thickness: 1,
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppTokens.coralAccent
          : Colors.transparent,
    ),
    checkColor: WidgetStateProperty.all(AppTokens.coralText),
    side: const BorderSide(color: AppTokens.midnightButtonBorder, width: 1.5),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppTokens.coralAccent
          : AppTokens.secondaryTextDark,
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppTokens.coralText
          : AppTokens.secondaryTextDark,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppTokens.coralAccent
          : AppTokens.midnightCardTop,
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppTokens.coralAccent,
    thumbColor: AppTokens.coralAccent,
    inactiveTrackColor: AppTokens.cardBorderDark,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppTokens.coralAccent,
    linearTrackColor: AppTokens.cardBorderDark,
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: AppTokens.midnightCardTop,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      border: Border.all(color: AppTokens.cardBorderDark),
    ),
    textStyle: const TextStyle(color: AppTokens.primaryTextDark),
  ),
);

final springTheme = _seasonalTheme(
  primary: ColorConst.springPrimaryLight,
  accent: ColorConst.springAccentLight,
  base: ColorConst.springBackgroundLight,
);

final springThemeDark = _seasonalTheme(
  primary: ColorConst.springPrimaryDark,
  accent: ColorConst.springAccentDark,
  base: ColorConst.springBackgroundDark,
  brightness: Brightness.dark,
);

final summerTheme = _seasonalTheme(
  primary: ColorConst.summerPrimaryLight,
  accent: ColorConst.summerAccentLight,
  base: ColorConst.summerBackgroundLight,
);

final summerThemeDark = _seasonalTheme(
  primary: ColorConst.summerPrimaryDark,
  accent: ColorConst.summerAccentDark,
  base: ColorConst.summerBackgroundDark,
  brightness: Brightness.dark,
);

final autumnTheme = _seasonalTheme(
  primary: ColorConst.fallPrimaryLight,
  accent: ColorConst.fallAccentLight,
  base: ColorConst.fallBackgroundLight,
);

final autumnThemeDark = _seasonalTheme(
  primary: ColorConst.fallPrimaryDark,
  accent: ColorConst.fallAccentDark,
  base: ColorConst.fallBackgroundDark,
  brightness: Brightness.dark,
);

final winterTheme = _seasonalTheme(
  primary: ColorConst.winterPrimaryLight,
  accent: ColorConst.winterAccentLight,
  base: ColorConst.winterBackgroundLight,
);

final winterThemeDark = _seasonalTheme(
  primary: ColorConst.winterPrimaryDark,
  accent: ColorConst.winterAccentDark,
  base: ColorConst.winterBackgroundDark,
  brightness: Brightness.dark,
);

final halloweenTheme = _seasonalTheme(
  primary: ColorConst.halloweenPrimaryLight,
  accent: ColorConst.halloweenAccentLight,
  base: ColorConst.halloweenBackgroundLight,
);

final halloweenThemeDark = _seasonalTheme(
  primary: ColorConst.halloweenPrimaryDark,
  accent: ColorConst.halloweenAccentDark,
  base: ColorConst.halloweenBackgroundDark,
  brightness: Brightness.dark,
);

final christmasTheme = _seasonalTheme(
  primary: ColorConst.christmasPrimaryLight,
  accent: ColorConst.christmasAccentLight,
  base: ColorConst.christmasBackgroundLight,
);

final christmasThemeDark = _seasonalTheme(
  primary: ColorConst.christmasPrimaryDark,
  accent: ColorConst.christmasAccentDark,
  base: ColorConst.christmasBackgroundDark,
  brightness: Brightness.dark,
);

final easterTheme = _seasonalTheme(
  primary: ColorConst.easterPrimaryLight,
  accent: ColorConst.easterAccentLight,
  base: ColorConst.easterBackgroundLight,
);

final easterThemeDark = _seasonalTheme(
  primary: ColorConst.easterPrimaryDark,
  accent: ColorConst.easterAccentDark,
  base: ColorConst.easterBackgroundDark,
  brightness: Brightness.dark,
);

ThemeData _seasonalTheme({
  required Color primary,
  required Color accent,
  required Color base,
  Brightness brightness = Brightness.light,
}) {
  final isDark = brightness == Brightness.dark;
  Color tint(Color color, double amount) =>
      Color.alphaBlend(primary.withValues(alpha: amount), color);

  final chromeBase = Color.lerp(primary, const Color(0xFF16242D), .38)!;
  final chrome = chromeBase.computeLuminance() <= .18
      ? chromeBase
      : Color.lerp(chromeBase, Colors.black, .25)!;
  final chromeEnd = Color.lerp(chrome, Colors.black, .23)!;
  final surface = tint(base, isDark ? .18 : .08);
  final canvas = tint(base, isDark ? .12 : .15);
  final shade = tint(base, isDark ? .25 : .27);
  final card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, tint(base, isDark ? .28 : .19)],
  );
  final gradients = SurfaceGradients(
    background: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [canvas, shade, tint(base, isDark ? .07 : .32)],
      stops: const [0, .56, 1],
    ),
    chrome: LinearGradient(colors: [chrome, chromeEnd]),
    rail: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [chrome, chromeEnd],
    ),
    surface: card,
  );

  final seed = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
  final accentScheme = ColorScheme.fromSeed(
    seedColor: Color.alphaBlend(accent, primary),
    brightness: brightness,
  );
  final selected = Color.lerp(Colors.white, accent, .32)!;
  const selectedInk = Color(0xFF16242D);
  final ink = isDark ? const Color(0xFFF4F2F0) : selectedInk;
  final muted = isDark ? const Color(0xFFCCC8C4) : const Color(0xFF3C464B);
  final outline = Color.lerp(surface, ink, .3)!;

  return ThemeData(
    colorScheme: seed.copyWith(
      primaryContainer: selected,
      onPrimaryContainer: selectedInk,
      secondary: accentScheme.primary,
      onSecondary: accentScheme.onPrimary,
      secondaryContainer: accentScheme.primaryContainer,
      onSecondaryContainer: accentScheme.onPrimaryContainer,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceDim: shade,
      surfaceBright: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: tint(base, isDark ? .20 : .11),
      surfaceContainer: canvas,
      surfaceContainerHigh: tint(base, isDark ? .23 : .21),
      surfaceContainerHighest: shade,
      outline: muted,
      outlineVariant: outline,
    ),
    extensions: [
      gradients,
      CardGradientTheme(gradient: card),
    ],
    primaryColor: chrome,
    scaffoldBackgroundColor: Colors.transparent,
    cardColor: surface,
    cardTheme: CardThemeData(color: surface),
    dialogTheme: DialogThemeData(backgroundColor: surface),
    drawerTheme: DrawerThemeData(backgroundColor: surface),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: surface,
      indicatorColor: selected,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: chrome,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: chrome,
      indicatorColor: selected,
      selectedIconTheme: const IconThemeData(color: selectedInk, size: 30),
      unselectedIconTheme: const IconThemeData(color: Colors.white),
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: chrome,
      selectedItemColor: selected,
      unselectedItemColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: chrome,
      indicatorColor: selected,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? selectedInk
              : Colors.white,
        ),
      ),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(color: Colors.white),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: selected,
      side: BorderSide(color: outline),
      checkmarkColor: selectedInk,
      labelStyle: TextStyle(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? selectedInk : ink,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: seed.primary,
      foregroundColor: seed.onPrimary,
    ),
  );
}
