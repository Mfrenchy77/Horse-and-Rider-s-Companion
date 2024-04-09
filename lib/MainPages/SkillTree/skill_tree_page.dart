import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({super.key});
  static const path = '/SkillTree';
  static const name = 'SkillTree';

  @override
  Widget build(BuildContext context) {
    return const SkillTreeView(
      key: Key('skillTreeView'),
    );
  }
}
