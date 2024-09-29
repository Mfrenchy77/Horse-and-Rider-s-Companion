// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: const ProfileBackButton(
        //   key: Key('backButton'),
        // ),
        actions: const [
          ProfileSearchButton(
            key: Key('HorseSearchButton'),
          ),
          HorseProfileOverFlowMenu(
            key: Key('RiderProfileOverFlowMenu'),
          ),
        ],
        title: const AppTitle(
          key: Key('appTitle'),
        ),
      ),
      body: AdaptiveLayout(
        internalAnimations: false,
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => SingleChildScrollView(
                child: HorseProfilePrimaryView(
                  horseProfile: horseProfile,
                  key: const Key('HorseProfilePrimaryView'),
                ),
              ),
            ),
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  HorseProfilePrimaryView(
                    horseProfile: horseProfile,
                    key: const Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  ProfileSkills(
                    skillLevels: horseProfile.skillLevels,
                    key: const Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
            Breakpoints.mediumLarge: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  HorseProfilePrimaryView(
                    horseProfile: horseProfile,
                    key: const Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  ProfileSkills(
                    skillLevels: horseProfile.skillLevels,
                    key: const Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
            Breakpoints.small: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  HorseProfilePrimaryView(
                    horseProfile: horseProfile,
                    key: const Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  ProfileSkills(
                    skillLevels: horseProfile.skillLevels,
                    key: const Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
          },
        ),
        secondaryBody: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('secondary'),
              builder: (context) => ListView(
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
          },
        ),
      ),
    );
  }
}
