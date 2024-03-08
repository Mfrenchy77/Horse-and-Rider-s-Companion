// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_back_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_floating_action_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_list_view.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_search_title.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResourcesView extends StatelessWidget {
  const ResourcesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ResourcesFloatingActionButton(
        key: Key('resourcesFloatingActionButton'),
      ),
      appBar: AppBar(
        leading: const AppBarBackButton(
          key: Key('appBarBackButton'),
        ),
        centerTitle: true,
        title: const ResourcesSearchTitle(
          key: Key('resourcesSearchTitle'),
        ),
        actions: const [
          AppBarSearchButton(
            key: Key('appBarSearchButton'),
          ),
          ResourcesOverflowMenu(
            key: Key('resourcesOverflowMenu'),
          ),
        ],
      ),
      body: const ResourcesListView(
        key: Key('resourcesListView'),
      ),
    );
  }
}

Widget resourcesView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  return Scaffold(
    floatingActionButton: const ResourcesFloatingActionButton(
      key: Key('resourcesFloatingActionButton'),
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
      title: const AppTitle(
        key: Key('appTitle'),
      ),
    ),
    body: const ResourcesListView(
      key: Key('resourcesListView'),
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
