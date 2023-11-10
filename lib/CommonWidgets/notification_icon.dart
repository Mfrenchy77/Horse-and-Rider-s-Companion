// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({
    super.key,
    this.onTap,
    this.text,
    required this.iconData,
    this.notificationCount = 0,
  });

  final IconData iconData;
  final String? text;
  final VoidCallback? onTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  iconData,
                  color: HorseAndRidersTheme()
                      .getTheme()
                      .appBarTheme
                      .iconTheme!
                      .color,
                ),
                Visibility(
                  visible: text != null,
                  child: Text(text ?? '', overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Visibility(
              visible: notificationCount > 0,
              child: Positioned(
                top: 6,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade300,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      //bold
                      fontWeight: FontWeight.bold, fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
