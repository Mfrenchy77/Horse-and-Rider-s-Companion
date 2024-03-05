import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';
import 'package:responsive_framework/responsive_framework.dart';

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
      child: BlocProvider(
        create: (context) => AppCubit(
          messagesRepository: _messagesRepository,
          skillTreeRepository: _skillTreeRepository,
          resourcesRepository: _resourcesRepository,
          horseProfileRepository: _horseProfileRepository,
          riderProfileRepository: _riderProfileRepository,
          authenticationRepository: _authenticationRepository,
        ),
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
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        return MaterialApp(
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
          restorationScopeId: 'app',
          title: "Horse & Rider's Companion",
          localizationsDelegates: const [
            AppLocalizations.delegate,
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
          themeMode: settingsController.darkMode,
          theme: settingsController.theme,
          darkTheme: settingsController.darkTheme,
          debugShowCheckedModeBanner: false,
          home: BlocListener<AppCubit, AppState>(
            // listenWhen: (previous, current) {
            //   return previous.index != current.index ||
            //       previous.user != current.user ||
            //       previous.isError != current.isError ||
            //       previous.isMessage != current.isMessage ||
            //       previous.pageStatus.name != current.pageStatus.name ||
            //       previous.isForRider != current.isForRider;
            // },
            listener: (context, state) {
              debugPrint('PageStatus: ${state.pageStatus.name}');
              final cubit = context.read<AppCubit>();
              switch (state.pageStatus) {
                case AppPageStatus.loading:
                  debugPrint('Loading');
                  showDialog<Dialog>(
                    context: context,
                    builder: (_) => const LoadingPage(),
                  );
                  break;
                case AppPageStatus.auth:
                  debugPrint('Auth Page');
                  Navigator.pushNamed(
                    context,
                    AuthPage.routeName,
                   // (Route<dynamic> route) => false,
                  );
                  break;
                case AppPageStatus.awitingEmailVerification:
                  debugPrint('Awaiting Email Verification');
                  showDialog<AlertDialog>(
                    context: context,
                    builder: (_) =>
                        EmailVerificationDialog(email: state.user.email),
                  );
                  break;
                case AppPageStatus.profileSetup:
                  debugPrint('Profile Setup');
                  showDialog<AlertDialog>(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => EditRiderProfileDialog(
                      riderProfile: null,
                      user: state.user,
                    ),
                  );
                  break;
                case AppPageStatus.profile:
                  debugPrint('Profile');
                  Navigator.of(context).pushReplacementNamed(
                    state.isForRider
                        ? RiderProfilePage.routeName
                        : HorseProfilePage.routeName,
                    // (Route<dynamic> route) => false,
                  );

                  break;
                case AppPageStatus.skillTree:
                  debugPrint('Skill Tree');
                  Navigator.pushNamed(
                    context,
                    SkillTreePage.routeName,
                  );
                  break;
                case AppPageStatus.resource:
                  // Implement your resource page navigation here
                  break;
              }
              // Profile Setup
              // if (state.pageStatus == AppPageStatus.profileSetup) {
              //   debugPrint('Show Profile Setup Dialog');
              //   showDialog<AlertDialog>(
              //     barrierDismissible: false,
              //     context: context,
              //     builder: (context) => EditRiderProfileDialog(
              //       riderProfile: null,
              //       user: state.user,
              //     ),
              //   ).then((value) => cubit.resetProfileSetup());
              // }

              // Error handling
              if (state.isError) {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          state.errorMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    ).closed.then((value) {
                      cubit.clearErrorMessage();
                    });
                });
              }
              // Message handling
              if (state.isMessage) {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          state.errorMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    ).closed.then((value) {
                      cubit.clearMessage();
                    });
                });
              }
            },
            child: BlocBuilder<AppCubit, AppState>(
              builder: (context, state) {
                return const AuthPage();
              },
            ),
          ),
          onGenerateRoute: (routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (context) {
                switch (routeSettings.name) {
                  case '/':
                    return AppView(
                      settingsController: SettingsController(SettingsService()),
                    );
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case AuthPage.routeName:
                    return const AuthPage();
                  // case HomePage.routeName:
                  //   return const HomePage();
                  case MessagesPage.routeName:
                    return const MessagesPage();
                  case RiderProfilePage.routeName:
                    return const RiderProfilePage();
                  case HorseProfilePage.routeName:
                    return const HorseProfilePage();
                  case SkillTreePage.routeName:
                    return const SkillTreePage();

                  default:
                    return const LoadingPage();
                }
              },
            );
          },
        );
        // ),
      },
    );
  }
}
