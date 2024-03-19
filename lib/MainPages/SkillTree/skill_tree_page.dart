import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({super.key});
  static const path = '/SkillTree';
  static const name = 'SkillTree';

  static Page<void> page() => const MaterialPage<void>(child: SkillTreePage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SkillTreePage());
  }

  @override
  Widget build(BuildContext context) {
    return
        //  const NavigatorView(
        //   child:
        const SkillTreeView(
      key: Key('skillTreeView'),
      // ),
    );
  }
}
