import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/back_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';

class RiderProfileView extends StatelessWidget {
  const RiderProfileView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            //back if viewing profile
            leading: !state.isGuest && state.viewingProfile != null
                ? const ProfileBackButton(
                    key: Key('ProfileBackButton'),
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
          drawer: state.isGuest || state.viewingProfile != null
              ? null
              : const UserProfileDrawer(),
          body: AdaptiveLayout(
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
                      const ProfileSkills(
                        key: Key('ProfileSkills'),
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
                        const PrimaryRiderView(
                          key: Key('ProfileView'),
                        ),
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
                ),
                Breakpoints.medium: SlotLayout.from(
                  key: const Key('mediumProfilePrimaryBody'),
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    children: [
                      const PrimaryRiderView(
                        key: Key('ProfileView'),
                      ),
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
                Breakpoints.large: SlotLayout.from(
                  key: const Key('largeProfilePrimaryBody'),
                  builder: (context) => const SingleChildScrollView(
                    child: PrimaryRiderView(
                      key: Key('ProfileView'),
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
