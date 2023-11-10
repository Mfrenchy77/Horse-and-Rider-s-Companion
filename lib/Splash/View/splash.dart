import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Logo(
      screenName: 'Welcome',
    );
  }
}
