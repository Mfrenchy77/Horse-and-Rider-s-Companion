import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/hero_header.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/profile_design_tokens.dart';

class ProfileCover extends StatelessWidget {
  const ProfileCover({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.locationName,
    required this.photoKey,
    this.status,
    this.subtitle,
    this.ribbon,
    this.edgeToEdge = false,
  });

  final String name;
  final String? photoUrl;
  final String? locationName;
  final Key photoKey;
  final String? status;
  final String? subtitle;
  final Widget? ribbon;
  final bool edgeToEdge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final location = locationName?.trim() ?? '';
    final roleText = subtitle?.trim() ?? '';

    final fallback = ColoredBox(
      color: isDark ? ProfileTokens.midnightMid : theme.colorScheme.surface,
      child: Align(
        alignment: const Alignment(0, -.38),
        child: FractionallySizedBox(
          widthFactor: .46,
          heightFactor: .58,
          child: Image.asset(
            'assets/horse_logo.png',
            fit: BoxFit.contain,
            color: isDark ? Colors.white.withValues(alpha: .72) : null,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );

    final hasFooter =
        status != null || location.isNotEmpty || roleText.isNotEmpty;

    final content = HeroHeader(
      title: name,
      imageUrl: photoUrl,
      imageKey: photoKey,
      imageAlignment: const Alignment(0, -0.2),
      imageSemanticLabel: 'Photo of $name',
      compact: edgeToEdge,
      topOverlay: ribbon,
      fallbackBackground: fallback,
      zoomTooltip: 'View full photo',
      heightBuilder: (maxWidth, {required hasImage}) => edgeToEdge
          ? (hasImage
                ? (maxWidth * .78).clamp(260.0, 380.0)
                : (maxWidth * .61).clamp(220.0, 380.0))
          : (maxWidth * .64).clamp(240.0, 370.0),
      footer: hasFooter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    status!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ProfileTokens.coralAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: ProfileTokens.primaryTextDark,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ProfileTokens.primaryTextDark.withValues(
                              alpha: 0.92,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (roleText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 18,
                        color: ProfileTokens.coralAccent.withValues(
                          alpha: 0.92,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          roleText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ProfileTokens.primaryTextDark.withValues(
                              alpha: 0.88,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            )
          : null,
    );

    if (edgeToEdge) {
      return content;
    }

    if (isDark) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProfileTokens.cardBorderDark),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: content,
        ),
      );
    }

    return GradientCard(margin: EdgeInsets.zero, child: content);
  }
}
