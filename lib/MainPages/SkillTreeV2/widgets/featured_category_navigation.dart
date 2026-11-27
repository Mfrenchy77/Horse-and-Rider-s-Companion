import 'dart:ui' show lerpDouble;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_category_illustration.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/classic_blue_gray.dart';

/// Animated, illustrated primary-category navigation for Skill Tree.
///
/// Displays the active category as an atmospheric featured banner with a warm
/// internal coral-peach glow and subtle landscape horizon contours, while the
/// remaining categories appear as understated monochrome tiles. Tapping any
/// unselected tile smoothly exchanges physical positions, scales the
/// illustration, and transfers the internal glow across 350–450 ms without any
/// additional Firebase reads or expensive blur filters.
class FeaturedCategoryNavigation extends StatelessWidget {
  const FeaturedCategoryNavigation({
    super.key,
    required this.subject,
    required this.availableRealms,
    required this.selectedRealm,
    required this.familyCountsByRealm,
    required this.onSelectRealm,
    this.isSearching = false,
  });

  final SkillSubject subject;
  final List<SkillCategory> availableRealms;
  final SkillCategory selectedRealm;
  final Map<SkillCategory, int> familyCountsByRealm;
  final ValueChanged<SkillCategory> onSelectRealm;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    if (availableRealms.isEmpty) return const SizedBox.shrink();

