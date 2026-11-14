import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_sort_dialog.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';

class SkillTreeAppBarOverFlowMenu extends StatelessWidget {
  const SkillTreeAppBarOverFlowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final settings = SettingsControllerScope.maybeOf(context);
    final tabIndex = context.select((AppCubit c) => c.state.skillTreeTabIndex);
    final isGuest = context.select((AppCubit c) => c.state.isGuest);
    final isEditor = context.select(
      (AppCubit c) => c.state.usersProfile?.editor ?? false,
    );

    final menuItems = <PopupMenuEntry<String>>[];

    // Add sort option only for skill list tab
    if (tabIndex == 0) {
      menuItems.add(const PopupMenuItem(value: 'Sort', child: Text('Sort')));
      if (settings != null) {
        menuItems
          ..add(const PopupMenuDivider())
          ..add(
            const PopupMenuItem(
              enabled: false,
              child: Text('Skill Tree layout'),
            ),
          )
          ..addAll([
            for (final layout in SkillTreeLayout.values)
              CheckedPopupMenuItem(
                key: ValueKey('skillTreeLayout-${layout.name}'),
                value: 'Layout-${layout.name}',
                checked: settings.skillTreeLayout == layout,
                child: Text(layout.label),
              ),
          ]);
      }
    }

    // Add edit toggle if user is editor
    if (!isGuest && isEditor) {
      menuItems.add(
        const PopupMenuItem(value: 'Edit', child: Text('Toggle Edit Controls')),
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
            showAppGlassDialog<void>(
              context: context,
              builder: (_) => const SkillSortDialog(),
            );
            break;
          default:
            if (value.startsWith('Layout-')) {
              final name = value.substring('Layout-'.length);
              final layout = SkillTreeLayout.values.firstWhere(
                (layout) => layout.name == name,
              );
              settings?.updateSkillTreeLayout(layout);
            }
        }
      },
    );
  }
}
