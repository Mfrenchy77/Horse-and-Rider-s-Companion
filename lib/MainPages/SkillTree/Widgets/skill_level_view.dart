// Prerequisites disabled; import retained for restoration.
// import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Prerequisites disabled; import retained for restoration.
// import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_progress_bar.dart';
// Prerequisites disabled; import retained for restoration.
// import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_prerequisite_diagram.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_resources_list.dart';
// Prerequisites disabled; import retained for restoration.
// import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';

class SkillLevelView extends StatelessWidget {
  const SkillLevelView({super.key, required this.skillId});

  final String? skillId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      // buildWhen: (previous, current) =>
      //     previous.usersProfile != current.usersProfile ||
      //     previous.horseProfile != current.horseProfile ||
      //     previous.skill != current.skill ||
      //     previous.allSkills != current.allSkills ||
      //     previous.isGuest != current.isGuest,
      builder: (context, state) {
        final skill = state.skill;

        if (skill == null) {
          return const Center(child: Text('Skill Not Found'));
        }
        // Prerequisite diagram data retained for possible restoration.
        //         final allSkills = state.allSkills;
        //
        //         final profileSkillLevels = state.isForRider
        //             ? state.viewingProfile?.skillLevels ??
        //                 state.usersProfile?.skillLevels ??
        //                 state.ownersProfile?.skillLevels
        //             : state.horseProfile?.skillLevels;
        //         final skillLevelsById = {
        //     for (final level in profileSkillLevels ?? const <SkillLevel>[])
        //             level.skillId: level,
        //         };
        //
        //         final isBaseSkill = skill.prerequisites.isEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            final scrollableContent = SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: Column(
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

                  // Prerequisite display retained for possible restoration.
                  //                   ///  Prerequisites
                  //                   const Divider(indent: 20, endIndent: 20),
                  //                   Text(
                  //               isBaseSkill ? 'Base Skill' : 'Prerequisites',
                  //                     style: const TextStyle(
                  //                       fontSize: 24,
                  //                       fontWeight: FontWeight.w100,
                  //                     ),
                  //                   ),
                  //                   const Divider(indent: 20, endIndent: 20),
                  //                   if (isBaseSkill)
                  //                     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 16),
                  //                       child: Text(
                  //          'This is a foundational skill and can be started '
                  //               'without completing other skills first.',
                  //                         textAlign: TextAlign.center,
                  //             style: Theme.of(context).textTheme.bodyMedium,
                  //                       ),
                  //                     )
                  //                   else
                  //                     Padding(
                  //        padding: const EdgeInsets.symmetric(horizontal: 8),
                  //                     child: Card(
                  //                         elevation: 6,
                  //                         clipBehavior: Clip.hardEdge,
                  //                         child: SizedBox(
                  //                           height: 520,
                  //                           child: SkillPrerequisiteDiagram(
                  //                             skill: skill,
                  //                             allSkills: allSkills,
                  //                          skillLevelsById: skillLevelsById,
                  //                             onSkillSelected: (selected) {
                  //                               context.goNamed(
                  //                              SkillTreeView.skillLevelName,
                  //                                 pathParameters: {
                  //              SkillTreeView.skillPathParam: selected.id,
                  //                                 },
                  //                               );
                  //                             },
                  //                           ),
                  //                         ),
                  //                       ),
                  //                     ),
                  const Divider(indent: 20, endIndent: 20),
                  const Text(
                    'Resources',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w100),
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  smallGap(),
                  const SkillResouresList(key: Key('skillResourcesList')),
                  smallGap(),
                  const SizedBox(height: 50),
                ],
              ),
            );

            final constrainedContent = constraints.hasBoundedHeight
                ? SizedBox(
                    height: constraints.maxHeight,
                    width: constraints.maxWidth,
                    child: scrollableContent,
                  )
                : scrollableContent;

            return Stack(
              fit: StackFit.expand,
              children: [
                constrainedContent,

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
            );
          },
        );
      },
    );
  }
}
