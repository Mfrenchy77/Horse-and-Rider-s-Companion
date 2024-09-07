import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/guest_login.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/guest_welcome_text.dart';

class GuestProfilePrimaryView extends StatelessWidget {
  const GuestProfilePrimaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProfileName(
            key: Key('ProfileName'),
          ),
          smallGap(),
          // DescribedFeatureOverlay(
          //   backgroundColor: Theme.of(context).primaryColor,
          //   featureId: 'GuestLoginButton',
          //   enablePulsingAnimation: false,
          //   title: const Text('Create account/Log in'),
          //   description: const Text(
          //     'Create an account or log\n in to access more all \nof the features'
          //     " of Horse & Rider's Companion",
          //   ),
          //   tapTarget: const GuestLoginButton(),
          //   child: 
          // ),
          const GuestLoginButton(
              key: Key('GuestLoginButton'),
            ),
          smallGap(),
          const GuestWelcomeText(
            key: Key('GuestWelcomeText'),
          ),
        ],
      ),
    );
  }
}
