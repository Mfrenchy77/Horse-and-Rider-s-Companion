import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
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
    required this.body,
  });
  final Widget body;

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
                    internalAnimations: false,
                    smallBreakpoint: const WidthPlatformBreakpoint(end: 800),
                    mediumBreakpoint: const WidthPlatformBreakpoint(
                      begin: 800,
                      end: 1200,
                    ),
                    largeBreakpoint: const WidthPlatformBreakpoint(begin: 1200),
                    leadingUnextendedNavRail: state.index == 0
                        ? const Image(
                            color: Colors.white,
                            fit: BoxFit.contain,
                            image: AssetImage('assets/horse_logo.png'),
                            height: 40,
                          )
                        : Visibility(
                            visible: state.index != 0 || state.isViewing,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: HorseAndRidersTheme()
                                    .getTheme()
                                    .appBarTheme
                                    .iconTheme
                                    ?.color,
                              ),
                              onPressed: cubit.backPressed,
                            ),
                          ),
                    leadingExtendedNavRail: state.index == 0
                        ? const Image(
                            color: Colors.white,
                            fit: BoxFit.contain,
                            image: AssetImage('assets/horse_logo.png'),
                            height: 40,
                          )
                        : Visibility(
                            visible: state.index != 0 || state.isViewing,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: HorseAndRidersTheme()
                                    .getTheme()
                                    .appBarTheme
                                    .iconTheme
                                    ?.color,
                              ),
                              onPressed: cubit.backPressed,
                            ),
                          ),
                    useDrawer: false,
                    destinations:
                        _buildDestinations(isForRider: state.isForRider),
                    selectedIndex: state.index,
                    onSelectedIndexChange: (p0) =>
                        context.read<AppCubit>().changeIndex(p0),
                    body: (_) => AdaptiveLayout(
                      internalAnimations: false,
                      body: SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('mainView'),
                            builder: (_) => body,
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
