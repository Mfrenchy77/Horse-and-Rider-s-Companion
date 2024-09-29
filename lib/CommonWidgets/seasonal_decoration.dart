import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

/// This widget will show an image depending on the current season set
class SeasonalDecorationWidget extends StatelessWidget {
  const SeasonalDecorationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final seasonalImage = _getSeasonalImage();
    if (seasonalImage == null || seasonalImage.isEmpty) {
      return SizedBox
          .shrink(); // Returns an empty space if no image is available.
    } else {
      return Container(
        clipBehavior: Clip.antiAlias, // Clip the image to avoid overflow
        width: 50, // Set width of the container
        height: 50, // Set height of the container
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(seasonalImage),
          ),
        ),
      );
    }
  }
}

String? _getSeasonalImage() {
  // Get the current season from the Theme
  // and return the corresponding image for the season
  final currentSeason = getThemeSeason();
  switch (currentSeason) {
    case ThemeSeasons.spring:
      debugPrint('Setting Spring Image');
      return 'assets/spring.png';
    case ThemeSeasons.summer:
      debugPrint('Setting Summer Image');
      return 'assets/summer.png';
    case ThemeSeasons.autumn:
      debugPrint('Setting Autumn Image');
      return 'assets/fall.png';
    case ThemeSeasons.winter:
      debugPrint('Setting Winter Image');
      return 'assets/winter.png';
    case ThemeSeasons.easter:
      debugPrint('Setting Easter Image');
      return 'assets/easter.png';
    case ThemeSeasons.christmas:
      debugPrint('Setting Christmas Image');
      return 'assets/christmas.png';
    case ThemeSeasons.halloween:
      debugPrint('Setting Halloween Image');
      return 'assets/halloween.png';
    case ThemeSeasons.main:
      debugPrint('Setting Main Image: none');
      return null;
  }
}
