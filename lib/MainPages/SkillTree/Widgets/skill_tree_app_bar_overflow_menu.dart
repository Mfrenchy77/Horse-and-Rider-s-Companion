import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

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
            if (state.skillTreeNavigation == SkillTreeNavigation.SkillList) {
              return [
                // adding a filter option to select a category or a subcategory

                const PopupMenuItem(
                  value: 'Difficulty',
                  child: Text('Difficulty'),
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
            } else {
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
            }
          },
          onSelected: (value) {
            switch (value) {
              case 'Skills':
                cubit.navigateToSkillsList();
                break;
              case 'Edit':
                cubit.toggleIsEditState();
                break;
              case 'Difficulty':
                // open the sort dialog
                _showDifficultySelectDialog(
                  cubit: cubit,
                  state: state,
                  context: context,
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

void _showDifficultySelectDialog({
  required AppCubit cubit,
  required AppState state,
  required BuildContext context,
}) {
  showDialog<AlertDialog>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Sort Skills by Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the difficulty you would like to view'),
            gap(),
            DropdownButton<DifficultyState>(
              value: state.difficultyState,
              items: const [
                DropdownMenuItem(
                  value: DifficultyState.all,
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: DifficultyState.introductory,
                  child: Text('Introductory'),
                ),
                DropdownMenuItem(
                  value: DifficultyState.intermediate,
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(
                  value: DifficultyState.advanced,
                  child: Text('Advanced'),
                ),
              ],
              onChanged: (value) {
                cubit.difficultyFilterChanged(
                  difficultyState: value ?? DifficultyState.all,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}
