import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/spotlight_tour_card.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:overmark/overmark.dart';

/// Coordinates the 6-step interactive Resources tutorial using Overmark.
class ResourcesSpotlightTour {
  const ResourcesSpotlightTour._();

  static final GlobalKey libraryListKey = GlobalKey(
    debugLabel: 'resourcesTourLibrary',
  );
  static final GlobalKey sortControlKey = GlobalKey(
    debugLabel: 'resourcesTourSort',
  );
  static final GlobalKey searchButtonKey = GlobalKey(
    debugLabel: 'resourcesTourSearch',
  );
  static final GlobalKey firstResourceCardKey = GlobalKey(
    debugLabel: 'resourcesTourFirstCard',
  );
  static final GlobalKey detailHeaderKey = GlobalKey(
    debugLabel: 'resourcesTourDetailHeader',
  );
  static final GlobalKey associatedSkillsKey = GlobalKey(
    debugLabel: 'resourcesTourAssociatedSkills',
  );
  static final GlobalKey commentsAreaKey = GlobalKey(
    debugLabel: 'resourcesTourCommentsArea',
  );
  static final GlobalKey contributeFabKey = GlobalKey(
    debugLabel: 'resourcesTourContributeFab',
  );
  static final GlobalKey overflowMenuKey = GlobalKey(
    debugLabel: 'resourcesTourOverflowMenu',
  );

  static final ValueNotifier<bool> isTourActive = ValueNotifier<bool>(false);
  static String? activeDetailResourceId;

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

  /// Starts the Resources Tutorial from the current screen.
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

    var onDetailRoute = false;

    Future<void> ensureOnResourcesList() async {
      if (cubit != null) {
        if (onDetailRoute) {
          cubit.resetFromResource();
        }
        if (cubit.state.index != 2) {
          cubit.setResourcesList();
        }
      }
      if (router != null && (onDetailRoute || cubit?.state.index != 2)) {
        onDetailRoute = false;
        router.goNamed(ResourcesPage.name);
        if (settle > Duration.zero) {
          await Future<void>.delayed(settle);
        }
      }
    }

    Resource? firstAvailableResource() {
      final list = cubit?.state.resources ?? const <Resource>[];
      return list.where((r) => r.id?.trim().isNotEmpty ?? false).firstOrNull;
    }

