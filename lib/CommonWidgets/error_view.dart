import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';

/// This is the ErrorPage widget
/// for the entire app
class ErrorView extends StatelessWidget {
  const ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Logo(
            screenName: 'Error: Something went wrong',
          ),
          Center(
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ),
        ],
      ),
    );
  }
}
