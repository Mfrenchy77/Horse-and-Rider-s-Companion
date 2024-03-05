import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';

class RiderBio extends StatelessWidget {
  const RiderBio({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.usersProfile != current.usersProfile ||
          previous.viewingProfile != current.viewingProfile,
      builder: (context, state) {
        final riderProfile = state.viewingProfile ?? state.usersProfile;
        return Visibility(
          visible: riderProfile?.bio != null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: MaxWidthBox(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              child: Text(
                riderProfile?.bio ?? '',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
