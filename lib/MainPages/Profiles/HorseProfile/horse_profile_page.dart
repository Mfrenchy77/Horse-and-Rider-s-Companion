import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_view.dart';

class HorseProfilePage extends StatelessWidget {
  const HorseProfilePage({super.key, required this.horseId});

  static const path = 'Horse_Profile/:horseId';
  static const name = 'HorseProfilePage';

  final String horseId;

  @override
  Widget build(BuildContext context) {
    return const NavigatorView(
      child: HorseProfileView(
        key: Key('horseProfileView'),
      ),
    );
  }
}
