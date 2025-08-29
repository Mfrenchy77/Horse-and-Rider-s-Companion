import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// App "chrome" (rail/bottom bar + banner) that wraps the StatefulNavigationShell.
/// The actual branch slide animation is provided by the shell's
/// navigatorContainerBuilder (see Routes).
class NavigationView extends StatefulWidget {
  const NavigationView({super.key, required this.child});

  final StatefulNavigationShell child;

  static const double mediumScreenWidth = 600;
  static const double largeScreenWidth = 1024;

  @override
  State<NavigationView> createState() => _NavigationViewState();
}

class _NavigationViewState extends State<NavigationView> {
  bool _emailDialogOpen = false;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();

    return BlocListener<AppCubit, AppState>(
      listener: (context, state) {
        // Switch shell branch when AppCubit index changes
        final newIndex = state.index;
        final currentIndex = widget.child.currentIndex;
        if (newIndex != currentIndex) {
          widget.child.goBranch(newIndex);
        }

        // Errors
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

        // Messages
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

        // Email verification
        if (state.showEmailVerification && !_emailDialogOpen) {
          _emailDialogOpen = true;
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            await context.pushNamed(
              EmailVerificationDialog.name,
              pathParameters: {
                EmailVerificationDialog.pathParms: state.user.email,
              },
            );
            if (mounted) setState(() => _emailDialogOpen = false);
          });
        } else if (!state.showEmailVerification && _emailDialogOpen) {
          // Close dialog if verification flag turned off
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            if (mounted) setState(() => _emailDialogOpen = false);
          });
        }
      },
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final screenWidth = MediaQuery.of(context).size.width;

          final isMedium = screenWidth >= NavigationView.mediumScreenWidth;
          final isLarge = screenWidth >= NavigationView.largeScreenWidth;

          final Widget navigation = isMedium
              ? NavigationRail(
                  selectedIndex: state.index,
                  onDestinationSelected: context.read<AppCubit>().changeIndex,
                  extended: isLarge,
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
                  onTap: context.read<AppCubit>().changeIndex,
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
                    if (isMedium) navigation,
                    // This renders the active branch content; the sliding
                    // between branches is handled by the shell container.
                    Expanded(child: ClipRect(child: widget.child)),
                  ],
                ),
              ),
              if (!isMedium) navigation,
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
