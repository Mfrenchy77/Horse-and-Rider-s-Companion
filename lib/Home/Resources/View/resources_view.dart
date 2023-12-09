// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/Resources/View/resource_item.dart';
import 'package:responsive_framework/responsive_framework.dart';

Widget resourcesView() {
  return BlocBuilder<HomeCubit, HomeState>(
    builder: (context, state) {
      final homeCubit = context.read<HomeCubit>();
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: homeCubit.skillTreeNavigationSelected,
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          actions: _appBarActions(
            state: state,
            homeCubit: homeCubit,
            context: context,
          ),
          title: BlocBuilder<HomeCubit, HomeState>(
            buildWhen: (previous, current) =>
                previous.resourcesSortStatus != current.resourcesSortStatus,
            builder: (context, state) {
              return Text(
                state.resourcesSortStatus == ResourcesSortStatus.oldest
                    ? 'Resources - Oldest'
                    : state.resourcesSortStatus ==
                            ResourcesSortStatus.mostRecommended
                        ? 'Resources - Most Recommended'
                        : state.resourcesSortStatus ==
                                ResourcesSortStatus.recent
                            ? 'Resources - Most Recent'
                            : 'Resources - Saved',
                style: const TextStyle(),
              );
            },
          ),
        ),
        body: Center(
          child: BlocBuilder<HomeCubit, HomeState>(
            buildWhen: (previous, current) =>
                previous.allResources != current.allResources,
            builder: (context, state) {
              return SingleChildScrollView(
                child: state.resourcesSortStatus == ResourcesSortStatus.saved
                    ? state.savedResources != null
                        ? Wrap(
                            alignment: WrapAlignment.center,
                            runSpacing: 4,
                            children: state.savedResources!
                                .map(
                                  (e) => resourceItem(
                                    resource: e!,
                                    isResourceList: true,
                                    usersWhoRated: e.usersWhoRated,
                                  ),
                                )
                                .toList(),
                          )
                        : const Text('No Resources Found')
                    : state.allResources != null
                        ? Wrap(
                            alignment: WrapAlignment.center,
                            runSpacing: 4,
                            children: state.allResources!
                                .map(
                                  (e) => resourceItem(
                                    resource: e!,
                                    isResourceList: true,
                                    usersWhoRated: e.usersWhoRated,
                                  ),
                                )
                                .toList(),
                          )
                        : const Text('No Resources Found'),
              );
            },
          ),
        ),
      );
    },
  );
}

// TODO(mfrenchy): This is all wonky and needs to be fixed
// items are not in the right order
List<Widget> _appBarActions({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  final isMobile = ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);
  final isTabletOrLarger = ResponsiveBreakpoints.of(context).largerThan(TABLET);
  return [
    if (isMobile)
      Visibility(
        visible: !state.isGuest,
        child: PopupMenuButton<String>(
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Add',
              child: Text('Add'),
            ),
            const PopupMenuItem<String>(
              value: 'Edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem<String>(value: 'Sort', child: Text('Sort')),
          ],
          onSelected: (value) {
            switch (value) {
              case 'Add':
                homeCubit.createOrEditResource(
                  resource: null,
                  context: context,
                );
                break;
              case 'Edit':
                homeCubit.toggleIsEditState();
                break;
              case 'Sort':
                homeCubit.openSortDialog(context);
                break;
            }
          },
        ),
      ),
    Tooltip(
      message: 'Sort Resources',
      child: IconButton(
        onPressed: () => homeCubit.openSortDialog(context),
        icon: const Icon(
          Icons.sort,
        ),
      ),
    ),
    if (isTabletOrLarger)
      Visibility(
        visible: state.usersProfile?.editor ?? false,
        child: Row(
          children: [
            Tooltip(
              message: 'Add Resource',
              child: IconButton(
                onPressed: () => context
                    .read<HomeCubit>()
                    .createOrEditResource(resource: null, context: context),
                icon: const Icon(
                  Icons.add,
                ),
              ),
            ),
            smallGap(),
            Tooltip(
              message: 'Edit Resource',
              child: IconButton(
                onPressed: () => homeCubit.toggleIsEditState(),
                icon: const Icon(
                  Icons.edit,
                ),
              ),
            ),
            smallGap(),
          ],
        ),
      ),
  ];
}
