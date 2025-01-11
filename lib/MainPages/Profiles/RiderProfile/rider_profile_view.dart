import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/primary_rider_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/Utilities/keys.dart';

class RiderProfileView extends StatelessWidget {
  const RiderProfileView({
    required this.profile,
    super.key,
  });
  final RiderProfile profile;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Scaffold(
          key: Keys.riderProfileScaffoldKey,
          appBar: AppBar(
            leading: profile.email == state.usersProfile?.email
                ? //hambuger icon
                IconButton(
                  icon: const Icon(Icons.menu),
                  key: const Key('HamburgerIcon'),
                  onPressed: () {
                    Keys.riderProfileScaffoldKey.currentState?.openDrawer();
                  },
                )
                : null,
            title: const AppTitle(
              key: Key('appTitle'),
            ),
            actions: const <Widget>[
              ProfileSearchButton(
                key: Key('RiderSearchButton'),
              ),
              RiderProfileOverFlowMenu(
                key: Key('RiderProfileOverFlowMenu'),
              ),
            ],
          ),
          drawer: profile.email == state.usersProfile?.email
              ? const UserProfileDrawer()
              : null,
          body: AdaptiveLayout(
            internalAnimations: false,
            secondaryBody: SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                Breakpoints.large: SlotLayout.from(
                  key: const Key('smallProfileSecondaryBody'),
                  builder: (context) => ListView(
                    children: [
                      const ProfileSkillsBanner(
                        key: Key('ProfileSkillsBanner'),
                      ),
                      gap(),
                      ProfileSkills(
                        skillLevels: profile.skillLevels,
                        key: const Key('ProfileSkills'),
                      ),
                    ],
                  ),
                ),
              },
            ),
            body: SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                Breakpoints.small: SlotLayout.from(
                  key: const Key('smallProfilePrimaryBody'),
                  builder: (context) => SingleChildScrollView(
                    child: Column(
                      // needed for scrolling on mobile web
                      children: [
                        PrimaryRiderView(
                          profile: profile,
                          key: const Key('ProfileView'),
                        ),
                        const SkillsTextButton(
                          key: Key('SkillsTextButton'),
                        ),
                        gap(),
                        ProfileSkills(
                          skillLevels: profile.skillLevels,
                          key: const Key('ProfileSkills'),
                        ),
                      ],
                    ),
                  ),
                ),
                Breakpoints.medium: SlotLayout.from(
                  key: const Key('mediumProfilePrimaryBody'),
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    children: [
                      PrimaryRiderView(
                        profile: profile,
                        key: const Key('ProfileView'),
                      ),
                      const SkillsTextButton(
                        key: Key('SkillsTextButton'),
                      ),
                      gap(),
                      ProfileSkills(
                        skillLevels: profile.skillLevels,
                        key: const Key('ProfileSkills'),
                      ),
                    ],
                  ),
                ),
                Breakpoints.mediumLarge: SlotLayout.from(
                  key: const Key('mediumLargeProfilePrimaryBody'),
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    children: [
                      PrimaryRiderView(
                        profile: profile,
                        key: const Key('ProfileView'),
                      ),
                      const SkillsTextButton(
                        key: Key('SkillsTextButton'),
                      ),
                      gap(),
                      ProfileSkills(
                        skillLevels: profile.skillLevels,
                        key: const Key('ProfileSkills'),
                      ),
                    ],
                  ),
                ),
                Breakpoints.large: SlotLayout.from(
                  key: const Key('largeProfilePrimaryBody'),
                  builder: (context) => SingleChildScrollView(
                    child: PrimaryRiderView(
                      profile: profile,
                      key: const Key('ProfileView'),
                    ),
                  ),
                ),
              },
            ),
          ),
        );
      },
    );
  }
}
