import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/App/View/app.dart';

/// {@template profile_back_button}
/// ProfileBackButton widget is a button that navigates back to the profle page
/// and clears the ViewingProfile and HorseProfile
/// {@endtemplate}
class ProfileBackButton extends StatelessWidget {
  /// {@macro profile_back_button}
  /// Displays the back button
  /// {@macro key}
  const ProfileBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    return IconButton(
      tooltip: cubit.state.isForRider
          ? 'Back to Rider Profile'
          : 'Back to Horse Profile',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        context.pop();
        cubit.profileBackButtonPressed();
      },
      // ..changeIndex(0),
    );
  }
}
