import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/guest_login.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/guest_welcome_text.dart';

class GuestProfilePrimaryView extends StatelessWidget {
  const GuestProfilePrimaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ProfileName(
          key: Key('ProfileName'),
        ),
        smallGap(),
        const GuestLoginButton(
          key: Key('GuestLoginButton'),
        ),
        smallGap(),
        const GuestWelcomeText(
          key: Key('GuestWelcomeText'),
        ),
      ],
    );
  }
}
