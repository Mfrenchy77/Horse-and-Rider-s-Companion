import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_page.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profiles_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

class Routes {
  GoRouter router({
    required SettingsController settingsController,
    required AppCubit appCubit,
  }) {
    return GoRouter(
      observers: [RouteObserver()],
      initialLocation: '/auth',
      debugLogDiagnostics: true,
      routes: [
        // Auth
        GoRoute(
          path: '/auth',
          name: 'auth',
          builder: (context, state) => const AuthPage(),
        ),

        // Rider Profile navigation
        GoRoute(
          path: RiderProfilePage.path,
          name: 'riderProfile',
          builder: (context, state) =>
              RiderProfilePage(id: state.pathParameters['id']!),
          routes: [
            // Horse Profile Navigation within Rider Profile
            GoRoute(
              path: HorseProfilePage.path,
              name: 'horseProfile',
              builder: (context, state) =>
                  HorseProfilePage(horseId: state.pathParameters['id']!),
              routes: [
                // Skill Tree within Horse Profile
                GoRoute(
                  path: SkillTreePage.path,
                  name: 'horseSkillTree',
                  builder: (context, state) => const SkillTreePage(),
                ),
                // Resources within Horse Profile
                GoRoute(
                  path: ResourcesPage.path,
                  name: 'horseResources',
                  builder: (context, state) => const ResourcesPage(),
                  routes: [
                    // Resource Comment within Horse Profile
                    GoRoute(
                      path: ResourceCommentPage.path,
                      name: 'horseResourceComment',
                      builder: (context, state) => ResourceCommentPage(
                        id: state.pathParameters['resourceId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Resources within Rider Profile
            GoRoute(
              path: ResourcesPage.path,
              name: 'riderResources',
              builder: (context, state) => const ResourcesPage(),
              routes: [
                // Resource Comment within Rider Profile
                GoRoute(
                  path: ResourceCommentPage.path,
                  name: 'riderResourceComment',
                  builder: (context, state) => ResourceCommentPage(
                    id: state.pathParameters['resourceId']!,
                  ),
                ),
              ],
            ),
            // Skill Tree within Rider Profile
            GoRoute(
              path: SkillTreePage.path,
              name: 'riderSkillTree',
              builder: (context, state) => const SkillTreePage(),
            ),
            // Settings within Rider Profile
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) =>
                  SettingsView(controller: settingsController),
            ),
            // Messages within Rider Profile
            GoRoute(
              path: 'messages',
              name: 'messages',
              builder: (context, state) => const MessagesPage(),
            ),
          ],
        ),
        // Guest Profile navigation
        GoRoute(
          path: GuestProfilePage.path,
          name: 'guestProfile',
          builder: (context, state) => const GuestProfilePage(),
          routes: [
            // Skill Tree within Guest Profile
            GoRoute(
              path: SkillTreePage.path,
              name: 'guestSkillTree',
              builder: (context, state) => const SkillTreePage(),
            ),
            // Resources within Guest Profile
            GoRoute(
              path: ResourcesPage.path,
              name: 'guestResources',
              builder: (context, state) => const ResourcesPage(),
              routes: [
                // Resource Comment within Guest Profile
                GoRoute(
                  path: ResourceCommentPage.path,
                  name: 'guestResourceComment',
                  builder: (context, state) => ResourceCommentPage(
                    id: state.pathParameters['resourceId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final status = context.read<AppCubit>().state.status;
        switch (status) {
          case AppStatus.unauthenticated:
            return '/auth';
          case AppStatus.authenticated:
            // Redirect to a default authenticated route if necessary
            return null;
        }
      },
    );
  }
}


//   GoRouter router({
//     required SettingsController settingsContoller,
//     required AppCubit appCubit,
//   }) {
//     final routeNavigatorKey = GlobalKey<NavigatorState>();
//     final sectionNavigatorKey = GlobalKey<NavigatorState>();
//     return GoRouter(
//       debugLogDiagnostics: true,
//       navigatorKey: routeNavigatorKey,
//       initialLocation: AuthPage.routeName,
//       routes: <RouteBase>[
//         GoRoute(
//           path: AuthPage.routeName,
//           builder: (context, state) => const AuthPage(),
//         ),
//         GoRoute(
//           path: SettingsView.routeName,
//           builder: (context, state) {
//             return SettingsView(
//               controller: settingsContoller,
//             );
//           },
//         ),
//         GoRoute(
//           path: MessagesPage.routeName,
//           builder: (context, state) => const MessagesPage(),
//         ),
// //Horse Profile navigation
//         StatefulShellRoute.indexedStack(
//           builder: (context, state, navigationShell) =>
//               NavigatorView(body: navigationShell),
//           branches: [
//             // HorseProfilePage index 0
//             StatefulShellBranch(
//               navigatorKey: sectionNavigatorKey,
//               routes: [
//                 GoRoute(
//                   path: HorseProfilePage.routeName,
//                   builder: (context, state) =>
//                       HorseProfilePage(horseId: state.pathParameters['id']!),
//                 ),
//               ],
//             ),
//             // SkillTreePage index 1
//             StatefulShellBranch(
//               routes: <RouteBase>[
//                 GoRoute(
//                   path: SkillTreePage.routeName,
//                   builder: (context, state) => const SkillTreePage(),
//                 ),
//               ],
//             ),
//             //ResourcesPage index 2
//             StatefulShellBranch(
//               routes: <RouteBase>[
//                 GoRoute(
//                   path: ResourcesPage.routeName,
//                   builder: (context, state) => const ResourcesPage(),
//                   routes: <RouteBase>[
//                     // ResourceCommentPage
//                     GoRoute(
//                       path: ResourceCommentPage.routeName,
//                       builder: (context, state) =>
//                           ResourceCommentPage(id: state.pathParameters['id']!),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),

//         //Rider Profile navigation
//         StatefulShellRoute.indexedStack(
//           builder: (context, state, navigationShell) =>
//               NavigatorView(body: navigationShell),
//           branches: [
//             // RiderProfilePage index 0
//             StatefulShellBranch(
//               navigatorKey: sectionNavigatorKey,
//               routes: <RouteBase>[
//                 GoRoute(
//                   path: RiderProfilePage.routeName,
//                   builder: (context, state) => const RiderProfilePage(),
//                 ),
//               ],
//             ),
//             // SkillTreePage index 1
//             StatefulShellBranch(
//               routes: <RouteBase>[
//                 GoRoute(
//                   path: SkillTreePage.routeName,
//                   builder: (context, state) => const SkillTreePage(),
//                 ),
//               ],
//             ),
//             //ResourcesPage index 2
//             StatefulShellBranch(
//               routes: <RouteBase>[
//                 GoRoute(
//                   path: ResourcesPage.routeName,
//                   builder: (context, state) => const ResourcesPage(),
//                   routes: <RouteBase>[
//                     // ResourceCommentPage
//                     GoRoute(
//                       name: ResourceCommentPage.name,
//                       path: ResourceCommentPage.routeName,
//                       builder: (context, state) =>
//                           ResourceCommentPage(id: state.pathParameters['id']!),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//       redirect: (context, state) {
//         final status = context.read<AppCubit>().state.status;
//         if (status == AppStatus.authenticated) {
//           return null;
//         } else if (status == AppStatus.unauthenticated) {
//           return AuthPage.routeName;
//         } else {
//           return null;
//         }
//       },
//     );
//   }
// }
