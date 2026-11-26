import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

//Widget that show the Horse and Riders Logo and the current page
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    required this.screenName,
    this.forceDark,
  });
  final String screenName;
  final bool? forceDark;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalWidth = isSmallScreen ? 350.0 : 500.0;
    final cachePx = (logicalWidth * dpr).round().clamp(350, 1200);
    final isDark = SharedPrefs().isDarkMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          forceDark != null
              ? 'assets/horse_logo_and_text_dark.png'
              : isDark
                  ? 'assets/horse_logo_and_text_dark.png'
                  : 'assets/horse_logo_and_text_light.png',
          width: logicalWidth,
          cacheWidth: cachePx,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            screenName,
            textAlign: TextAlign.center,
            style: isSmallScreen
                ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: forceDark != null
                          ? Colors.white
                          : isDark
                              ? Colors.white
                              : Colors.black,
                    )
                : Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: forceDark != null
                          ? Colors.white
                          : isDark
                              ? Colors.white
                              : Colors.black,
                    ),
          ),
        ),
      ],
    );
  }
}
