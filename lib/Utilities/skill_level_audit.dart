import 'package:database_repository/database_repository.dart';

/// Result of evaluating a profile's skill levels against the live skill
/// catalog.
class SkillLevelAuditResult {
  const SkillLevelAuditResult({
    required this.validLevels,
    required this.deprecatedLevels,
    required this.isCatalogReady,
  });

  /// Skill levels that still map to a skill in the current catalog.
  final List<SkillLevel> validLevels;

  /// Skill levels pointing to a skill that no longer exists.
  final List<SkillLevel> deprecatedLevels;

  /// Whether the catalog snapshot contained at least one skill, indicating
  /// that the audit ran against real data instead of an empty placeholder.
  final bool isCatalogReady;
}

/// Utility helpers for auditing stored skill levels against the live catalog.
class SkillLevelAudit {
  const SkillLevelAudit._();

  /// Splits [profileSkillLevels] into valid and deprecated entries based on
  /// whether their `skillId` exists inside [allSkills].
  static SkillLevelAuditResult evaluate({
    required List<SkillLevel>? profileSkillLevels,
    required List<Skill?> allSkills,
  }) {
    final catalog = allSkills.whereType<Skill>().toList();
    final isCatalogReady = catalog.isNotEmpty;
    final levels = List<SkillLevel>.from(profileSkillLevels ?? const []);

    if (!isCatalogReady) {
      return SkillLevelAuditResult(
        validLevels: levels,
        deprecatedLevels: const [],
        isCatalogReady: false,
      );
    }

    final knownIds = catalog.map((skill) => skill.id).toSet();
    final valid = <SkillLevel>[];
    final deprecated = <SkillLevel>[];
    for (final level in levels) {
      if (knownIds.contains(level.skillId)) {
        valid.add(level);
      } else {
        deprecated.add(level);
      }
    }

    return SkillLevelAuditResult(
      validLevels: List.unmodifiable(valid),
      deprecatedLevels: List.unmodifiable(deprecated),
      isCatalogReady: true,
    );
  }
}
