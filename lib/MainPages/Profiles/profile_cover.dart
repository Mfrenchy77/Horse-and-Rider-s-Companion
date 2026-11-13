import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
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
    final photo = photoUrl?.trim() ?? '';
    final location = locationName?.trim() ?? '';
    final roleText = subtitle?.trim() ?? '';
    final fadeTarget = isDark
        ? ProfileTokens.midnightBase
        : Color.alphaBlend(
            theme.colorScheme.surface.withValues(alpha: .85),
            Colors.black,
          );

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

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final height = edgeToEdge
            ? (photo.isEmpty
                  ? (constraints.maxWidth * .61).clamp(220.0, 380.0)
                  : (constraints.maxWidth * .78).clamp(260.0, 380.0))
            : (constraints.maxWidth * .64).clamp(240.0, 370.0);
        return SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.isEmpty)
                fallback
              else
                Image.network(
                  photo,
                  key: photoKey,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  semanticLabel: 'Photo of $name',
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  frameBuilder: (context, child, frame, synchronouslyLoaded) {
                    if (frame == null) return child;
                    return Tooltip(
                      message: 'View full photo',
                      child: InkWell(
                        onTap: () => showProfilePhoto(context, photo),
                        child: child,
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => fallback,
                ),
              // Subtle edge-darkening vignette for atmospheric depth.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.15),
                      radius: 1.05,
                      colors: [Colors.transparent, Color(0x73051013)],
                      stops: [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // Smooth bottom gradient melting into the page background.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x28051013),
                        Colors.transparent,
                        fadeTarget.withValues(alpha: 0.72),
                        fadeTarget,
                      ],
                      stops: const [0.0, 0.28, 0.74, 1.0],
                    ),
                  ),
                ),
              ),
              if (ribbon case final coverRibbon?)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IgnorePointer(child: coverRibbon),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ProfileTokens.heroNameStyle(
                          context,
                          compact: edgeToEdge,
                        ),
                      ),
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
                                  color: ProfileTokens.primaryTextDark
                                      .withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (roleText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                  color: ProfileTokens.primaryTextDark
                                      .withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
