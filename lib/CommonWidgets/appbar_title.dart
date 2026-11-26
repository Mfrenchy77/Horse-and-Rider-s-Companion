import 'package:flutter/material.dart';

/// {@template app_title}
/// AppTitle widget displays the Horse & Riders Companion wordmark.
/// {@endtemplate}
class AppTitle extends StatelessWidget {
  /// {@macro app_title}
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 8,
          child: Image(
            color: Colors.white,
            image: AssetImage('assets/horse_text.png'),
            height: 25,
          ),
        ),
      ],
    );
  }
}

/// Responsive app-bar branding widget that shows the full [AppTitle] wordmark
/// when sufficient horizontal space is available, and falls back to the compact
/// horse-shield logo when space is constrained.
class ResponsiveAppBarTitle extends StatelessWidget {
  const ResponsiveAppBarTitle({
    super.key,
    this.wordmarkMinWidth = 240,
    this.wordmarkKey,
    this.compactLogoKey,
  });

  final double wordmarkMinWidth;
  final Key? wordmarkKey;
  final Key? compactLogoKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Horse & Rider's Companion",
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showFullWordmark =
              !constraints.hasBoundedWidth ||
              constraints.maxWidth >= wordmarkMinWidth;
          if (showFullWordmark) {
            return AppTitle(key: wordmarkKey);
          }
          return Image(
            key: compactLogoKey,
            color: Colors.white,
            fit: BoxFit.contain,
            image: const AssetImage('assets/horse_logo.png'),
            height: 30,
          );
        },
      ),
    );
  }
}
