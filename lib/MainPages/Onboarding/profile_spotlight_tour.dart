import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:overmark/overmark.dart';

/// Hooks registered by `RiderProfileView` so [ProfileSpotlightTour] can open
/// and close the overflow menu and navigation drawer without duplicate keys.
class ProfileSpotlightHooks {
  const ProfileSpotlightHooks({
    required this.openOverflowMenu,
    required this.closeOverflowMenu,
    required this.openDrawer,
    required this.closeDrawer,
  });

  final VoidCallback openOverflowMenu;
  final VoidCallback closeOverflowMenu;
  final VoidCallback openDrawer;
  final VoidCallback closeDrawer;
}

/// Coordinates the 4-chapter interactive Profile Spotlight Tour using Overmark.
class ProfileSpotlightTour {
  const ProfileSpotlightTour._();

  // Chapter 1: Your Profile
  static final GlobalKey riderIdentityKey = GlobalKey(
    debugLabel: 'profileTourIdentity',
  );
  static final GlobalKey editProfileMenuItemKey = GlobalKey(
    debugLabel: 'profileTourEditProfileMenuItem',
  );
  static final GlobalKey riderAboutKey = GlobalKey(
    debugLabel: 'profileTourAbout',
  );
  static final GlobalKey riderSearchButtonKey = GlobalKey(
    debugLabel: 'profileTourSearchButton',
  );

  // Chapter 2: Your Horses
  static final GlobalKey riderHorsesSectionKey = GlobalKey(
    debugLabel: 'profileTourHorsesSection',
  );
  static final GlobalKey riderAddHorseButtonKey = GlobalKey(
    debugLabel: 'profileTourAddHorseButton',
  );
  static final GlobalKey horseIdentityKey = GlobalKey(
    debugLabel: 'profileTourHorseIdentity',
  );

  // Chapter 3: Training and Progress
  static final GlobalKey riderLogBookButtonKey = GlobalKey(
    debugLabel: 'profileTourLogBookButton',
  );
  static final GlobalKey riderAddEntryButtonKey = GlobalKey(
    debugLabel: 'profileTourAddEntryButton',
  );
  static final GlobalKey riderSkillsSectionKey = GlobalKey(
    debugLabel: 'profileTourSkillsSection',
  );
  static final GlobalKey suggestedNextSkillKey = GlobalKey(
    debugLabel: 'profileTourSuggestedNextSkill',
  );
  static final GlobalKey skillsEmptyStateKey = GlobalKey(
    debugLabel: 'profileTourSkillsEmptyState',
  );

  // Chapter 4: Connections and Tools
  static final GlobalKey connectionsSectionKey = GlobalKey(
    debugLabel: 'profileTourConnectionsSection',
  );
  static final GlobalKey drawerNavListKey = GlobalKey(
    debugLabel: 'profileTourDrawerNavList',
  );
  static final GlobalKey drawerTutorialTileKey = GlobalKey(
    debugLabel: 'profileTourDrawerTutorialTile',
  );

  static ProfileSpotlightHooks? riderHooks;

  static final OvermarkController controller = OvermarkController();

  /// Broadcasts whether the Profile Spotlight Tour is currently active so
  /// widgets only attach tour-specific [GlobalKey]s when needed.
  static final ValueNotifier<bool> isTourActive = ValueNotifier<bool>(false);

