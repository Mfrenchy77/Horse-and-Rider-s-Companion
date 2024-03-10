import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';

class ResourcesFloatingActionButton extends StatelessWidget {
  const ResourcesFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Visibility(
          visible: !state.isGuest,
          child: FloatingActionButton(
            tooltip: 'Add a new resource',
            onPressed: () => showDialog<CreateResourcDialog>(
              context: context,
              builder: (context) => CreateResourcDialog(
                skills: state.allSkills,
                userProfile: state.usersProfile!,
                resource: null,
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
