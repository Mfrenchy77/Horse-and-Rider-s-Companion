import 'package:flutter/material.dart';

/// Widget showing the Theme Text for Horse & Rider's Companion
Widget appBarTitle() {
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
