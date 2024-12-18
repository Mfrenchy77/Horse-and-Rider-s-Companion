import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.controller,
  });

  static const routeName = 'Settings';
  static const name = 'SettingsView';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: appCubit.resetProfileSetup,
        // ),
        title: const Text('Settings'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Center(
            child: MaxWidthBox(
              maxWidth: 800,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    smallGap(),
                    Divider(
                      color: Theme.of(context).colorScheme.secondary,
                      indent: 8,
                      endIndent: 8,
                    ),
                    gap(),
                    Row(
                      children: [
                        // Theme
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Choose a Theme'),
                        ),
                        DropdownButton<ThemeMode>(
                          value: controller.darkMode,
                          onChanged: controller.updateThemeMode,
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System Theme'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light Theme'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark Theme'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    gap(),

                    // Disable/Enable Seasonal Theme
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: controller.seasonalMode,
                            onChanged: (value) {
                              controller.updateSeasonalMode();
                            },
                            title: controller.seasonalMode
                                ? const Text('Disable seasonal theme?')
                                : const Text('Enable seasonal theme?'),
                          ),
                        ),
                      ],
                    ),
                    gap(),
                    // Units
                    Text(
                      'Units',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    smallGap(),
                    Divider(
                      color: Theme.of(context).colorScheme.secondary,
                      indent: 8,
                      endIndent: 8,
                    ),
                    gap(),
                    // Horse Height Units
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Horse Height'),
                        ),
                        DropdownButton<bool>(
                          value: controller.isHands,
                          onChanged: (value) =>
                              controller.updateHorseHeightUnit(),
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Centimeters'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Hands'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    gap(),
                    // Horse Weight Units
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Horse Weight'),
                        ),
                        DropdownButton<bool>(
                          value: controller.isPounds,
                          onChanged: (value) =>
                              controller.updateHorseWeightUnit(),
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Kilograms'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Pounds'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    gap(),
                    Divider(
                      color: Theme.of(context).colorScheme.secondary,
                      indent: 8,
                      endIndent: 8,
                    ),
                    gap(),
                    // Show onboarding
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Reset opening tutorial'),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.updateOnboardingStatus();
                              },
                              child: const Text('Reset Tutorial'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
