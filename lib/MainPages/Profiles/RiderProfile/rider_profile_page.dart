import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_view.dart';

class RiderProfilePage extends StatelessWidget {
  const RiderProfilePage({super.key, required this.id});
  static const name = 'RiderProfilePage';
  static const path = '/RiderProfile/:id';

  final String id;

  @override
  Widget build(BuildContext context) {
    return const NavigatorView(
      child: RiderProfileView(
        key: Key('RiderProfileView'),
      ),
    );
  }
}
