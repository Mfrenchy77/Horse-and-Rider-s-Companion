// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_primary_view.dart';

class HorseProfileView extends StatelessWidget {
  const HorseProfileView({super.key, required this.horseProfile});
  final HorseProfile horseProfile;

  static const double largeBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(key: Key('appTitle')),
        actions: const [
          ProfileSearchButton(key: Key('HorseSearchButton')),
          HorseProfileOverFlowMenu(key: Key('RiderProfileOverFlowMenu')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= largeBreakpoint;

          if (isLarge) {
            // Large screen: split view
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ListView(
                    children: [
                      HorseProfilePrimaryView(
                        horseProfile: horseProfile,
                        key: const Key('HorseProfilePrimaryView'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView(
                    children: [
                      const ProfileSkillsBanner(
                        key: Key('ProfileSkillsBanner'),
                      ),
                      gap(),
                      ProfileSkills(
                        skillLevels: horseProfile.skillLevels,
                        key: const Key('ProfileSkills'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Small & medium: stacked layout
          return ListView(
            children: [
              HorseProfilePrimaryView(
                horseProfile: horseProfile,
                key: const Key('HorseProfilePrimaryView'),
              ),
              gap(),
              const SkillsTextButton(key: Key('SkillsTextButton')),
              gap(),
              ProfileSkills(
                skillLevels: horseProfile.skillLevels,
                key: const Key('ProfileSkills'),
              ),
            ],
          );
        },
      ),
    );
  }
}