    Future<bool> enterFirstResourceDetail() async {
      final resource = firstAvailableResource();
      final id = resource?.id?.trim() ?? '';
      if (resource == null || id.isEmpty) return false;
      activeDetailResourceId = id;
      if (!onDetailRoute && router != null) {
        onDetailRoute = true;
        cubit?.selectResource(resource);
        router.goNamed(
          ResourceCommentPage.name,
          pathParameters: {ResourceCommentPage.pathParams: id},
        );
        if (settle > Duration.zero) {
          await Future<void>.delayed(settle);
        }
      }
      return true;
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
          badgeLabel: 'Resources · ${details.index + 1}/${details.stepCount}',
          details: details,
          cardKey: Key('resourcesTourStepCard_${details.index}'),
          skipKey: const Key('resourcesTourSkipButton'),
          backKey: const Key('resourcesTourBackButton'),
          nextKey: const Key('resourcesTourNextButton'),
        ),
      );
    }

    final hasSampleResource = firstAvailableResource() != null;

    final steps = <OvermarkStep>[
      step(
        anchorKey: libraryListKey,
        title: 'Resource Library',
        message:
            'Browse educational videos, articles, and guides shared by the '
            'equestrian community.',
        radius: AppTokens.radiusLg,
        prepare: (_) async {
          await ensureOnResourcesList();
          await _ensureVisible(libraryListKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: sortControlKey,
        title: 'Sorting and Filtering',
        message:
            'Sort by Most Recent, Most Recommended, or Saved, and use Search '
            'to quickly find material for your goals.',
        extraFocus: [
          OvermarkFocus(
            anchorKey: searchButtonKey,
            shape: OvermarkShape.circle,
          ),
        ],
        prepare: (_) async {
          await ensureOnResourcesList();
          await _ensureVisible(sortControlKey, reducedMotion: reducedMotion);
        },
      ),
      step(
        anchorKey: hasSampleResource ? detailHeaderKey : libraryListKey,
        title: 'Open a Resource',
        message:
            'Open any Resource to read its title, description, and source, '
            'and use the viewing or saving controls.',
        radius: AppTokens.radiusLg,
        prepare: (_) async {
          if (hasSampleResource) {
            await enterFirstResourceDetail();
            await _ensureVisible(detailHeaderKey, reducedMotion: reducedMotion);
          } else {
            await ensureOnResourcesList();
            await _ensureVisible(libraryListKey, reducedMotion: reducedMotion);
          }
        },
      ),
      OvermarkStep(
        anchorKey: associatedSkillsKey,
        shape: OvermarkShape.rrect,
        radius: AppTokens.radiusSm,
        secondaryFocus: [
          OvermarkFocus(
            anchorKey: associatedSkillsKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusSm,
          ),
          OvermarkFocus(
            anchorKey: detailHeaderKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusLg,
          ),
          OvermarkFocus(
            anchorKey: libraryListKey,
            shape: OvermarkShape.rrect,
            radius: AppTokens.radiusLg,
          ),
        ],
        prepare: (_) async {
          if (hasSampleResource) {
            await enterFirstResourceDetail();
            final target = associatedSkillsKey.currentContext != null
                ? associatedSkillsKey
                : detailHeaderKey;
            await _ensureVisible(target, reducedMotion: reducedMotion);
          } else {
            await ensureOnResourcesList();
          }
        },
        title: 'Associated Skills',
        message:
            'Linking a Resource to skills makes it discoverable directly from '
            'those skills in the Skill Tree. Contributors can update links '
            'anytime using Manage Links.',
        cardBuilder: (ctx, details) => SpotlightTourCard(
          badgeLabel: 'Resources · ${details.index + 1}/${details.stepCount}',
          details: details,
          cardKey: Key('resourcesTourStepCard_${details.index}'),
          skipKey: const Key('resourcesTourSkipButton'),
          backKey: const Key('resourcesTourBackButton'),
          nextKey: const Key('resourcesTourNextButton'),
        ),
      ),
      if (hasSampleResource)
        step(
          anchorKey: commentsAreaKey,
          title: 'Comments and Discussion',
          message:
              'Discuss takeaways, ask questions, and share helpful context '
              'with fellow riders, horse owners, and instructors.',
          prepare: (_) async {
            await enterFirstResourceDetail();
            await _ensureVisible(commentsAreaKey, reducedMotion: reducedMotion);
          },
        ),
      OvermarkStep(
        anchorKey: contributeFabKey,
        shape: OvermarkShape.circle,
        secondaryFocus: [
          OvermarkFocus(
            anchorKey: contributeFabKey,
            shape: OvermarkShape.circle,
          ),
          OvermarkFocus(
            anchorKey: overflowMenuKey,
            shape: OvermarkShape.circle,
          ),
        ],
        prepare: (_) async {
          await ensureOnResourcesList();
          final target = contributeFabKey.currentContext != null
              ? contributeFabKey
              : overflowMenuKey;
          await _ensureVisible(target, reducedMotion: reducedMotion);
        },
        title: 'Contribute to the Library',
        message:
            'Signed-in members can share helpful articles, videos, and '
            'guides with the community from here.',
        cardBuilder: (ctx, details) => SpotlightTourCard(
          badgeLabel: 'Resources · ${details.index + 1}/${details.stepCount}',
          details: details,
          cardKey: Key('resourcesTourStepCard_${details.index}'),
          skipKey: const Key('resourcesTourSkipButton'),
          backKey: const Key('resourcesTourBackButton'),
          nextKey: const Key('resourcesTourNextButton'),
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
        routeSettings: const RouteSettings(name: 'resources_spotlight_tour'),
      );
      if (outcome == OvermarkOutcome.completed) {
        await OnboardingPrefs.setCompleted(
          tour: OnboardingTourId.resources,
          userKey: userKey,
          completed: true,
        );
      }
      return outcome;
    } finally {
      isTourActive.value = false;
      activeDetailResourceId = null;
      if (onDetailRoute && router != null) {
        cubit?.resetFromResource();
        cubit?.setResourcesList();
        router.goNamed(ResourcesPage.name);
      }
    }
  }
}
