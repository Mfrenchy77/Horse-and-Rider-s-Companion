import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:overmark/overmark.dart';

/// Shared Overmark explanation card used by all guided tours.
///
/// Constrains height to the available viewport and keeps the header and
/// Back/Next/Finish footer pinned so navigation controls are never clipped on
/// narrow or short mobile screens.
class SpotlightTourCard extends StatelessWidget {
  const SpotlightTourCard({
    super.key,
    required this.badgeLabel,
    required this.details,
    this.onPrimaryPressed,
    this.cardKey,
    this.skipKey,
    this.backKey,
    this.nextKey,
  });

  final String badgeLabel;
  final OvermarkStepDetails details;
  final VoidCallback? onPrimaryPressed;
  final Key? cardKey;
  final Key? skipKey;
  final Key? backKey;
  final Key? nextKey;

  /// Computes a safe [OvermarkTheme.cardMargin] that respects `SafeArea` and
  /// avoids overlapping the mobile bottom navigation bar.
  static EdgeInsets themeCardMargin(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 600;
    return EdgeInsets.fromLTRB(
      AppTokens.spaceMd,
      AppTokens.spaceMd,
      AppTokens.spaceMd,
      isCompact ? 88 : AppTokens.spaceLg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height -
        media.padding.vertical -
        (media.size.width < 600 ? 112 : 48);
    final maxCardHeight = availableHeight.clamp(190.0, 340.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 360,
        maxHeight: maxCardHeight,
      ),
      child: AppSurfaceCard(
        key: cardKey,
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
                      badgeLabel,
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
                    key: skipKey,
                    onPressed: details.skip,
                    style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Skip'),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: AppTokens.spaceSm,
              children: [
                if (!details.isFirst)
                  OutlinedButton(
                    key: backKey,
                    onPressed: details.previous,
                    child: const Text('Back'),
                  ),
                FilledButton(
                  key: nextKey,
                  onPressed: onPrimaryPressed ?? details.next,
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
