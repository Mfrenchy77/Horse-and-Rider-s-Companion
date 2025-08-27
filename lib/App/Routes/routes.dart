import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/route_observer.dart';

import 'package:horseandriderscompanion/MainPages/About/about_page.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/messages_list_page.dart';
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
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

class Routes {
  GoRouter router({
    required SettingsController settingsContoller,
    required AppCubit appCubit,
  }) {
    final routeNavigatorKey = GlobalKey<NavigatorState>();
    final profileNavigatorKey = GlobalKey<NavigatorState>();
    final skillTreeNavigatorKey = GlobalKey<NavigatorState>();
    final resourcesNavigatorKey = GlobalKey<NavigatorState>();

    // ── Observers (unchanged behavior) ──────────────────────────────────────
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
        if (route.settings.name == HorseProfilePage.name &&
            previousRoute?.settings.name == ProfilePage.name) {
          appCubit
            ..resetFromHorseProfile()
            ..sortForHorse();
        } else if (route.settings.name == ViewingProfilePage.name &&
            previousRoute?.settings.name == ProfilePage.name) {
          appCubit.resetFromViewingProfile();
        }
      },
      onPush: (route, previousRoute) {
        if (route.settings.name == HorseProfilePage.name) {
          appCubit
            ..setHorseProfile()
            ..sortForHorse();
        } else if (route.settings.name == ViewingProfilePage.name) {
          appCubit.setViewingProfile();
        }
      },
    );

    final routeObserverSkillTree = RouteObserverWithCallback(
      onPush: (route, previousRoute) {
        if (route.settings.name == SkillTreePage.name) {
          appCubit.setSkillTree();
        }
      },
      onPop: (_, __) {},
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

        // ── MAIN SHELL: builder + navigatorContainerBuilder ─────────────────
        StatefulShellRoute(
          // Wrap the shell with your app chrome (NavigationView).
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            // IMPORTANT: include the navigationShell here so it renders.
            return NavigationView(child: navigationShell);
          },

          // Provide a custom container that lays out &
          //animates the branch Navigators.
          navigatorContainerBuilder: (
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
            // ── Branch 0: Profile ───────────────────────────────────────────
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
                      name: MessagesPage.name,
                      path: MessagesPage.path,
                      builder: (context, state) => const MessagesPage(),
                      routes: [
                        GoRoute(
                          name: MessagePage.name,
                          path: MessagePage.path,
                          builder: (context, state) => MessagePage(
                            messageId:
                                state.pathParameters[MessagePage.pathParams]!,
                          ),
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
                      builder: (context, state) => const PrivacyPolicyPage(),
                    ),
                    GoRoute(
                      name: AboutPage.name,
                      path: AboutPage.routeName,
                      builder: (context, state) => const AboutPage(),
                    ),
                    GoRoute(
                      name: EmailVerificationDialog.name,
                      path: EmailVerificationDialog.path,
                      builder: (context, state) => EmailVerificationDialog(
                        email: state
                            .pathParameters[EmailVerificationDialog.pathParms]!,
                      ),
                    ),
                    GoRoute(
                      name: DeletePage.name,
                      path: DeletePage.path,
                      builder: (context, state) => const DeletePage(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Branch 1: Skill Tree ────────────────────────────────────────
            StatefulShellBranch(
              observers: [routeObserverSkillTree],
              navigatorKey: skillTreeNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: SkillTreePage.path,
                  name: SkillTreePage.name,
                  builder: (context, state) => const SkillTreePage(),
                  routes: [
                    // 1) Skills List
                    GoRoute(
                      path: SkillTreeView.skillsListPath,
                      name: SkillTreeView.skillsListName,
                      builder: (context, state) {
                        if (state
                                .pathParameters[SkillTreeView.skillPathParam] ==
                            null) {
                          context.read<AppCubit>().setSkillTreeTabIndex(0);
                        }
                        return const SkillTreeView();
                      },
                      routes: [
                        // 2) Skill Detail (slide)
                        GoRoute(
                          path: SkillTreeView.skillLevelPath,
                          name: SkillTreeView.skillLevelName,
                          pageBuilder: (context, state) {
                            final id = state
                                .pathParameters[SkillTreeView.skillPathParam]!;
                            final isLarge = MediaQuery.of(context).size.width >=
                                StringConstants.splitScreenBreakpoint;

                            context.read<AppCubit>()
                              ..setSkill(id)
                              ..setSkillTreeTabIndex(isLarge ? 0 : 1);

                            return _horizontalSlidePage(
                              key: state.pageKey,
                              child: SkillTreeView(skillId: id),
                            );
                          },
                        ),
                      ],
                    ),

                    // 3) Training Paths List (slide)
                    GoRoute(
                      path: 'TrainingPaths',
                      name: SkillTreeView.trainingPathListName,
                      pageBuilder: (context, state) {
                        if (state.pathParameters[
                                SkillTreeView.trainingPathPathParam] ==
                            null) {
                          final isLarge = MediaQuery.of(context).size.width >=
                              StringConstants.splitScreenBreakpoint;
                          context
                              .read<AppCubit>()
                              .setSkillTreeTabIndex(isLarge ? 1 : 2);
                        }
                        return _horizontalSlidePage(
                          key: state.pageKey,
                          child: const SkillTreeView(),
                        );
                      },
                      routes: [
                        // 4) Training Path Detail (slide)
                        GoRoute(
                          path: SkillTreeView.trainingPathViewPath,
                          name: SkillTreeView.trainingPathViewName,
                          pageBuilder: (context, state) {
                            final id = state.pathParameters[
                                SkillTreeView.trainingPathPathParam]!;
                            final isLarge = MediaQuery.of(context).size.width >=
                                StringConstants.splitScreenBreakpoint;

                            context.read<AppCubit>()
                              ..setTrainingPath(id)
                              ..setSkillTreeTabIndex(isLarge ? 1 : 3);

                            return _horizontalSlidePage(
                              key: state.pageKey,
                              child: SkillTreeView(trainingPathId: id),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // ── Branch 2: Resources ─────────────────────────────────────────
            StatefulShellBranch(
              observers: [routeObserverResources],
              navigatorKey: resourcesNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: ResourcesPage.path,
                  name: ResourcesPage.name,
                  builder: (context, state) => const ResourcesPage(),
                  routes: <RouteBase>[
                    GoRoute(
                      name: ResourceCommentPage.name,
                      path: ResourceCommentPage.path,
                      builder: (context, state) => ResourceCommentPage(
                        id: state
                            .pathParameters[ResourceCommentPage.pathParams]!,
                      ),
                    ),
                    GoRoute(
                      name: ResourceWebPage.name,
                      path: ResourceWebPage.path,
                      builder: (context, state) => ResourceWebPage(
                        url: state
                            .pathParameters[ResourceWebPage.urlPathParams]!,
                        title: state
                            .pathParameters[ResourceWebPage.titlePathParams]!,
                      ),
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

  // Horizontal slide for in-branch pushes/pops (Skill Tree pages).
  static CustomTransitionPage<dynamic> _horizontalSlidePage({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<dynamic>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final inTween =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut));
        final outTween =
            Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
                .chain(CurveTween(curve: Curves.easeInOut));

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
}

/// Holds & animates all branch Navigators. Used by navigatorContainerBuilder.
/// Keeps state per branch; only current + outgoing
///  branch are visible during slide.
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

      // Hide others after animation finishes
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

    // ⬇️ This clip keeps slides inside the content
    // area so they never cover the rail
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
                child: TickerMode(
                  enabled: index == curr,
                  child: navigator,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
