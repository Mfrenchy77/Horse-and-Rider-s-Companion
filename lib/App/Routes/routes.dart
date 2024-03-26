import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/route_observer.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/messages_list_page.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

class Routes {
  GoRouter router({
    required SettingsController settingsContoller,
    required AppCubit appCubit,
  }) {
    final routeNavigatorKey = GlobalKey<NavigatorState>();
    final sectionNavigatorKey = GlobalKey<NavigatorState>();

    /// Route Observers: These are used to observe the route changes
    /// and perform actions based on the route changes.
    /// One is needed for each branch of the navigator.
    /// The observer is used to reset the state of the appCubit
    /// when the user navigates back from a specific page.
    /// This is done to ensure that the appCubit is in the correct state
    /// when the user navigates back to the page.
    final routeObserver = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        debugPrint('Observer Pop: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
      },
      onPush: (route, previousRoute) {
        debugPrint('Observer Push: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
        if (previousRoute?.settings.name == AuthPage.name) {
          appCubit.setProfile();
        }
      },
    );
    final routeObserverProfile = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        debugPrint('Profile Observer Pop: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
        //if from horse profile page
        if (route.settings.name == HorseProfilePage.name &&
            previousRoute?.settings.name == ProfilePage.name) {
          debugPrint('Horse Profile Page Pop');
          appCubit.resetFromHorseProfile();
        }
        //if from viewing profile page
        else if (route.settings.name == ViewingProfilePage.name &&
            previousRoute?.settings.name == ProfilePage.name) {
          debugPrint('Viewing Profile Page Pop');
          appCubit.resetFromViewingProfile();
        }
      },
      onPush: (route, previousRoute) {
        debugPrint('Profile Observer Push: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
        // if route is horse profile page
        if (route.settings.name == HorseProfilePage.name) {
          debugPrint('Horse Profile Page Push');
          appCubit.setHorseProfile();
        }
      },
    );
    final routeObserverSkillTree = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        debugPrint('SkillTree Observer Pop: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
      },
      onPush: (route, previousRoute) {
        debugPrint('SkillTree Observer Push: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
        if (route.settings.name == SkillTreePage.name) {
          debugPrint('SkillTree Page Push');
          appCubit.setSkillTree();
        }
      },
    );
    final routeObserverResources = RouteObserverWithCallback(
      onPop: (route, previousRoute) {
        debugPrint('Resource Observer Pop: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
        if (route.settings.name == ResourceCommentPage.name &&
            previousRoute?.settings.name == ResourcesPage.name) {
          debugPrint('Resource Comment Page Pop');

          appCubit.resetFromResource();
        }
      },
      onPush: (route, previousRoute) {
        debugPrint('Resource Observer Push: '
            '${route.settings.name}, ${previousRoute?.settings.name}');
        if (route.settings.name == ResourcesPage.name) {
          debugPrint('Resource Page Push');
          appCubit.setResourcesList();
        }
        if (route.settings.name == ResourceCommentPage.name) {
          debugPrint('Resource Comment Page Push');
          appCubit.setResource();
        }
      },
    );
    return GoRouter(
      observers: [routeObserver],
      //  debugLogDiagnostics: true,
      navigatorKey: routeNavigatorKey,
      initialLocation: ProfilePage.path,
      routes: <RouteBase>[
        GoRoute(
          path: AuthPage.path,
          name: AuthPage.name,
          builder: (context, state) => const AuthPage(),
        ),

        //Rider Profile navigation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              NavigatorView(child: navigationShell),
          branches: [
            // RiderProfilePage index 0
            StatefulShellBranch(
              observers: [routeObserverProfile],
              navigatorKey: sectionNavigatorKey,
              routes: <RouteBase>[
                // RiderProfilePage
                GoRoute(
                  name: ProfilePage.name,
                  path: ProfilePage.path,
                  builder: (context, state) => const ProfilePage(),
                  routes: [
                    // Settings
                    GoRoute(
                      name: SettingsView.name,
                      path: SettingsView.routeName,
                      builder: (context, state) {
                        return SettingsView(
                          controller: settingsContoller,
                        );
                      },
                    ),
                    // MessagesPage
                    GoRoute(
                      name: MessagesPage.name,
                      path: MessagesPage.path,
                      builder: (context, state) => const MessagesPage(),
                      routes: [
                        // MessagePage
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
                    //HorserProfilePage
                    GoRoute(
                      path: HorseProfilePage.path,
                      name: HorseProfilePage.name,
                      builder: (context, state) => HorseProfilePage(
                        horseId:
                            state.pathParameters[HorseProfilePage.pathParams]!,
                      ),
                    ),
                    // ViewingProfilePage
                    GoRoute(
                      path: ViewingProfilePage.path,
                      name: ViewingProfilePage.name,
                      builder: (context, state) => ViewingProfilePage(
                        id: state
                            .pathParameters[ViewingProfilePage.pathParams]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // SkillTreePage index 1
            StatefulShellBranch(
              observers: [routeObserverSkillTree],
              routes: <RouteBase>[
                GoRoute(
                  path: SkillTreePage.path,
                  name: SkillTreePage.name,
                  builder: (context, state) => const SkillTreePage(),
                ),
              ],
            ),
            //ResourcesPage for User index 2
            StatefulShellBranch(
              observers: [routeObserverResources],
              routes: <RouteBase>[
                GoRoute(
                  path: ResourcesPage.path,
                  name: ResourcesPage.name,
                  builder: (context, state) => const ResourcesPage(),
                  routes: <RouteBase>[
                    // ResourceCommentPage
                    GoRoute(
                      name: ResourceCommentPage.name,
                      path: ResourceCommentPage.path,
                      builder: (context, state) => ResourceCommentPage(
                        id: state
                            .pathParameters[ResourceCommentPage.pathParams]!,
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
}
