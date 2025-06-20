import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/skill_create_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_sort_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_item.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillsListView extends StatelessWidget {
  const SkillsListView({this.onSkillSelected, super.key});

  static const String name = 'SkillsListView';
  static const String path = 'Skills';

  final VoidCallback? onSkillSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.sortedSkills != current.sortedSkills ||
          previous.isEdit != current.isEdit ||
          previous.isGuest != current.isGuest ||
          previous.isForRider != current.isForRider ||
          previous.categorySortState != current.categorySortState ||
          previous.difficultySortState != current.difficultySortState ||
          previous.horseProfile != current.horseProfile ||
          previous.usersProfile != current.usersProfile ||
          previous.viewingProfile != current.viewingProfile,
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
                    // ignore: avoid_redundant_argument_values
                    skill: null,
                    isEdit: false,
                    allSkills: state.allSkills,
                    isForRider: state.isForRider,
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
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        child: InkWell(
                          onTap: () {
                            showDialog<AlertDialog>(
                              context: context,
                              builder: (_) => const SkillSortDialog(),
                            );
                          },
                          child: Text(
                            '${state.isForRider ? 'Rider' : 'Horse'}'
                            ' Skills - ${state.categorySortState.name}'
                            ' - ${state.difficultySortState.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                gap(),
                if (state.sortedSkills.isNotEmpty)
                  SingleChildScrollView(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: state.sortedSkills
                          .map(
                            (skill) => SkillItem(
                              skill: skill,
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
                              name: skill?.skillName,
                              onTap: () {
                                debugPrint(
                                  'Tapped on skill: ${skill?.skillName}',
                                );
                                context.goNamed(
                                  SkillTreeView.skillLevelName,
                                  pathParameters: {
                                    SkillTreeView.skillPathParam:
                                        skill?.id ?? '',
                                  },
                                );
                              },
                              onEdit: () {
                                if (cubit.canEditSkill(skill)) {
                                  showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      isEdit: true,
                                      skill: skill,
                                      allSkills: state.allSkills,
                                      isForRider: state.isForRider,
                                      usersProfile: state.usersProfile!,
                                      position:
                                          skills.isNotEmpty ? skills.length : 0,
                                    ),
                                  );
                                } else {
                                  // ignore: lines_longer_than_80_chars
                                  // TODO(mfrenchy77): Show contact admin or creator dialog
                                  cubit.createError(
                                    'You do not have permission'
                                    ' to edit this skill',
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
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
