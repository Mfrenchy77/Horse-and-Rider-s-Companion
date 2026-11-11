import 'package:flutter/widgets.dart';

enum ResourceLayout { vertical, horizontal }

/// Publishes the current preference to every resource surface.
class ResourceLayoutScope extends InheritedWidget {
  const ResourceLayoutScope({
    super.key,
    required this.layout,
    required super.child,
  });

  final ResourceLayout layout;

  static ResourceLayout of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ResourceLayoutScope>()
          ?.layout ??
      ResourceLayout.vertical;

  @override
  bool updateShouldNotify(ResourceLayoutScope oldWidget) =>
      layout != oldWidget.layout;
}
