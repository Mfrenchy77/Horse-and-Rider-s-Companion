import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.size,
    this.profilePicUrl,
  });

  final double size;
  final String? profilePicUrl;
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
    return profilePicUrl != null && profilePicUrl!.isNotEmpty
        ? InkWell(
            onTap: () => showDialog<AlertDialog>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Image.network(profilePicUrl!),
                );
              },
            ),
            child: CircleAvatar(
              radius: size / 3,
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(profilePicUrl!),
            ),
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
}
