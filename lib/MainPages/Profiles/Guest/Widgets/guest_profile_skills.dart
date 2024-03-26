import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/CommonWidgets/example_skill.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';

class GuestProfileSkills extends StatelessWidget {
  const GuestProfileSkills({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: Text(
            'This is where the skills that you are working on and '
            'proficent in will be displayed.  If a trainer or '
            'instructor has verified the skill, '
            'it will marked as such and in yellow.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        gap(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: [
            ...ExampleSkill().getSkillLevels().map(
                  (e) => SkillLevelCard(
                    onTap: () => context.goNamed(SkillTreePage.name),
                    skillLevel: e,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
