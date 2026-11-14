import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = 'Settings';
  static const name = 'SettingsView';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(
        title: const Text('Settings'),
      ),
      body: AppScaffoldBackdrop(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Center(
                child: MaxWidthBox(
                  maxWidth: 800,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTokens.spaceLg),
                    children: [
                      const AppSectionHeader(title: 'Theme'),
                      const SizedBox(height: AppTokens.spaceSm),
                      AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<ThemeMode>(
                              initialValue: controller.darkMode,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Choose a Theme',
                                prefixIcon: Icon(Icons.palette_outlined),
                              ),
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
                            const SizedBox(height: AppTokens.spaceSm),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: controller.seasonalMode,
                              onChanged: (_) =>
                                  controller.updateSeasonalMode(),
                              title: Text(
                                controller.seasonalMode
                                    ? 'Disable seasonal theme?'
                                    : 'Enable seasonal theme?',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppTokens.primaryTextColor(
                                        context,
                                      ),
                                    ),
                              ),
                              subtitle: Text(
                                'Show subtle seasonal accents when active.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTokens.secondaryTextColor(
                                        context,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceLg),
                      const AppSectionHeader(title: 'Units & Layout'),
                      const SizedBox(height: AppTokens.spaceSm),
                      AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<bool>(
                              initialValue: controller.isHands,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Horse Height',
                                prefixIcon: Icon(Icons.straighten_outlined),
                              ),
                              onChanged: (_) =>
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
                            const SizedBox(height: AppTokens.spaceMd),
                            DropdownButtonFormField<bool>(
                              initialValue: controller.isPounds,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Horse Weight',
                                prefixIcon: Icon(Icons.monitor_weight_outlined),
                              ),
                              onChanged: (_) =>
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
                            const SizedBox(height: AppTokens.spaceMd),
                            DropdownButtonFormField<ResourceLayout>(
                              initialValue: controller.resourceLayout,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Resources layout',
                                helperText:
                                    'Horizontal cards stack on narrow screens.',
                                prefixIcon: Icon(Icons.view_agenda_outlined),
                              ),
                              onChanged: controller.updateResourceLayout,
                              items: const [
                                DropdownMenuItem(
                                  value: ResourceLayout.vertical,
                                  child: Text('Vertical'),
                                ),
                                DropdownMenuItem(
                                  value: ResourceLayout.horizontal,
                                  child: Text('Horizontal'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spaceMd),
                            DropdownButtonFormField<SkillTreeLayout>(
                              key: const Key('skillTreeLayoutSetting'),
                              initialValue: controller.skillTreeLayout,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Skill Tree layout',
                                prefixIcon: Icon(Icons.account_tree_outlined),
                              ),
                              items: [
                                for (final layout in SkillTreeLayout.values)
                                  DropdownMenuItem(
                                    value: layout,
                                    child: Text(layout.label),
                                  ),
                              ],
                              onChanged: controller.updateSkillTreeLayout,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
