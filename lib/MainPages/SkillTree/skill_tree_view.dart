// ignore_for_file: lines_longer_than_80_chars, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_app_bar_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_secondary_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_title_search_bar.dart';

///   This is the main view for the Skill Tree section of the app.

class SkillTreeView extends StatelessWidget {
  const SkillTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final isSplitScreen = MediaQuery.of(context).size.width > 840;
        final cubit = context.read<AppCubit>();
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                debugPrint('Skill Tree Back Pressed\n'
                    'SkillTreeNavigationState: ${state.skillTreeNavigation}\n '
                    'From profile: ${state.isFromProfile}\n '
                    'From Training Path List: ${state.isFromTrainingPathList}\n '
                    'From Training Path: ${state.isFromTrainingPath}');
                if (isSplitScreen) {
                  switch (context.read<AppCubit>().state.skillTreeNavigation) {
                    case SkillTreeNavigation.TrainingPath:
                      cubit.navigateToTrainingPathList();
                      break;
                    case SkillTreeNavigation.TrainingPathList:
                      cubit.navigateToSkillsList();
                      break;
                    case SkillTreeNavigation.SkillList:
                      cubit.changeIndex(0);
                      break;
                    case SkillTreeNavigation.SkillLevel:
                      if (context
                          .read<AppCubit>()
                          .state
                          .isFromTrainingPathList) {
                        cubit.navigateToTrainingPathList();
                      } else {
                        cubit.changeIndex(0);
                      }
                      break;
                  }
                } else {
                  switch (context.read<AppCubit>().state.skillTreeNavigation) {
                    case SkillTreeNavigation.TrainingPath:
                      cubit.navigateToTrainingPathList();
                      break;
                    case SkillTreeNavigation.TrainingPathList:
                      cubit.navigateToSkillsList();
                      break;
                    case SkillTreeNavigation.SkillList:
                      cubit.changeIndex(0);
                      break;
                    case SkillTreeNavigation.SkillLevel:
                      cubit.navigateToSkillsList();
                      break;
                  }
                }
              },
            ),
            centerTitle: true,
            title: const SkillTreeSearchTitleBar(
              key: Key('skillTreeSearchTitleBar'),
            ),
            actions: const [
              AppBarSearchButton(),
              SkillTreeAppBarOverFlowMenu(),
            ],
          ),
          body: AdaptiveLayout(
            internalAnimations: false,
            body: SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                Breakpoints.small: SlotLayout.from(
                  key: const Key('primaryView'),
                  builder: (_) {
                    return const SkillTreePrimaryView();
                  },
                ),
                Breakpoints.medium: SlotLayout.from(
                  key: const Key('primaryView'),
                  builder: (_) {
                    return const SkillTreePrimaryView();
                  },
                ),
                Breakpoints.large: SlotLayout.from(
                  key: const Key('primaryView'),
                  builder: (_) {
                    return const SkillTreeSecondaryView(
                      key: Key('secondaryView'),
                    );
                  },
                ),
              },
            ),
            secondaryBody: SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                Breakpoints.large: SlotLayout.from(
                  key: const Key('secondaryView'),
                  builder: (_) {
                    return const SkillTreePrimaryView();
                  },
                ),
              },
            ),
          ),
        );
      },
    );
  }
}
