import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/training_path_create_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';

class TrainingPathListView extends StatelessWidget {
  const TrainingPathListView({this.onTrainingPathSelected, super.key});

  static const String name = 'TrainingPathListView';
  static const String path = 'TrainingPaths';

  final VoidCallback? onTrainingPathSelected;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.trainingPaths != current.trainingPaths,
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        // final trainingPaths = state.trainingPaths
        //     .where((element) => element?.isForRider == state.isForRider)
        //     .toList();
        return Scaffold(
          floatingActionButton: Visibility(
            visible: !state.isGuest && state.isEdit,
            child: Tooltip(
              message: 'Create Training Path',
              child: FloatingActionButton(
                key: const Key('createTrainingPathButton'),
                onPressed: () => showDialog<CreateTrainingPathDialog>(
                  context: context,
                  builder: (context) => CreateTrainingPathDialog(
                    usersProfile: state.usersProfile!,
                    trainingPath: null,
                    isEdit: false,
                    allSkills: state.sortedSkills
                        .where((s) => s != null)
                        .cast<Skill>()
                        .toList(),
                    isForRider: true,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                ),
              ),
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Training Paths',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
              gap(),
              if (state.trainingPaths.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.trainingPaths.length,
                  itemBuilder: (context, index) {
                    final trainingPath = state.trainingPaths[index];
                    debugPrint(
                      'Training Path: ${trainingPath?.name}, '
                      'Nubmer of Skills: ${trainingPath?.skillNodes.length}',
                    );
                    return MaxWidthBox(
                      maxWidth: 600,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Card(
                          elevation: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: state.usersProfile?.email ==
                                        trainingPath?.createdById
                                    ? null
                                    : () => context.goNamed(
                                          ViewingProfilePage.name,
                                          pathParameters: {
                                            ViewingProfilePage.pathParams:
                                                trainingPath!.createdById,
                                          },
                                        ),
                                child: Text(trainingPath?.createdBy ?? ''),
                              ),
                              ListTile(
                                trailing: !state.isEdit || state.isGuest
                                    ? null
                                    : PopupMenuButton<String>(
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            child: const Text('Edit'),
                                            onTap: () {
                                              if (cubit.canEditTrainingPath(
                                                trainingPath!,
                                              )) {
                                                showDialog<
                                                    CreateTrainingPathDialog>(
                                                  context: context,
                                                  builder: (context) =>
                                                      CreateTrainingPathDialog(
                                                    usersProfile:
                                                        state.usersProfile!,
                                                    trainingPath: trainingPath,
                                                    isEdit: true,
                                                    allSkills: state
                                                        .sortedSkills
                                                        .where((s) => s != null)
                                                        .cast<Skill>()
                                                        .toList(),
                                                    isForRider: true,
                                                  ),
                                                );
                                              } else {
                                                cubit.createError(
                                                  'You do not have permission'
                                                  ' to edit this training path',
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                onTap: () {
                                  debugPrint(
                                    'Clicked on ${trainingPath?.name}',
                                  );
                                  context.goNamed(
                                    SkillTreeView.trainingPathViewName,
                                    pathParameters: {
                                      SkillTreeView.trainingPathPathParam:
                                          trainingPath!.id,
                                    },
                                  );
                                },
                                title: Text(trainingPath?.name ?? ''),
                                subtitle: Text('${trainingPath?.description}'
                                    ' Number of skills '
                                    '${trainingPath?.skillNodes.length}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                const Center(
                  child: Text('No Training Paths'),
                ),
            ],
          ),
        );
      },
    );
  }
}
