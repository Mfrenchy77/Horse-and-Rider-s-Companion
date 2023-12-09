import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/error_view.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/Login/view/login_page.dart';
import 'package:horseandriderscompanion/Messages/view/messages_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';
import 'package:responsive_framework/responsive_framework.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    // required this.auth,
    required this.settingsController,
    required AuthenticationRepository authenticationRepository,
  }) : _authenticationRepository = authenticationRepository;
  // final FirebaseAuth auth;
  final AuthenticationRepository _authenticationRepository;
  final SettingsController settingsController;
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authenticationRepository,
      child: BlocProvider(
        create: (context) =>
            AppBloc(authenticationRepository: _authenticationRepository),
        child: AppView(settingsController: settingsController),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key, required this.settingsController});
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // final isDarkMode = SharedPrefs().isDarkMode;
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<MessagesRepository>(
              create: (context) => MessagesRepository(),
            ),
            RepositoryProvider<SkillTreeRepository>(
              create: (context) => SkillTreeRepository(),
            ),
            RepositoryProvider<RiderProfileRepository>(
              create: (context) => RiderProfileRepository(),
            ),
            RepositoryProvider<ResourcesRepository>(
              create: (context) => ResourcesRepository(),
            ),
            RepositoryProvider<HorseProfileRepository>(
              create: (context) => HorseProfileRepository(),
            ),
            RepositoryProvider<CatagorryRepository>(
              create: (context) => CatagorryRepository(),
            ),
            RepositoryProvider<SkillsRepository>(
              create: (context) => SkillsRepository(),
            ),
            RepositoryProvider<LevelsRepository>(
              create: (context) => LevelsRepository(),
            ),
            RepositoryProvider<SubCategoryRepository>(
              create: (context) => SubCategoryRepository(),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
            // Providing a restorationScopeId allows the Navigator built by the
            // MaterialApp to restore the navigation stack when a user leaves
            // and
            // returns to the app after it has been killed while running in the
            // background.
            restorationScopeId: 'app',

            /// The title of the app
            title: "Horse & Rider's Companion",

            // Provide the generated AppLocalizations to the MaterialApp. This
            // allows descendant Widgets to display the correct translations
            // depending on the user's locale.
            localizationsDelegates: const [
              AppLocalizations.delegate,
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,

            // The appTitle is defined in .arb files found in the localization
            // directory.
            onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
            themeMode: settingsController.darkMode,
            theme: settingsController.theme,
            darkTheme: settingsController.darkTheme,
            debugShowCheckedModeBanner: false,
            home: BlocBuilder<AppBloc, AppState>(
              builder: (context, state) {
                switch (state.status) {                 
                  case AppStatus.authenticated:
                    return const HomePage();
                  case AppStatus.unauthenticated:
                    return const LoginPage();
                }
              },
            ),

            // FlowBuilder<AppStatus>(
            //   state: context.select((AppBloc bloc) => bloc.state.status),
            //  onGeneratePages: onGenerateAppViewPages,
            // ),
            // Define a function to handle named routes in order to support
            // Flutter web url navigation and deep linking.

            onGenerateRoute: (routeSettings) {
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (context) {
                  switch (routeSettings.name) {
                    case '/':
                      return AppView(
                        settingsController:
                            SettingsController(SettingsService()),
                      );
                    case SettingsView.routeName:
                      return SettingsView(controller: settingsController);
                    case LoginPage.routeName:
                      return const LoginPage();
                    case HomePage.routeName:
                      return const HomePage();
                    // case HorseHomePage.routeName:
                    //   return const HorseHomePage();
                    case MessagesPage.routeName:
                      return const MessagesPage();

                    default:
                      return errorView(context);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
