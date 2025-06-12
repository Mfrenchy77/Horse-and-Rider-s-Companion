import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile.dart';

class GuestProfilePage extends StatelessWidget {
  const GuestProfilePage({super.key});
  static const path = '/Guest';
  static const name = 'GuestProfilePage';

  @override
  Widget build(BuildContext context) {
    return
        //const NavigatorView(child:
        const GuestProfile();
  }
}
