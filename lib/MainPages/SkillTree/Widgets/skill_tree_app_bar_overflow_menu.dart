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

        final menuItems = <PopupMenuEntry<String>>[];

        // Add sort option only for skill list tab
        if (state.skillTreeTabIndex == 0) {
          menuItems.add(
            const PopupMenuItem(
              value: 'Sort',
              child: Text('Sort'),
            ),
          );
        }

        // Add edit toggle if user is editor
        if (!state.isGuest && isEditor) {
          menuItems.add(
            const PopupMenuItem(
              value: 'Edit',
              child: Text('Toggle Edit Controls'),
            ),
          );
        }

        if (menuItems.isEmpty) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          itemBuilder: (context) => menuItems,
          onSelected: (value) {
            switch (value) {
              case 'Edit':
                cubit.toggleIsEditState();
                break;
              case 'Sort':
                showDialog<AlertDialog>(
                  context: context,
                  builder: (_) => const SkillSortDialog(),
                );
                break;
            }
          },
        );
      },
    );
  }
}
