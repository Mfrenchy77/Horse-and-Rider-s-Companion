import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/profile_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Frosted-glass selector allowing signed-in users to launch or restart
/// available interactive guided tours.
class TutorialSelectorDialog extends StatelessWidget {
  const TutorialSelectorDialog({
    super.key,
    required this.cubit,
    required this.router,
    required this.rootNavigator,
  });

  final AppCubit cubit;
  final GoRouter? router;
  final NavigatorState rootNavigator;

  static Future<void> show(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final router = GoRouter.maybeOf(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    return showAppGlassDialog<void>(
      context: context,
      builder: (_) => TutorialSelectorDialog(
        cubit: cubit,
        router: router,
        rootNavigator: rootNavigator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.select((AppCubit c) => c.state);
    final userKey = appState.usersProfile?.email ?? appState.user.id;
    final profileCompleted = OnboardingPrefs.isCompleted(
      tour: OnboardingTourId.profile,
      userKey: userKey,
    );

    return AppGlassDialog(
      key: const Key('tutorialSelectorDialog'),
      maxWidth: 460,
      title: const Text('Guided Tours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceSm,
        children: [
          Text(
            'Choose an interactive walkthrough to explore the app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          _TourOptionTile(
            key: const Key('tutorialSelectProfile'),
            icon: Icons.person_outline_rounded,
            title: 'Your Profile',
            subtitle:
                'Identity, horses, logbook, Skill Tree progress, and '
                'connections.',
            badgeLabel: profileCompleted ? 'Completed' : 'Available',
            badgeTone: profileCompleted
                ? AppStatusTone.success
                : AppStatusTone.coral,
            onTap: () {
              Navigator.of(context).pop();
              cubit.setProfile();
              router?.goNamed(ProfilePage.name);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final navContext = rootNavigator.context;
                if (!navContext.mounted) return;
                unawaited(ProfileSpotlightTour.start(navContext));
              });
            },
          ),
          const _TourOptionTile(
            key: Key('tutorialSelectSkillTree'),
            icon: Icons.account_tree_outlined,
            title: 'Skill Tree',
            subtitle:
                'Guided walkthrough for signed-in skill assessments and '
                'verification.',
            badgeLabel: 'Coming soon',
            badgeTone: AppStatusTone.neutral,
          ),
          const _TourOptionTile(
            key: Key('tutorialSelectResources'),
            icon: Icons.menu_book_outlined,
            title: 'Resources',
            subtitle:
                'Guided walkthrough for saving, organizing, and linking '
                'resources.',
            badgeLabel: 'Coming soon',
            badgeTone: AppStatusTone.neutral,
          ),
        ],
      ),
      actions: [
        AppOutlinedButton(
          key: const Key('tutorialSelectorCloseButton'),
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _TourOptionTile extends StatelessWidget {
  const _TourOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeTone,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final AppStatusTone badgeTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(AppTokens.radiusMd);
    final accent = AppTokens.accentColor(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? AppTokens.midnightInputFill
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: 0.45)
                : (isDark
                      ? AppTokens.cardBorderDark
                      : theme.colorScheme.outlineVariant),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceSm + 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: enabled
                        ? accent
                        : AppTokens.secondaryTextColor(context),
                  ),
                  const SizedBox(width: AppTokens.spaceSm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppTokens.primaryTextColor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            AppStatusBadge(label: badgeLabel, tone: badgeTone),
                          ],
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTokens.secondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
