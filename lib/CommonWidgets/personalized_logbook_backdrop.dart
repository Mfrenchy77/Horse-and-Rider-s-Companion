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
            // Blur tuning (1/3): Lower maxLogicalWidth pre-softens the image
            // and routes through wsrv.nl (preferDirectFirst: false) so Web
            // renders in CanvasKit where BackdropFilter can blur it.
            maxLogicalWidth: 32,
            config: const SmartImageConfig(preferDirectFirst: false),
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
                        scale: 1.12,
                        child: ColorFiltered(
                          colorFilter: _desaturate,
                          child: photoWidget,
                        ),
                      ),
                      // Blur tuning (2/3): Stacked BackdropFilter passes
                      // (keep each sigma <= 30 so WebGL/CanvasKit does not
                      // clamp or skip the blur; add/remove passes to taste).
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: 28,
                            sigmaY: 28,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: 28,
                            sigmaY: 28,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      // Blur tuning (3/3): Midnight-teal atmospheric scrim
                      // controlling how much of the blurred photo shows
                      // through (higher alpha = darker/subtler).
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
