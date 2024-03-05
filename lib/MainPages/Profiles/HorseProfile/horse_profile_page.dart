import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_view.dart';

class HorseProfilePage extends StatelessWidget {
  const HorseProfilePage({super.key});
  static const routeName = '/horseProfile';
  static Page<void> page() =>
      const MaterialPage<void>(child: HorseProfilePage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HorseProfilePage());
  }

  @override
  Widget build(BuildContext context) {
    return const NavigatorView(
      body: HorseProfileView(
        key: Key('horseProfileView'),
      ),
    );
  }
}

/// Arguments holder class for [HorseProfilePage].
class HorseProfilePageArguments {
  HorseProfilePageArguments({required this.horseId});
  final String? horseId;
}
