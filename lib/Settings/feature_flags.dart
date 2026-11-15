/// Compile-time feature flags for staged rollouts.
class FeatureFlags {
  const FeatureFlags._();

  /// Enables Skill Tree 2.0 by default for production release.
  /// Pass `--dart-define=SKILL_TREE_V2=false` as an emergency rollback flag
  /// to revert to the legacy Skill Tree.
  static const bool kSkillTreeV2Default = bool.fromEnvironment(
    'SKILL_TREE_V2',
    defaultValue: true,
  );
}
