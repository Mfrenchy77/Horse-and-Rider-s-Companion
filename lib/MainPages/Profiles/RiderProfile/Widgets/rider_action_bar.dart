import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/Theme/profile_design_tokens.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Responsive primary action bar rendered beneath the Rider Profile hero.
class RiderActionBar extends StatelessWidget {
  const RiderActionBar({
    super.key,
    required this.profile,
    required this.ownProfile,
    required this.showLogbook,
    required this.showWebsite,
    this.studentConnection,
    this.saving = false,
  });

  final RiderProfile profile;
  final bool ownProfile;
  final bool showLogbook;
  final bool showWebsite;
  final CoachingConnection? studentConnection;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    if (!showLogbook && !showWebsite) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outlinedFg = isDark
        ? ProfileTokens.primaryTextDark
        : theme.colorScheme.onSurface;
    final outlinedBorder = isDark
        ? ProfileTokens.midnightButtonBorder
        : theme.colorScheme.outline;
    final outlinedBg = isDark
        ? ProfileTokens.midnightButtonFill
        : theme.colorScheme.surface.withValues(alpha: 0.7);
    final coralBg = ProfileTokens.accentColor(context);
    final coralFg = isDark
        ? ProfileTokens.coralText
        : theme.colorScheme.onPrimary;

    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: outlinedFg,
      backgroundColor: outlinedBg,
      side: BorderSide(color: outlinedBorder),
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProfileTokens.buttonRadius),
      ),
    );

    final filledStyle = FilledButton.styleFrom(
      backgroundColor: coralBg,
      foregroundColor: coralFg,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProfileTokens.buttonRadius),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final textScale = MediaQuery.textScalerOf(context).scale(14);
        final useWrap = constraints.maxWidth < 340 || textScale > 20;

        final logLabel = ownProfile ? "Rider's Log Book" : 'Student logbook';
        final addLabel = ownProfile ? 'Add entry' : 'Add lesson';

        final buttons = <Widget>[
          if (showLogbook) ...[
            _ActionButtonShell(
              expand: !useWrap,
              child: OutlinedButton(
                key: const Key('LogBookButton'),
                style: outlinedStyle,
                onPressed: ownProfile
                    ? () => RiderLogbookPage.open(context)
                    : () => ConnectionPanel.openHistory(
                        context,
                        studentConnection!,
                      ),
                child: _ButtonContent(
                  icon: HorseAndRiderIcons.riderLogIcon,
                  label: logLabel,
                  stacked: compact && !useWrap,
                ),
              ),
            ),
            _ActionButtonShell(
              expand: !useWrap,
              child: FilledButton(
                key: const Key('AddEntryButton'),
                style: filledStyle,
                onPressed: saving
                    ? null
                    : ownProfile
                    ? () => RiderLogbookPage.addEntry(context)
                    : () => RiderLogbookPage.addLessonFor(
                        context,
                        studentConnection!,
                      ),
                child: _ButtonContent(
                  icon: Icons.add,
                  label: addLabel,
                  stacked: compact && !useWrap,
                ),
              ),
            ),
          ],
          if (showWebsite)
            _ActionButtonShell(
              expand: !useWrap,
              child: OutlinedButton(
                key: const Key('RiderWebsiteButton'),
                style: outlinedStyle,
                onPressed: () {
                  final uri = Uri.tryParse(profile.homeUrl?.trim() ?? '');
                  if (uri != null) launchUrl(uri);
                },
                child: _ButtonContent(
                  icon: Icons.open_in_new,
                  label: 'Website',
                  stacked: compact && !useWrap,
                ),
              ),
            ),
        ];

        if (useWrap) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: buttons,
          );
        }

        return Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              buttons[i],
            ],
          ],
        );
      },
    );
  }
}

class _ActionButtonShell extends StatelessWidget {
  const _ActionButtonShell({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return expand ? Expanded(child: child) : child;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.icon,
    required this.label,
    required this.stacked,
  });

  final IconData icon;
  final String label;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
