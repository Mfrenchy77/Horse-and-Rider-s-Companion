import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/contact_request_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_action_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_cover.dart';
import 'package:horseandriderscompanion/Theme/profile_design_tokens.dart';

class PrimaryRiderView extends StatelessWidget {
  const PrimaryRiderView({
    super.key,
    required this.profile,
    this.edgeToEdgeCover = false,
    this.includeLists = true,
  });

  final RiderProfile profile;
  final bool edgeToEdgeCover;
  final bool includeLists;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppCubit>().state;
    final connections = context.watch<ConnectionsCubit?>()?.state;
    final instructor = connections?.instructorFor(profile.email);
    final viewer = app.usersProfile?.email;
    final ownProfile = viewer == profile.email;
    final showStudentLogbook =
        !app.isGuest &&
        instructor != null &&
        instructor.coach == viewer?.toLowerCase();
    final showLogbook = !app.isGuest && (ownProfile || showStudentLogbook);
    final showWebsite = profile.homeUrl?.trim().isNotEmpty ?? false;
    final subtitle = (profile.isTrainer ?? false)
        ? 'Professional Trainer'
        : null;

    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLogbook || showWebsite) ...[
          RiderActionBar(
            profile: profile,
            ownProfile: ownProfile,
            showLogbook: showLogbook,
            showWebsite: showWebsite,
            studentConnection: showStudentLogbook ? instructor : null,
            saving:
                showStudentLogbook && (connections?.actionInProgress ?? false),
          ),
          const SizedBox(height: 16),
        ],
        _RiderAbout(key: ValueKey(profile.email), bio: profile.bio),
        if (includeLists) ...[
          const SizedBox(height: 16),
          RiderListOfProfiles(
            profile: profile,
            key: const Key('RiderListOfProfiles'),
          ),
        ] else
          const SizedBox(height: 16),
        ConnectionPanel(rider: profile, showRecordActions: !showStudentLogbook),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ContactRequestButton(profile: profile),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileCover(
          key: const Key('riderIdentity'),
          name: profile.name,
          photoUrl: profile.picUrl,
          locationName: profile.locationName,
          subtitle: subtitle,
          photoKey: const Key('riderCoverPhoto'),
          edgeToEdge: edgeToEdgeCover,
        ),
        SizedBox(height: edgeToEdgeCover ? 8 : 16),
        if (edgeToEdgeCover)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: bodyContent,
          )
        else
          bodyContent,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyStyle =
        theme.textTheme.bodyMedium?.copyWith(
          color: isDark
              ? ProfileTokens.primaryTextDark.withValues(alpha: 0.92)
              : theme.colorScheme.onSurface,
          height: 1.5,
        ) ??
        const TextStyle(height: 1.5);
    final accent = ProfileTokens.accentColor(context);

    return ProfileSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: ProfileTokens.sectionTitleStyle(context)),
          const SizedBox(height: 10),
          if (bio.isEmpty)
            Text(
              'No bio added yet.',
              style: bodyStyle.copyWith(
                color: ProfileTokens.secondaryTextColor(context),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final span = MarkdownBioText.buildSpan(bio, bodyStyle);
                final preview = TextPainter(
                  text: span,
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
                    MarkdownBioText(
                      markdown: bio,
                      style: bodyStyle,
                      maxLines: _expanded ? null : _previewLines,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                    if (canExpand) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () =>
                            setState(() => _expanded = !_expanded),
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          minimumSize: const Size(48, 44),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expanded ? 'Show less' : 'Read full bio',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _expanded
                                  ? Icons.arrow_upward
                                  : Icons.arrow_forward,
                              size: 16,
                              color: accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
