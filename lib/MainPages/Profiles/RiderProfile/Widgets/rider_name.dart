import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_name.dart';

/// {@template rider_name}
/// RiderName widget displays the name of the rider
/// {@endtemplate}
class RiderProfileName extends StatelessWidget {
  /// {@macro rider_name}
  /// Displays the name of the rider on a background that matches the theme
  /// {@macro key}
  const RiderProfileName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return ProfileName(
          name: state.viewingProfile?.name ?? state.usersProfile?.name,
          profilePicUrl:
              state.viewingProfile?.picUrl ?? state.usersProfile?.picUrl,
          key: const Key('riderName'),
        );
      },
    );
  }
}
