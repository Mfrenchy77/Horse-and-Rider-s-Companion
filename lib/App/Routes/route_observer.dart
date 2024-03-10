import 'package:flutter/material.dart';

class RoouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Pushed route from ${previousRoute?.settings.name} '
        'to ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Popped route from ${route.settings.name} '
        'to ${previousRoute?.settings.name}');
  }
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('Replaced route from ${oldRoute?.settings.name} '
        'to ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Removed route from ${route.settings.name} '
        'to ${previousRoute?.settings.name}');
  }
  
}
