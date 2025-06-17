import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/example_skill.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';

class GuestProfileSkills extends StatelessWidget {
  const GuestProfileSkills({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                    hasUnmetPrerequisites: true,
                    category: SkillCategory.In_Hand,
                    difficulty: DifficultyState.Intermediate,
                    onTap: () => context.read<AppCubit>().changeIndex(1),
                    skillLevel: e,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
