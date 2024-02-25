import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/training_path_create_dialog.dart';
Widget trainingPathsList({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  // if state.isForRider we want to show the training paths for the rider only
  final trainingPaths = state.trainingPaths
      .where((element) => element?.isForHorse == !state.isForRider)
      .toList();
  return Scaffold(
    floatingActionButton: Visibility(
      visible: !state.isGuest,
      child: Tooltip(
        message: 'Create Training Path',
        child: FloatingActionButton(
          onPressed: () => showDialog<CreateTrainingPathDialog>(
            context: context,
            builder: (context) => CreateTrainingPathDialog(
              usersProfile: state.usersProfile!,
              trainingPath: null,
              isEdit: false,
              allSkills: state.allSkills!,
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
        if (trainingPaths.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: trainingPaths.length,
            itemBuilder: (context, index) {
              final trainingPath = trainingPaths[index];
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(trainingPath?.createdBy ?? ''),
                    ListTile(
                      onTap: () {
                        debugPrint('Clicked on ${trainingPath?.name}');
                        homeCubit.navigateToTrainingPath(
                          trainingPath: trainingPath,
                        );
                      },
                      title: Text(trainingPath?.name ?? ''),
                      subtitle: Text(trainingPath?.description ?? ''),
                    ),
                  ],
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
}
