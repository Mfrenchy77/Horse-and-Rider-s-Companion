import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/Widgets/guest_profile_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/Widgets/guest_profile_skills.dart';

class GuestProfile extends StatelessWidget {
  const GuestProfile({super.key});

  static const double mediumBreakpoint = 600;
  static const double largeBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(key: Key('appTitle')),
        actions: const [
          ProfileSearchButton(key: Key('GuestSearchButton')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          if (screenWidth >= largeBreakpoint) {
            // Large layout: split view with side column
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ListView(
                    key: const Key('largeProfileBody'),
                    children: const [
                      GuestProfilePrimaryView(
                        key: Key('GuestProfilePrimaryView'),
                      ),
                    ],
                  ),
                ),
                // const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: ListView(
                    key: const Key('largeProfileSecondaryBody'),
                    children: [
                      const ProfileSkillsBanner(
                        key: Key('ProfileSkillsBanner'),
                      ),
                      gap(),
                      const GuestProfileSkills(key: Key('GuestProfileSkills')),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Small & Medium layout: single column scroll view
            return SingleChildScrollView(
              key: const Key('compactProfileBody'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GuestProfilePrimaryView(
                    key: Key('GuestProfilePrimaryView'),
                  ),
                  const SkillsTextButton(key: Key('SkillsTextButton')),
                  gap(),
                  const GuestProfileSkills(key: Key('GuestProfileSkills')),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
