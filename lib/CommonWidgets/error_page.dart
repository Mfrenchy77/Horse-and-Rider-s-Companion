import 'package:flutter/material.dart';

/// This is the ErrorPage widget
/// for the entire app
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset('assets/error_color.png', fit: BoxFit.cover),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}
