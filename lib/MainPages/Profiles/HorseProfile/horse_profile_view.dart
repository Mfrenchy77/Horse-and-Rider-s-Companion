// ignore_for_file: cast_nullable_to_non_nullable

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
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/back_button.dart';

class HorseProfileView extends StatelessWidget {
  const HorseProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const ProfileBackButton(
          key: Key('backButton'),
        ),
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
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => const SingleChildScrollView(
                child: HorseProfilePrimaryView(
                  key: Key('HorseProfilePrimaryView'),
                ),
              ),
            ),
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  const HorseProfilePrimaryView(
                    key: Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  const ProfileSkills(
                    key: Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
            Breakpoints.small: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  const HorseProfilePrimaryView(
                    key: Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  const ProfileSkills(
                    key: Key('ProfileSkills'),
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
                  const ProfileSkills(
                    key: Key('ProfileSkills'),
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
