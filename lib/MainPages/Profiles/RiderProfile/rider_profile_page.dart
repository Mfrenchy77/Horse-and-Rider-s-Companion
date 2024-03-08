import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_view.dart';

class RiderProfilePage extends StatelessWidget {
  const RiderProfilePage({super.key});
  static const routeName = '/riderProfile';
  // static Page<void> page() =>
  //     const MaterialPage<void>(child: RiderProfilePage());
  // static Route<void> route() {
  //   return MaterialPageRoute<void>(builder: (_) => const RiderProfilePage());
  // }

  @override
  Widget build(BuildContext context) {
    return const NavigatorView(
      body: RiderProfileView(
        key: Key('RiderProfileView'),
      ),
    );
  }
}
