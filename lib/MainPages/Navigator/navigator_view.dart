import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// This is the reusable navigator that shows
/// the bottom app bar on small screens
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
          previous.isGuest != current.isGuest ||
          previous.usersProfile != current.usersProfile ||
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

        // Navigation Handling
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

        // Error Handling
        if (state.isError) {
          debugPrint('Error Called');
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
                if (!context.mounted) return;
                cubit.clearErrorMessage();
              });
          });
        }

        // Message Handling
        if (state.isMessage) {
          debugPrint('Message Called');
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
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
                cubit.clearErrorMessage();
              });
          });
        }

        // Email Verification Handling
        if (state.showEmailVerification) {
          debugPrint('Email Verification Called');
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            debugPrint('Email Verification Dialog Called');
            const time = Duration(milliseconds: 200);
            if (timeStamp < time) {
              context.pushNamed(
                EmailVerificationDialog.name,
                pathParameters: {
                  EmailVerificationDialog.pathParms: state.user.email,
                },
              );
            } else {
              debugPrint('Email Verification Dialog already shown: $timeStamp');
            }
          });
        }
        // Additional state handling can be added here
      },
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final cubit = context.read<AppCubit>();

          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: AdaptiveLayout(
                        internalAnimations: false,
                        primaryNavigation: SlotLayout(
                          config: <Breakpoint, SlotLayoutConfig?>{
                            // Medium screens
                            Breakpoints.mediumAndUp: SlotLayout.from(
                              key: const Key('primaryNavigationMedium'),
                              builder: (_) {
                                return AdaptiveScaffold.standardNavigationRail(
                                  padding: EdgeInsets.zero,
                                  selectedIndex: state.index,
                                  onDestinationSelected: cubit.changeIndex,
                                  leading: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Image(
                                      color: Colors.white,
                                      fit: BoxFit.contain,
                                      image:
                                          AssetImage('assets/horse_logo.png'),
                                      height: 40,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  destinations:
                                      _buildNavigationRailDestinations(
                                    isForRider: state.isForRider,
                                  ),
                                 
                                );
                              },
                            ),
                            // Large screens
                            Breakpoints.mediumLargeAndUp: SlotLayout.from(
                              key: const Key('primaryNavigationLarge'),
                              builder: (_) {
                                return AdaptiveScaffold.standardNavigationRail(
                                  padding: EdgeInsets.zero,
                                  selectedIndex: state.index,
                                  onDestinationSelected: cubit.changeIndex,
                                  leading: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Image(
                                      color: Colors.white,
                                      fit: BoxFit.contain,
                                      image:
                                          AssetImage('assets/horse_logo.png'),
                                      height: 40,
                                    ),
                                  ),
                                  extended:
                                      true, // Extended rail for larger screens
                                  backgroundColor: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  destinations:
                                      _buildNavigationRailDestinations(
                                    isForRider: state.isForRider,
                                  ),
                                  
                                );
                              },
                            ),
                            // Add more breakpoints if necessary
                          },
                        ),
                        // Define the body slot
                        body: SlotLayout(
                          config: <Breakpoint, SlotLayoutConfig>{
                            Breakpoints.standard: SlotLayout.from(
                              key: const Key('mainView'),
                              builder: (_) => child,
                            ),
                          },
                        ),
                        // Define the bottom navigation slot for small screens
                        bottomNavigation: SlotLayout(
                          config: <Breakpoint, SlotLayoutConfig?>{
                            Breakpoints.small: SlotLayout.from(
                              key: const Key('bottomNavigation'),
                              builder: (_) {
                                return BottomNavigationBar(
                                  backgroundColor: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  currentIndex: state.index,
                                  onTap: cubit.changeIndex,
                                  items: _buildBottomNavigationBarItems(
                                    isForRider: state.isForRider,
                                  ),
                                  selectedItemColor: Colors.white,
                                  unselectedItemColor: Colors.grey,
                                  type: BottomNavigationBarType
                                      .fixed, // Adjust as needed
                                  // Optionally, customize other properties
                                );
                              },
                            ),
                          },
                        ),
                      ),
                    ),
                    const BannerAdView(
                      key: Key('BannerAdView'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Builds the list of NavigationRailDestination for the NavigationRail.
List<NavigationRailDestination> _buildNavigationRailDestinations({
  required bool isForRider,
}) {
  return [
    NavigationRailDestination(
      icon: isForRider
          ? const Icon(Icons.person_outline)
          : const Icon(HorseAndRiderIcons.horseIcon),
      selectedIcon: isForRider
          ? const Icon(Icons.person)
          : const Icon(HorseAndRiderIcons.horseIconCircle),
      label: Text(isForRider ? 'Profile' : 'Horse Profile'),
    ),
    NavigationRailDestination(
      icon: isForRider
          ? const Icon(HorseAndRiderIcons.riderSkillIcon)
          : const Icon(HorseAndRiderIcons.horseSkillIcon),
      selectedIcon: isForRider
          ? const Icon(HorseAndRiderIcons.riderSkillIcon)
          : const Icon(HorseAndRiderIcons.horseSkillIcon),
      label: const Text('Skill Tree'),
    ),
    const NavigationRailDestination(
      icon: Icon(HorseAndRiderIcons.resourcesIcon),
      selectedIcon: Icon(HorseAndRiderIcons.resourcesIcon),
      label: Text('Resources'),
    ),
  ];
}

/// Builds the list of BottomNavigationBarItem for the BottomNavigationBar.
List<BottomNavigationBarItem> _buildBottomNavigationBarItems({
  required bool isForRider,
}) {
  return [
    BottomNavigationBarItem(
      icon: isForRider
          ? const Icon(Icons.person_outline)
          : const Icon(HorseAndRiderIcons.horseIcon),
      label: isForRider ? 'Profile' : 'Horse Profile',
    ),
    BottomNavigationBarItem(
      icon: isForRider
          ? const Icon(HorseAndRiderIcons.riderSkillIcon)
          : const Icon(HorseAndRiderIcons.horseSkillIcon),
      label: 'Skill Tree',
    ),
    const BottomNavigationBarItem(
      icon: Icon(HorseAndRiderIcons.resourcesIcon),
      label: 'Resources',
    ),
  ];
}
