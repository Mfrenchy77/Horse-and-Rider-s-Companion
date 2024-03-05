import 'package:flutter/material.dart';

/// {@template app_title}
/// AppTitle widget displays the Horse & Riders Companion 
/// {@endtemplate}
class AppTitle extends StatelessWidget {
  /// {@macro app_title}
  /// Displays Horse & Riders Companion 
  /// {@macro key}
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 8,
          child: Image(
            color: Colors.white,
            image: AssetImage(
              'assets/horse_text.png',
            ),
            height: 25,
          ),
        ),
      ],
    );
  }
}
