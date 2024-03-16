import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_page.dart';
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
    return GoRouter(
      debugLogDiagnostics: true,
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
                      name: 'settings',
                      path: SettingsView.routeName,
                      builder: (context, state) {
                        return SettingsView(
                          controller: settingsContoller,
                        );
                      },
                    ),
                    // MessagesPage
                    GoRoute(
                      name: 'messages',
                      path: MessagesPage.path,
                      builder: (context, state) => const MessagesPage(),
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
              routes: <RouteBase>[
                GoRoute(
                  path: SkillTreePage.path,
                  name: 'usersSkillTree',
                  builder: (context, state) => const SkillTreePage(),
                ),
              ],
            ),
            //ResourcesPage for User index 2
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: ResourcesPage.path,
                  name: 'usersResources',
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
