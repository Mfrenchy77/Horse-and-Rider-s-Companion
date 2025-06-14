import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_progress_bar.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_resources_list.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class SkillLevelView extends StatelessWidget {
  const SkillLevelView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final skill = state.skill;
        final allSkills = state.allSkills;

        if (skill == null) {
          return const Center(child: Text('No Skill Selected'));
        }

        final prerequisiteSkills = skill.prerequisites
            .map(
              (id) => allSkills.firstWhere(
                (s) => s?.id == id,
                orElse: () => null,
              ),
            )
            .whereType<Skill>()
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Visibility(
                        visible: state.isGuest,
                        child: const Text(
                          'This is where you will be able to track your '
                          'progress for this skill. There will be '
                          'information for each skill that explains '
                          'what is expected for "Learning" and "Proficient"',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        skill.skillName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(skill.description ?? ''),
                      ),
                      const Text(
                        'Learning Description: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(skill.learningDescription ?? ''),
                      ),
                      const Text(
                        'Proficient Description: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(skill.proficientDescription ?? ''),
                      ),

                      ///  Prerequisites
                      if (prerequisiteSkills.isNotEmpty) ...[
                        const Divider(indent: 20, endIndent: 20),
                        const Text(
                          'Prerequisites',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                        const Divider(indent: 20, endIndent: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: prerequisiteSkills.length,
                          itemBuilder: (context, index) {
                            final prereq = prerequisiteSkills[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              elevation: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient:
                                      cubit.horizontalGradient(skill: prereq),
                                  color:
                                      cubit.horizontalGradient(skill: prereq) ==
                                              null
                                          ? cubit.levelColor(
                                              skill: prereq,
                                              levelState: LevelState.PROFICIENT,
                                            )
                                          : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: ColoredBox(
                                    color: HorseAndRidersTheme()
                                        .getTheme()
                                        .cardColor,
                                    child: ListTile(
                                      title: Text(prereq.skillName),
                                      subtitle: Text(
                                        prereq.description ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        context.read<AppCubit>()
                                          ..navigateToSkillLevel(skill: prereq)
                                          ..setSkillTreeTabIndex(1);
                                      },
                                      trailing:
                                          const Icon(Icons.arrow_forward_ios),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        const Divider(indent: 20, endIndent: 20),
                        const Text(
                          'No Prerequisites',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],

                      const Divider(indent: 20, endIndent: 20),
                      const Text(
                        'Resources',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      const Divider(indent: 20, endIndent: 20),
                      smallGap(),
                      const SkillResouresList(key: Key('skillResourcesList')),
                      smallGap(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),

                /// Progress Bar at the top
                Visibility(
                  visible: state.skill != null,
                  child: const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SkillLevelProgressBar(
                      key: Key('skillLevelProgressBar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
