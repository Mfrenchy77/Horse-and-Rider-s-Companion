import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

class SaveResourceButton extends StatelessWidget {
  const SaveResourceButton({super.key, required this.resource});
  final Resource resource;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<AppCubit>();
    final (isGuest, isSaved) = context.select(
      (AppCubit c) => (
        c.state.isGuest,
        resource.id != null &&
            (c.state.usersProfile?.savedResourcesList?.contains(resource.id) ??
                false),
      ),
    );

    return IconButton(
      tooltip: 'Save Resource',
      onPressed: isGuest ? null : () => cubit.saveResource(resource: resource),
      icon: isSaved
          ? const Icon(Icons.favorite)
          : const Icon(Icons.favorite_border),
      color: isSaved
          ? Colors.red
          : isDark
          ? Colors.grey.shade300
          : Colors.black54,
    );
  }
}
