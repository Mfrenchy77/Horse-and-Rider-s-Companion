// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_floating_action_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_list_view.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_search_title.dart';

class ResourcesView extends StatelessWidget {
  const ResourcesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ResourcesFloatingActionButton(
        key: Key('resourcesFloatingActionButton'),
      ),
      appBar: AppBar(
        // leading: const AppBarBackButton(
        //   key: Key('appBarBackButton'),
        // ),
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
