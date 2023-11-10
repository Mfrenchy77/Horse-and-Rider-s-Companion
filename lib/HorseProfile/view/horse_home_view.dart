import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/skilltree_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/skill_tree_view_filters.dart';
import 'package:horseandriderscompanion/HorseProfile/cubit/horse_profile_cubit.dart';
import 'package:horseandriderscompanion/HorseProfile/view/horse_profile_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class HorseHomeView extends StatelessWidget {
  const HorseHomeView({this.usersProfile, super.key});
  final RiderProfile? usersProfile;
  @override
  Widget build(BuildContext context) {
    const skillTreeState = SkilltreeState();
    return Container(
      child: BlocListener<HorseHomeCubit, HorseHomeState>(
        listener: (context, state) {
          final horseHomeCubit = context.read<HorseHomeCubit>();
          if (state.isErrorSnackBar) {
            SchedulerBinding.instance.addPostFrameCallback((timestamp) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.error,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                ).closed.then(
                      (value) => horseHomeCubit.clearErrorSnackBar(),
                    );
            });
          }
          if (state.isSnackbar) {
            SchedulerBinding.instance.addPostFrameCallback((timestamp) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        HorseAndRidersTheme().getTheme().colorScheme.primary,
                  ),
                ).closed.then(
                      (value) => horseHomeCubit.clearSnackbar(),
                    );
            });
          }
        },
        child: BlocBuilder<HorseHomeCubit, HorseHomeState>(
          builder: (context, state) {
            final horseHomeCubit = context.read<HorseHomeCubit>();
            return Scaffold(
              body: state.horseHomePageStatus == HorseHomePageStatus.profile
                  ? HorseProfileView(
                      horseHomeCubit: horseHomeCubit,
                      usersProfile: usersProfile,
                      state: state,
                    )
                  : state.horseHomePageStatus == HorseHomePageStatus.skillTree
                      ? SkillTreeViewFilter(
                        usersProfile: usersProfile,
                          homeContext: context,
                        )
                      : const Center(child: Logo(screenName: '')),
              bottomNavigationBar: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BottomNavigationBar(
                    currentIndex: state.index,
                    onTap: (value) {
                      switch (value) {
                        case 0:
                          context.read<HorseHomeCubit>().horseProfileSelected();
                          break;
                        case 1:
                          context.read<HorseHomeCubit>().skillTreeSelected();
                          break;
                      }
                    },
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(HorseAndRiderIcons.horseIconOpen),
                        label: 'Profile',
                        activeIcon: Icon(
                          HorseAndRiderIcons.horseIcon,
                        ),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(HorseAndRiderIcons.horseSkillIcon),
                        label: 'Skill Tree',
                        activeIcon: Icon(
                          HorseAndRiderIcons.horseSkillIcon,
                        ),
                      ),
                    ],
                  ),
                  _bannerAd(state: state, context: context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _bannerAd({
  required HorseHomeState state,
  required BuildContext context,
}) {
  if (state.isBannerAdReady) {
    return Visibility(
      visible: state.isBannerAdReady,
      child: Container(
        color: HorseAndRidersTheme().getTheme().primaryColor,
        width: double.infinity,
        height: state.bannerAd?.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: state.bannerAd!),
      ),
    );
  } else {
    return const SizedBox();
  }
}
