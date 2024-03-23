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
            // TODO: implement listener
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
