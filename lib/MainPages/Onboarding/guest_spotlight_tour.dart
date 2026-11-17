import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:overmark/overmark.dart';

/// Hooks registered by Skill Tree 2.0 so the Guest Discovery Tour can expand
/// a family, open a skill, or return to the family list on narrow screens.
class GuestSpotlightSkillTreeHooks {
  const GuestSpotlightSkillTreeHooks({
    required this.expandFirstFamily,
    required this.ensureSkillSelected,
    required this.showFamilyList,
  });

  final VoidCallback expandFirstFamily;
  final VoidCallback ensureSkillSelected;
  final VoidCallback showFamilyList;
}

/// Coordinates the optional, manually triggered Guest Discovery Tour.
class GuestSpotlightTour {
  const GuestSpotlightTour._();

  static final GlobalKey profileNavKey = GlobalKey(
    debugLabel: 'tourProfileNav',
  );
  static final GlobalKey skillTreeNavKey = GlobalKey(
    debugLabel: 'tourSkillTreeNav',
  );
  static final GlobalKey skillTreeFamilyKey = GlobalKey(
    debugLabel: 'tourSkillTreeFamily',
  );
  static final GlobalKey skillTreeSkillRowKey = GlobalKey(
    debugLabel: 'tourSkillTreeSkillRow',
  );
  static final GlobalKey skillTreeDifficultyKey = GlobalKey(
    debugLabel: 'tourSkillTreeDifficulty',
  );
  static final GlobalKey resourcesNavKey = GlobalKey(
    debugLabel: 'tourResourcesNav',
  );
  static final GlobalKey resourcesHeaderKey = GlobalKey(
    debugLabel: 'tourResourcesHeader',
  );

  static GuestSpotlightSkillTreeHooks? skillTreeHooks;

  /// Broadcasts the active step index (or `null` when closed) so widgets
  /// inside `AnimatedSwitcher` only attach tour `GlobalKey`s on their step.
  static final ValueNotifier<int?> activeStep = ValueNotifier<int?>(null);

  /// The currently active skill ID in Skill Tree 2.0, preventing outgoing
  /// `AnimatedSwitcher` panels from claiming `skillTreeDifficultyKey`.
  static String? activeDifficultySkillId;

  static final OvermarkController controller = OvermarkController();

  /// Completes action-gated tour steps when the user taps the highlighted
  /// navigation destination directly.
  static void notifyNavBranchSelected(int branchIndex) {
    if (!controller.isShowing || !controller.isAwaitingAction) return;
    final stepIndex = controller.currentStep;
    if (stepIndex == 0 && branchIndex == 1) {
      controller.completeAction();
    } else if (stepIndex == 4 && branchIndex == 2) {
      controller.completeAction();
    }
  }

  /// Completes the skill-row action gate when the user taps a skill during
  /// Step 3 (Explore an Individual Skill).
  static void notifySkillSelected() {
    if (!controller.isShowing || !controller.isAwaitingAction) return;
    if (controller.currentStep == 2) {
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

    var currentBranch = cubit?.state.index ?? 0;

    Future<void> goToBranch(int branchIndex) async {
      final changed = currentBranch != branchIndex;
      currentBranch = branchIndex;
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
      if (router != null && changed) {
        final targetRoute = switch (branchIndex) {
          0 => ProfilePage.name,
          1 => SkillTreePage.name,
          _ => ResourcesPage.name,
        };
        router.goNamed(targetRoute);
      }
      if (changed && settle > Duration.zero) {
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
        prepare: (_) => goToBranch(0),
        title: 'Explore Skill Tree',
        message:
            'Browse structured horsemanship skills for Rider and Horse. '
            'Tap the highlighted Skill Tree button or press Next to continue.',
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
        prepare: (_) async {
          await goToBranch(1);
          skillTreeHooks?.showFamilyList();
        },
        title: 'Skill Families',
        message:
            'Skills are grouped into Skill Families across Husbandry, '
            'In-Hand, Mounted, and Theory & Knowledge.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: details.next,
        ),
      ),
      OvermarkStep(
        anchorKey: skillTreeSkillRowKey,
        shape: OvermarkShape.rrect,
        radius: AppTokens.radiusSm,
        gate: OvermarkStepGate.action,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: skillTreeSkillRowKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusSm,
          ),
        ],
        prepare: (_) async {
          await goToBranch(1);
          skillTreeHooks?.showFamilyList();
          skillTreeHooks?.expandFirstFamily();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
        },
        title: 'Explore an Individual Skill',
        message:
            'Expand any family to browse its skills. Tap the highlighted '
            'skill—or press Next—to open its full standards and guidance.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: () async {
            skillTreeHooks?.ensureSkillSelected();
            if (settle > Duration.zero) {
              await Future<void>.delayed(settle);
            }
            details.completeAction();
          },
        ),
      ),
      OvermarkStep(
        anchorKey: skillTreeDifficultyKey,
        shape: OvermarkShape.rrect,
        radius: AppTokens.radiusMd,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: skillTreeDifficultyKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusMd,
          ),
        ],
        prepare: (_) async {
          await goToBranch(1);
          skillTreeHooks?.ensureSkillSelected();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
        },
        title: 'Understand Difficulty Levels',
        message:
            'Switch between progressive difficulty levels to view clear '
            'criteria. Sign in anytime to record Learning or Proficient '
            'progress.',
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
        title: 'Find Educational Resources',
        message:
            'Explore curated articles, videos, and training guides. Tap the '
            'highlighted Resources button or press Next to continue.',
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
        title: 'Browse Resources',
        message:
            'Sort and browse resources linked directly to skills—tap any '
            'skill chip on a resource card to jump straight to that skill.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: details.next,
        ),
      ),
      OvermarkStep(
        anchorKey: profileNavKey,
        shape: OvermarkShape.circle,
        secondaryFocus: <OvermarkFocus>[
          OvermarkFocus(
            anchorKey: profileNavKey,
            shape: OvermarkShape.circle,
          ),
        ],
        prepare: (_) => goToBranch(2),
        title: 'You’re Ready to Explore',
        message:
            'Explore skills and resources freely as a guest, or visit Profile '
            'to create an account for progress tracking and horse records.',
        cardBuilder: (ctx, details) => _TourCard(
          details: details,
          onPrimaryPressed: details.next,
        ),
      ),
    ];

    activeStep.value = 0;
    try {
      return await Overmark.show(
        context,
        steps: steps,
        theme: theme,
        config: config,
        controller: controller,
        onStepChanged: (index) => activeStep.value = index,
        routeSettings: const RouteSettings(name: 'guest_spotlight_tour'),
      );
    } finally {
      activeStep.value = null;
    }
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
