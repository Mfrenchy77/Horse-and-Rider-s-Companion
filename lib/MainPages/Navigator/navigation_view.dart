import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key, required this.child});
  final StatefulNavigationShell child;

  static const double mediumScreenWidth = 600;
  static const double largeScreenWidth = 1024;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listener: (context, state) {
        final cubit = context.read<AppCubit>();

        // Navigation
        child.goBranch(state.index);

        // Error Handling
        if (state.isError) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
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
              ).closed.then((_) => cubit.clearErrorMessage());
          });
        }

        // Message Handling
        if (state.isMessage) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
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
              ).closed.then((_) => cubit.clearErrorMessage());
          });
        }

        // Email Verification Handling
        if (state.showEmailVerification) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            context.pushNamed(
              EmailVerificationDialog.name,
              pathParameters: {
                EmailVerificationDialog.pathParms: state.user.email,
              },
            );
          });
        }
      },
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final cubit = context.read<AppCubit>();
          final screenWidth = MediaQuery.of(context).size.width;

          final isMediumScreen = screenWidth >= mediumScreenWidth;
          final isLargeScreen = screenWidth >= largeScreenWidth;
          final Widget navigation = isMediumScreen
              ? NavigationRail(
                  selectedIndex: state.index,
                  onDestinationSelected: cubit.changeIndex,
                  extended: isLargeScreen,
                  leading: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Image(
                      color: Colors.white,
                      fit: BoxFit.contain,
                      image: AssetImage('assets/horse_logo.png'),
                      height: 40,
                    ),
                  ),
                  destinations: _buildNavigationRailDestinations(
                    isForRider: state.isForRider,
                  ),
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                )
              : BottomNavigationBar(
                  currentIndex: state.index,
                  onTap: cubit.changeIndex,
                  items: _buildBottomNavigationBarItems(
                    isForRider: state.isForRider,
                  ),
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.grey,
                );

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isMediumScreen) navigation,
                    Expanded(child: child),
                  ],
                ),
              ),
              if (!isMediumScreen) navigation,
              const BannerAdView(key: Key('BannerAdView')),
            ],
          );
        },
      ),
    );
  }
}

List<NavigationRailDestination> _buildNavigationRailDestinations({
  required bool isForRider,
}) =>
    [
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

List<BottomNavigationBarItem> _buildBottomNavigationBarItems({
  required bool isForRider,
}) =>
    [
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
