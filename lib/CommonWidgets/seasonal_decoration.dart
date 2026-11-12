import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

/// Shows the active seasonal theme alongside its festive icon.
class SeasonalDecorationWidget extends StatelessWidget {
  const SeasonalDecorationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final (label, asset) = switch (getThemeSeason()) {
      ThemeSeasons.spring => ('Spring', 'assets/spring.png'),
      ThemeSeasons.summer => ('Summer', 'assets/summer.png'),
      ThemeSeasons.autumn => ('Autumn', 'assets/fall.png'),
      ThemeSeasons.winter => ('Winter', 'assets/winter.png'),
      ThemeSeasons.easter => ('Easter', 'assets/easter.png'),
      ThemeSeasons.christmas => ('Christmas', 'assets/christmas.png'),
      ThemeSeasons.halloween => ('Halloween', 'assets/halloween.png'),
      ThemeSeasons.main => (null, null),
    };
    if (label == null || asset == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(asset, width: 24, height: 24, excludeFromSemantics: true),
        const SizedBox(width: 4),
        Text(
          label,
          semanticsLabel: '$label theme',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
