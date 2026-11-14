import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Shared timeline entry card for Rider and Horse logbooks.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTokens.accentColor(context);
    final iconBg = isDark
        ? AppTokens.midnightButtonFill
        : theme.colorScheme.secondaryContainer;
    final iconBorder = isDark
        ? AppTokens.midnightButtonBorder
        : theme.colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceSm + 2),
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          child: InkWell(
            onTap: onTap,
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
                              color: AppTokens.primaryTextColor(context)
                                  .withValues(alpha: 0.9),
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
                    child: trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTokens.secondaryTextColor(context),
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
