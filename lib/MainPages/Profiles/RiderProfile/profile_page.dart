import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  static const name = 'RiderProfilePage';
  static const path = '/';

  //final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        // show a loading page while the profile is loading
        if (state.pageStatus == AppPageStatus.loading) {
          return const LoadingPage();
        }
        // show the profile

        return state.isGuest || state.usersProfile == null
            ? const GuestProfile(
                key: Key('GuestProfileView'),
              )
            : RiderProfileView(
                profile: state.usersProfile!,
                key: const Key('RiderProfileView'),
              );
      },
    );
  }
}
