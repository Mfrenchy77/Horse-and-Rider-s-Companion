import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
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
      listenWhen: (previous, current) =>
          previous.index != current.index ||
          previous.isError != current.isError ||
          previous.isMessage != current.isMessage ||
          previous.errorMessage != current.errorMessage ||
          previous.showOnboarding != current.showOnboarding ||
          previous.isProfileSetup != current.isProfileSetup ||
          previous.showEmailVerification != current.showEmailVerification,
      listener: (context, state) {
        debugPrint('NavigatorView Listener Called');
        if (!context.mounted) return;
        final cubit = context.read<AppCubit>();

        // First Launch
        if (state.showFirstLaunch) {
          debugPrint('First Launch Called');
          // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          //   if (!context.mounted) return;
          //   const time = Duration(milliseconds: 200);
          //   if (timeStamp < time) {
          //     GoRouter.of(context)
          //         .pushNamed(AboutPage.name)
          //         .then((value) => cubit.setFirstLaunch());
          //   } else {
          //     debugPrint('First Launch already shown: $timeStamp');
          //   }
          // });
        }

        // Onboarding
        if (state.showOnboarding) {
          debugPrint('Onboarding Called');
        }

        // Navigation
        switch (state.index) {
          case 0:
            debugPrint('Index 0');
            child.goBranch(0);
            break;
          case 1:
            debugPrint('Index 1');
            child.goBranch(1);
            break;
          case 2:
            debugPrint('Index 2');
            child.goBranch(2);
            break;
          default:
            debugPrint('Default');
            child.goBranch(0);
        }

        // Error handling
        if (state.isError) {
          debugPrint('Error Called');
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            //if (!context.mounted) return;
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
                if (!context.mounted) return;
                cubit.clearErrorMessage();
              });
          });
        }
        // Message handling
        if (state.isMessage) {
          debugPrint('Message Called');
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            //  if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor:
                      HorseAndRidersTheme().getTheme().primaryColor,
                ),
              ).closed.then((value) {
                if (!context.mounted) return;
                cubit.clearMessage();
              });
          });
        }
        // Email verification
        if (state.showEmailVerification) {
          debugPrint('Email Verification Called');
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            debugPrint('Email Verification Dialog Called');
            //if (!context.mounted) return;
            const time = Duration(milliseconds: 200);
            if (timeStamp < time) {
              context.pushNamed(
                EmailVerificationDialog.name,
                pathParameters: {
                  EmailVerificationDialog.pathParms: state.user.email,
                },
              );
              // showDialog<AlertDialog>(
              //   barrierDismissible: false,
              //   context: context,
              //   builder: (context) => EmailVerificationDialog(
              //     email: state.user.email,
              //     key: const Key('EmailVerificationDialog'),
              //   ),
              // ).then((value) => cubit.clearEmailVerification()
            } else {
              debugPrint('Email Verification Dialog already shown: $timeStamp');
            }
          });
        }
        // Profile Set up
        if (state.isProfileSetup) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            if (!context.mounted) return;
            const time = Duration(milliseconds: 4000);
            debugPrint('Profile Set Up Called Time: $time');
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
            child: state.pageStatus == AppPageStatus.resource
                ? child
                : Column(
                    children: [
                      Expanded(
                        child: AdaptiveScaffold(
                          appBar: AppBar(),
                          internalAnimations: false,
                          smallBreakpoint:
                              const WidthPlatformBreakpoint(end: 800),
                          mediumBreakpoint: const WidthPlatformBreakpoint(
                            begin: 800,
                            end: 1200,
                          ),
                          largeBreakpoint:
                              const WidthPlatformBreakpoint(begin: 1200),
                          leadingUnextendedNavRail: const Image(
                            color: Colors.white,
                            fit: BoxFit.contain,
                            image: AssetImage('assets/horse_logo.png'),
                            height: 40,
                          ),
                          leadingExtendedNavRail: const Image(
                            color: Colors.white,
                            fit: BoxFit.contain,
                            image: AssetImage('assets/horse_logo.png'),
                            height: 40,
                          ),
                          useDrawer: false,
                          destinations:
                              _buildDestinations(isForRider: state.isForRider),
                          selectedIndex: state.index,
                          onSelectedIndexChange: cubit.changeIndex,
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
