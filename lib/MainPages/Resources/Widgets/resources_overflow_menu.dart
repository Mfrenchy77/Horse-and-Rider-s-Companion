import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/resources_sort_dialog.dart';

class ResourcesOverflowMenu extends StatelessWidget {
  const ResourcesOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return state.usersProfile?.editor ?? false || !state.isGuest
            ? PopupMenuButton<String>(
                tooltip: 'Add, Edit or Sort Resources',
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Add',
                    child: Text('Add'),
                  ),
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
                      showModalBottomSheet<CreateResourcDialog>(
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        context: context,
                        builder: (context) => CreateResourcDialog(
                          skills: state.allSkills,
                          userProfile: state.usersProfile!,
                          resource: null,
                        ),
                      );
                      break;
                    case 'Edit':
                      cubit.toggleIsEditState();
                      break;
                    case 'Sort':
                      showDialog<AlertDialog>(
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
                  showDialog<AlertDialog>(
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
