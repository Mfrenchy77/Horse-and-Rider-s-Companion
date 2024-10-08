import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/Widgets/guest_profile_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/Widgets/guest_profile_skills.dart';

class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(
          key: Key('appTitle'),
        ),
        actions: const [
          ProfileSearchButton(
            key: Key('GuestSearchButton'),
          ),
        ],
      ),
      body: AdaptiveLayout(
        internalAnimations: false,
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('largeProfileBody'),
              builder: (context) => const GuestProfilePrimaryView(
                key: Key('GuestProfilePrimaryView'),
              ),
            ),
            Breakpoints.small: SlotLayout.from(
              key: const Key('smallProfileBody'),
              builder: (context) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GuestProfilePrimaryView(
                      key: Key('GuestProfilePrimaryView'),
                    ),
                    const SkillsTextButton(
                      key: Key('SkillsTextButton'),
                    ),
                    gap(),
                    const GuestProfileSkills(
                      key: Key('GuestProfileSkills'),
                    ),
                  ],
                ),
              ),
            ),
            Breakpoints.medium: SlotLayout.from(
              key: const Key('mediumProfileBody'),
              builder: (context) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GuestProfilePrimaryView(
                      key: Key('GuestProfilePrimaryView'),
                    ),
                    const SkillsTextButton(
                      key: Key('SkillsTextButton'),
                    ),
                    gap(),
                    const GuestProfileSkills(
                      key: Key('GuestProfileSkills'),
                    ),
                  ],
                ),
              ),
            ),
            Breakpoints.mediumLarge: SlotLayout.from(
              key: const Key('mediumLargeProfileBody'),
              builder: (context) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GuestProfilePrimaryView(
                      key: Key('GuestProfilePrimaryView'),
                    ),
                    const SkillsTextButton(
                      key: Key('SkillsTextButton'),
                    ),
                    gap(),
                    const GuestProfileSkills(
                      key: Key('GuestProfileSkills'),
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
        secondaryBody: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('largeProfileSecondaryBody'),
              builder: (context) => ListView(
                children: [
                  const ProfileSkillsBanner(
                    key: Key('ProfileSkillsBanner'),
                  ),
                  gap(),
                  const GuestProfileSkills(
                    key: Key('GuestProfileSkills'),
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
