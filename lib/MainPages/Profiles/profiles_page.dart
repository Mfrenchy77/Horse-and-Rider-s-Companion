import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});
  static const name = 'Home';
  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return const LoadingPage();
  }
}
