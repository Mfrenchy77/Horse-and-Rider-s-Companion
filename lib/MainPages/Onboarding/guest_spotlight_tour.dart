import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:overmark/overmark.dart';

/// Coordinates the optional, manually triggered Guest Spotlight Tour.
class GuestSpotlightTour {
  const GuestSpotlightTour._();

  static final GlobalKey skillTreeNavKey = GlobalKey(
    debugLabel: 'tourSkillTreeNav',
  );
  static final GlobalKey skillTreeFamilyKey = GlobalKey(
    debugLabel: 'tourSkillTreeFamily',
  );
  static final GlobalKey resourcesNavKey = GlobalKey(
    debugLabel: 'tourResourcesNav',
  );
  static final GlobalKey resourcesHeaderKey = GlobalKey(
    debugLabel: 'tourResourcesHeader',
  );

  static final OvermarkController controller = OvermarkController();

  /// Completes action-gated tour steps when the user taps the highlighted
  /// navigation destination directly.
  static void notifyNavBranchSelected(int branchIndex) {
    if (!controller.isShowing || !controller.isAwaitingAction) return;
    final stepIndex = controller.currentStep;
    if (stepIndex == 0 && branchIndex == 1) {
      controller.completeAction();
    } else if (stepIndex == 2 && branchIndex == 2) {
      controller.completeAction();
    }
  }

  /// Starts the 4-step Guest Spotlight Tour from the current screen.
  static Future<OvermarkOutcome> start(
    BuildContext context, {
    Duration? branchSettleDelay,
    Duration readinessTimeout = const Duration(seconds: 3),
  }) async {
    if (Overmark.isShowing || !context.mounted) {
      return OvermarkOutcome.notShown;
    }

    final router = GoRouter.maybeOf(context);
    AppCubit? cubit;
    try {
      cubit = context.read<AppCubit>();
    } catch (_) {
      cubit = null;
    }

    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final settle =
        branchSettleDelay ??
        (reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 260));

    Future<void> goToBranch(int branchIndex) async {
      if (cubit != null) {
        switch (branchIndex) {
          case 0:
            cubit.setProfile();
          case 1:
            cubit.setSkillTree();
          case 2:
            cubit.setResourcesList();
        }
      }
      if (router != null) {
        final targetRoute = switch (branchIndex) {
          0 => ProfilePage.name,
          1 => SkillTreePage.name,
          _ => ResourcesPage.name,
        };
        router.goNamed(targetRoute);
      }
      if (settle > Duration.zero) {
        await Future<void>.delayed(settle);
      }
    }

    final theme = OvermarkTheme(
      scrimColor: AppTokens.midnightDeep.withValues(alpha: 0.78),
      spotlightBorderColor: AppTokens.coralAccent,
      spotlightRadius: AppTokens.radiusLg,
      // Keep secondaryFocus cutouts 100% clear so each step can use
      // SpotlightPainter's saveLayer + BlendMode.clear path on Flutter Web,
      // where Path.combine(PathOperation.difference, ...) can leave the hole
      // dimmed.
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

    final steps = <OvermarkStep>[
      OvermarkStep(
        anchorKey: skillTreeNavKey,
        shape: OvermarkShape.circle,
        gate: OvermarkStepGate.action,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: skillTreeNavKey,
            shape: OvermarkShape.circle,
          ),
        ],
        title: 'Explore Skill Tree',
        message:
            'Browse structured horsemanship skills for Rider and Horse and '
            'track learning progress. Tap the highlighted Skill Tree button '
            'to continue.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: () async {
            await goToBranch(1);
            details.completeAction();
          },
        ),
      ),
      OvermarkStep(
        anchorKey: skillTreeFamilyKey,
        shape: OvermarkShape.rrect,
        radius: AppTokens.radiusLg,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: skillTreeFamilyKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusLg,
          ),
        ],
        prepare: (_) => goToBranch(1),
        title: 'Families & Skills',
        message:
            'Skills are organized into Skill Families. Open any family to '
            'view difficulty-level standards, guidance, and linked resources.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: details.next,
        ),
      ),
      OvermarkStep(
        anchorKey: resourcesNavKey,
        shape: OvermarkShape.circle,
        gate: OvermarkStepGate.action,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: resourcesNavKey,
            shape: OvermarkShape.circle,
          ),
        ],
        prepare: (_) => goToBranch(1),
        title: 'Discover Resources',
        message:
            'Educational articles, videos, and training guides are connected '
            'to skills. Tap the highlighted Resources button to continue.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: () async {
            await goToBranch(2);
            details.completeAction();
          },
        ),
      ),
      OvermarkStep(
        anchorKey: resourcesHeaderKey,
        shape: OvermarkShape.rrect,
        radius: AppTokens.radiusMd,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: resourcesHeaderKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusMd,
          ),
        ],
        prepare: (_) => goToBranch(2),
        title: 'You’re Ready to Explore',
        message:
            'Filter, rate, and open any resource—or tap a linked skill chip '
            'to jump straight to that skill.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: details.next,
        ),
      ),
    ];

    return Overmark.show(
      context,
      steps: steps,
      theme: theme,
      config: config,
      controller: controller,
      routeSettings: const RouteSettings(name: 'guest_spotlight_tour'),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.details,
    required this.onPrimaryPressed,
  });

  final OvermarkStepDetails details;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: AppSurfaceCard(
        key: Key('tourStepCard_${details.index}'),
        useDoubleGradient: true,
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceSm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Step ${details.index + 1} of ${details.stepCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (!details.isLast)
                  TextButton(
                    key: const Key('tourSkipButton'),
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
                    key: const Key('tourBackButton'),
                    onPressed: details.previous,
                    child: const Text('Back'),
                  ),
                FilledButton(
                  key: const Key('tourNextButton'),
                  onPressed: onPrimaryPressed,
                  child: Text(details.isLast ? 'Got it' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
