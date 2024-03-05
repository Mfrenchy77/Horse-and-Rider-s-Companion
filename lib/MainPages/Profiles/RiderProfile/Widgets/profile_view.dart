import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/guest_login.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/guest_welcome_text.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_bio.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_location.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_website_link.dart';

class PrimaryRiderView extends StatelessWidget {
  const PrimaryRiderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: RiderProfileName(
            key: Key('riderName'),
          ),
        ),
        const GuestLoginButton(),
        const Divider(
          indent: 50,
          endIndent: 50,
          color: Colors.black,
          thickness: 1,
        ),
        const GuestWelcomeText(),
        Column(
          children: [
            gap(),
            const RiderLocation(),
            gap(),
            const RiderBio(),
            gap(),
            const Center(
              child: RiderWebsiteLink(),
            ),

            gap(),
            const RiderListOfProfiles(),
            gap(),
            // Log Book Button
            const LogBookButton(),
          ],
        ),
      ],
    );
  }
}
