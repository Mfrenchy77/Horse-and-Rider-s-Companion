import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/route_observer.dart';

import 'package:horseandriderscompanion/MainPages/About/about_page.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigation_view.dart';
import 'package:horseandriderscompanion/MainPages/Privacy%20Policy/privacy_policy_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_web_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

class Routes {
  GoRouter router({
    required SettingsController settingsContoller,
    required AppCubit appCubit,
  }) {
    final routeNavigatorKey = GlobalKey<NavigatorState>();
    final profileNavigatorKey = GlobalKey<NavigatorState>();
    final skillTreeNavigatorKey = GlobalKey<NavigatorState>();
    final resourcesNavigatorKey = GlobalKey<NavigatorState>();

    // ── Observers (your existing behavior) ───────────────────────────────────
    final routeObserver = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        debugPrint(
          'Observer Pop: ${route.settings.name},'
          ' ${previousRoute?.settings.name}',
        );
      },
      onPush: (route, previousRoute) {
        debugPrint(
          'Observer Push: ${route.settings.name},'
          ' ${previousRoute?.settings.name}',
        );
        if (previousRoute?.settings.name == AuthPage.name) {
          appCubit.setProfile();
        }
      },
    );

    final routeObserverProfile = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        if (route.settings.name == HorseProfilePage.name) {
          if (previousRoute?.settings.name == ViewingProfilePage.name) {
            appCubit
              ..resetFromHorseProfile()
              ..setViewingProfile()
              ..sortForHorse();
          } else if (previousRoute?.settings.name == ProfilePage.name) {
            appCubit
              ..resetFromHorseProfile()
              ..resetFromViewingProfile()
              ..sortForHorse();
          }
        } else if (route.settings.name == ViewingProfilePage.name) {
          if (previousRoute?.settings.name == HorseProfilePage.name) {
            appCubit
              ..resetFromViewingProfile()
              ..setHorseProfile()
              ..sortForHorse();
          } else if (previousRoute?.settings.name == ProfilePage.name) {
            appCubit
              ..resetFromViewingProfile()
              ..resetFromHorseProfile()
              ..sortForHorse();
          }
        }
      },
      onPush: (route, previousRoute) {
        if (route.settings.name == HorseProfilePage.name) {
          if (previousRoute?.settings.name == ProfilePage.name) {
            appCubit.resetFromViewingProfile();
          }
          appCubit
            ..setHorseProfile()
            ..sortForHorse();
        } else if (route.settings.name == ViewingProfilePage.name) {
          if (previousRoute?.settings.name == ProfilePage.name) {
            appCubit.resetFromHorseProfile();
          }
          appCubit
            ..setViewingProfile()
            ..sortForHorse();
        }
      },
    );

    final routeObserverSkillTree = RouteObserverWithCallback(
      onPush: (route, previousRoute) {
        if (route.settings.name == SkillTreePage.name) {
          appCubit.setSkillTree();
        } else if (route.settings.name == SkillTreeView.skillsListName) {
          appCubit
            ..setSkillTree()
            ..navigateToSkillsList()
            ..setSkillTreeTabIndex(0);
        } else if (route.settings.name == SkillTreeView.skillLevelName) {
          appCubit.setSkillTree();
        }
      },
      onPop: (route, previousRoute) {
        if (route.settings.name == SkillTreeView.skillLevelName &&
            previousRoute?.settings.name == SkillTreeView.skillsListName) {
          appCubit
            ..navigateToSkillsList()
            ..setSkillTreeTabIndex(0);
        }
      },
    );

    final routeObserverResources = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        if (route.settings.name == ResourceCommentPage.name &&
            previousRoute?.settings.name == ResourcesPage.name) {
          appCubit.resetFromResource();
        }
        if (route.settings.name == ResourceWebPage.name &&
            previousRoute?.settings.name == ResourcesPage.name) {
          appCubit.resetFromResource();
        }
      },
      onPush: (route, previousRoute) {
        if (route.settings.name == ResourcesPage.name) {
          appCubit.setResourcesList();
        }
        if (route.settings.name == ResourceCommentPage.name ||
            route.settings.name == ResourceWebPage.name) {
          appCubit.setResource();
        }
      },
    );

    return GoRouter(
      observers: [routeObserver],
      navigatorKey: routeNavigatorKey,
      initialLocation: ProfilePage.path,
      routes: <RouteBase>[
        GoRoute(
          path: AuthPage.path,
          name: AuthPage.name,
          builder: (context, state) => const AuthPage(),
        ),

        // ── MAIN SHELL: app chrome + animated branch container ───────────────
        StatefulShellRoute(
          // Your chrome (rail/bottom bar + content)
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell navigationShell,
              ) {
                return NavigationView(child: navigationShell);
              },

          // Our container that slides branch Navigators left/right
          navigatorContainerBuilder:
              (
                BuildContext context,
                StatefulNavigationShell navigationShell,
                List<Widget> children,
              ) {
                return BranchSlideContainer(
                  navigationShell: navigationShell,
                  children: children,
                );
              },

          branches: [
            // ── Branch 0: Profile ────────────────────────────────────────────
            StatefulShellBranch(
              observers: [routeObserverProfile],
              navigatorKey: profileNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: ProfilePage.path,
                  name: ProfilePage.name,
                  builder: (context, state) => const ProfilePage(),
                  routes: [
                    GoRoute(
                      name: SettingsView.name,
                      path: SettingsView.routeName,
                      builder: (context, state) =>
                          SettingsView(controller: settingsContoller),
                    ),
                    GoRoute(
                      path: 'Messages',
                      redirect: (_, _) => ProfilePage.path,
                      routes: [
                        GoRoute(
                          path: 'Message/:messageId',
                          redirect: (_, _) => ProfilePage.path,
                        ),
                      ],
                    ),
                    GoRoute(
                      path: HorseProfilePage.path,
                      name: HorseProfilePage.name,
                      builder: (context, state) => HorseProfilePage(
                        horseId:
                            state.pathParameters[HorseProfilePage.pathParams]!,
                      ),
                    ),
                    GoRoute(
                      path: ViewingProfilePage.path,
                      name: ViewingProfilePage.name,
                      builder: (context, state) => ViewingProfilePage(
                        id: state
                            .pathParameters[ViewingProfilePage.pathParams]!,
                      ),
                    ),
                    GoRoute(
                      name: PrivacyPolicyPage.name,
                      path: PrivacyPolicyPage.path,
                      pageBuilder: (context, state) => AppGlassDialogPage<void>(
                        key: state.pageKey,
                        name: state.name,
                        child: const PrivacyPolicyPage(),
                      ),
                    ),
                    GoRoute(
                      name: AboutPage.name,
                      path: AboutPage.routeName,
                      pageBuilder: (context, state) => AppGlassDialogPage<void>(
                        key: state.pageKey,
                        name: state.name,
                        child: const AboutPage(),
                      ),
                    ),
                    GoRoute(
                      name: EmailVerificationDialog.name,
                      path: EmailVerificationDialog.path,
                      pageBuilder: (context, state) => AppGlassDialogPage<void>(
                        key: state.pageKey,
                        name: state.name,
                        child: EmailVerificationDialog(
                          email:
                              state.pathParameters[EmailVerificationDialog
                                  .pathParms]!,
                        ),
                      ),
                    ),
                    GoRoute(
                      name: DeletePage.name,
                      path: DeletePage.path,
                      pageBuilder: (context, state) => AppGlassDialogPage<void>(
                        key: state.pageKey,
                        name: state.name,
                        child: const DeletePage(),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Branch 1: Skill Tree (already sliding) ───────────────────────
            StatefulShellBranch(
              observers: [routeObserverSkillTree],
              navigatorKey: skillTreeNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: SkillTreePage.path,
                  name: SkillTreePage.name,
                  builder: (context, state) => const SkillTreePage(),
                  routes: [
                    GoRoute(
                      path: SkillTreeView.skillsListPath,
                      name: SkillTreeView.skillsListName,
                      builder: (context, state) => const SkillTreeView(),
                      routes: [
                        GoRoute(
                          path: SkillTreeView.skillLevelPath,
                          name: SkillTreeView.skillLevelName,
                          pageBuilder: (context, state) {
                            final id = state
                                .pathParameters[SkillTreeView.skillPathParam]!;
                            return _horizontalSlidePage(
                              key: state.pageKey,
                              name: state.name,
                              child: SkillTreeView(skillId: id),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // ── Branch 2: Resources (NOW with sliding to comments/web) ───────
            StatefulShellBranch(
              observers: [routeObserverResources],
              navigatorKey: resourcesNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: ResourcesPage.path,
                  name: ResourcesPage.name,
                  builder: (context, state) => const ResourcesPage(),
                  routes: <RouteBase>[
                    // Resource → Comment (slide)
                    GoRoute(
                      name: ResourceCommentPage.name,
                      path: ResourceCommentPage.path,
                      pageBuilder: (context, state) {
                        final id = state
                            .pathParameters[ResourceCommentPage.pathParams]!;
                        return _resourceCommentPage(
                          key: state.pageKey,
                          name: state.name,
                          child: ResourceCommentPage(key: ValueKey(id), id: id),
                        );
                      },
                    ),
                    // Resource → Web (slide)
                    GoRoute(
                      name: ResourceWebPage.name,
                      path: ResourceWebPage.path,
                      pageBuilder: (context, state) {
                        return _horizontalSlidePage(
                          key: state.pageKey,
                          name: state.name,
                          child: ResourceWebPage.fromState(state),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Shared left/right slide for in-branch pushes/pops.
  static CustomTransitionPage<dynamic> _horizontalSlidePage({
    required LocalKey key,
    required Widget child,
    String? name,
  }) {
    return CustomTransitionPage<dynamic>(
      key: key,
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final inTween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        final outTween = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1, 0),
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(inTween),
          child: SlideTransition(
            position: secondaryAnimation.drive(outTween),
            child: child,
          ),
        );
      },
    );
  }

  /// The resource summary is the only moving element on this transition.
  /// Keeping the page itself stationary prevents a second lateral motion from
  /// being combined with the Hero's move between the list card and header.
  static CustomTransitionPage<dynamic> _resourceCommentPage({
    required LocalKey key,
    required Widget child,
    String? name,
  }) {
    return CustomTransitionPage<dynamic>(
      key: key,
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Holds & animates all branch Navigators. Used by navigatorContainerBuilder.
/// Keeps state per branch; only current +
///  outgoing branch are visible during slide.
/// Also clips so the animating page never draws over the navigation rail.
class BranchSlideContainer extends StatefulWidget {
  const BranchSlideContainer({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<BranchSlideContainer> createState() => _BranchSlideContainerState();
}

class _BranchSlideContainerState extends State<BranchSlideContainer> {
  late int _currentIndex;
  final Set<int> _temporarilyVisible = <int>{};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
    _temporarilyVisible.add(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant BranchSlideContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _currentIndex) {
      final prev = _currentIndex;
      _currentIndex = newIndex;
      _temporarilyVisible
        ..add(prev)
        ..add(newIndex);

      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(
          () => _temporarilyVisible.removeWhere((i) => i != _currentIndex),
        );
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final curr = _currentIndex;

    // Clip so slides never cover the rail on larger screens.
    return ClipRect(
      child: Stack(
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final navigator = entry.value;

          final targetOffset = (index == curr)
              ? Offset.zero
              : (index < curr ? const Offset(-1, 0) : const Offset(1, 0));

          final show = index == curr || _temporarilyVisible.contains(index);

          return AnimatedSlide(
            offset: targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Offstage(
              offstage: !show,
              child: IgnorePointer(
                ignoring: index != curr,
                child: TickerMode(enabled: index == curr, child: navigator),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
