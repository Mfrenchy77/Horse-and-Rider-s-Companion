import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/contact_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_website_link.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_cover.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class PrimaryRiderView extends StatelessWidget {
  const PrimaryRiderView({super.key, required this.profile});
  final RiderProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ProfileCover(
        key: const Key('riderIdentity'),
        name: profile.name,
        photoUrl: profile.picUrl,
        locationName: profile.locationName,
        photoKey: const Key('riderCoverPhoto'),
      ),
      const SizedBox(height: 12),
      GradientCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                profile.bio?.trim().isNotEmpty ?? false
                    ? profile.bio!
                    : 'No bio added yet.',
              ),
              if (profile.homeUrl?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                RiderWebsiteLink(homeUrl: profile.homeUrl),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      LogBookButton(
        profile: profile,
        horseProfile: null,
        key: const Key('LogBookButton'),
      ),
      const SizedBox(height: 12),
      ConnectionPanel(rider: profile),
      RiderListOfProfiles(
        profile: profile,
        key: const Key('RiderListOfProfiles'),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ContactRequestButton(profile: profile),
      ),
    ],
  );
}
