import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';

/// {@template profile_skills}
/// ProfileSkills widget displays the skills of the user or horse
/// {@endtemplate}
class ProfileSkills extends StatelessWidget {
  /// {@macro profile_skills}
  /// Displays the skills of the user or horse
  /// {@macro key}
  const ProfileSkills({
    super.key,
    required this.skillLevels,
  });
  final List<SkillLevel>? skillLevels;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final audit = SkillLevelAudit.evaluate(
          profileSkillLevels: skillLevels,
          allSkills: state.allSkills,
        );

        if (!audit.isCatalogReady) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final visibleLevels = audit.validLevels;
        final children = visibleLevels.isEmpty
            ? <Widget>[const Text('No Skills')]
            : visibleLevels
                .map(
                  (e) => SkillLevelCard(
                    hasUnmetPrerequisites:
                        cubit.hasUnmetPrerequisites(e.skillId),
                    category: cubit.getSkillCategory(e.skillId),
                    difficulty: cubit.getDifficulty(e.skillId),
                    skillLevel: e,
                    onTap: state.isGuest
                        ? null
                        : () {
                            debugPrint('Goto Skill: ${e.skillName}');

                            context.pushNamed(
                              SkillTreeView.skillLevelName,
                              pathParameters: {
                                SkillTreeView.skillPathParam: e.skillId,
                              },
                            );
                          },
                  ),
                )
                .toList();

        return Wrap(
          spacing: 5,
          runSpacing: 5,
          alignment: WrapAlignment.center,
          children: children,
        );
      },
    );
  }
}
