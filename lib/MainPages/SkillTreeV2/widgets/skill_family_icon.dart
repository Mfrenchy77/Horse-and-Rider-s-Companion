import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Visual interaction state used to tint monochrome Skill Family artwork.
enum SkillFamilyIconState { normal, selected, disabled }

/// Bundled monochrome SVG asset lookup for Skill Family illustrations.
///
/// Artwork source files are pure black (`#000000`) on transparent backgrounds
/// and are dynamically tinted via [ColorFilter] at runtime so they adapt to
/// light/dark themes and selection states cleanly without duplicating assets.
class SkillFamilyIconAssets {
  const SkillFamilyIconAssets._();

  static const String safetyHandling =
      'assets/icons/skill_families/safety_handling.svg';
  static const String dailyCareGrooming =
      'assets/icons/skill_families/daily_care_grooming.svg';
  static const String healthFirstAid =
      'assets/icons/skill_families/health_first_aid.svg';
  static const String feedingStable =
      'assets/icons/skill_families/feeding_stable.svg';
  static const String tackEquipment =
      'assets/icons/skill_families/tack_equipment.svg';
  static const String halteringLeading =
      'assets/icons/skill_families/haltering_leading.svg';
  static const String groundControlYielding =
      'assets/icons/skill_families/ground_control_yielding.svg';
  static const String longeingLongLining =
      'assets/icons/skill_families/longeing_long_lining.svg';
  static const String obstaclesOutingsTravel =
      'assets/icons/skill_families/obstacles_outings_travel.svg';
  static const String positionBalanceSafety =
      'assets/icons/skill_families/position_balance_safety.svg';
  static const String standingMountingManners =
      'assets/icons/skill_families/standing_mounting_manners.svg';
  static const String gaitsRhythmTransitions =
      'assets/icons/skill_families/gaits_rhythm_transitions.svg';
  static const String steeringBendDirection =
      'assets/icons/skill_families/steering_bend_direction.svg';
  static const String pivotsBodyControl =
      'assets/icons/skill_families/pivots_body_control.svg';
  static const String lateralMovements =
      'assets/icons/skill_families/lateral_movements.svg';
  static const String terrainObstacles =
      'assets/icons/skill_families/terrain_obstacles.svg';
  static const String objectHandling =
      'assets/icons/skill_families/object_handling.svg';
  static const String trainingPrinciples =
      'assets/icons/skill_families/training_principles.svg';
  static const String equineLearning =
      'assets/icons/skill_families/equine_learning.svg';
  static const String equineBiomechanics =
      'assets/icons/skill_families/equine_biomechanics.svg';
  static const String horseBehaviorWelfare =
      'assets/icons/skill_families/horse_behavior_welfare.svg';
  static const String riderKnowledgeEquipment =
      'assets/icons/skill_families/rider_knowledge_equipment.svg';
  static const String leadingGroundManners =
      'assets/icons/skill_families/leading_ground_manners.svg';
  static const String handlingCooperativeCare =
      'assets/icons/skill_families/handling_cooperative_care.svg';
  static const String travelEnvironments =
      'assets/icons/skill_families/travel_environments.svg';
  static const String workOnLine =
      'assets/icons/skill_families/work_on_line.svg';

  /// Maps all 33 Skill Tree 2.0 curriculum families to the 26 bundled SVGs
  /// (the 6 shared Mounted families plus Ground Control & Yielding share
  /// artwork across Rider and Horse).
  static const Map<String, String> byFamilyId = {
    'rider.husbandry.safety_handling': safetyHandling,
    'rider.husbandry.daily_care_grooming': dailyCareGrooming,
    'rider.husbandry.health_first_aid': healthFirstAid,
    'rider.husbandry.feeding_stable': feedingStable,
    'rider.husbandry.tack_equipment': tackEquipment,
    'rider.in_hand.haltering_leading': halteringLeading,
    'rider.in_hand.ground_control_yielding': groundControlYielding,
    'rider.in_hand.longeing_long_lining': longeingLongLining,
    'rider.in_hand.obstacles_outings_travel': obstaclesOutingsTravel,
    'rider.mounted.position_balance_safety': positionBalanceSafety,
    'rider.mounted.gaits_rhythm_transitions': gaitsRhythmTransitions,
    'rider.mounted.steering_bend_direction': steeringBendDirection,
    'rider.mounted.pivots_body_control': pivotsBodyControl,
    'rider.mounted.lateral_movements': lateralMovements,
    'rider.mounted.terrain_obstacles': terrainObstacles,
    'rider.mounted.object_handling': objectHandling,
    'rider.theory.training_principles': trainingPrinciples,
    'rider.theory.learning': equineLearning,
    'rider.theory.movement_training': equineBiomechanics,
    'rider.theory.behavior': horseBehaviorWelfare,
    'rider.theory.rider_equipment': riderKnowledgeEquipment,
    'horse.in_hand.leading_manners': leadingGroundManners,
    'horse.in_hand.ground_control_yielding': groundControlYielding,
    'horse.in_hand.cooperative_care': handlingCooperativeCare,
    'horse.in_hand.travel_environments': travelEnvironments,
    'horse.in_hand.work_on_line': workOnLine,
    'horse.mounted.standing_mounting_manners': standingMountingManners,
    'horse.mounted.gaits_rhythm_transitions': gaitsRhythmTransitions,
    'horse.mounted.steering_bend_direction': steeringBendDirection,
    'horse.mounted.pivots_body_control': pivotsBodyControl,
    'horse.mounted.lateral_movements': lateralMovements,
    'horse.mounted.terrain_obstacles': terrainObstacles,
    'horse.mounted.object_handling': objectHandling,
  };

  /// Resolves a bundled SVG asset path for [familyId], or `null` when a
  /// dynamically added custom family falls back to a realm glyph.
  static String? assetForFamily(String familyId) => byFamilyId[familyId];
}

/// Renders a Skill Family's custom monochrome SVG illustration with dynamic
/// theme recoloring, falling back cleanly to [HorseAndRiderIcons] realm glyphs
/// only for unrecognized custom family IDs.
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
