import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skills_list.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_path_view.dart';

class SkillTreePrimaryView extends StatelessWidget {
  const SkillTreePrimaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final isSplitScreen = MediaQuery.of(context).size.width > 840;
        switch (state.skillTreeNavigation) {
          case SkillTreeNavigation.TrainingPath:
            return const TrainingPathView(
              key: Key('trainingPathView'),
            );
          case SkillTreeNavigation.TrainingPathList:
            return const SkillLevelView(
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
