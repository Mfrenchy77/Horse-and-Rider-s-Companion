import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Settings/feature_flags.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({super.key, this.forceV2});

  final bool? forceV2;

  static const path = '/SkillTree';
  static const name = 'SkillTree';

  @override
  Widget build(BuildContext context) {
    final useV2 =
        forceV2 ??
        SettingsControllerScope.maybeOf(context)?.skillTreeV2Enabled ??
        FeatureFlags.kSkillTreeV2Default;
    if (useV2) {
      return const SkillTreeV2View(key: Key('skillTreeV2PageView'));
    }
    return const SkillTreeView(
      key: Key('skillTreeView'),
    );
  }
}
