import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/example_skill.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';

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
          children: [
            ...ExampleSkill().getSkillLevels().map(
                  (e) => SkillLevelCard(
                    skillLevel: e,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
