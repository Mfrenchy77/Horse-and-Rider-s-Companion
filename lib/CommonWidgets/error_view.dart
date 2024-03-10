import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';

/// This is the ErrorPage widget
/// for the entire app

Widget errorView(BuildContext context) {
  return Stack(
    children: [
      const Logo(
        screenName: 'Error: Something went wrong',
        forceDark: true,
      ),
      Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Try Again'),
        ),
      ),
    ],
  );
}
