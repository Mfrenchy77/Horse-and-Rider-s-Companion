import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/contact_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/instructor_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/message_profile_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_website_link.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/student_request.button.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class PrimaryRiderView extends StatelessWidget {
  const PrimaryRiderView({super.key, required this.profile});
  final RiderProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _RiderCover(profile: profile),
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
      RiderListOfProfiles(
        profile: profile,
        key: const Key('RiderListOfProfiles'),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ContactRequestButton(profile: profile),
          InstructorRequestButton(profile: profile),
          StudentRequestButton(profile: profile),
          MessageProfileButton(profile: profile),
        ],
      ),
    ],
  );
}

class _RiderCover extends StatelessWidget {
  const _RiderCover({required this.profile});

  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = profile.picUrl?.trim() ?? '';
    final location = profile.locationName?.trim() ?? '';
    final scrim = Color.alphaBlend(
      theme.colorScheme.surface.withValues(alpha: .15),
      Colors.black,
    );
    final fallback = Align(
      alignment: const Alignment(0, -.45),
      child: FractionallySizedBox(
        widthFactor: .5,
        heightFactor: .62,
        child: Image.asset(
          'assets/horse_logo.png',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );

    return GradientCard(
      key: const Key('riderIdentity'),
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: (constraints.maxWidth * .63).clamp(220.0, 380.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.isEmpty)
                fallback
              else
                Image.network(
                  photo,
                  key: const Key('riderCoverPhoto'),
                  fit: BoxFit.cover,
                  semanticLabel: 'Photo of ${profile.name}',
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  frameBuilder: (context, child, frame, synchronouslyLoaded) {
                    if (frame == null) return child;
                    return Tooltip(
                      message: 'View full photo',
                      child: InkWell(
                        onTap: () => showProfilePhoto(context, photo),
                        child: child,
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => fallback,
                ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, scrim],
                      stops: const [.26, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
