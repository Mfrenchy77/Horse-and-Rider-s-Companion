import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_view.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});
  static const routeName = '/resources';
  static Page<void> page() => const MaterialPage<void>(child: ResourcesPage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ResourcesPage());
  }

  @override
  Widget build(BuildContext context) {
    return const NavigatorView(
      body: ResourcesView(
        key: Key('resourcesView'),
      ),
    );
  }
}
