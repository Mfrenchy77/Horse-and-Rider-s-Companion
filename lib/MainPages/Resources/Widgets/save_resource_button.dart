import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

class SaveResourceButton extends StatelessWidget {
  const SaveResourceButton({super.key, required this.resource});
  final Resource resource;
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
    // if the state.usersProfile.savedResources contains the resource.id

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isSaved = state.usersProfile?.savedResourcesList
                ?.firstWhere(
                  (element) => element == resource.id,
                  orElse: () => '',
                )
                .isNotEmpty ??
            false;
        return IconButton(
          tooltip: 'Save Resource',
          onPressed: state.isGuest
              ? null
              : () {
                  cubit.saveResource(resource: resource);
                },
          icon: isSaved
              ? const Icon(Icons.favorite)
              : const Icon(Icons.favorite_border),
          color: isSaved
              ? Colors.red
              : isDark
                  ? Colors.grey.shade300
                  : Colors.black54,
        );
      },
    );
  }
}
