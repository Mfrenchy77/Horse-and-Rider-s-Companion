import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Shared photographic hero header for Rider and Horse logbooks.
class LogbookHeroHeader extends StatelessWidget {
  const LogbookHeroHeader({
    super.key,
    required this.title,
    this.subtitle = 'Training journal & progress history',
    this.details,
    this.photoUrl,
    this.imageProvider,
    this.onAddEntry,
    this.addEntryLabel = 'Add entry',
    this.fallbackIcon = Icons.auto_stories_outlined,
  });

  final String title;
  final String subtitle;
  final String? details;
  final String? photoUrl;
  final ImageProvider? imageProvider;
  final VoidCallback? onAddEntry;
  final String addEntryLabel;
  final IconData fallbackIcon;

  static const _glassBorderDark = Color(0x475E8F99);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUrl = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final hasPhoto = imageProvider != null || hasUrl;
    final cardBase = isDark
        ? AppTokens.midnightCardBottom
        : theme.colorScheme.surfaceContainerLow;
    final borderColor = isDark
        ? _glassBorderDark
        : theme.colorScheme.outlineVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final minHeight = isWide ? 196.0 : 176.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTokens.midnightCardTop.withValues(alpha: 0.72),
                        AppTokens.midnightCardBottom.withValues(alpha: 0.62),
                      ],
                    )
                  : null,
              color: isDark ? null : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasPhoto
                      ? _PhotoBackdrop(
                          photoUrl: photoUrl,
                          imageProvider: imageProvider,
                          cardBase: cardBase,
                          isWide: isWide,
                          fallback: _PlaceholderBackdrop(
                            icon: fallbackIcon,
                            isDark: isDark,
                          ),
                        )
                      : _PlaceholderBackdrop(
                          icon: fallbackIcon,
                          isDark: isDark,
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(
                    isWide ? AppTokens.spaceXl : AppTokens.spaceLg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? constraints.maxWidth * 0.62 : 420,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.heroTitleStyle(
                            context,
                          ).copyWith(fontSize: isWide ? 28 : 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTokens.secondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (details != null && details!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            details!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTokens.secondaryTextColor(
                                context,
                              ).withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                        if (onAddEntry != null) ...[
                          const SizedBox(height: AppTokens.spaceMd),
                          AppPrimaryButton(
                            label: addEntryLabel,
                            icon: Icons.add,
                            onPressed: onAddEntry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoBackdrop extends StatelessWidget {
  const _PhotoBackdrop({
    required this.photoUrl,
    required this.imageProvider,
    required this.cardBase,
    required this.isWide,
    required this.fallback,
  });

  final String? photoUrl;
  final ImageProvider? imageProvider;
  final Color cardBase;
  final bool isWide;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final image = imageProvider != null
        ? Image(
            image: imageProvider!,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => fallback,
          )
        : SmartImage(photoUrl, fallback: fallback);

    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: isWide ? 0.58 : 0.72,
            heightFactor: 1,
            child: image,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardBase.withValues(alpha: 0.90),
                cardBase.withValues(alpha: 0.82),
                cardBase.withValues(alpha: 0.42),
                cardBase.withValues(alpha: 0.08),
              ],
              stops: isWide
                  ? const [0.0, 0.40, 0.68, 1.0]
                  : const [0.0, 0.34, 0.66, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, cardBase.withValues(alpha: 0.32)],
              stops: const [0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderBackdrop extends StatelessWidget {
  const _PlaceholderBackdrop({required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTokens.midnightCardTop.withValues(alpha: 0.74),
                  AppTokens.midnightMid.withValues(alpha: 0.68),
                  AppTokens.midnightDeep.withValues(alpha: 0.78),
                ]
              : [
                  theme.colorScheme.surfaceContainerHigh,
                  theme.colorScheme.surfaceContainer,
                ],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: AppTokens.spaceXl),
          child: Icon(
            icon,
            size: 88,
            color: (isDark ? Colors.white : theme.colorScheme.primary)
                .withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}
