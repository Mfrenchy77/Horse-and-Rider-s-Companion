import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Shared translucent glass-style timeline entry card for Rider and Horse
/// logbooks.
class LogbookEntryCard extends StatelessWidget {
  const LogbookEntryCard({
    required this.title,
    required this.metadata,
    required this.icon,
    required this.onTap,
    this.preview,
    this.trailing,
    super.key,
  });

  final String title;
  final String metadata;
  final IconData icon;
  final VoidCallback onTap;
  final String? preview;
  final Widget? trailing;

  static const _glassBorderDark = Color(0x475E8F99);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTokens.accentColor(context);
    final iconBg = isDark
        ? AppTokens.midnightButtonFill.withValues(alpha: 0.72)
        : theme.colorScheme.secondaryContainer;
    final iconBorder = isDark
        ? _glassBorderDark
        : theme.colorScheme.outlineVariant;

    final cardContent = Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMd,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: iconBorder),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? accent : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTokens.primaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                        height: 1.35,
                      ),
                    ),
                    if (preview != null && preview!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTokens.primaryTextColor(
                            context,
                          ).withValues(alpha: 0.92),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child:
                    trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTokens.secondaryTextColor(context),
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isDark) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.spaceSm + 2),
        child: AppSurfaceCard(padding: EdgeInsets.zero, child: cardContent),
      );
    }

    final radius = BorderRadius.circular(AppTokens.radiusLg);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceSm + 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTokens.midnightCardTop.withValues(alpha: 0.68),
              AppTokens.midnightCardBottom.withValues(alpha: 0.56),
            ],
          ),
          border: Border.all(color: _glassBorderDark),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: radius, child: cardContent),
      ),
    );
  }
}

/// Shared show-placing badge used in Rider and Horse logbooks.
class LogbookPlacingBadge extends StatelessWidget {
  const LogbookPlacingBadge({super.key, required this.placing});

  final String placing;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (placing.trim().toLowerCase()) {
      '1' || '1st' => ('1st', AppStatusTone.warning),
      '2' || '2nd' => ('2nd', AppStatusTone.neutral),
      '3' || '3rd' => ('3rd', AppStatusTone.coral),
      _ => (placing, AppStatusTone.info),
    };
    return Semantics(
      label: 'Show placing: $label',
      excludeSemantics: true,
      child: AppStatusBadge(
        label: label,
        icon: Icons.emoji_events_outlined,
        tone: tone,
      ),
    );
  }
}

/// Shared floating action button for adding entries in Rider and Horse
/// logbooks.
class LogbookAddFab extends StatelessWidget {
  const LogbookAddFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return FloatingActionButton(
      tooltip: 'Add log entry',
      backgroundColor: AppTokens.accentColor(context),
      foregroundColor: isDark
          ? AppTokens.coralText
          : theme.colorScheme.onPrimary,
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}
