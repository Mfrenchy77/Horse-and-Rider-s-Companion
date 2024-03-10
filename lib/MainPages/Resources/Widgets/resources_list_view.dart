import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_item.dart';

class ResourcesListView extends StatelessWidget {
  const ResourcesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Center(
          child: ListView(
            children: [
              Text(
                state.resourcesSortStatus == ResourcesSortStatus.oldest
                    ? 'Resources - Oldest'
                    : state.resourcesSortStatus ==
                            ResourcesSortStatus.mostRecommended
                        ? 'Resources - Most Recommended'
                        : state.resourcesSortStatus ==
                                ResourcesSortStatus.recent
                            ? 'Resources - Most Recent'
                            : 'Resources - Saved',
                style: const TextStyle(fontSize: 20),
              ),
              smallGap(),
              if (state.resourcesSortStatus == ResourcesSortStatus.saved)
                state.savedResources.isNotEmpty
                    ? Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 4,
                        children: state.savedResources
                            .map(
                              (e) => ResourcesItem(
                                resource: e!,
                                isResourceList: true,
                              ),
                            )
                            .toList(),
                      )
                    : const Text('No Resources Found')
              else
                state.resources.isNotEmpty
                    ? Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 4,
                        children: state.resources
                            .map(
                              (e) => ResourcesItem(
                                resource: e!,
                                isResourceList: true,
                              ),
                            )
                            .toList(),
                      )
                    : const Text('No Resources Found'),
            ],
          ),
        );
      },
    );
  }
}
