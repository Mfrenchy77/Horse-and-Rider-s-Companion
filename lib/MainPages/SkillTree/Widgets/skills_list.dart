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
        final skills = state.sortedSkills;
        return Scaffold(
          floatingActionButton: Visibility(
            // ignore: use_if_null_to_convert_nulls_to_bools
            visible: !state.isGuest && state.isEdit,
            child: Tooltip(
              message:
                  'Add a new ${state.isForRider ? 'Rider' : 'Horse'} skill',
              child: FloatingActionButton(
                key: const Key('addSkillButton'),
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
                          'Skills - ${state.skillTreeSortState.name}',
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
                if (state.sortedSkills.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: state.sortedSkills
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
                            onEdit: () {
                              if (cubit.canEditSkill(skill!)) {
                                showDialog<CreateSkillDialog>(
                                  context: context,
                                  builder: (context) => CreateSkillDialog(
                                    isForRider: state.isForRider,
                                    isEdit: true,
                                    skill: skill,
                                    usersProfile: state.usersProfile!,
                                    position:
                                        skills.isNotEmpty ? skills.length : 0,
                                  ),
                                );
                              } else {
                                // TODO: Show contact admin or creator dialog
                                cubit.createError(
                                  'You do not have permission'
                                  ' to edit this skill',
                                );
                              }
                            },
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
