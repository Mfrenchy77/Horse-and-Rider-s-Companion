import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:responsive_framework/responsive_framework.dart';

Widget profileItem({
  required String profileName,
  required String profilePicUrl,
  required BuildContext context,
  required GestureTapCallback onTap,
}) {
  double size;
  if (ResponsiveBreakpoints.of(context).equals(MOBILE)) {
    size = 40;
  } else if (ResponsiveBreakpoints.of(context).equals(TABLET)) {
    size = 50;
  } else if (ResponsiveBreakpoints.of(context).equals(DESKTOP)) {
    size = 70;
  } else if (ResponsiveBreakpoints.of(context).largerThan(DESKTOP)) {
    size = 80;
  } else {
    size = 50;
  }

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: MenuItemButton(
        onPressed: () => onTap(),
        child: Row(
          
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            profilePhoto(size: size, profilePicUrl: profilePicUrl),
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
