import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/training_path_create_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_node_card.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class TrainingPathView extends StatelessWidget {
  const TrainingPathView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final scrollController = ScrollController();
        debugPrint('Training Path View: ${state.trainingPath?.name}');

        final cubit = context.read<AppCubit>();

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Training Path Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        state.trainingPath?.name ?? 'Select a Training Path',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w100,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Visibility(
                      visible: state.isEdit && state.isGuest == false,
                      child: IconButton(
                        tooltip: 'Edit Training Path',
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => showDialog<CreateTrainingPathDialog>(
                          context: context,
                          builder: (context) => CreateTrainingPathDialog(
                            usersProfile: state.usersProfile!,
                            trainingPath: state.trainingPath,
                            isEdit: true,
                            allSkills: state.sortedSkills,
                            isForRider: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Description
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(state.trainingPath?.description ?? ''),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .9,
                  child: Divider(
                    color: HorseAndRidersTheme().getTheme().primaryColor,
                    thickness: 1,
                  ),
                ),
                Scrollbar(
                  trackVisibility: true,
                  thickness: 6,
                  thumbVisibility: true,
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        children: state.trainingPath?.skillNodes
                                .where(
                                  (element) =>
                                      element!.parentId?.isEmpty ?? false,
                                )
                                .where(
                                  (skillNode) =>
                                      cubit
                                          .getSkillFromId(skillNode!.skillId) !=
                                      null,
                                )
                                .map(
                                  (e) => SkillNodeCard(
                                    skillNode: e,
                                  ),
                                )
                                .toList() ??
                            [const Text('')],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
