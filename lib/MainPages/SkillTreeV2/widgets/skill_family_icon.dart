import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Visual interaction state used to tint monochrome Skill Family artwork.
enum SkillFamilyIconState { normal, selected, disabled }

/// Bundled monochrome SVG asset lookup for Skill Family prototype
/// illustrations.
///
/// Artwork source files are pure black (`#000000`) on transparent backgrounds
/// and are dynamically tinted via [ColorFilter] at runtime so they adapt to
/// light/dark themes and selection states cleanly without duplicating assets.
class SkillFamilyIconAssets {
  const SkillFamilyIconAssets._();

  static const String dailyCareGrooming =
      'assets/icons/skill_families/daily_care_grooming.svg';
  static const String gaitsRhythmTransitions =
      'assets/icons/skill_families/gaits_rhythm_transitions.svg';
  static const String safetyHandling =
      'assets/icons/skill_families/safety_handling.svg';

  static const Map<String, String> byFamilyId = {
    'rider.husbandry.safety_handling': safetyHandling,
    'rider.husbandry.daily_care_grooming': dailyCareGrooming,
    'rider.mounted.gaits_rhythm_transitions': gaitsRhythmTransitions,
    'horse.mounted.gaits_rhythm_transitions': gaitsRhythmTransitions,
  };

  /// Resolves a bundled SVG asset path for [familyId], or `null` when the
  /// family uses a realm glyph fallback until Phase 3 artwork is generated.
  static String? assetForFamily(String familyId) => byFamilyId[familyId];
}

/// Renders a Skill Family's custom monochrome SVG illustration with dynamic
/// theme recoloring, falling back cleanly to [HorseAndRiderIcons] realm glyphs
/// for families awaiting Phase 3 illustrations.
class SkillFamilyIcon extends StatelessWidget {
  const SkillFamilyIcon({
    super.key,
    required this.familyId,
    this.fallbackRealm = SkillCategory.Other,
    this.size = 44,
    this.state = SkillFamilyIconState.normal,
    this.colorOverride,
    this.semanticLabel,
  });

  final String familyId;
  final SkillCategory fallbackRealm;
  final double size;
  final SkillFamilyIconState state;
  final Color? colorOverride;
  final String? semanticLabel;

  /// Resolves crisp accessible foreground tint for monochrome family icons.
  static Color resolveColor(
    BuildContext context, {
    SkillFamilyIconState state = SkillFamilyIconState.normal,
    Color? colorOverride,
  }) {
    if (colorOverride != null) return colorOverride;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return switch (state) {
      SkillFamilyIconState.disabled => theme.colorScheme.onSurface.withValues(
        alpha: 0.38,
      ),
      SkillFamilyIconState.selected =>
        isDark ? AppTokens.coralAccent : theme.colorScheme.primary,
      SkillFamilyIconState.normal =>
        isDark ? AppTokens.primaryTextDark : theme.colorScheme.onSurface,
    };
  }

  IconData _fallbackIconForRealm(SkillCategory realm) => switch (realm) {
    SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
    SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
    SkillCategory.Mounted => HorseAndRiderIcons.riding,
    _ => HorseAndRiderIcons.riderSkillIcon,
  };

  @override
  Widget build(BuildContext context) {
    final color = resolveColor(
      context,
      state: state,
      colorOverride: colorOverride,
    );
    final asset = SkillFamilyIconAssets.assetForFamily(familyId);
    if (asset == null) {
      return Icon(
        _fallbackIconForRealm(fallbackRealm),
        size: size * 0.78,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// Framed soft medallion container giving Skill Family artwork clear focal
/// hierarchy across light/dark surfaces and collapsed/expanded states.
class SkillFamilyIconBadge extends StatelessWidget {
  const SkillFamilyIconBadge({
    super.key,
    required this.familyId,
    this.fallbackRealm = SkillCategory.Other,
    this.badgeSize = 58,
    this.iconSize = 42,
    this.state = SkillFamilyIconState.normal,
    this.colorOverride,
    this.semanticLabel,
  });

  final String familyId;
  final SkillCategory fallbackRealm;
  final double badgeSize;
  final double iconSize;
  final SkillFamilyIconState state;
  final Color? colorOverride;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppTokens.coralAccent : theme.colorScheme.primary;
    final selected = state == SkillFamilyIconState.selected;
    final disabled = state == SkillFamilyIconState.disabled;

    final fillColor = selected
        ? accent.withValues(alpha: isDark ? 0.16 : 0.11)
        : (isDark
              ? AppTokens.midnightBase.withValues(alpha: disabled ? 0.45 : 0.78)
              : theme.colorScheme.surfaceContainerLow.withValues(
                  alpha: disabled ? 0.55 : 0.92,
                ));

    final borderColor = selected
        ? accent.withValues(alpha: 0.75)
        : (isDark
              ? AppTokens.cardBorderDark.withValues(
                  alpha: disabled ? 0.25 : 0.7,
                )
              : theme.dividerColor.withValues(alpha: disabled ? 0.18 : 0.38));

    return RepaintBoundary(
      child: Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: borderColor, width: selected ? 1.3 : 1),
        ),
        child: SkillFamilyIcon(
          familyId: familyId,
          fallbackRealm: fallbackRealm,
          size: iconSize,
          state: state,
          colorOverride: colorOverride,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
