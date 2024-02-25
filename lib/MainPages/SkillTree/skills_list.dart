import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/skill_create_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_item.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

Widget skillsList({
  required List<Skill?>? skills,
  required BuildContext context,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  final isSplitScreen = MediaQuery.of(context).size.width > 800;
  return Scaffold(
    floatingActionButton: Visibility(
      visible: !state.isGuest || state.usersProfile?.editor == true,
      child: Tooltip(
        message: 'Add a new ${state.isForRider ? 'Rider' : 'Horse'} skill',
        child: FloatingActionButton(
          onPressed: () => showDialog<CreateSkillDialog>(
            context: context,
            builder: (context) => CreateSkillDialog(
              allSubCategories: state.subCategories ?? [],
              isRider: state.isForRider,
              isEdit: false,
              // ignore: avoid_redundant_argument_values
              skill: null,
              userName: state.usersProfile?.name,
              position: skills != null && skills.isNotEmpty ? skills.length : 0,
            ),
          ),
          child: const Icon(
            Icons.add,
          ),
        ),
      ),
    ),
    body: Center(
      child: Column(
        children: [
          ColoredBox(
            color:
                HorseAndRidersTheme().getTheme().appBarTheme.backgroundColor ??
                    Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    'Skills - ${_skillsTitle(state, homeCubit)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          gap(),
          if (skills != null && skills.isNotEmpty)
            Wrap(
              children: skills
                  .map(
                    (skill) => skillItem(
                      isEditState: state.isEditState,
                      isGuest: state.isGuest,
                      difficulty: skill!.difficulty,
                      name: skill.skillName,
                      onTap: () {
                        homeCubit
                          ..setFromSkills()
                          ..navigateToSkillLevel(
                            skill: skill,
                            isSplitScreen: isSplitScreen,
                          );
                      },
                      onEdit: () => showDialog<CreateSkillDialog>(
                        context: context,
                        builder: (context) => CreateSkillDialog(
                          allSubCategories: state.subCategories ?? [],
                          isRider: state.isForRider,
                          isEdit: true,
                          skill: skill,
                          userName: state.usersProfile?.name,
                          position: skills.isNotEmpty ? skills.length : 0,
                        ),
                      ),
                      backgroundColor:
                          skill.difficulty == DifficultyState.introductory
                              ? Colors.greenAccent.shade200
                              : skill.difficulty == DifficultyState.intermediate
                                  ? Colors.yellowAccent.shade200
                                  : Colors.redAccent.shade200,
                    ),
                  )
                  .toList(),
            )
          else
            const Center(
              child: Text('No Skills'),
            ),
        ],
      ),
    ),
  );
}

String _skillsTitle(
  HomeState state,
  HomeCubit homeCubit,
) {
  switch (state.difficultyState) {
    case DifficultyState.advanced:
      return 'Advanced';
    case DifficultyState.intermediate:
      return 'Intermediate';
    case DifficultyState.introductory:
      return 'Introductory';
    case DifficultyState.all:
      return 'All';
  }
}
