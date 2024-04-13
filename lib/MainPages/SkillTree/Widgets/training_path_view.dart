import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
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
        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.trainingPath?.name ?? 'Select a Training Path',
                    //bold and bigger font
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  Visibility(
                    visible: state.isEdit,
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
              smallGap(),
              Text(state.trainingPath?.description ?? ''),
              smallGap(),
              SizedBox(
                width: MediaQuery.of(context).size.width * .9,
                child: Divider(
                  color: HorseAndRidersTheme().getTheme().primaryColor,
                  thickness: 2,
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
        );
      },
    );
  }
}
