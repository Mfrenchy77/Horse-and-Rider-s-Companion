/// Compile-time feature flags for staged rollouts.
class FeatureFlags {
  const FeatureFlags._();

  /// Enables Skill Tree 2.0 when `--dart-define=SKILL_TREE_V2=true` is passed.
  /// Defaults to `false` so production retains the legacy Skill Tree until
  /// Phase 3 review and backend rollout are complete.
  static const bool kSkillTreeV2Default = bool.fromEnvironment(
    'SKILL_TREE_V2',
  );
}
