import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_app_bar_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_secondary_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_title_search_bar.dart';

class SkillTreeView extends StatelessWidget {
  const SkillTreeView({super.key});

  static const double splitScreenBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                _handleBackButton(context, state, cubit);
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen =
                  constraints.maxWidth >= splitScreenBreakpoint;

              if (isLargeScreen) {
                // Split view
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SkillTreeSecondaryView(key: Key('secondaryView')),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkillTreePrimaryView(key: Key('primaryView')),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Single view
              return const SkillTreePrimaryView(key: Key('primaryView'));
            },
          ),
        );
      },
    );
  }
}

void _handleBackButton(BuildContext context, AppState state, AppCubit cubit) {
  final isSplitScreen = MediaQuery.of(context).size.width > 840;
  debugPrint('Skill Tree Back Pressed\n'
      'SkillTreeNavigationState: ${state.skillTreeNavigation}\n '
      'From profile: ${state.isFromProfile}\n '
      'From Training Path List: ${state.isFromTrainingPathList}\n '
      'From Training Path: ${state.isFromTrainingPath}');

  final nav = state.skillTreeNavigation;

  if (isSplitScreen) {
    switch (nav) {
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
        if (state.isFromTrainingPathList) {
          cubit.navigateToTrainingPathList();
        } else {
          cubit.changeIndex(0);
        }
        break;
    }
  } else {
    switch (nav) {
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
}
