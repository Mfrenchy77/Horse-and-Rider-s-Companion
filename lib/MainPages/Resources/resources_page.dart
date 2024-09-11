import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_view.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});
  static const path = '/Resources';
  static const name = 'Resources';
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        debugPrint(
          'Resources Page Pop Invoked: $didPop, result: $result',
        );
      },
      child: const ResourcesView(
        key: Key('resourcesView'),
      ),
    );
  }
}
