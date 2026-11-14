import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Cinematic blurred photographic backdrop for Rider and Horse logbooks.
///
/// Renders a single pre-blurred decorative layer of the rider or horse photo
/// behind the entire scrollable logbook, tinted with a midnight-teal overlay
/// so translucent entry cards reveal subtle atmospheric variation without
/// per-card backdrop blur costs.
class PersonalizedLogbookBackdrop extends StatelessWidget {
  const PersonalizedLogbookBackdrop({
    super.key,
    required this.child,
    this.photoUrl,
    this.imageProvider,
  });

  final Widget child;
  final String? photoUrl;
  final ImageProvider? imageProvider;

  // Gentle desaturation matrix (~65% saturation) so bright photo highlights
  // add atmospheric depth without competing with foreground text.
  static const _desaturate = ui.ColorFilter.matrix(<double>[
    0.72, 0.21, 0.07, 0, 0,
    0.14, 0.79, 0.07, 0, 0,
    0.14, 0.21, 0.65, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUrl = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final hasImage = imageProvider != null || hasUrl;

    if (!isDark || !hasImage) {
      return AppScaffoldBackdrop(child: child);
    }

    final photoWidget = imageProvider != null
        ? Image(
            image: imageProvider!,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : SmartImage(
            photoUrl,
            maxLogicalWidth: 400,
            fallback: const SizedBox.shrink(),
          );

    return AppScaffoldBackdrop(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: 1.08,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 72,
                            sigmaY: 72,
                            tileMode: TileMode.mirror,
                          ),
                          child: ColorFiltered(
                            colorFilter: _desaturate,
                            child: photoWidget,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTokens.midnightBase.withValues(alpha: 0.78),
                              AppTokens.midnightMid.withValues(alpha: 0.74),
                              AppTokens.midnightDeep.withValues(alpha: 0.86),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
