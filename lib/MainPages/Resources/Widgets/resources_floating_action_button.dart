import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';

class ResourcesFloatingActionButton extends StatelessWidget {
  const ResourcesFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final canCreate = !state.isGuest && state.usersProfile != null;

        return Visibility(
          visible: canCreate,
          child: FloatingActionButton.extended(
            key: const Key('addResourceButton'),
            icon: const Icon(Icons.add),
            label: const Text('Add resource'),
            tooltip: 'Add a link or upload a PDF',
            onPressed: () {
              final user = state.usersProfile;
              if (user == null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to add resources.'),
                    ),
                  );
                return;
              }

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
            },
          ),
        );
      },
    );
  }
}
