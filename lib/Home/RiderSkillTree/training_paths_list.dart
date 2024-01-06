import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/CreateSkillTreeDialogs/Views/training_path_create_dialog.dart';

Widget trainingPathsList({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  return Scaffold(
    floatingActionButton: Visibility(
      visible: !state.isGuest,
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
    body: Column(
      children: [
        Text('Training Path', style: Theme.of(context).textTheme.headline5),
        gap(),
        if (state.trainingPaths.isNotEmpty)
          ListView.builder(
            itemCount: state.trainingPaths.length,
            itemBuilder: (context, index) {
              final trainingPath = state.trainingPaths[index];
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
