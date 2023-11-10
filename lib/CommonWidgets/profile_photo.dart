import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

Widget profilePhoto({
  required double size,
  required String? profilePicUrl,
}) {
  final isDark = SharedPrefs().isDarkMode;
  return profilePicUrl != null && profilePicUrl.isNotEmpty
      ? CircleAvatar(
        
          radius: size / 3,
          backgroundColor: Colors.grey,
          backgroundImage: NetworkImage(profilePicUrl),
        )
      : CircleAvatar(
          radius: size / 3,
          backgroundColor: Colors.transparent,
          backgroundImage: AssetImage(
            isDark
                ? 'assets/horse_icon_circle_dark.png'
                : 'assets/horse_icon_circle.png',
          ),
        );
}
