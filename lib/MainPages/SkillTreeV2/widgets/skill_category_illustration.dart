import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Bundled monochrome landscape SVG illustrations for primary Skill Tree
/// categories across Rider and Horse views.
///
/// All assets are pure `#000000` vector paths (`viewBox="0 0 384 224"`) on
/// transparent backgrounds, dynamically recolored at runtime by Flutter via
/// [ColorFilter] so light/dark themes and featured-glow transitions never
/// require duplicated artwork.
///
/// Note on taxonomy alignment:
/// - Rider currently exposes 4 curriculum categories (`Husbandry`, `In-Hand`,
///   `Mounted`, `Theory & Knowledge`), mapped 1:1 to [riderHusbandry],
///   [riderInHand], [riderMounted], and [riderTheoryKnowledge].
/// - Horse currently exposes 2 curriculum categories (`In-Hand`, `Mounted`),
///   mapped to [horseInHand] and [horseMounted].
/// - The remaining two complementary Horse illustrations
///   ([horseCareWellbeing] and [horsePartnershipConfidence]) are bundled for
///   reuse in Horse Profile wellness summaries, Training Logbook milestones, or
///   future Horse Skill Tree category expansions without inventing unbacked
///   Skill Tree categories.
class SkillCategoryIllustrationAssets {
  const SkillCategoryIllustrationAssets._();

  static const String riderHusbandry =
      'assets/icons/skill_categories/rider_husbandry.svg';
  static const String riderInHand =
      'assets/icons/skill_categories/rider_in_hand.svg';
  static const String riderMounted =
      'assets/icons/skill_categories/rider_mounted.svg';
  static const String riderTheoryKnowledge =
      'assets/icons/skill_categories/rider_theory_knowledge.svg';

  static const String horseInHand =
      'assets/icons/skill_categories/horse_in_hand.svg';
  static const String horseMounted =
      'assets/icons/skill_categories/horse_mounted.svg';
  static const String horseCareWellbeing =
      'assets/icons/skill_categories/horse_care_wellbeing.svg';
  static const String horsePartnershipConfidence =
      'assets/icons/skill_categories/horse_partnership_confidence.svg';

  /// Logical design-canvas aspect ratio matching every category SVG
  /// (`viewBox="0 0 384 224"`).
  static const double aspectRatio = 384 / 224;

  static const List<String> allAssets = [
    riderHusbandry,
    riderInHand,
    riderMounted,
    riderTheoryKnowledge,
    horseInHand,
    horseMounted,
    horseCareWellbeing,
    horsePartnershipConfidence,
  ];

  /// Resolves the category illustration asset for [subject] and [realm].
  static String? assetFor({
    required SkillSubject subject,
    required SkillCategory realm,
  }) {
    if (subject == SkillSubject.horse) {
      return switch (realm) {
        SkillCategory.In_Hand => horseInHand,
        SkillCategory.Mounted => horseMounted,
        SkillCategory.Husbandry => horseCareWellbeing,
        SkillCategory.Other => horsePartnershipConfidence,
      };
    }
    return switch (realm) {
      SkillCategory.Husbandry => riderHusbandry,
      SkillCategory.In_Hand => riderInHand,
      SkillCategory.Mounted => riderMounted,
      SkillCategory.Other => riderTheoryKnowledge,
    };
  }
}

/// Renders a bundled monochrome category silhouette dynamically tinted to
/// [color] with an isolated [RepaintBoundary] to keep animations and scrolling
/// inexpensive across mobile and Flutter Web Wasm.
class SkillCategoryIllustration extends StatelessWidget {
  const SkillCategoryIllustration({
    super.key,
    required this.subject,
    required this.realm,
    required this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.assetOverride,
  });

  final SkillSubject subject;
  final SkillCategory realm;
  final Color color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final String? assetOverride;

  IconData _fallbackIcon() => switch (realm) {
    SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
    SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
    SkillCategory.Mounted => HorseAndRiderIcons.riding,
    SkillCategory.Other =>
      subject == SkillSubject.horse
          ? HorseAndRiderIcons.horseIcon
          : HorseAndRiderIcons.riderSkillIcon,
  };

  @override
  Widget build(BuildContext context) {
    final asset =
        assetOverride ??
        SkillCategoryIllustrationAssets.assetFor(
          subject: subject,
          realm: realm,
        );
    if (asset == null) {
      return Icon(
        _fallbackIcon(),
        size: (height ?? width ?? 48) * 0.72,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    return RepaintBoundary(
      child: SvgPicture.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        semanticsLabel: semanticLabel,
      ),
    );
  }
}
