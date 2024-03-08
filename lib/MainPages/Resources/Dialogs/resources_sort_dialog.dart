import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

class ResourcesSortDialog extends StatelessWidget {
  const ResourcesSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return AlertDialog(
          title: const Text('Sort Resources'),
          content: DropdownButton<ResourcesSortStatus>(
            value: state.resourcesSortStatus,
            onChanged: (ResourcesSortStatus? newValue) {
              if (newValue != null) {
                cubit.updateResourceSortStatus(newValue);
                Navigator.of(context).pop();
              }
            },
            items: ResourcesSortStatus.values.map((ResourcesSortStatus status) {
              return DropdownMenuItem<ResourcesSortStatus>(
                value: status,
                child: Text(_getSortOptionLabel(status)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getSortOptionLabel(ResourcesSortStatus sortStatus) {
    switch (sortStatus) {
      case ResourcesSortStatus.mostRecommended:
        return 'Most Recommended';
      case ResourcesSortStatus.recent:
        return 'Most Recent';
      case ResourcesSortStatus.saved:
        return 'Saved';
      case ResourcesSortStatus.oldest:
        return 'Oldest';
    }
  }
}
