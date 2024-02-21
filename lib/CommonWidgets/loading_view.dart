import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';

Widget loadingView() {
  // ignore: lines_longer_than_80_chars
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo(screenName: 'Loading...'),
        CircularProgressIndicator(),
      ],
    ),
  );
}
