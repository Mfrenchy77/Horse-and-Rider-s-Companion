import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  static const name = 'RiderProfilePage';
  static const path = '/';

  //final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return state.isGuest
            ? const GuestProfileView(
                key: Key('GuestProfileView'),
              )
            :  RiderProfileView(
              profile: state.usersProfile!,
                key: const Key('RiderProfileView'),
              );
      },
    );
  }
}
