import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Settings/feature_flags.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({
    super.key,
    this.forceV2,
    this.initialSkillId,
    this.initialLevel,
  });

  final bool? forceV2;
  final String? initialSkillId;
  final DifficultyState? initialLevel;

  static const path = '/SkillTree';
  static const name = 'SkillTree';

  @override
  Widget build(BuildContext context) {
    final useV2 =
        forceV2 ??
        SettingsControllerScope.maybeOf(context)?.skillTreeV2Enabled ??
        FeatureFlags.kSkillTreeV2Default;
    if (useV2) {
      return SkillTreeV2View(
        key: const Key('skillTreeV2PageView'),
        initialSkillId: initialSkillId,
        initialLevel: initialLevel,
      );
    }
    return SkillTreeView(
      key: const Key('skillTreeView'),
      skillId: initialSkillId,
    );
  }
}
