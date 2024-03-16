import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';

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
      settingsContoller: settingsController,
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
            // switch (state.pageStatus) {
            //   case AppPageStatus.auth:
            //     debugPrint('AuthPage');
            //     router.goNamed('auth');
            //     break;
            //   case AppPageStatus.error:
            //     debugPrint('ErrorPage');
            //     break;
            //   case AppPageStatus.loading:
            //     debugPrint('LoadingPage');
            //     break;
            //   case AppPageStatus.awitingEmailVerification:
            //     debugPrint('AwaitingEmailVerificationPage');
            //     break;
            //   case AppPageStatus.profileSetup:
            //     debugPrint('ProfileSetupPage');
            //     break;
            //   case AppPageStatus.settings:
            //     debugPrint('SettingsPage');
            //     router.goNamed('settings');
            //     break;
            //   case AppPageStatus.messages:
            //     debugPrint('MessagesPage');
            //     router.goNamed('messages');
            //     break;
            //   case AppPageStatus.profile:
            //     if (state.isViewing) {
            //       debugPrint('ViewingProfilePage');
            //       router.goNamed(
            //         ViewingProfilePage.name,
            //         pathParameters: {
            //           ViewingProfilePage.pathParams:
            //               state.viewingProfile?.email ??
            //                   state.viewingProfielEmail,
            //         },
            //       );
            //     } else if (!state.isForRider) {
            //       debugPrint('HorseProfilePage');
            //       router.goNamed(
            //         HorseProfilePage.name,
            //         pathParameters: {
            //           HorseProfilePage.pathParams: state.horseId,
            //         },
            //       );
            //     } else {
            //       debugPrint('RiderProfilePage');
            //       router.goNamed(ProfilePage.name);
            //     }

            //     break;
            //   case AppPageStatus.skillTree:
            //     // if (state.isGuest) {
            //     //   debugPrint('SkillTreePage for Guest');
            //     //   router.goNamed('guestSkillTree');
            //     // } else {
            //     debugPrint('SkillTreePage for Rider');
            //     router.goNamed('usersSkillTree');
            //     // }
            //     break;
            //   case AppPageStatus.resourceList:
            //     debugPrint('ResourcesPage for Guest');

            //     // state.isGuest
            //     //     ? router.goNamed('guestResources')
            //     //     :
            //     router.goNamed('usersResources');

            //     break;
            //   case AppPageStatus.resource:
            //     // if (state.isGuest) {
            //     //   debugPrint('ResourceCommentPage for Guest');
            //     //   router.goNamed(
            //     //     'guestResourceComment',
            //     //     pathParameters: {'resourceId': state.resource!.id!},
            //     //   );
            //     // } else {
            //     debugPrint('ResourceCommentPage for Rider');
            //     router.goNamed(
            //       'usersResourceComment',
            //       pathParameters: {
            //         'resourceId': state.resource!.id!,
            //       },
            //     );

            //     break;
            //   // }
            // }
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
