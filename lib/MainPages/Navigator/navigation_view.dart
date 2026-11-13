import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/banner_ad_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
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
  String? _promptedVerificationEmail;
  final bool _onboardingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _showEmailVerificationIfNeeded(context.read<AppCubit>());
  }

  @override
  void didUpdateWidget(covariant NavigationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.child.currentIndex;
    if (index != oldWidget.child.currentIndex) {
      final cubit = context.read<AppCubit>();
      if (cubit.state.index != index) {
        switch (index) {
          case 0:
            cubit.setProfile();
          case 1:
            cubit.setSkillTree();
          case 2:
            cubit.setResourcesList();
        }
      }
    }
  }

  void _showEmailVerificationIfNeeded(AppCubit cubit) {
    final state = cubit.state;
    if (!state.showEmailVerification) {
      _promptedVerificationEmail = null;
      return;
    }

    final email = state.user.email;
    if (_promptedVerificationEmail == email) return;
    _promptedVerificationEmail = email;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !cubit.state.showEmailVerification ||
          cubit.state.user.email != email) {
        return;
      }
      GoRouter.of(context).pushNamed(
        EmailVerificationDialog.name,
        pathParameters: {EmailVerificationDialog.pathParms: email},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();

    return BlocListener<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.index != current.index ||
          previous.showOnboarding != current.showOnboarding ||
          previous.isError != current.isError ||
          previous.isMessage != current.isMessage ||
          previous.errorMessage != current.errorMessage ||
          previous.showEmailVerification != current.showEmailVerification ||
          previous.user.email != current.user.email,
      listener: (context, state) {
        // Switch shell branch when AppCubit index changes
        final newIndex = state.index;
        final currentIndex = widget.child.currentIndex;
        if (newIndex != currentIndex) {
          // If the router has already moved to the requested branch (deep
          // links, programmatic navigation), don't override the URL by calling
          // goBranch, which would jump to the branch's last known location.
          //
          // If the router is still on the old branch (e.g. back buttons that
          // only update AppCubit state), goBranch now so the slide starts
          // immediately.
          final path = GoRouter.of(context).routeInformationProvider.value.uri;
          final location = path.path;
          final routerBranchIndex = location.startsWith(SkillTreePage.path)
              ? 1
              : location.startsWith(ResourcesPage.path)
              ? 2
              : 0;
          if (routerBranchIndex != newIndex) {
            widget.child.goBranch(newIndex);
          }
        }

        // Manual onboarding presentation (guest vs signed-in)
        if (state.showOnboarding && !_onboardingDialogOpen) {
          debugPrint('onboarding');
          //   _onboardingDialogOpen = true;
          //   SchedulerBinding.instance.addPostFrameCallback((_) async {
          //     if (!mounted) return;
          //     final dialogContext = context;
          //     if (state.status == AppStatus.authenticated) {
          //       final result = await showDialog<String?>(
          //         context: dialogContext,
          //         barrierDismissible: false,
          //         builder: (ctx) => UserOnboardingDialog(
          //           onSkip: cubit.completeOnboarding,
          //         ),
          //       );
          //       if (!dialogContext.mounted) return;
          //       cubit.completeOnboarding();
          //       if (result == 'finish') {
          //         if (!dialogContext.mounted) return;
          //         await showDialog<EditRiderProfileDialog>(
          //           context: dialogContext,
          //           builder: (ctx) => EditRiderProfileDialog(
          //             onProfileUpdated: () {},
          //             riderProfile: state.usersProfile,
          //             user: state.user,
          //           ),
          //         );
          //       }
          //     } else {
          //       await showDialog<void>(
          //         context: dialogContext,
          //         barrierDismissible: false,
          //         builder: (ctx) => GuestOnboardingDialog(
          //           onSkip: cubit.completeOnboarding,
          //         ),
          //       );
          //       if (!dialogContext.mounted) return;
          //       cubit.completeOnboarding();
          //     }
          //     if (!mounted) return;
          //     setState(() => _onboardingDialogOpen = false);
          //   });
          // } else if (!state.showOnboarding && _onboardingDialogOpen) {
          //   // Close dialog if onboarding flag turned off
          //   SchedulerBinding.instance.addPostFrameCallback((_) {
          //     if (Navigator.of(context).canPop()) {
          //       Navigator.of(context).pop();
          //     }
          //     if (mounted) setState(() => _onboardingDialogOpen = false);
          //   });
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
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ).closed.then((_) => cubit.clearErrorMessage());
          });
        }

        _showEmailVerificationIfNeeded(cubit);
      },
      child: Builder(
        builder: (context) {
          final isForRider = context.select((AppCubit c) => c.state.isForRider);
          final screenWidth = MediaQuery.of(context).size.width;

          final isMedium = screenWidth >= NavigationView.mediumScreenWidth;
          final isLarge = screenWidth >= NavigationView.largeScreenWidth;

          final theme = Theme.of(context);
          final isOceanCoralDark = isOceanCoralDarkTheme(context);
          final gradients = theme.extension<SurfaceGradients>();
          final railGradient = gradients?.rail;
          final chromeGradient = gradients?.chrome;
          final Widget navigation = isMedium
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: railGradient,
                    border: isOceanCoralDark
                        ? const Border(
                            right: BorderSide(
                              color: ColorConst.dividerDarkBlueGrey,
                            ),
                          )
                        : null,
                  ),
                  child: NavigationRail(
                    selectedIndex: widget.child.currentIndex,
                    onDestinationSelected: (index) {
                      if (index == widget.child.currentIndex) return;
                      // Trigger the branch slide immediately on tap.
                      // The BlocListener below still handles programmatic
                      // index changes (e.g. deep links) with extra safety.
                      widget.child.goBranch(index);
                      context.read<AppCubit>().changeIndex(index);
                    },
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
                      isForRider: isForRider,
                    ),
                    backgroundColor: railGradient != null
                        ? Colors.transparent
                        : theme.appBarTheme.backgroundColor,
                  ),
                )
              : DecoratedBox(
                  decoration: isOceanCoralDark
                      ? const BoxDecoration(
                          color: ColorConst.mainPrimaryDark,
                          border: Border(
                            top: BorderSide(
                              color: ColorConst.dividerDarkBlueGrey,
                            ),
                          ),
                        )
                      : BoxDecoration(gradient: chromeGradient),
                  child: BottomNavigationBar(
                    currentIndex: widget.child.currentIndex,
                    onTap: (index) {
                      if (index == widget.child.currentIndex) return;
                      widget.child.goBranch(index);
                      context.read<AppCubit>().changeIndex(index);
                    },
                    items: _buildBottomNavigationBarItems(
                      isForRider: isForRider,
                    ),
                    backgroundColor: isOceanCoralDark || chromeGradient != null
                        ? Colors.transparent
                        : theme.appBarTheme.backgroundColor,
                    selectedItemColor:
                        theme.bottomNavigationBarTheme.selectedItemColor ??
                        Colors.white,
                    unselectedItemColor: isOceanCoralDark
                        ? ColorConst.darkMuted
                        : theme.bottomNavigationBarTheme.unselectedItemColor ??
                              Colors.grey,
                    elevation: 0,
                  ),
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
}) => [
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
}) => [
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
