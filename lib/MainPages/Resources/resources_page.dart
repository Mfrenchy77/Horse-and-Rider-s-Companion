import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_view.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});
  static const path = '/Resources';
  static const name = 'Resources';
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        debugPrint('ResourcesPage: Pop Invoked');
      },
      child: const ResourcesView(
        key: Key('resourcesView'),
      ),
    );
  }
}
