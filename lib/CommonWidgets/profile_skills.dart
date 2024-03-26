import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';

/// {@template profile_skills}
/// ProfileSkills widget displays the skills of the user or horse
/// {@endtemplate}
class ProfileSkills extends StatelessWidget {
  /// {@macro profile_skills}
  /// Displays the skills of the user or horse
  /// {@macro key}
  const ProfileSkills({super.key, required this.skillLevels});
  final List<SkillLevel>? skillLevels;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Wrap(
          spacing: 5,
          runSpacing: 5,
          alignment: WrapAlignment.center,
          children: [
            ...skillLevels
                    ?.map(
                      (e) => SkillLevelCard(
                        skillLevel: e,
                        onTap: state.isGuest
                            ? null
                            : () {
                                debugPrint('Goto Skill: ${e.skillName}');
                                context.goNamed(SkillTreePage.name);
                                cubit.navigateToSkillLevel(
                                  skill: state.allSkills.firstWhere(
                                    (element) =>
                                        element?.skillName == e.skillName,
                                  ),
                                );
                              },
                      ),
                    )
                    .toList() ??
                [const Text('No Skills')],
          ],
        );
      },
    );
  }
}
