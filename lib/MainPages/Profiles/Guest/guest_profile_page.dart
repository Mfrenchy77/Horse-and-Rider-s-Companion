import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile_view.dart';

class GuestProfilePage extends StatelessWidget {
  const GuestProfilePage({super.key});
  static const path = '/Guest';
  static const name = 'GuestProfilePage';

  @override
  Widget build(BuildContext context) {
    return const NavigatorView(child: GuestProfileView());
  }
}
