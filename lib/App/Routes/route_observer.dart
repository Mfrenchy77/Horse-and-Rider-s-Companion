import 'package:flutter/material.dart';

/// A [RouteObserver] that provides callbacks for
///  when routes are pushed and popped.
class RouteObserverWithCallback extends RouteObserver<PageRoute<dynamic>> {
  RouteObserverWithCallback({
    required this.onPop,
    required this.onPush,
  });

  /// A callback that is called when a route is popped. Showing
  /// the route that is shown and where it was popped from.
  final void Function(Route<dynamic>, Route<dynamic>?) onPop;

  /// A callback that is called when a route is pushed. Showing
  /// the route that is shown and where it was pushed from.
  final void Function(Route<dynamic>, Route<dynamic>?) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPush(route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // debugPrint('Replaced route from $oldRoute '
    //     'to $newRoute');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // debugPrint('Removed route from $previousRoute '
    //     'to $route');
  }
}
