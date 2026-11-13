import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
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
  Widget build(BuildContext context) {
    final showLogbook = context.select(
      (AppCubit cubit) =>
          !cubit.state.isGuest &&
          cubit.state.usersProfile?.email == profile.email,
    );
    final showWebsite = profile.homeUrl?.trim().isNotEmpty ?? false;
    return Column(
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
        if (showLogbook || showWebsite) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (showLogbook)
                LogBookButton(
                  profile: profile,
                  horseProfile: null,
                  key: const Key('LogBookButton'),
                ),
              if (showWebsite) RiderWebsiteLink(homeUrl: profile.homeUrl),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _RiderAbout(key: ValueKey(profile.email), bio: profile.bio),
        const SizedBox(height: 12),
        RiderListOfProfiles(
          profile: profile,
          key: const Key('RiderListOfProfiles'),
        ),
        ConnectionPanel(rider: profile),
        Align(
          alignment: Alignment.centerLeft,
          child: ContactRequestButton(profile: profile),
        ),
      ],
    );
  }
}

class _RiderAbout extends StatefulWidget {
  const _RiderAbout({required this.bio, super.key});

  final String? bio;

  @override
  State<_RiderAbout> createState() => _RiderAboutState();
}

class _RiderAboutState extends State<_RiderAbout> {
  static const _previewLines = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.bio?.trim() ?? '';
    return GradientCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('About', style: Theme.of(context).textTheme.titleLarge),
            if (bio.isEmpty)
              const Text('No bio added yet.')
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final style = DefaultTextStyle.of(context).style;
                  final preview = TextPainter(
                    text: TextSpan(text: bio, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: _previewLines,
                    ellipsis: '…',
                  )..layout(maxWidth: constraints.maxWidth);
                  final canExpand = preview.didExceedMaxLines;
                  preview.dispose();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bio,
                        maxLines: _expanded ? null : _previewLines,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                      if (canExpand)
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          icon: Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          label: Text(
                            _expanded ? 'Show less' : 'Read full bio',
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
