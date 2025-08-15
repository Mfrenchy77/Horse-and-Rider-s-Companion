import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart'; // where AppCubit/AppState/ResourcesSortStatus live

class ResourcesSortDialog extends StatelessWidget {
  const ResourcesSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return AlertDialog(
          title: const Text('Sort Resources'),
          content: RadioGroup<ResourcesSortStatus>(
            groupValue: state.resourcesSortStatus,
            onChanged: (ResourcesSortStatus? newValue) {
              if (newValue == null) return;
              cubit.updateResourceSortStatus(newValue);
              Navigator.of(context).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ResourcesSortStatus.values
                  .map(
                    (status) => RadioListTile<ResourcesSortStatus>(
                      title: Text(_getSortOptionLabel(status)),
                      value: status,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  String _getSortOptionLabel(ResourcesSortStatus sortStatus) {
    switch (sortStatus) {
      case ResourcesSortStatus.leastRecommended:
        return 'Least Recommended';
      case ResourcesSortStatus.mostRecommended:
        return 'Most Recommended';
      case ResourcesSortStatus.recent:
        return 'Recent';
      case ResourcesSortStatus.saved:
        return 'Saved';
      case ResourcesSortStatus.oldest:
        return 'Oldest';
    }
  }
}
