import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_name.dart';

/// {@template horse_profile_name}
/// HorseProfileName widget displays the name of the horse
/// {@endtemplate}
class HorseProfileName extends StatelessWidget {
  /// {@macro horse_profile_name}
  /// Displays the name of the horse on a background that matches the theme
  /// {@macro key}
  const HorseProfileName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return ProfileName(
          name: state.horseProfile?.name ?? 'Profile',
          profilePicUrl: state.horseProfile?.picUrl,
          key: const Key('horseName'),
        );
      },
    );
  }
}
