import 'package:collection/collection.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_item.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillNodeCard extends StatelessWidget {
  const SkillNodeCard({super.key, required this.skillNode});
  final SkillNode? skillNode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final skillNode = this.skillNode;

        if (skillNode != null) {
          // Ensure the current skill node has a corresponding skill
          final skill = cubit.getSkillFromId(skillNode.skillId);
          debugPrint('SkillNodeCard: ${skillNode.name} - ${skillNode.skillId}');

          if (skill == null) {
            return const SizedBox.shrink();
          }
          debugPrint('Corresonding skill: ${skill.skillName} - ${skill.id}');
          // Check if the current node has children with corresponding skills
          final childrenNodes = cubit
              .childrenNodes(skillNode: skillNode)
              .where(
                (childNode) => cubit.getSkillFromId(childNode.skillId) != null,
              )
              .toList();

          final hasChildren = childrenNodes.isNotEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkillItem(
                skill: skill,
                name: skill.skillName,
                onTap: () {
                  cubit.setIsFromTrainingPath(isFromTrainingPath: true);

                  context.goNamed(
                    SkillTreeView.skillLevelName,
                    pathParameters: {SkillTreeView.skillPathParam: skill.id},
                  );
                },
                onEdit: () {},
                isGuest: state.isGuest,
                verified: isVerified(
                  horseProfile: state.horseProfile,
                  skill: getSkillForSkillNode(
                    skillNode: skillNode,
                    allSkills: state.allSkills,
                  ),
                  profile: state.viewingProfile ?? state.usersProfile,
                ),
                levelState: getLevelState(
                  horseProfile: state.horseProfile,
                  skill: getSkillForSkillNode(
                    skillNode: skillNode,
                    allSkills: state.allSkills,
                  ),
                  profile: state.viewingProfile ?? state.usersProfile,
                ),
                isEditState: false,
              ),
              if (hasChildren)
                Container(
                  height: 10,
                  width: 2,
                  color: HorseAndRidersTheme().getTheme().brightness ==
                          Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              Wrap(
                children: childrenNodes.asMap().entries.map(
                  (entry) {
                    final e = entry.value;

                    return Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 2,
                              width: 99,
                              color: e.position == 0
                                  ? Colors.transparent
                                  : HorseAndRidersTheme()
                                              .getTheme()
                                              .brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                            ),
                            Container(
                              height: 2,
                              width: 2,
                              color:
                                  HorseAndRidersTheme().getTheme().brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                            ),
                            Container(
                              width: 99,
                              height: 2,
                              color: e.position == childrenNodes.length - 1
                                  ? Colors.transparent
                                  : HorseAndRidersTheme()
                                              .getTheme()
                                              .brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ],
                        ),
                        Container(
                          height: 10,
                          color: HorseAndRidersTheme().getTheme().brightness ==
                                  Brightness.light
                              ? Colors.black
                              : Colors.white,
                          width: 2,
                        ),
                        SkillNodeCard(
                          skillNode: e,
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

/// Get skill for skill node
Skill? getSkillForSkillNode({
  required SkillNode skillNode,
  required List<Skill?> allSkills,
}) {
  return allSkills.firstWhereOrNull(
    (element) => element?.skillName == skillNode.name,
  );
}
