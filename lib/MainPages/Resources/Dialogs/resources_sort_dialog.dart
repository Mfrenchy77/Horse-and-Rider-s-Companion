import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart'; // where AppCubit/AppState/ResourcesSortStatus live
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';

class ResourcesSortDialog extends StatelessWidget {
  const ResourcesSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final selected =
        context.select((AppCubit c) => c.state.resourcesSortStatus);

    void submit(ResourcesSortStatus? value) {
      if (value == null) return;
      cubit.updateResourceSortStatus(value);
      Navigator.of(context).pop();
    }

    return OceanCoralAppDialog(
      title: const Text('Sort Resources'),
      content: RadioGroup<ResourcesSortStatus>(
        groupValue: selected,
        onChanged: submit,
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
