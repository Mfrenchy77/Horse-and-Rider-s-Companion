import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
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

  static const double mediumBreakpoint = 600;
  static const double largeBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Scaffold(
          key: Keys.riderProfileScaffoldKey,
          appBar: AppBar(
            leading: profile.email == state.usersProfile?.email
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    key: const Key('HamburgerIcon'),
                    onPressed: () {
                      Keys.riderProfileScaffoldKey.currentState?.openDrawer();
                    },
                  )
                : null,
            title: const AppTitle(key: Key('appTitle')),
            actions: const [
              ProfileSearchButton(key: Key('RiderSearchButton')),
              RiderProfileOverFlowMenu(key: Key('RiderProfileOverFlowMenu')),
            ],
          ),
          drawer: profile.email == state.usersProfile?.email
              ? const UserProfileDrawer()
              : null,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              if (screenWidth >= largeBreakpoint) {
                // Split layout: profile left, skills right
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView(
                        children: [
                          PrimaryRiderView(
                            profile: profile,
                            key: const Key('ProfileView'),
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
                            skillLevels: profile.skillLevels,
                            key: const Key('ProfileSkills'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Single column layout
              return SingleChildScrollView(
                child: Column(
                  children: [
                    PrimaryRiderView(
                      profile: profile,
                      key: const Key('ProfileView'),
                    ),
                    const SkillsTextButton(key: Key('SkillsTextButton')),
                    gap(),
                    ProfileSkills(
                      skillLevels: profile.skillLevels,
                      key: const Key('ProfileSkills'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
