import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/CreateSkillTreeDialogs/Views/skill_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/skill_item.dart';

Widget skillsList() {
  return BlocBuilder<HomeCubit, HomeState>(
    buildWhen: (previous, current) {
      return previous.skills != current.skills;
    },
    builder: (context, state) {
      final isSplitScreen = MediaQuery.of(context).size.width > 800;
      final homeCubit = context.read<HomeCubit>();
      if (state.allSkills != null && state.allSkills!.isNotEmpty) {
        switch (state.difficultyState) {
          /// Filter is set to all so we will display all skills
          /// in the selected subcategory
          case DifficultyState.all:
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      /// Introductory
                      Column(
                        children: [
                          smallGap(),
                          Visibility(
                            visible: state.allSkills!
                                .where(
                                  (skill) =>
                                      skill!.difficulty ==
                                      DifficultyState.introductory,
                                )
                                .isNotEmpty,
                            child: const Center(
                              child: Text(
                                'Introductory',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          smallGap(),
                          Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...state.introSkills!.map(
                                (skill) => skillItem(
                                  isEditState: state.isEditState,
                                  isGuest: state.isGuest,
                                  difficulty: DifficultyState.introductory,
                                  name: skill!.skillName,
                                  onTap: () =>
                                      context.read<HomeCubit>().skillSelected(
                                            isFromTrainingPath: false,
                                            skill: skill,
                                            isSplitScreen: isSplitScreen,
                                          ),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.introSkills != null &&
                                              state.introSkills!.isNotEmpty
                                          ? state.introSkills!.length
                                          : 0,
                                    ),
                                  ),
                                  backgroundColor: Colors.greenAccent.shade200,
                                ),
                              ),
                            ],
                          ),
                          smallGap(),
                        ],
                      ),

                      /// Intermediate
                      Column(
                        children: [
                          Visibility(
                            visible: state.intermediateSkills!.isNotEmpty,
                            child: const Center(
                              child: Text(
                                'Intermediate',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          smallGap(),
                          Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...state.intermediateSkills!.map(
                                (skill) => skillItem(
                                  isEditState: state.isEditState,
                                  isGuest: state.isGuest,
                                  difficulty: DifficultyState.intermediate,
                                  name: skill!.skillName,
                                  onTap: () =>
                                      context.read<HomeCubit>().skillSelected(
                                            isFromTrainingPath: false,
                                            skill: skill,
                                            isSplitScreen: isSplitScreen,
                                          ),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position:
                                          state.intermediateSkills != null &&
                                                  state.intermediateSkills!
                                                      .isNotEmpty
                                              ? state.intermediateSkills!.length
                                              : 0,
                                    ),
                                  ),
                                  backgroundColor: Colors.yellowAccent.shade200,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      /// Advanced
                      Column(
                        children: [
                          smallGap(),
                          Visibility(
                            visible: state.advancedSkills!.isNotEmpty,
                            child: const Center(
                              child: Text(
                                'Advanced',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          smallGap(),
                          Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...state.advancedSkills!.map(
                                (skill) => skillItem(
                                  isEditState: state.isEditState,
                                  isGuest: state.isGuest,
                                  difficulty: DifficultyState.advanced,
                                  name: skill!.skillName,
                                  backgroundColor: Colors.redAccent.shade200,
                                  onTap: () =>
                                      context.read<HomeCubit>().skillSelected(
                                            isFromTrainingPath: false,
                                            skill: skill,
                                            isSplitScreen: isSplitScreen,
                                          ),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.advancedSkills != null &&
                                              state.advancedSkills!.isNotEmpty
                                          ? state.advancedSkills!.length
                                          : 0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          case DifficultyState.introductory:
            return Wrap(
              children: [
                const Center(
                  child: Text(
                    'Introductory',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                smallGap(),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...state.introSkills!.map(
                        (skill) => skillItem(
                          isEditState: state.isEditState,
                          isGuest: state.isGuest,
                          difficulty: DifficultyState.introductory,
                          name: skill!.skillName,
                          onTap: () => context.read<HomeCubit>().skillSelected(
                                isFromTrainingPath: false,
                                skill: skill,
                                isSplitScreen: isSplitScreen,
                              ),
                          onEdit: () => showDialog<CreateSkillDialog>(
                            context: context,
                            builder: (context) => CreateSkillDialog(
                              allSubCategories: state.subCategories ?? [],
                              isRider: state.isForRider,
                              isEdit: true,
                              skill: skill,
                              userName: state.usersProfile?.name,
                              position: state.introSkills != null &&
                                      state.introSkills!.isNotEmpty
                                  ? state.introSkills!.length
                                  : 0,
                            ),
                          ),
                          backgroundColor: Colors.greenAccent.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          case DifficultyState.intermediate:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Intermediate',
                  style: TextStyle(fontSize: 20),
                ),
                smallGap(),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...state.intermediateSkills!.map(
                        (skill) => skillItem(
                          isEditState: state.isEditState,
                          isGuest: state.isGuest,
                          difficulty: DifficultyState.intermediate,
                          name: skill!.skillName,
                          onTap: () => context.read<HomeCubit>().skillSelected(
                                isFromTrainingPath: false,
                                skill: skill,
                                isSplitScreen: isSplitScreen,
                              ),
                          onEdit: () => showDialog<CreateSkillDialog>(
                            context: context,
                            builder: (context) => CreateSkillDialog(
                              allSubCategories: state.subCategories ?? [],
                              isRider: state.isForRider,
                              isEdit: true,
                              skill: skill,
                              userName: state.usersProfile?.name,
                              position: state.intermediateSkills != null &&
                                      state.intermediateSkills!.isNotEmpty
                                  ? state.intermediateSkills!.length
                                  : 0,
                            ),
                          ),
                          backgroundColor: Colors.yellowAccent.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          case DifficultyState.advanced:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Advanced',
                  style: TextStyle(fontSize: 20),
                ),
                smallGap(),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...state.advancedSkills!.map(
                        (skill) => skillItem(
                          isEditState: state.isEditState,
                          isGuest: state.isGuest,
                          difficulty: DifficultyState.advanced,
                          name: skill!.skillName,
                          onTap: () => context.read<HomeCubit>().skillSelected(
                                isFromTrainingPath: false,
                                skill: skill,
                                isSplitScreen: isSplitScreen,
                              ),
                          onEdit: () => showDialog<CreateSkillDialog>(
                            context: context,
                            builder: (context) => CreateSkillDialog(
                              allSubCategories: state.subCategories ?? [],
                              isRider: state.isForRider,
                              isEdit: true,
                              skill: skill,
                              userName: state.usersProfile?.name,
                              position: state.advancedSkills != null &&
                                      state.advancedSkills!.isNotEmpty
                                  ? state.advancedSkills!.length
                                  : 0,
                            ),
                          ),
                          backgroundColor: Colors.redAccent.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        }
      } else {
        homeCubit.getSkills();
        return const Center(child: Text('No Skills'));
      }
    },
  );
}
