import 'package:flutter/widgets.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';

/// Makes the shared settings controller available to in-app preference menus.
class SettingsControllerScope extends InheritedNotifier<SettingsController> {
  const SettingsControllerScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SettingsControllerScope>()
      ?.notifier;
}
