import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/skill_create_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_item.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillsListView extends StatelessWidget {
  const SkillsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final skills = cubit.sortedSkills();
        return Scaffold(
          floatingActionButton: Visibility(
            visible: !state.isGuest || state.usersProfile?.editor == true,
            child: Tooltip(
              message:
                  'Add a new ${state.isForRider ? 'Rider' : 'Horse'} skill',
              child: FloatingActionButton(
                onPressed: () => showDialog<CreateSkillDialog>(
                  context: context,
                  builder: (context) => CreateSkillDialog(
                    isForRider: state.isForRider,
                    isEdit: false,
                    // ignore: avoid_redundant_argument_values
                    skill: null,
                    usersProfile: state.usersProfile!,
                    position: skills.isNotEmpty ? skills.length : 0,
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
                  color: HorseAndRidersTheme()
                          .getTheme()
                          .appBarTheme
                          .backgroundColor ??
                      Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(
                          'Skills - ${_skillsTitle(state.difficultyState)}',
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
                if (skills.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: skills
                        .map(
                          (skill) => SkillItem(
                            verified: isVerified(
                                  horseProfile: state.horseProfile,
                                  profile: state.viewingProfile ??
                                      state.usersProfile,
                                  skill: skill,
                                ) ??
                                false,
                            isEditState: state.isEdit,
                            isGuest: state.isGuest,
                            levelState: getLevelState(
                              horseProfile: state.horseProfile,
                              profile:
                                  state.viewingProfile ?? state.usersProfile,
                              skill: skill,
                            ),
                            name: skill?.skillName ?? '',
                            onTap: () {
                              cubit
                                ..setFromSkills()
                                ..navigateToSkillLevel(
                                  skill: skill,
                                );
                            },
                            onEdit: () => showDialog<CreateSkillDialog>(
                              context: context,
                              builder: (context) => CreateSkillDialog(
                                isForRider: state.isForRider,
                                isEdit: true,
                                skill: skill,
                                usersProfile: state.usersProfile!,
                                position: skills.isNotEmpty ? skills.length : 0,
                              ),
                            ),
                            backgroundColor: skill?.difficulty ==
                                    DifficultyState.introductory
                                ? Colors.greenAccent.shade200
                                : skill?.difficulty ==
                                        DifficultyState.intermediate
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
      },
    );
  }
}

String _skillsTitle(
  DifficultyState difficultyState,
) {
  switch (difficultyState) {
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
