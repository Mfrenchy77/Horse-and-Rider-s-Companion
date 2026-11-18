import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/spotlight_tour_card.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:overmark/overmark.dart';

/// Hooks registered by `SkillTreeV2View` so [SkillTreeSpotlightTour] can
/// coordinate family expansion, skill selection, difficulty switching, and
/// guidance expansion without modifying progress data.
class SkillTreeSpotlightHooks {
  const SkillTreeSpotlightHooks({
    required this.showFamilyList,
    required this.expandFirstFamily,
    required this.ensureSkillSelected,
    required this.selectSecondLevelIfAvailable,
    required this.expandGuidance,
  });

  final VoidCallback showFamilyList;
  final VoidCallback expandFirstFamily;
  final VoidCallback ensureSkillSelected;
  final VoidCallback selectSecondLevelIfAvailable;
  final VoidCallback expandGuidance;
}

/// Coordinates the 11-step interactive Skill Tree tutorial using Overmark.
class SkillTreeSpotlightTour {
  const SkillTreeSpotlightTour._();

  static final GlobalKey subjectKey = GlobalKey(
    debugLabel: 'skillTreeTourSubject',
  );
  static final GlobalKey categoriesKey = GlobalKey(
    debugLabel: 'skillTreeTourCategories',
  );
  static final GlobalKey familyKey = GlobalKey(
    debugLabel: 'skillTreeTourFamily',
  );
  static final GlobalKey skillRowKey = GlobalKey(
    debugLabel: 'skillTreeTourSkillRow',
  );
  static final GlobalKey descriptionKey = GlobalKey(
    debugLabel: 'skillTreeTourDescription',
  );
  static final GlobalKey difficultyKey = GlobalKey(
    debugLabel: 'skillTreeTourDifficulty',
  );
  static final GlobalKey criteriaKey = GlobalKey(
    debugLabel: 'skillTreeTourCriteria',
  );
  static final GlobalKey selfAssessKey = GlobalKey(
    debugLabel: 'skillTreeTourSelfAssess',
  );
  static final GlobalKey verificationKey = GlobalKey(
    debugLabel: 'skillTreeTourVerification',
  );
  static final GlobalKey guidanceKey = GlobalKey(
    debugLabel: 'skillTreeTourGuidance',
  );
  static final GlobalKey suggestKey = GlobalKey(
    debugLabel: 'skillTreeTourSuggest',
  );
  static final GlobalKey overflowMenuKey = GlobalKey(
    debugLabel: 'skillTreeTourOverflowMenu',
  );

  static SkillTreeSpotlightHooks? hooks;

  static final ValueNotifier<bool> isTourActive = ValueNotifier<bool>(false);
  static final ValueNotifier<int> expandGuidanceRevision = ValueNotifier<int>(
    0,
  );
  static String? activeSkillId;

  static final OvermarkController controller = OvermarkController();

