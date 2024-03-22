import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/contact_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/instructor_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/message_profile_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_bio.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_location.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_website_link.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/student_request.button.dart';

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
        Wrap(
          spacing: 5,
          runSpacing: 5,
          alignment: WrapAlignment.center,
          children: [
            ContactRequestButton(
              profile: profile,
              key: const Key('ContactRequestButton'),
            ),
            InstructorRequestButton(
              profile: profile,
              key: const Key('InstructorRequestButton'),
            ),
            StudentRequestButton(
              profile: profile,
              key: const Key('StudentRequestButton'),
            ),
            MessageProfileButton(
              profile: profile,
              key: const Key('MessageProfileButton'),
            ),
          ],
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
