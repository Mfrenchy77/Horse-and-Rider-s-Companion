import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skills_list.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_path_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_paths_list.dart';

class SkillTreeSecondaryView extends StatelessWidget {
  const SkillTreeSecondaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        switch (state.skillTreeNavigation) {
          case SkillTreeNavigation.TrainingPath:
            return const TrainingPathListView(
              key: Key('TrainingPathListView'),
            );
          case SkillTreeNavigation.TrainingPathList:
            return const TrainingPathListView(
              key: Key('TrainingPathListView'),
            );
          case SkillTreeNavigation.SkillList:
            return const SkillsListView(
              key: Key('SkillsListView'),
            );
          case SkillTreeNavigation.SkillLevel:
            return state.isFromProfile
                ? const TrainingPathListView(
                    key: Key('TrainingPathListView'),
                  )
                : state.isFromTrainingPath
                    ? const TrainingPathView(
                        key: Key('TrainingPathView'),
                      )
                    : state.isFromTrainingPathList
                        ? const TrainingPathView(
                            key: Key('TrainingPathView'),
                          )
                        : const SkillsListView(
                            key: Key('SkillsListView'),
                          );
        }
      },
    );
  }
}
