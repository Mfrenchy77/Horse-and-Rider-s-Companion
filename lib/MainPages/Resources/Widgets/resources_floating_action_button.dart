import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/quick_share_resource_page.dart';

class ResourcesFloatingActionButton extends StatelessWidget {
  const ResourcesFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.isGuest) {
          return FloatingActionButton.extended(
            key: const Key('signInToShareResource'),
            icon: const Icon(Icons.login),
            label: const Text('Sign in to share'),
            onPressed: () => context.goNamed(
              AuthPage.name,
              queryParameters: {'mode': 'login'},
            ),
          );
        }
        final user = state.usersProfile;
        if (user == null) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          key: const Key('addResourceButton'),
          icon: const Icon(Icons.add),
          label: const Text('Add resource'),
          tooltip: 'Add a link or upload a PDF',
          onPressed: () => QuickShareResourcePage.open(
            context,
            skills: state.allSkills,
            profile: user,
          ),
        );
      },
    );
  }
}
