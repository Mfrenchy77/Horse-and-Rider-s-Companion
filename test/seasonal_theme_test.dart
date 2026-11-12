import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

void main() {
  final seasons = {
    'spring': (springTheme, springThemeDark),
    'summer': (summerTheme, summerThemeDark),
    'autumn': (autumnTheme, autumnThemeDark),
    'winter': (winterTheme, winterThemeDark),
    'Halloween': (halloweenTheme, halloweenThemeDark),
    'Christmas': (christmasTheme, christmasThemeDark),
    'Easter': (easterTheme, easterThemeDark),
  };

  for (final MapEntry(key: season, value: (light, dark)) in seasons.entries) {
    test('$season has readable gradients in light and dark mode', () {
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      for (final theme in [light, dark]) {
        final gradients = theme.extension<SurfaceGradients>()!;
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
        expect(
          theme.extension<CardGradientTheme>()!.gradient,
          gradients.surface,
        );

        for (final gradient in [gradients.chrome!, gradients.rail]) {
          expect(gradient.colors.toSet(), hasLength(2));
          for (final color in gradient.colors) {
            expect(1.05 / (color.computeLuminance() + .05), greaterThan(4.5));
          }
        }

        final ink = theme.colorScheme.onSurface.computeLuminance();
        for (final gradient in [gradients.background, gradients.surface]) {
          expect(gradient.colors.toSet().length, greaterThan(1));
          for (final color in gradient.colors) {
            final fill = color.computeLuminance();
            final contrast = theme.brightness == Brightness.dark
                ? (ink + .05) / (fill + .05)
                : (fill + .05) / (ink + .05);
            expect(contrast, greaterThan(4.5));
          }
        }
      }
    });
  }
}
