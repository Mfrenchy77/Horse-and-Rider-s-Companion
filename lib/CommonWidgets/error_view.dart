import 'package:flutter/material.dart';

/// This is the ErrorPage widget
/// for the entire app

Widget errorView(BuildContext context) {
  return Stack(
    children: [
      Image.asset('assets/error_color.png', fit: BoxFit.cover),
      Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Try Again'),
        ),
      ),
    ],
  );
}
