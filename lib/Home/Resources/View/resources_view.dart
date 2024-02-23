// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/Resources/View/resource_item.dart';
import 'package:responsive_framework/responsive_framework.dart';

Widget resourcesView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  return Scaffold(
    floatingActionButton: Visibility(
      visible: !state.isGuest,
      child: FloatingActionButton(
        onPressed: () => homeCubit.createOrEditResource(
          resource: null,
          context: context,
        ),
        child: const Icon(
          Icons.add,
        ),
      ),
    ),
    appBar: AppBar(
      leading: Visibility(
        visible: // smallscreen
            MediaQuery.of(context).size.width < 800,
        child: IconButton(
          onPressed: homeCubit.navigateToTrainingPathList,
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
      ),
      actions: _appBarActions(
        state: state,
        homeCubit: homeCubit,
        context: context,
      ),
      titleSpacing: 0,
      centerTitle: true,
      title: appBarTitle(),
    ),
    body: Center(
      child: ListView(
        children: [
          Text(
            state.resourcesSortStatus == ResourcesSortStatus.oldest
                ? 'Resources - Oldest'
                : state.resourcesSortStatus ==
                        ResourcesSortStatus.mostRecommended
                    ? 'Resources - Most Recommended'
                    : state.resourcesSortStatus == ResourcesSortStatus.recent
                        ? 'Resources - Most Recent'
                        : 'Resources - Saved',
            style: const TextStyle(fontSize: 24),
          ),
          smallGap(),
          if (state.resourcesSortStatus == ResourcesSortStatus.saved)
            state.savedResources != null
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
          else
            state.allResources != null
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
        ],
      ),
    ),
  );
}

List<Widget> _appBarActions({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  final isMobile = ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);
  final isTabletOrLarger = ResponsiveBreakpoints.of(context).largerThan(TABLET);
  return [
    IconButton(
      onPressed: () {},
      icon: const Icon(Icons.search),
    ),
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
    Visibility(
      visible: !isMobile,
      child: Tooltip(
        message: 'Sort Resources',
        child: IconButton(
          onPressed: () => homeCubit.openSortDialog(context),
          icon: const Icon(
            Icons.sort,
          ),
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
