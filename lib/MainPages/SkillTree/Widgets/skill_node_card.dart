import 'package:collection/collection.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_item.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
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
          // Check if the current node has children
          final hasChildren = state.trainingPath?.skillNodes
                  .any((element) => element?.parentId == skillNode.id) ??
              false;
          // Check if the current node is a child

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // If it is a child node, show a divider on top
              // if (isChild) const Divider(color: Colors.black, thickness: 2),

              SkillItem(
                name: skillNode.name,
                onTap: () {
                  cubit.navigateToSkillLevel(
                    skill: state.allSkills.firstWhere(
                      (element) => element?.skillName == skillNode.name,
                    ),
                  );
                },
                onEdit: () {
                  cubit.navigateToSkillLevel(
                    skill: state.allSkills.firstWhere(
                      (element) => element?.skillName == skillNode.name,
                    ),
                  );
                },
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

              // If it has children, show a vertical divider below
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
                children: cubit
                    .childrenNodes(skillNode: skillNode)
                    .asMap()
                    .entries
                    .map(
                  (entry) {
                    final e = entry.value;

                    return Column(
                      children: [
                        // _buildHorizontalDividerLine(index, totalChildren),
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
                              color: e.position ==
                                      cubit
                                              .childrenNodes(
                                                skillNode: skillNode,
                                              )
                                              .length -
                                          1
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
          return const Text('');
        }
      },
    );
  }
}

///Get skill for skill node
Skill? getSkillForSkillNode({
  required SkillNode skillNode,
  required List<Skill?> allSkills,
}) {
  return allSkills.firstWhereOrNull(
    (element) => element?.skillName == skillNode.name,
  );
}
