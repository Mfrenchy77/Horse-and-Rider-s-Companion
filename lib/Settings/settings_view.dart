import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings_text),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from Sthe dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(S.of(context).settings_theme_picker),
                ),
                DropdownButton<ThemeMode>(
                  // Read the selected themeMode from the controller
                  value: controller.darkMode,
                  onChanged: controller.updateThemeMode,
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(S.of(context).settings_system),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(S.of(context).settings_light),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(S.of(context).settings_dark),
                    ),
                  ],
                ),
              ],
            ),
            gap(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: SharedPrefs().isSeasonalMode(),
                    onChanged: (value) {
                      debugPrint('Value: $value');
                      debugPrint(
                        'Seasonal Mode: ${SharedPrefs().isSeasonalMode()}',
                      );
                      controller.updateSeasonalMode();
                    },
                    title: SharedPrefs().isSeasonalMode()
                        ? Text(S.of(context).settings_seasonal_disable)
                        : Text(S.of(context).settings_seasonal_enable),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
