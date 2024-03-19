import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_bio.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_location.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_website_link.dart';

class PrimaryRiderView extends StatelessWidget {
  const PrimaryRiderView({super.key, required this.profile});
  final RiderProfile profile;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: ProfileName(
            name: profile.name,
            profilePicUrl: profile.picUrl,
            key: const Key('profileName'),
          ),
        ),
        gap(),
        RiderLocation(
          locationName: profile.locationName,
          key: const Key('RiderLocation'),
        ),
        const Divider(
          indent: 50,
          endIndent: 50,
          color: Colors.black,
          thickness: 1,
        ),
        RiderBio(
          bio: profile.bio,
          key: const Key('RiderBio'),
        ),
        gap(),
        Center(
          child: RiderWebsiteLink(
            homeUrl: profile.homeUrl,
            key: const Key(
              'RiderWebsiteLink',
            ),
          ),
        ),

        gap(),
        RiderListOfProfiles(
          profile: profile,
          key: const Key('RiderListOfProfiles'),
        ),
        gap(),
        // Log Book Button
        LogBookButton(
          profile: profile,
          horseProfile: null,
          key: const Key('LogBookButton'),
        ),
      ],
    );
  }
}
