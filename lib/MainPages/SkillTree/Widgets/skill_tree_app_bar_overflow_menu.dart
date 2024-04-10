import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_sort_dialog.dart';

class SkillTreeAppBarOverFlowMenu extends StatelessWidget {
  const SkillTreeAppBarOverFlowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isEditor = state.usersProfile?.editor ?? false;
        return PopupMenuButton<String>(
          itemBuilder: (context) {
            switch (state.skillTreeNavigation) {
              case SkillTreeNavigation.SkillList:
                return [
                  const PopupMenuItem(
                    value: 'Sort',
                    child: Text('Sort'),
                  ),
                  const PopupMenuItem(
                    value: 'Training Paths',
                    child: Text('Training Paths'),
                  ),
                  if (!state.isGuest && isEditor)
                    const PopupMenuItem(
                      value: 'Edit',
                      child: Text('Toggle Edit Controls'),
                    ),
                ];
              case SkillTreeNavigation.TrainingPathList:
                return [
                  const PopupMenuItem(
                    value: 'Skills',
                    child: Text('Skills'),
                  ),
                  if (!state.isGuest && isEditor)
                    const PopupMenuItem(
                      value: 'Edit',
                      child: Text('Toggle Edit Controls'),
                    ),
                ];
              case SkillTreeNavigation.TrainingPath:
                return [
                  const PopupMenuItem(
                    value: 'Skills',
                    child: Text('Skills'),
                  ),
                  if (!state.isGuest && isEditor)
                    const PopupMenuItem(
                      value: 'Edit',
                      child: Text('Toggle Edit Controls'),
                    ),
                ];
              case SkillTreeNavigation.SkillLevel:
                return [
                  const PopupMenuItem(
                    value: 'Skills',
                    child: Text('Skills'),
                  ),
                  const PopupMenuItem(
                    value: 'Training Paths',
                    child: Text('Training Paths'),
                  ),
                  if (!state.isGuest && isEditor)
                    const PopupMenuItem(
                      value: 'Edit',
                      child: Text('Toggle Edit Controls'),
                    ),
                ];
            }

            // if (state.skillTreeNavigation == SkillTreeNavigation.SkillList) {
            //   return [
            //     const PopupMenuItem(
            //       value: 'Sort',
            //       child: Text('Sort'),
            //     ),
            //     const PopupMenuItem(
            //       value: 'Training Paths',
            //       child: Text('Training Paths'),
            //     ),
            //     if (!state.isGuest && isEditor)
            //       const PopupMenuItem(
            //         value: 'Edit',
            //         child: Text('Toggle Edit Controls'),
            //       ),
            //   ];
            // } else {
            //   return [
            //     const PopupMenuItem(
            //       value: 'Skills',
            //       child: Text('Skills'),
            //     ),
            //     if (!state.isGuest && isEditor)
            //       const PopupMenuItem(
            //         value: 'Edit',
            //         child: Text('Toggle Edit Controls'),
            //       ),
            //   ];
            // }
          },
          onSelected: (value) {
            switch (value) {
              case 'Skills':
                cubit.navigateToSkillsList();
                break;
              case 'Edit':
                cubit.toggleIsEditState();
                break;
              case 'Sort':
                // open the sort dialog
                showDialog<AlertDialog>(
                  context: context,
                  builder: (_) => const SkillSortDialog(),
                );
                break;
              case 'Training Paths':
                cubit.navigateToTrainingPathList();
                break;
            }
          },
        );
      },
    );
  }
}
