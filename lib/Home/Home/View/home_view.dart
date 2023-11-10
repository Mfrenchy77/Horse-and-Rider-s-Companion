// ignore_for_file: cast_nullable_to_non_nullable

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Home/Home/RidersLog/riders_log_view.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/Resources/View/resources_view.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/profile_view.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/search_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/support_message_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/skill_tree_view_filters.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.user,
    required this.buildContext,
    this.viewingProfile,
  });

  final RiderProfile? viewingProfile;
  final User user;
  final BuildContext buildContext;

  @override
  Widget build(Object context) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          final homeCubit = context.read<HomeCubit>();

          ///Open a dialog to send a message to support

          if (state.isSendingMessageToSupport) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              showDialog<SupportMessageDialog>(
                context: context,
                builder: (dialogContext) => const SupportMessageDialog(),
              ).then((value) => homeCubit.closeMessageToSupport());
            });
          }

          /// Show Search
          if (state.isSearching) {
            showDialog<SearchDialog>(
              context: context,
              builder: (context) => const SearchDialog(),
            ).then((value) => context.read<HomeCubit>().clearSearch());
          }

          /// Show Error Snackbar
          if (state.errorSnackBar) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
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
                ).closed.then((value) {
                  homeCubit.clearSnackBar();
                });
            });
          }

          /// Show Regular SnackBar
          if (state.snackBar) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor:
                        HorseAndRidersTheme().getTheme().colorScheme.primary,
                    content: Text(
                      state.error,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ).closed.then(
                      (value) => homeCubit.clearSnackBar(),
                    );
            });
          }

          /// Show Message SnackBar
          if (state.messageSnackBar) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    action: SnackBarAction(
                      label: 'Open Messages',
                      onPressed: () => context
                          .read<HomeCubit>()
                          .openMessages(context: context),
                    ),
                    backgroundColor:
                        HorseAndRidersTheme().getTheme().colorScheme.primary,
                    content: Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ).closed.then(
                      (value) => homeCubit.clearSnackBar(),
                    );
            });
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final homeCubit = context.read<HomeCubit>();
            return state.usersProfile != null
                ? _mainView(
                    homeCubit: homeCubit,
                    isViewed: state.isViewing,
                    viewingProfile: state.viewingProfile,
                    usersProfile: state.usersProfile,
                    context: context,
                    user: user,
                    state: state,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Logo(screenName: 'Loading...'),
                        CircularProgressIndicator(),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }
}

Widget _loadingView({
  required BuildContext context,
  required bool isDark,
}) {
  return const Padding(
    padding: EdgeInsets.all(20),
    child: Expanded(child: Center(child: Logo(screenName: 'Loading...'))),
  );
}

Widget _mainView({
  required BuildContext context,
  required User user,
  required HomeState state,
  required RiderProfile? viewingProfile,
  required RiderProfile? usersProfile,
  required bool isViewed,
  required HomeCubit homeCubit,
}) {
  debugPrint('Users Profile: ${state.usersProfile?.name}');
  final isDark = SharedPrefs().isDarkMode;

  return Scaffold(
    body: state.homeStatus == HomeStatus.profile
        ? state.isViewing
            ?

            ///  Go to Rider's Profile
            ProfileView(
                homeCubit: homeCubit,
                isViewing: state.isViewing,
                state: state,
                user: user,
                buildContext: context,
                usersProfile: state.usersProfile,
                viewingProfile: viewingProfile,
              )
            : ProfileView(
                homeCubit: homeCubit,
                user: user,
                state: state,
                isViewing: state.isViewing,
                buildContext: context,
                viewingProfile: null,
                usersProfile: usersProfile,
              )
        : state.homeStatus == HomeStatus.ridersLog
            ? LogView(
                horseState: null,
                isRider: true,
                state: state,
              )
            : state.homeStatus == HomeStatus.skillTree
                ?

                /// Go to the Skill Tree
                SkillTreeViewFilter(
                    usersProfile: usersProfile,
                    homeContext: context,
                  )
                : state.homeStatus == HomeStatus.resource
                    ?

                    /// Go to the Resource View
                    ResourcesView(
                        homeCubit: homeCubit,
                        state: state,
                        usersProfile: usersProfile,
                      )
                    : state.homeStatus == HomeStatus.loading
                        ?

                        ///  Loading Screen
                        _loadingView(context: context, isDark: isDark)
                        : const Center(
                            child: Logo(screenName: ''),
                          ),
    bottomNavigationBar: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.person),
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(HorseAndRiderIcons.riderSkillIcon),
              icon: Icon(HorseAndRiderIcons.riderSkillIcon),
              label: 'Skill Tree',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(HorseAndRiderIcons.resourcesIcon),
              icon: Icon(HorseAndRiderIcons.resourcesIcon),
              label: 'Resources',
            ),
          ],
          currentIndex: state.index,
          onTap: (value) {
            switch (value) {
              case 0:
                homeCubit.riderProfileNavigationSelected();

                break;
              case 1:
                homeCubit.skillTreeNavigationSelected();
                break;

              case 2:
                homeCubit.resourcesNavigationSelected();

                break;
            }
          },

          //   );
          // },
        ),

        //Ad
        _bannerAd(state: state, context: context),
      ],
    ),
  );
}

Widget _bannerAd({required HomeState state, required BuildContext context}) {
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
