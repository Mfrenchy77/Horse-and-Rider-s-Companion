import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.settingsController,
    required this._messagesRepository,
    required this._skillTreeRepository,
    required this._resourcesRepository,
    required this._riderProfileRepository,
    required this._horseProfileRepository,
    required this._authenticationRepository,
  });

  final SettingsController settingsController;
  final MessagesRepository _messagesRepository;
  final SkillTreeRepository _skillTreeRepository;
  final ResourcesRepository _resourcesRepository;
  final RiderProfileRepository _riderProfileRepository;
  final HorseProfileRepository _horseProfileRepository;
  final AuthenticationRepository _authenticationRepository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppCubit _appCubit;
  final _connections = ConnectionRepository();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _appCubit = AppCubit(
      messagesRepository: widget._messagesRepository,
      skillTreeRepository: widget._skillTreeRepository,
      resourcesRepository: widget._resourcesRepository,
      horseProfileRepository: widget._horseProfileRepository,
      riderProfileRepository: widget._riderProfileRepository,
      authenticationRepository: widget._authenticationRepository,
      submitCoachingAction: _connections.submit,
    );

    _router = Routes().router(
      settingsContoller: widget.settingsController,
      appCubit: _appCubit,
    );
  }

  @override
  void dispose() {
    _appCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _connections),
        RepositoryProvider.value(value: widget._messagesRepository),
        RepositoryProvider.value(value: widget._skillTreeRepository),
        RepositoryProvider.value(value: widget._resourcesRepository),
        RepositoryProvider.value(value: widget._riderProfileRepository),
        RepositoryProvider.value(value: widget._horseProfileRepository),
        RepositoryProvider.value(value: widget._authenticationRepository),
      ],
      child: BlocProvider.value(
        value: _appCubit,
        child: BlocProvider(
          create: (context) =>
              ConnectionsCubit(context.read<ConnectionRepository>(), _appCubit),
          child: AppView(
            settingsController: widget.settingsController,
            router: _router,
          ),
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
        return MaterialApp.router(
          title: "Horse & Rider's Companion",
          debugShowCheckedModeBanner: false,

          // Theme
          theme: settingsController.theme,
          darkTheme: settingsController.darkTheme,
          themeMode: settingsController.darkMode,
          builder: (context, child) {
            final useOceanCoralBackground =
                !settingsController.seasonalMode &&
                Theme.of(context).brightness == Brightness.dark;
            return DecoratedBox(
              decoration: useOceanCoralBackground
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorConst.mainPrimaryDark,
                          ColorConst.backgroundDark,
                          ColorConst.mainBackgroundDark,
                        ],
                        stops: [0, 0.56, 1],
                      ),
                    )
                  : const BoxDecoration(),
              child: SettingsControllerScope(
                controller: settingsController,
                child: ResourceLayoutScope(
                  layout: settingsController.resourceLayout,
                  child: SkillTreeLayoutScope(
                    layout: settingsController.skillTreeLayout,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },

          // Modern, single-parameter config
          routerConfig: router,

          // Localization (English only + Quill)
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('en', 'US')],
        );
      },
    );
  }
}
