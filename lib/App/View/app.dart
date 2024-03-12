import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profiles_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

// GoRouter _router({
//   required SettingsController settingsContoller,
//   required AppCubit appCubit,
// }) {
//   return GoRouter(
//     initialLocation: AuthPage.routeName,
//     debugLogDiagnostics: true,
//     routes: [
//       GoRoute(
//         path: AuthPage.routeName,
//         name: 'auth',
//         builder: (context, state) => const AuthPage(),
//       ),
//       GoRoute(
//         path: SettingsView.routeName,
//         name: 'settings',
//         builder: (context, state) {
//           return SettingsView(
//             controller: settingsContoller,
//           );
//         },
//       ),
//       GoRoute(
//         path: MessagesPage.routeName,
//         name: 'messages',
//         builder: (context, state) => const MessagesPage(),
//       ),
//       GoRoute(
//         path: RiderProfilePage.routeName,
//         name: 'riderProfile/:id',
//         builder: (context, state) => const RiderProfilePage(),
//       ),
//       GoRoute(
//         path: HorseProfilePage.routeName,
//         name: 'horseProfile',
//         builder: (context, state) => const HorseProfilePage(),
//       ),
//       GoRoute(
//         path: SkillTreePage.routeName,
//         name: 'skillTree',
//         builder: (context, state) => const SkillTreePage(),
//       ),
//       GoRoute(
//         path: ResourcesPage.routeName,
//         name: 'resources',
//         builder: (context, state) => const ResourcesPage(),
//       ),
//     ],
//     redirect: (context, state) {
//       final appState = appCubit.state;

//       switch (appState.pageStatus) {
//         case AppPageStatus.loading:
//           return null;
//         case AppPageStatus.auth:
//           return AuthPage.routeName;
//         case AppPageStatus.awitingEmailVerification:
//           return null;
//         case AppPageStatus.profileSetup:
//           return null;
//         case AppPageStatus.profile:
//           return appState.isForRider
//               ? RiderProfilePage.routeName
//               : HorseProfilePage.routeName;
//         case AppPageStatus.skillTree:
//           return SkillTreePage.routeName;
//         case AppPageStatus.resource:
//           return ResourcesPage.routeName;
//         case AppPageStatus.messages:
//           return MessagesPage.routeName;
//         case AppPageStatus.settings:
//           return SettingsView.routeName;
//       }
//     },
//   );
// }

/// The `App` class is responsible for building the main
///  application widget tree.
/// It provides the necessary dependencies and initializes
/// the `AppBloc` and `AppView` widgets.
class App extends StatelessWidget {
  const App({
    super.key,
    required this.settingsController,
    required MessagesRepository messagesRepository,
    required SkillTreeRepository skillTreeRepository,
    required ResourcesRepository resourcesRepository,
    required RiderProfileRepository riderProfileRepository,
    required HorseProfileRepository horseProfileRepository,
    required AuthenticationRepository authenticationRepository,
  })  : _messagesRepository = messagesRepository,
        _skillTreeRepository = skillTreeRepository,
        _resourcesRepository = resourcesRepository,
        _riderProfileRepository = riderProfileRepository,
        _horseProfileRepository = horseProfileRepository,
        _authenticationRepository = authenticationRepository;

  final SettingsController settingsController;
  final MessagesRepository _messagesRepository;
  final SkillTreeRepository _skillTreeRepository;
  final ResourcesRepository _resourcesRepository;
  final RiderProfileRepository _riderProfileRepository;
  final HorseProfileRepository _horseProfileRepository;
  final AuthenticationRepository _authenticationRepository;