  static Future<void> _ensureVisible(
    GlobalKey key, {
    required bool reducedMotion,
  }) async {
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final box = ctx.findRenderObject();
    final viewportHeight = MediaQuery.sizeOf(ctx).height;
    final isTallTarget =
        box is RenderBox &&
        box.hasSize &&
        box.size.height > viewportHeight * 0.45;
    await Scrollable.ensureVisible(
      ctx,
      alignment: isTallTarget ? 0.05 : 0.25,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  /// Starts the 11-step Skill Tree Tutorial from the current screen.
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
    final router = GoRouter.maybeOf(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final settle =
        settleDelay ??
        (reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 260));

    Future<void> ensureOnSkillTree() async {
      if (cubit != null && cubit.state.index != 1) {
        cubit.setSkillTree();
        router?.goNamed(SkillTreePage.name);
        if (settle > Duration.zero) {
          await Future<void>.delayed(settle);
        }
      }
    }

    final theme = OvermarkTheme(
      scrimColor: AppTokens.midnightDeep.withValues(alpha: 0.78),
      spotlightBorderColor: AppTokens.coralAccent,
      spotlightRadius: AppTokens.radiusLg,
      cardMargin: SpotlightTourCard.themeCardMargin(context),
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

    OvermarkStep step({
      required GlobalKey anchorKey,
      required String title,
      required String message,
      OvermarkShape shape = OvermarkShape.rrect,
      double radius = AppTokens.radiusMd,
      List<OvermarkFocus>? extraFocus,
      Future<void> Function(BuildContext)? prepare,
    }) {
      return OvermarkStep(
        anchorKey: anchorKey,
        shape: shape,
        radius: radius,
        secondaryFocus: [
          OvermarkFocus(anchorKey: anchorKey, shape: shape, radius: radius),
          ...?extraFocus,
        ],
        prepare: prepare,
        title: title,
        message: message,
        cardBuilder: (ctx, details) => SpotlightTourCard(
          badgeLabel: 'Skill Tree · ${details.index + 1}/${details.stepCount}',
          details: details,
          cardKey: Key('skillTreeTourStepCard_${details.index}'),
          skipKey: const Key('skillTreeTourSkipButton'),
          backKey: const Key('skillTreeTourBackButton'),
          nextKey: const Key('skillTreeTourNextButton'),
        ),
      );
    }

    final steps = <OvermarkStep>[
      step(
        anchorKey: subjectKey,
        title: 'Rider and Horse Skills',
        message:
            'Rider and horse development are tracked separately. Open the '
            'Skill Tree from your Rider or Horse profile to focus on either '
            'partner.',
        radius: AppTokens.radiusSm,
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.showFamilyList();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(subjectKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: categoriesKey,
        title: 'Categories',
        message:
            'Major learning areas—such as Husbandry, In-Hand, Mounted, and '
            'Theory & Knowledge—help you focus on one part of horsemanship at '
            'a time.',
        radius: AppTokens.radiusSm,
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.showFamilyList();
          await _ensureVisible(categoriesKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: familyKey,
        title: 'Skill Families',
        message:
            'Related skills are grouped together into families. We expanded '
            'this family so you can browse the skills inside.',
        radius: AppTokens.radiusLg,
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.showFamilyList();
          hooks?.expandFirstFamily();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(familyKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: skillRowKey,
        title: 'Individual Skills',
        message:
            'Each row represents a practical horsemanship skill. Next, we '
            'will open this skill to see its details and levels.',
        radius: AppTokens.radiusSm,
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.showFamilyList();
          hooks?.expandFirstFamily();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(skillRowKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: descriptionKey,
        title: 'Skill Description',
        message:
            'Read the overview and purpose to understand what you or your '
            'horse are practicing and why it matters.',
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(descriptionKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: difficultyKey,
        title: 'Difficulty Levels',
        message:
            'Switch between available difficulty levels to see how '
            'expectations progress from Introductory to Intermediate and '
            'Advanced.',
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          hooks?.selectSecondLevelIfAvailable();
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(difficultyKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: criteriaKey,
        title: 'Learning and Proficient Criteria',
        message:
            'Each level describes what someone should be able to demonstrate: '
            'Learning covers early guided practice, while Proficient reflects '
            'consistent, independent execution.',
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          await _ensureVisible(criteriaKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: selfAssessKey,
        title: 'Self-Assessment',
        message:
            'Signed-in members can mark their own or their horse’s progress as '
            'Learning or Proficient anytime to keep training milestones up to '
            'date.',
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          await _ensureVisible(selfAssessKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: verificationKey,
        title: 'Instructor Verification',
        message:
            'Instructor verification is separate from self-assessment. '
            'Connected instructors can verify when a skill has been '
            'demonstrated at a Proficient level.',
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          await _ensureVisible(verificationKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: guidanceKey,
        title: 'Learning Aids & Related Resources',
        message:
            'Guidance components are helpful study aids—not separate '
            'checkoffs. Related Resources below connect articles and videos '
            'directly to this skill.',
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          hooks?.expandGuidance();
          expandGuidanceRevision.value++;
          if (settle > Duration.zero) {
            await Future<void>.delayed(settle);
          }
          await _ensureVisible(guidanceKey, reducedMotion: reducedMotion);
        },
      ),
      OvermarkStep(
        anchorKey: suggestKey,
        shape: OvermarkShape.rrect,
        radius: AppTokens.radiusSm,
        secondaryFocus: [
          OvermarkFocus(
            anchorKey: suggestKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusSm,
          ),
          OvermarkFocus(
            anchorKey: overflowMenuKey,
            shape: OvermarkShape.circle,
          ),
        ],
        prepare: (_) async {
          await ensureOnSkillTree();
          hooks?.ensureSkillSelected();
          final target = suggestKey.currentContext != null
              ? suggestKey
              : overflowMenuKey;
          await _ensureVisible(target, reducedMotion: reducedMotion);
        },
        title: 'Suggest Improvements',
        message:
            'Notice something missing or unclear? Use Suggest Improvement to '
            'recommend corrections, additions, or clearer wording for review.',
        cardBuilder: (ctx, details) => SpotlightTourCard(
          badgeLabel: 'Skill Tree · ${details.index + 1}/${details.stepCount}',
          details: details,
          cardKey: Key('skillTreeTourStepCard_${details.index}'),
          skipKey: const Key('skillTreeTourSkipButton'),
          backKey: const Key('skillTreeTourBackButton'),
          nextKey: const Key('skillTreeTourNextButton'),
        ),
      ),
    ];

    final appState = cubit?.state;
    final userKey = appState?.usersProfile?.email ?? appState?.user.id;
    isTourActive.value = true;
    try {
      final outcome = await Overmark.show(
        context,
        steps: steps,
        theme: theme,
        config: config,
        controller: controller,
        routeSettings: const RouteSettings(name: 'skill_tree_spotlight_tour'),
      );
      if (outcome == OvermarkOutcome.completed) {
        await OnboardingPrefs.setCompleted(
          tour: OnboardingTourId.skillTree,
          userKey: userKey,
          completed: true,
        );
      }
      return outcome;
    } finally {
      isTourActive.value = false;
    }
  }
}
