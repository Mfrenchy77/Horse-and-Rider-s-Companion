import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/information_dialog.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_level_select_confirmation_dialog.dart';

class SkillLevelProgressBar extends StatelessWidget {
  const SkillLevelProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isConflict =
            state.horseProfile == null && state.skill?.rider == false;
        debugPrint('Is Conflict between horse and skill: $isConflict');
        return MaxWidthBox(
          maxWidth: 1000,
          child: Row(
            children: [
              // Learning
              Expanded(
                child: InkWell(
                  onTap: state.isGuest || isConflict
                      ? null
                      : () {
                          showDialog<AlertDialog>(
                            context: context,
                            builder: (context) =>
                                const SkillLevelSelectedConfimationDialog(
                              key: Key('levelSelectedConfirmationDialog'),
                              levelState: LevelState.LEARNING,
                            ),
                          );
                        },
                  child: ColoredBox(
                    color: cubit.levelColor(
                      skill: state.skill!,
                      levelState: LevelState.LEARNING,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Learning',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            GestureDetector(
                              onTapDown: (details) {
                                InformationDialog.show(
                                  context,
                                  const Text(
                                    'Learning: This stage indicates that the '
                                    'individual should be actively engaged in '
                                    'acquiring the skill. They should be in '
                                    'the process of understanding and '
                                    'practicing the basic concepts and '
                                    'techniques. Mistakes are '
                                    'common at this level, but they provide '
                                    'valuable learning experiences. The '
                                    'individual should be developing their '
                                    'abilities but not yet mastered the skill.',
                                  ),
                                  details.globalPosition,
                                );
                              },
                              child: const Icon(
                                Icons.info_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Proficient
              Expanded(
                child: InkWell(
                  onTap: state.isGuest || isConflict
                      ? null
                      : () {
                          showDialog<AlertDialog>(
                            context: context,
                            builder: (context) =>
                                const SkillLevelSelectedConfimationDialog(
                              key: Key('levelSelectedConfirmationDialog'),
                              levelState: LevelState.PROFICIENT,
                            ),
                          );
                        },
                  child: ColoredBox(
                    color: cubit.levelColor(
                      skill: state.skill!,
                      levelState: LevelState.PROFICIENT,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Proficient',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            GestureDetector(
                              onTapDown: (details) {
                                InformationDialog.show(
                                  context,
                                  const Text(
                                    'Proficient: At this level, the individual '
                                    'should have achieved a significant degree '
                                    'of competence in the skill. They should '
                                    'demonstrate consistent and effective '
                                    'application of the skill in relevant '
                                    'situations. Proficiency implies that the '
                                    'individual can perform the skill '
                                    'independently and reliably, with a good '
                                    'understanding of advanced concepts and '
                                    'techniques.',
                                  ),
                                  details.globalPosition,
                                );
                              },
                              child: const Icon(
                                Icons.info_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Resource list
            ],
          ),
        );
      },
    );
  }
}