    final effectiveSelected = availableRealms.contains(selectedRealm)
        ? selectedRealm
        : availableRealms.first;
    final unselectedRealms = [
      for (final realm in availableRealms)
        if (realm != effectiveSelected) realm,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isDesktopRibbon = maxWidth >= 820;
        final otherCount = unselectedRealms.length;
        final slotRects = <SkillCategory, Rect>{};
        late final double totalHeight;

        if (isDesktopRibbon) {
          const gap = 12.0;
          const cardHeight = 118.0;
          final featuredFraction = otherCount <= 1 ? 0.58 : 0.43;
          final featuredWidth = otherCount == 0
              ? maxWidth
              : (maxWidth - gap) * featuredFraction;
          slotRects[effectiveSelected] = Rect.fromLTWH(
            0,
            0,
            featuredWidth,
            cardHeight,
          );
          if (otherCount > 0) {
            final remainingWidth = maxWidth - featuredWidth - gap;
            final tileWidth =
                (remainingWidth - gap * (otherCount - 1)) / otherCount;
            for (var i = 0; i < otherCount; i++) {
              slotRects[unselectedRealms[i]] = Rect.fromLTWH(
                featuredWidth + gap + i * (tileWidth + gap),
                0,
                tileWidth,
                cardHeight,
              );
            }
          }
          totalHeight = cardHeight;
        } else {
          final gap = maxWidth < 480 ? 10.0 : 12.0;
          final featuredHeight = maxWidth < 360
              ? 136.0
              : (maxWidth < 520 ? 148.0 : 168.0);
          final tileHeight = otherCount == 1
              ? (maxWidth < 520 ? 66.0 : 74.0)
              : (maxWidth < 360 ? 78.0 : (maxWidth < 520 ? 84.0 : 92.0));

          slotRects[effectiveSelected] = Rect.fromLTWH(
            0,
            0,
            maxWidth,
            featuredHeight,
          );
          if (otherCount > 0) {
            final tileWidth = (maxWidth - gap * (otherCount - 1)) / otherCount;
            for (var i = 0; i < otherCount; i++) {
              slotRects[unselectedRealms[i]] = Rect.fromLTWH(
                i * (tileWidth + gap),
                featuredHeight + gap,
                tileWidth,
                tileHeight,
              );
            }
          }
          totalHeight =
              featuredHeight + (otherCount > 0 ? gap + tileHeight : 0);
        }

        // Paint unselected cards first and the active featured card last so the
        // promoted category smoothly glides on top of shifting neighbors.
        final renderOrder = [...unselectedRealms, effectiveSelected];
        final moveDuration = AppTokens.motionDuration(
          context,
          const Duration(milliseconds: 400),
        );

        return SizedBox(
          width: maxWidth,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final realm in renderOrder)
                AnimatedPositioned(
                  key: ValueKey('categorySlot_${subject.name}_${realm.name}'),
                  duration: moveDuration,
                  curve: Curves.easeInOutCubic,
                  left: slotRects[realm]!.left,
                  top: slotRects[realm]!.top,
                  width: slotRects[realm]!.width,
                  height: slotRects[realm]!.height,
                  child: _AnimatedCategoryCard(
                    subject: subject,
                    realm: realm,
                    label: realmDisplayLabel(realm),
                    familyCount: familyCountsByRealm[realm] ?? 0,
                    isFeatured: realm == effectiveSelected,
                    isSearching: isSearching,
                    onTap: () => onSelectRealm(realm),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedCategoryCard extends StatefulWidget {
  const _AnimatedCategoryCard({
    required this.subject,
    required this.realm,
    required this.label,
    required this.familyCount,
    required this.isFeatured,
    required this.isSearching,
    required this.onTap,
  });

  final SkillSubject subject;
  final SkillCategory realm;
  final String label;
  final int familyCount;
  final bool isFeatured;
  final bool isSearching;
  final VoidCallback onTap;

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: widget.isFeatured ? 1.0 : 0.0,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(covariant _AnimatedCategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final target = widget.isFeatured ? 1.0 : 0.0;
    if (reducedMotion) {
      _controller.value = target;
      return;
    }
    if (widget.isFeatured != oldWidget.isFeatured) {
      if (widget.isFeatured) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.isFeatured ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final countText =
        '${widget.familyCount} '
        '${widget.familyCount == 1 ? 'family' : 'families'}';
    final selectedSemantic = widget.isFeatured && !widget.isSearching;

    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final t = _curved.value;
        final glowStrength = t * (widget.isSearching ? 0.52 : 1.0);
        final radius = BorderRadius.circular(lerpDouble(13, 18, t)!);
        final borderColor = isDark
            ? Color.lerp(
                AppTokens.cardBorderDark,
                AppTokens.coralAccent.withValues(
                  alpha: widget.isSearching ? 0.45 : 0.78,
                ),
                t,
              )!
            : Color.lerp(
                ClassicBlueGray.outline,
                ClassicBlueGray.coral.withValues(
                  alpha: widget.isSearching ? 0.45 : 0.78,
                ),
                t,
              )!;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: isDark
                ? _buildDarkBaseGradient(t)
                : _buildLightBaseGradient(t),
            border: Border.all(
              color: borderColor,
              width: lerpDouble(1.0, 1.45, t)!,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  0,
                  0,
                  0,
                  isDark
                      ? lerpDouble(0.18, 0.36, t)!
                      : lerpDouble(0.06, 0.14, t)!,
                ),
                blurRadius: lerpDouble(8, 20, t)!,
                offset: Offset(0, lerpDouble(2, 7, t)!),
              ),
              if (glowStrength > 0.02)
                BoxShadow(
                  color:
                      (isDark ? AppTokens.coralAccent : ClassicBlueGray.coral)
                          .withValues(alpha: 0.14 * glowStrength),
                  blurRadius: 18 * glowStrength,
                  spreadRadius: 0.5 * glowStrength,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (glowStrength > 0.01)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? _buildDarkGlowGradient(glowStrength)
                          : _buildLightGlowGradient(glowStrength),
                    ),
                  ),
                if (t > 0.02)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AtmosphericHorizonPainter(
                        progress: t,
                        isDark: isDark,
                      ),
                    ),
                  ),
                if (glowStrength > 0.05)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          (isDark
                                  ? AppTokens.coralAccent
                                  : ClassicBlueGray.coral)
                              .withValues(alpha: 0.10 * glowStrength),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.48],
                      ),
                    ),
                  ),
                Material(
                  type: MaterialType.transparency,
                  child: Semantics(
                    button: true,
                    selected: selectedSemantic,
                    label: '${widget.label}, $countText',
                    child: InkWell(
                      key: Key('skillTreeV2Realm_${widget.realm.name}'),
                      borderRadius: radius,
                      onTap: widget.onTap,
                      splashColor:
                          (isDark
                                  ? AppTokens.coralAccent
                                  : ClassicBlueGray.coral)
                              .withValues(alpha: 0.16),
                      highlightColor:
                          (isDark
                                  ? AppTokens.coralAccent
                                  : ClassicBlueGray.coral)
                              .withValues(alpha: 0.08),
                      child: LayoutBuilder(
                        builder: (context, cardConstraints) => _buildInterior(
                          context,
                          cardWidth: cardConstraints.maxWidth,
                          cardHeight: cardConstraints.maxHeight,
                          t: t,
                          isDark: isDark,
                          countText: countText,
                        ),
                      ),
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

  Widget _buildInterior(
    BuildContext context, {
    required double cardWidth,
    required double cardHeight,
    required double t,
    required bool isDark,
    required String countText,
  }) {
    final compactHorizontal = cardWidth / cardHeight > 2.25;
    final compactPad = cardWidth < 120 ? 6.0 : 10.0;

    // Compact geometry (t == 0)
    final double compactArtLeft;
    final double compactArtTop;
    final double compactArtW;
    final double compactArtH;
    final double compactTextLeft;
    final double compactTextTop;
    final double compactTextW;
    final double compactTextH;

    if (compactHorizontal) {
      compactArtW = (cardWidth * 0.34).clamp(64.0, 140.0);
      compactArtH = (cardHeight - 14).clamp(32.0, 62.0);
      compactArtLeft = cardWidth - compactArtW - 14;
      compactArtTop = (cardHeight - compactArtH) * 0.5;
      compactTextLeft = 16.0;
      compactTextTop = 8.0;
      compactTextW = (compactArtLeft - compactTextLeft - 10).clamp(48.0, 260.0);
      compactTextH = cardHeight - 16;
    } else {
      compactArtW = (cardWidth - compactPad * 2).clamp(24.0, 160.0);
      compactArtH = (cardHeight * 0.46).clamp(24.0, 62.0);
      compactArtLeft = (cardWidth - compactArtW) * 0.5;
      compactArtTop = cardHeight < 86 ? 6.0 : 8.0;
      compactTextLeft = compactPad;
      compactTextTop = compactArtTop + compactArtH + 2;
      compactTextW = (cardWidth - compactPad * 2).clamp(24.0, 240.0);
      compactTextH = (cardHeight - compactTextTop - 4).clamp(18.0, 44.0);
    }

    // Featured geometry (t == 1)
    final featPadH = cardWidth < 360 ? 14.0 : 20.0;
    final featPadV = cardHeight < 130 ? 10.0 : 14.0;
    final featuredTextW = (cardWidth * 0.43).clamp(96.0, 240.0);
    final featuredTextH = (cardHeight - featPadV * 2).clamp(48.0, 140.0);
    final featuredTextLeft = featPadH;
    final featuredTextTop = featPadV;

    final featuredArtLeft = (featPadH + featuredTextW - 6).clamp(
      cardWidth * 0.38,
      cardWidth * 0.46,
    );
    final featuredArtW = (cardWidth - featuredArtLeft - 10).clamp(64.0, 360.0);
    final featuredArtH = (cardHeight - 14).clamp(56.0, 152.0);
    final featuredArtTop = (cardHeight - featuredArtH) * 0.56;

    // Interpolated slot coordinates
    final artLeft = lerpDouble(compactArtLeft, featuredArtLeft, t)!;
    final artTop = lerpDouble(compactArtTop, featuredArtTop, t)!;
    final artW = lerpDouble(compactArtW, featuredArtW, t)!;
    final artH = lerpDouble(compactArtH, featuredArtH, t)!;

    final textLeft = lerpDouble(compactTextLeft, featuredTextLeft, t)!;
    final textTop = lerpDouble(compactTextTop, featuredTextTop, t)!;
    final textW = lerpDouble(compactTextW, featuredTextW, t)!;
    final textH = lerpDouble(compactTextH, featuredTextH, t)!;

    final artColor = isDark
        ? Color.lerp(
            const Color(0xFFD5E4E6).withValues(alpha: 0.84),
            const Color(0xFF07181C),
            t,
          )!
        : Color.lerp(ClassicBlueGray.muted, const Color(0xFF173036), t)!;

    final compactStyle = TextStyle(
      fontFamily: Theme.of(context).textTheme.titleSmall?.fontFamily,
      fontSize: cardWidth < 110 ? 11.0 : 12.2,
      fontWeight: FontWeight.w600,
      height: 1.12,
      letterSpacing: 0.1,
      color: isDark ? const Color(0xFFE4EDEE) : ClassicBlueGray.ink,
    );
    final featuredFontSize = cardWidth < 360
        ? 19.0
        : (cardHeight < 130 ? 20.5 : 23.0);
    final featuredStyle = TextStyle(
      fontFamily: AppTokens.serifFont,
      fontFamilyFallback: AppTokens.serifFallback,
      fontSize: featuredFontSize,
      fontWeight: FontWeight.w600,
      height: 1.10,
      letterSpacing: 0.2,
      color: isDark ? const Color(0xFFF7F1EB) : const Color(0xFF162F35),
      shadows: isDark
          ? const [
              Shadow(
                color: Color(0x88000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ]
          : null,
    );
    final labelStyle = TextStyle.lerp(compactStyle, featuredStyle, t)!;
    final textAlign = t > 0.5 || compactHorizontal
        ? TextAlign.left
        : TextAlign.center;
    final alignment = Alignment.lerp(
      compactHorizontal ? Alignment.centerLeft : Alignment.topCenter,
      Alignment.centerLeft,
      t,
    )!;
    final subtitleFactor = ((t - 0.55) / 0.45).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: artLeft,
          top: artTop,
          width: artW,
          height: artH,
          child: IgnorePointer(
            child: SkillCategoryIllustration(
              subject: widget.subject,
              realm: widget.realm,
              color: artColor,
              width: artW,
              height: artH,
            ),
          ),
        ),
        Positioned(
          left: textLeft,
          top: textTop,
          width: textW,
          height: textH,
          child: Align(
            alignment: alignment,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: t > 0.5 || compactHorizontal
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: textAlign,
                  style: labelStyle,
                ),
                if (subtitleFactor > 0.01)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      heightFactor: subtitleFactor,
                      child: Opacity(
                        opacity: subtitleFactor,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            countText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: isDark
                                  ? const Color(0xFFF2C2B2)
                                  : ClassicBlueGray.selectedInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _buildDarkBaseGradient(double t) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF17343A), const Color(0xFF11292E), t)!,
        Color.lerp(const Color(0xFF0E2328), const Color(0xFF0A1D21), t)!,
        Color.lerp(const Color(0xFF0A1C20), const Color(0xFF061317), t)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  LinearGradient _buildLightBaseGradient(double t) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(ClassicBlueGray.surface, const Color(0xFFDDEAF0), t)!,
        Color.lerp(ClassicBlueGray.surfaceHigh, const Color(0xFFCEE0E9), t)!,
        Color.lerp(ClassicBlueGray.surfaceHighest, const Color(0xFFBBD1DC), t)!,
      ],
      stops: const [0.0, 0.52, 1.0],
    );
  }

  RadialGradient _buildDarkGlowGradient(double strength) {
    return RadialGradient(
      center: const Alignment(0.32, 0.08),
      radius: 0.92,
      stops: const [0.0, 0.34, 0.66, 1.0],
      colors: [
        const Color(0xFFF8B49B).withValues(alpha: 0.86 * strength),
        const Color(0xFFEC8E74).withValues(alpha: 0.58 * strength),
        const Color(0xFF694542).withValues(alpha: 0.30 * strength),
        const Color(0xFF0A1D21).withValues(alpha: 0),
      ],
    );
  }

  RadialGradient _buildLightGlowGradient(double strength) {
    return RadialGradient(
      center: const Alignment(0.32, 0.08),
      radius: 0.96,
      stops: const [0.0, 0.36, 0.70, 1.0],
      colors: [
        const Color(0xFFF7C3AE).withValues(alpha: 0.84 * strength),
        const Color(0xFFEDA38D).withValues(alpha: 0.52 * strength),
        const Color(0xFFDECAC4).withValues(alpha: 0.24 * strength),
        const Color(0xFFD5E4EC).withValues(alpha: 0),
      ],
    );
  }
}

class _AtmosphericHorizonPainter extends CustomPainter {
  const _AtmosphericHorizonPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01 || size.isEmpty) return;

    final backColor = isDark
        ? const Color(0xFF0B2025).withValues(alpha: 0.62 * progress)
        : const Color(0xFF4F6E79).withValues(alpha: 0.14 * progress);
    final frontColor = isDark
        ? const Color(0xFF061519).withValues(alpha: 0.86 * progress)
        : const Color(0xFF334E57).withValues(alpha: 0.20 * progress);

    final backPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.60,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.76,
        size.width,
        size.height * 0.66,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final frontPath = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.74,
        size.width * 0.74,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.86,
        size.width,
        size.height * 0.81,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..drawPath(backPath, Paint()..color = backColor)
      ..drawPath(frontPath, Paint()..color = frontColor);
  }

  @override
  bool shouldRepaint(covariant _AtmosphericHorizonPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
