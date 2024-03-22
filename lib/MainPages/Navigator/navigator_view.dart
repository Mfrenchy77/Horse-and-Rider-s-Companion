import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// This is the reusable navigator that shows
///  the bottom app bar on small screens
/// and nav rail on larger screens across all pages.
class NavigatorView extends StatelessWidget {
  /// {@macro navigator_view}
  /// Displays the bottom app bar on small screens
  /// and nav rail on larger screens across all pages.
  /// {@macro key}
  const NavigatorView({
    super.key,
    required this.child,
  });
  final StatefulNavigationShell child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listener: (context, state) {
        final cubit = context.read<AppCubit>();

        // Error handling
        if (state.isError) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              ).closed.then((value) {
                cubit.clearErrorMessage();
              });
          });
        }
        // Message handling
        if (state.isMessage) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ).closed.then((value) {
                cubit.clearMessage();
              });
          });
        }
        // Email verification
        if (state.isEmailVerification) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            const time = Duration(milliseconds: 200);
            if (timeStamp < time) {
              showDialog<AlertDialog>(
                context: context,
                builder: (context) =>
                    EmailVerificationDialog(email: state.user.email),
              );
            } else {
              debugPrint('Email Verification Dialog already shown: $timeStamp');
            }
          });
        }
        // Profile Set up
        if (state.isProfileSetup) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            debugPrint(timeStamp.toString());
            const time = Duration(milliseconds: 200);
            debugPrint('Time: $time');
            // if timestamp is less than 10 milliseconds, show the dialog
            if (timeStamp < time) {
              debugPrint('Showing Profile Setup Dialog');
              showDialog<AlertDialog>(
                barrierDismissible: false,
                context: context,
                builder: (context) => EditRiderProfileDialog(
                  riderProfile: null,
                  user: state.user,
                  key: const Key('ProfileSetup'),
                ),
              ).then((value) => cubit.clearProfileSetup());
            } else {
              debugPrint('Profile Setup already shown: $timeStamp');
            }
          });
        }
      },
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final cubit = context.read<AppCubit>();
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Expanded(
                  child: AdaptiveScaffold(
                    appBar: AppBar(),
                    internalAnimations: false,
                    smallBreakpoint: const WidthPlatformBreakpoint(end: 800),
                    mediumBreakpoint: const WidthPlatformBreakpoint(
                      begin: 800,
                      end: 1200,
                    ),
                    largeBreakpoint: const WidthPlatformBreakpoint(begin: 1200),
                    leadingUnextendedNavRail: const Image(
                      color: Colors.white,
                      fit: BoxFit.contain,
                      image: AssetImage('assets/horse_logo.png'),
                      height: 40,
                    ),
                    //   ) state.index == 0
                    // ?
                    // : Visibility(
                    //     visible: state.index != 0 || state.isViewing,
                    //     child: IconButton(
                    //       icon: Icon(
                    //         Icons.arrow_back,
                    //         color: HorseAndRidersTheme()
                    //             .getTheme()
                    //             .appBarTheme
                    //             .iconTheme
                    //             ?.color,
                    //       ),
                    //       onPressed: cubit.backPressed,
                    //     ),
                    //   ),
                    leadingExtendedNavRail: const Image(
                      color: Colors.white,
                      fit: BoxFit.contain,
                      image: AssetImage('assets/horse_logo.png'),
                      height: 40,
                    ),
                    //    state.index == 0
                    // ?
                    // : Visibility(
                    //     visible: state.index != 0 || state.isViewing,
                    //     child: IconButton(
                    //       icon: Icon(
                    //         Icons.arrow_back,
                    //         color: HorseAndRidersTheme()
                    //             .getTheme()
                    //             .appBarTheme
                    //             .iconTheme
                    //             ?.color,
                    //       ),
                    //       onPressed: cubit.backPressed,
                    //     ),
                    //   ),
                    useDrawer: false,
                    destinations:
                        _buildDestinations(isForRider: state.isForRider),
                    selectedIndex: child.currentIndex,
                    onSelectedIndexChange: (p0) => _onTap(p0, cubit, child),
                    body: (_) => AdaptiveLayout(
                      internalAnimations: false,
                      body: SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('mainView'),
                            builder: (_) => child,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
                const BannerAdView(
                  key: Key('BannerAdView'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onTap(int index, AppCubit cubit, StatefulNavigationShell body) {
    body.goBranch(
      index,
      initialLocation: index == body.currentIndex,
    );
    cubit.changeIndex(index);
  }
}

List<NavigationDestination> _buildDestinations({required bool isForRider}) {
  return [
    NavigationDestination(
      selectedIcon: isForRider
          ? const Icon(Icons.person)
          : const Icon(HorseAndRiderIcons.horseIconCircle),
      icon: isForRider
          ? const Icon(Icons.person_outline)
          : const Icon(HorseAndRiderIcons.horseIcon),
      label: isForRider ? 'Profile' : 'Horse Profile',
    ),
    NavigationDestination(
      selectedIcon: isForRider
          ? const Icon(HorseAndRiderIcons.riderSkillIcon)
          : const Icon(HorseAndRiderIcons.horseSkillIcon),
      icon: isForRider
          ? const Icon(HorseAndRiderIcons.riderSkillIcon)
          : const Icon(HorseAndRiderIcons.horseSkillIcon),
      label: 'Skill Tree',
    ),
    const NavigationDestination(
      selectedIcon: Icon(HorseAndRiderIcons.resourcesIcon),
      icon: Icon(HorseAndRiderIcons.resourcesIcon),
      label: 'Resources',
    ),
  ];
}