  static Future<void> _ensureVisible(
    GlobalKey key, {
    required bool reducedMotion,
  }) async {
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.25,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  /// Starts the Profile Spotlight Tour for the signed-in user's own profile.
  static Future<OvermarkOutcome> start(
    BuildContext context, {
    Duration? settleDelay,
    Duration readinessTimeout = const Duration(seconds: 3),
  }) async {
    if (Overmark.isShowing || !context.mounted) {
      return OvermarkOutcome.notShown;
    }

    AppCubit? cubit;
    try {
      cubit = context.read<AppCubit>();
    } catch (_) {
      cubit = null;
    }
    final appState = cubit?.state;
    final profile = appState?.usersProfile;
    if (appState != null && (appState.isGuest || profile == null)) {
      return OvermarkOutcome.notShown;
    }

    final router = GoRouter.maybeOf(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final settle =
        settleDelay ??
        (reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 260));

    final ownedHorses = profile?.ownedHorses ?? const [];
    final firstHorseId = ownedHorses
        .map((h) => h.id?.trim() ?? '')
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    final hasHorses = firstHorseId.isNotEmpty;

    var onHorseRoute = false;

    Future<void> ensureOnRiderProfile() async {
      riderHooks?.closeOverflowMenu();
      riderHooks?.closeDrawer();
      if (cubit != null) {
        cubit.setProfile();
        if (onHorseRoute) {
          cubit.resetFromHorseProfile();
        }
      }
      if (router != null && onHorseRoute) {
        router.goNamed(ProfilePage.name);
        onHorseRoute = false;
        if (settle > Duration.zero) {
          await Future<void>.delayed(settle);
        }
      }
    }

    Future<void> enterHorseProfile() async {
      riderHooks?.closeOverflowMenu();
      riderHooks?.closeDrawer();
      if (!hasHorses) return;
      if (cubit != null) {
        unawaited(cubit.getHorseProfile(id: firstHorseId));
      }
      if (router != null && !onHorseRoute) {
        onHorseRoute = true;
        router.goNamed(
          HorseProfilePage.name,
          pathParameters: {HorseProfilePage.pathParams: firstHorseId},
        );
        if (settle > Duration.zero) {
          await Future<void>.delayed(settle);
        }
      }
    }

    final theme = OvermarkTheme(
      scrimColor: AppTokens.midnightDeep.withValues(alpha: 0.78),
      spotlightBorderColor: AppTokens.coralAccent,
      spotlightRadius: AppTokens.radiusLg,
      secondaryHoleStrength: 1,
      cardMotion: reducedMotion
          ? OvermarkCardMotion.none
          : OvermarkCardMotion.fadeSlide,
      showLeaderLine: false,
    );

    final config = OvermarkConfig(
      advanceOnBarrierTap: false,
      animationDuration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      transitionDuration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      readinessTimeout: readinessTimeout,
    );

    OvermarkStep rrectStep({
      required GlobalKey anchorKey,
      required String chapter,
      required String title,
      required String message,
      double radius = AppTokens.radiusMd,
      Future<void> Function(BuildContext)? prepare,
    }) {
      return OvermarkStep(
        anchorKey: anchorKey,
        shape: OvermarkShape.rrect,
        radius: radius,
        secondaryFocus: [
          OvermarkFocus(
            anchorKey: anchorKey,
            shape: OvermarkShape.rrect,
            radius: radius,
          ),
        ],
        prepare: prepare,
        title: title,
        message: message,
        cardBuilder: (ctx, details) =>
            _ProfileTourCard(chapter: chapter, details: details),
      );
    }

    OvermarkStep circleStep({
      required GlobalKey anchorKey,
      required String chapter,
      required String title,
      required String message,
      Future<void> Function(BuildContext)? prepare,
    }) {
      return OvermarkStep(
        anchorKey: anchorKey,
        shape: OvermarkShape.circle,
        secondaryFocus: [
          OvermarkFocus(anchorKey: anchorKey, shape: OvermarkShape.circle),
        ],
        prepare: prepare,
        title: title,
        message: message,
        cardBuilder: (ctx, details) =>
            _ProfileTourCard(chapter: chapter, details: details),
      );
    }

    final steps = <OvermarkStep>[
      // Chapter 1: Your Profile
      rrectStep(
        anchorKey: riderIdentityKey,
        chapter: 'Chapter 1 · Your Profile',
        title: 'Profile Identity',
        message:
            'This is your personal riding profile and training identity, '
            'including your photo, name, and location.',
        radius: AppTokens.radiusLg,
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(riderIdentityKey, reducedMotion: reducedMotion);
        },
      ),
      rrectStep(
        anchorKey: editProfileMenuItemKey,
        chapter: 'Chapter 1 · Your Profile',
        title: 'Edit Profile',
        message:
            'Open this menu anytime to update your profile details, photo, '
            'location, bio, and trainer status.',
        radius: AppTokens.radiusSm,
        prepare: (_) async {
          await ensureOnRiderProfile();
          riderHooks?.openOverflowMenu();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
        },
      ),
      rrectStep(
        anchorKey: riderAboutKey,
        chapter: 'Chapter 1 · Your Profile',
        title: 'About',
        message:
            'Introduce yourself, your riding background, and your goals so '
            'instructors and fellow equestrians can get to know you.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(riderAboutKey, reducedMotion: reducedMotion);
        },
      ),
      circleStep(
        anchorKey: riderSearchButtonKey,
        chapter: 'Chapter 1 · Your Profile',
        title: 'Find Riders and Horses',
        message:
            'Use Search to look up other riders, instructors, and public '
            'horse profiles by name or email.',
        prepare: (_) async {
          await ensureOnRiderProfile();
        },
      ),

      // Chapter 2: Your Horses
      if (hasHorses)
        rrectStep(
          anchorKey: riderHorsesSectionKey,
          chapter: 'Chapter 2 · Your Horses',
          title: 'Owned Horses',
          message:
              'Each horse has its own profile, Skill Tree progress, and '
              'training history.',
          prepare: (_) async {
            await ensureOnRiderProfile();
            await _ensureVisible(
              riderHorsesSectionKey,
              reducedMotion: reducedMotion,
            );
          },
        ),
      rrectStep(
        anchorKey: riderAddHorseButtonKey,
        chapter: 'Chapter 2 · Your Horses',
        title: 'Add Horse',
        message: hasHorses
            ? 'Add another horse profile anytime to keep its records organized.'
            : 'Start by adding a horse profile to track its skills, notes, '
                  'and training history.',
        radius: AppTokens.radiusSm,
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(
            riderAddHorseButtonKey,
            reducedMotion: reducedMotion,
          );
        },
      ),
      rrectStep(
        anchorKey: hasHorses ? horseIdentityKey : riderHorsesSectionKey,
        chapter: 'Chapter 2 · Your Horses',
        title: 'Horse Profiles',
        message: hasHorses
            ? 'Inside a horse profile you can review identity details, track '
                  'Horse Skill Tree progress, and keep a dedicated training '
                  'logbook.'
            : 'Once you add a horse, its profile will hold its identity '
                  'details, Horse Skill Tree progress, and training logbook.',
        radius: AppTokens.radiusLg,
        prepare: (_) async {
          if (hasHorses) {
            await enterHorseProfile();
            await _ensureVisible(
              horseIdentityKey,
              reducedMotion: reducedMotion,
            );
          } else {
            await ensureOnRiderProfile();
            await _ensureVisible(
              riderHorsesSectionKey,
              reducedMotion: reducedMotion,
            );
          }
        },
      ),

