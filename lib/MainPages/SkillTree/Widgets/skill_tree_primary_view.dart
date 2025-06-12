import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skills_list.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_path_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_paths_list.dart';

class SkillTreePrimaryView extends StatelessWidget {
  const SkillTreePrimaryView({super.key});
// TODO(mfrenchy): Fix the routing logic here. the primary view should show the right screen and the  back button should return  to the skill tree if we are not in a split screen

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.skillTreeNavigation != current.skillTreeNavigation,
      builder: (context, state) {
        debugPrint('SkillTrePrimaryView Build');
        final isSplitScreen = MediaQuery.of(context).size.width > 840;
        switch (state.skillTreeNavigation) {
          case SkillTreeNavigation.TrainingPath:
            return const TrainingPathView(
              key: Key('trainingPathView'),
            );
          case SkillTreeNavigation.TrainingPathList:
            return isSplitScreen
                ? const SkillLevelView(
                    key: Key('trainingPathListView'),
                  )
                : const TrainingPathListView(
                    key: Key('trainingPathListView'),
                  );
          case SkillTreeNavigation.SkillList:
            return isSplitScreen
                ? const SkillLevelView(
                    key: Key('skillLevelView'),
                  )
                : const SkillsListView(
                    key: Key('skillsListView'),
                  );

          case SkillTreeNavigation.SkillLevel:
            return const SkillLevelView(
              key: Key('skillLevelView'),
            );
        }
      },
    );
  }
}
