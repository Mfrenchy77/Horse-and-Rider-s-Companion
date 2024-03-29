import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

Widget profileItem({
  required String profileName,
  required String profilePicUrl,
  required BuildContext context,
  required GestureTapCallback onTap,
}) {
  // double size;
  // if (ResponsiveBreakpoints.of(context).equals(MOBILE)) {
  //   size = 40;
  // } else if (ResponsiveBreakpoints.of(context).equals(TABLET)) {
  //   size = 50;
  // } else if (ResponsiveBreakpoints.of(context).equals(DESKTOP)) {
  //   size = 70;
  // } else if (ResponsiveBreakpoints.of(context).largerThan(DESKTOP)) {
  //   size = 80;
  // } else {
  //   size = 50;
  // }

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: MenuItemButton(
        onPressed: () => onTap(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfilePhoto(
              size: 60,
              profilePicUrl: profilePicUrl,
            ),
            smallGap(),
            Text(
              profileName,
              style: TextStyle(
                color: SharedPrefs().isDarkMode ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