  @override
  Widget build(BuildContext context) {
    final appCubit = AppCubit(
      messagesRepository: _messagesRepository,
      skillTreeRepository: _skillTreeRepository,
      resourcesRepository: _resourcesRepository,
      horseProfileRepository: _horseProfileRepository,
      riderProfileRepository: _riderProfileRepository,
      authenticationRepository: _authenticationRepository,
    );
    final router = Routes().router(
      settingsController: settingsController,
      appCubit: appCubit,
    );
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: _messagesRepository,
        ),
        RepositoryProvider.value(
          value: _skillTreeRepository,
        ),
        RepositoryProvider.value(
          value: _resourcesRepository,
        ),
        RepositoryProvider.value(
          value: _riderProfileRepository,
        ),
        RepositoryProvider.value(
          value: _horseProfileRepository,
        ),
        RepositoryProvider.value(
          value: _authenticationRepository,
        ),
      ],
      child: BlocProvider.value(
        value: appCubit,
        child: AppView(
          settingsController: settingsController,
          router: router,
        ),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({
    super.key,
    required this.settingsController,
    required this.router,
  });
  final SettingsController settingsController;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        return BlocListener<AppCubit, AppState>(
          listener: (context, state) {
            //router.refresh();
            switch (state.pageStatus) {
              case AppPageStatus.auth:
                debugPrint('AuthPage');
                router.goNamed('auth');
                break;
              case AppPageStatus.error:
                debugPrint('ErrorPage');
                break;
              case AppPageStatus.loading:
                debugPrint('LoadingPage');
                break;
              case AppPageStatus.awitingEmailVerification:
                debugPrint('AwaitingEmailVerificationPage');
                break;
              case AppPageStatus.profileSetup:
                debugPrint('ProfileSetupPage');
                break;
              case AppPageStatus.settings:
                debugPrint('SettingsPage');
                router.goNamed('settings');
                break;
              case AppPageStatus.messages:
                debugPrint('MessagesPage');
                router.goNamed('messages');
                break;
              case AppPageStatus.profile:
                if (state.isGuest) {
                  debugPrint('GuestProfilePage');
                  router.goNamed('guestProfile');
                } else if (state.isForRider) {
                  debugPrint('RiderProfilePage');
                  router.goNamed(
                    'riderProfile',
                    pathParameters: {'id': state.usersProfile!.id},
                  );
                } else {
                  debugPrint('HorseProfilePage');
                  router.goNamed(
                    'horseProfile',
                    pathParameters: {
                      'horseId': state.horseProfile!.id,
                      'id': state.usersProfile!.id,
                    },
                  );
                }
                break;
              case AppPageStatus.skillTree:
                if (state.isGuest) {
                  debugPrint('SkillTreePage for Guest');
                  router.goNamed('guestSkillTree');
                } else if (state.isForRider) {
                  debugPrint('SkillTreePage for Rider');
                  router.goNamed(
                    'riderSkillTree',
                    pathParameters: {'id': state.usersProfile!.id},
                  );
                } else {
                  debugPrint('SkillTreePage for Horse');
                  state.isGuest
                      ? router.goNamed('guestSkillTree')
                      : router.goNamed(
                          'horseSkillTree',
                          pathParameters: {
                            'horseId': state.horseProfile!.id,
                            'id': state.usersProfile!.id,
                          },
                        );
                }
                break;
              case AppPageStatus.resourceList:
                if (state.isGuest) {
                  debugPrint('ResourcesPage for Guest');

                  !state.isForRider
                      ? router.goNamed(
                          'guestResources',
                          pathParameters: {'horseId': state.horseProfile!.id},
                        )
                      : router.goNamed('guestResources');
                } else if (state.isForRider) {
                  debugPrint('ResourcesPage for Rider');
                  router.goNamed(
                    'riderResources',
                    pathParameters: {'id': state.usersProfile!.id},
                  );
                } else {
                  debugPrint('ResourcesPage for Horse');
                  router.goNamed(
                    'horseResources',
                    pathParameters: {
                      'horseId': state.horseProfile!.id,
                    },
                  );
                }
                break;
              case AppPageStatus.resource:
                if (state.isGuest) {
                  debugPrint('ResourceCommentPage for Guest');
                  router.goNamed(
                    'guestResourceComment',
                    pathParameters: {'resourceId': state.resource!.id!},
                  );
                } else if (state.isForRider) {
                  debugPrint('ResourceCommentPage for Rider');
                  router.goNamed(
                    'riderResourceComment',
                    pathParameters: {
                      'id': state.usersProfile!.id,
                      'resourceId': state.resource!.id!,
                    },
                  );
                } else {
                  debugPrint('ResourceCommentPage for Horse');
                  router.goNamed(
                    'horseResourceComment',
                    pathParameters: {
                      'resourceId': state.resource!.id!,
                      'horseId': state.horseProfile!.id,
                    },
                  );
                }
                break;
            }
            // if (state.pageStatus == AppPageStatus.auth) {
            //   router.go(AuthPage.routeName);
            // }
            // if (state.pageStatus == AppPageStatus.messages) {
            //   router.go(MessagesPage.routeName);
            // }
            // if (state.pageStatus == AppPageStatus.settings) {
            //   router.go(SettingsView.routeName);
            // }
            // if (state.pageStatus == AppPageStatus.profile) {

            // }

            // if (state.pageStatus == AppPageStatus.skillTree) {
            //   router.go('${AuthPage.routeName}'
            //       '${RiderProfilePage.routeName}/'
            //       '${SkillTreePage.routeName}');
            // }
            // if (state.pageStatus == AppPageStatus.resourceList) {
            //   router.go('${AuthPage.routeName}'
            //       '${RiderProfilePage.routeName}/'
            //       '${ResourcesPage.routeName}');
            // }
            // if (state.pageStatus == AppPageStatus.resource) {
            //   router.goNamed(
            //     ResourceCommentPage.name,
            //     pathParameters: {
            //       'id': state.resource!.id!,
            //     },
            //   );
            // }
          },
          child: MaterialApp.router(
            routerDelegate: router.routerDelegate,
            routeInformationParser: router.routeInformationParser,
            routeInformationProvider: router.routeInformationProvider,
            title: "Horse & Rider's Companion",
            themeMode: settingsController.darkMode,
            theme: settingsController.theme,
            darkTheme: settingsController.darkTheme,
            debugShowCheckedModeBanner: false,
          ),
        );
        // ),
      },
    );
  }
}
