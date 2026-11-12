import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/quick_share_resource_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/resources_sort_dialog.dart';

class ResourcesOverflowMenu extends StatelessWidget {
  const ResourcesOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final profile = state.usersProfile;
        return !state.isGuest && profile != null
            ? PopupMenuButton<String>(
                tooltip: 'Add, Edit or Sort Resources',
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'Add', child: Text('Add')),
                  const PopupMenuItem<String>(
                    value: 'Edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Sort',
                    child: Text('Sort'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'Add':
                      QuickShareResourcePage.open(
                        context,
                        skills: state.allSkills,
                        profile: profile,
                      );
                      break;
                    case 'Edit':
                      cubit.toggleIsEditState();
                      break;
                    case 'Sort':
                      showAppDialog<void>(
                        context: context,
                        builder: (context) => const ResourcesSortDialog(
                          key: Key('resources_sort_dialog'),
                        ),
                      );
                      break;
                  }
                },
              )
            : PopupMenuButton<String>(
                tooltip: 'Sort Resources',
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Sort',
                      child: Text('Sort'),
                    ),
                  ];
                },
                onSelected: (value) {
                  showAppDialog<void>(
                    context: context,
                    builder: (context) => const ResourcesSortDialog(
                      key: Key('resources_sort_dialog'),
                    ),
                  );
                },
              );
      },
    );
  }
}