      // Chapter 3: Training and Progress
      rrectStep(
        anchorKey: riderLogBookButtonKey,
        chapter: 'Chapter 3 · Training and Progress',
        title: "Rider's Log Book",
        message:
            'Your Log Book keeps a chronological history of rides, lessons, '
            'and reflections.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(
            riderLogBookButtonKey,
            reducedMotion: reducedMotion,
          );
        },
      ),
      rrectStep(
        anchorKey: riderAddEntryButtonKey,
        chapter: 'Chapter 3 · Training and Progress',
        title: 'Add Entry',
        message:
            'Record training sessions, notes, and milestones right from your '
            'profile.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(
            riderAddEntryButtonKey,
            reducedMotion: reducedMotion,
          );
        },
      ),
      rrectStep(
        anchorKey: riderSkillsSectionKey,
        chapter: 'Chapter 3 · Training and Progress',
        title: 'Skills & Progress',
        message:
            "See what you're learning, what you've become proficient in, and "
            'which skills an instructor has verified. Select any skill to '
            'explore it in the Skill Tree.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(
            riderSkillsSectionKey,
            reducedMotion: reducedMotion,
          );
        },
      ),
      rrectStep(
        anchorKey: suggestedNextSkillKey,
        chapter: 'Chapter 3 · Training and Progress',
        title: 'Suggested Next Skill',
        message:
            'When you have recorded progress, we highlight a helpful next '
            'skill to practice. New riders can tap Explore Skill Tree here to '
            'begin.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          final target = suggestedNextSkillKey.currentContext != null
              ? suggestedNextSkillKey
              : riderSkillsSectionKey;
          await _ensureVisible(target, reducedMotion: reducedMotion);
        },
      ),

      // Chapter 4: Connections and Tools
      rrectStep(
        anchorKey: connectionsSectionKey,
        chapter: 'Chapter 4 · Connections and Tools',
        title: 'Training Connections',
        message:
            'Connect with instructors or students to share training records '
            'and document instructor verifications.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          await _ensureVisible(
            connectionsSectionKey,
            reducedMotion: reducedMotion,
          );
        },
      ),
      rrectStep(
        anchorKey: drawerNavListKey,
        chapter: 'Chapter 4 · Connections and Tools',
        title: 'Navigation Drawer',
        message:
            'Use the drawer for quick access to your Log Book, Contacts, '
            'Horses, Instructors, Students, and Settings.',
        prepare: (_) async {
          await ensureOnRiderProfile();
          riderHooks?.openDrawer();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(drawerNavListKey, reducedMotion: reducedMotion);
        },
      ),
      rrectStep(
        anchorKey: drawerTutorialTileKey,
        chapter: 'Chapter 4 · Connections and Tools',
        title: 'Tutorial and Help',
        message:
            'You can reopen guided tours anytime from Tutorial. Start '
            'exploring the Skill Tree and tracking your progress whenever '
            'you are ready!',
        radius: AppTokens.radiusSm,
        prepare: (_) async {
          await ensureOnRiderProfile();
          riderHooks?.openDrawer();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(
            drawerTutorialTileKey,
            reducedMotion: reducedMotion,
          );
        },
      ),
    ];

    final userKey = profile?.email ?? appState?.user.id;
    isTourActive.value = true;
    try {
      final outcome = await Overmark.show(
        context,
        steps: steps,
        theme: theme,
        config: config,
        controller: controller,
        routeSettings: const RouteSettings(name: 'profile_spotlight_tour'),
      );
      if (outcome == OvermarkOutcome.completed) {
        await OnboardingPrefs.setCompleted(
          tour: OnboardingTourId.profile,
          userKey: userKey,
          completed: true,
        );
        await OnboardingPrefs.setInviteState(
          tour: OnboardingTourId.profile,
          userKey: userKey,
          state: OnboardingInviteState.accepted,
        );
      }
      return outcome;
    } finally {
      isTourActive.value = false;
      riderHooks?.closeOverflowMenu();
      riderHooks?.closeDrawer();
      if (onHorseRoute && router != null) {
        cubit?.setProfile();
        cubit?.resetFromHorseProfile();
        router.goNamed(ProfilePage.name);
      }
    }
  }
}

class _ProfileTourCard extends StatelessWidget {
  const _ProfileTourCard({required this.chapter, required this.details});

  final String chapter;
  final OvermarkStepDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: AppSurfaceCard(
        key: Key('profileTourStepCard_${details.index}'),
        useDoubleGradient: true,
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceSm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$chapter · ${details.index + 1}/${details.stepCount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceXs),
                if (!details.isLast)
                  TextButton(
                    key: const Key('profileTourSkipButton'),
                    onPressed: details.skip,
                    child: const Text('Skip'),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              details.step.title ?? '',
              style: AppTokens.sectionTitleStyle(
                context,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              details.step.message ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.secondaryTextColor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: AppTokens.spaceSm,
              children: [
                if (!details.isFirst)
                  OutlinedButton(
                    key: const Key('profileTourBackButton'),
                    onPressed: details.previous,
                    child: const Text('Back'),
                  ),
                FilledButton(
                  key: const Key('profileTourNextButton'),
                  onPressed: details.next,
                  child: Text(details.isLast ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
