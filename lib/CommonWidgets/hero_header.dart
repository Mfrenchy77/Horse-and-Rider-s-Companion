import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Shared full-width hero image and title header used by Dictionary entries,
/// Horse profiles, and Rider profiles.
///
/// Displays an optional full-width image with a subtle vertical
/// black-to-transparent gradient protecting the bottom-left title overlay,
/// tap-to-zoom support via [showProfilePhoto], and a graceful no-image
/// fallback that uses existing theme surface colors.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.title,
    this.imageUrl,
    this.imageKey,
    this.tapKey,
    this.imageFit = BoxFit.cover,
    this.imageAlignment = Alignment.center,
    this.imageSemanticLabel,
    this.useSmartImage = false,
    this.categoryBadges = const [],
    this.badges = const [],
    this.subtitle,
    this.footer,
    this.topOverlay,
    this.fallbackBackground,
    this.heightBuilder,
    this.compact = false,
    this.borderRadius,
    this.enableTapToZoom = true,
    this.zoomTooltip = 'View full image',
  });

  final String title;
  final String? imageUrl;
  final Key? imageKey;
  final Key? tapKey;
  final BoxFit imageFit;
  final AlignmentGeometry imageAlignment;
  final String? imageSemanticLabel;
  final bool useSmartImage;
  final List<String> categoryBadges;
  final List<Widget> badges;
  final String? subtitle;
  final Widget? footer;
  final Widget? topOverlay;
  final Widget? fallbackBackground;
  final double Function(double maxWidth, {required bool hasImage})?
  heightBuilder;
  final bool compact;
  final BorderRadius? borderRadius;
  final bool enableTapToZoom;
  final String zoomTooltip;

  /// Subtle vertical black-to-transparent gradient, darkest at the bottom and
  /// fading upward so white overlay text remains legible without decorative
  /// color washes.
  static const LinearGradient bottomScrimGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color.fromARGB(243, 0, 0, 0),
      Color(0x66000000),
      Color(0x14000000),
      Colors.transparent,
    ],
    stops: [0.0, 0.34, 0.62, 0.85],
  );

  @override
  Widget build(BuildContext context) {
    final photo = imageUrl?.trim() ?? '';
    final hasImage = photo.isNotEmpty;
    final hasBackdrop = hasImage || fallbackBackground != null;

    final content = hasBackdrop
        ? _buildVisualHero(context, photo: photo, hasImage: hasImage)
        : _buildSurfaceFallback(context);

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildVisualHero(
    BuildContext context, {
    required String photo,
    required bool hasImage,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageBackgroundColor = isDark
        ? AppTokens.midnightDeep
        : theme.colorScheme.surfaceContainerHighest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height =
            heightBuilder?.call(maxWidth, hasImage: hasImage) ??
            (maxWidth * 0.52).clamp(220.0, 380.0);

        final imageFallback =
            fallbackBackground ??
            ColoredBox(
              color: imageBackgroundColor,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 36,
                  color: Colors.white54,
                ),
              ),
            );

        Widget mediaLayer;
        if (!hasImage) {
          mediaLayer = fallbackBackground!;
        } else {
          final rawImage = useSmartImage
              ? ColoredBox(
                  color: imageBackgroundColor,
                  child: SmartImage(
                    photo,
                    key: imageKey,
                    width: double.infinity,
                    height: height,
                    fit: imageFit,
                    maxLogicalWidth: 960,
                    fallback: imageFallback,
                  ),
                )
              : Image.network(
                  photo,
                  key: imageKey,
                  fit: imageFit,
                  alignment: imageAlignment,
                  semanticLabel: imageSemanticLabel ?? title,
                  errorBuilder: (_, _, _) => imageFallback,
                );

          final semanticImage = useSmartImage
              ? Semantics(
                  image: true,
                  label: imageSemanticLabel ?? title,
                  child: rawImage,
                )
              : rawImage;

          mediaLayer = enableTapToZoom
              ? Semantics(
                  button: true,
                  label: '$zoomTooltip: ${imageSemanticLabel ?? title}',
                  child: Tooltip(
                    message: zoomTooltip,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        key: tapKey,
                        onTap: () => showProfilePhoto(context, photo),
                        child: semanticImage,
                      ),
                    ),
                  ),
                )
              : semanticImage;
        }

        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              mediaLayer,
              const IgnorePointer(
                child: DecoratedBox(
                  key: Key('heroHeaderGradientOverlay'),
                  decoration: BoxDecoration(gradient: bottomScrimGradient),
                ),
              ),
              if (topOverlay case final overlay?)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IgnorePointer(child: overlay),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: IgnorePointer(
                  child: _buildTitleBlock(context, overDarkScrim: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurfaceFallback(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTokens.midnightMid.withValues(alpha: 0.72)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return DecoratedBox(
      key: const Key('heroHeaderFallbackSurface'),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          if (topOverlay case final overlay?)
            Positioned(top: 0, left: 0, child: IgnorePointer(child: overlay)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: _buildTitleBlock(context, overDarkScrim: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context, {required bool overDarkScrim}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseTitleStyle = AppTokens.heroTitleStyle(context, compact: compact);
    final effectiveTitleStyle = overDarkScrim
        ? baseTitleStyle
        : baseTitleStyle.copyWith(
            color: AppTokens.primaryTextColor(context),
            shadows: isDark ? baseTitleStyle.shadows : const [],
          );
    final effectiveSubtitle = subtitle?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (categoryBadges.isNotEmpty || badges.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in categoryBadges)
                if (overDarkScrim)
                  _HeroScrimBadge(label: label)
                else
                  AppStatusBadge(label: label, tone: AppStatusTone.info),
              ...badges,
            ],
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: effectiveTitleStyle,
          ),
        ),
        if (effectiveSubtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            effectiveSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: overDarkScrim
                  ? AppTokens.primaryTextDark.withValues(alpha: 0.9)
                  : AppTokens.secondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (footer != null) footer!,
      ],
    );
  }
}

class _HeroScrimBadge extends StatelessWidget {
  const _HeroScrimBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTokens.primaryTextDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
