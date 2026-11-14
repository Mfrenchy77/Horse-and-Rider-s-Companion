import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Delete/firebase_account_deletion_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';

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
    this._mediaStorageRepository,
    this._keysRepository,
    this._connectionRequestStore,
    this.useCompositeRequestStore = kUseCompositeRequestStore,
    this.mirrorRequestWritesToLegacy = kMirrorRequestWritesToLegacy,
    this._firestore,
  });

  /// Opt-in flag for dual-reading `Requests` alongside legacy
  /// `Conversations`/`Messages` during the migration window.
  ///
  /// Disabled by default until `Requests` security rules and backfill are
  /// deployed to production.
  static const bool kUseCompositeRequestStore = bool.fromEnvironment(
    'USE_COMPOSITE_REQUEST_STORE',
  );

  /// Opt-in flag to mirror new `Requests` writes to legacy
  /// `Conversations`/`Messages` for older client builds during transition.
  static const bool kMirrorRequestWritesToLegacy = bool.fromEnvironment(
    'MIRROR_REQUEST_WRITES_TO_LEGACY',
  );

  final SettingsController settingsController;
  final MessagesStore _messagesRepository;
  final SkillTreeStore _skillTreeRepository;
  final ResourcesStore _resourcesRepository;
  final RiderProfileStore _riderProfileRepository;
  final HorseProfileStore _horseProfileRepository;
  final AuthGateway _authenticationRepository;
  final MediaStorageRepository? _mediaStorageRepository;
  final ApiKeyProvider? _keysRepository;
  final ConnectionRequestStore? _connectionRequestStore;
  final bool useCompositeRequestStore;
  final bool mirrorRequestWritesToLegacy;
  final FirebaseFirestore? _firestore;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppCubit _appCubit;
  late final ConnectionRepository _connections = ConnectionRepository(
    authGateway: widget._authenticationRepository,
  );
  late final AccountDeletionRepository _accountDeletionRepository =
      FirebaseAccountDeletionRepository(
        authGateway: widget._authenticationRepository,
      );
  late final ConnectionRequestStore _connectionRequestStore =
      widget._connectionRequestStore ??
      (widget.useCompositeRequestStore
          ? CompositeConnectionRequestStore(
              primary: FirestoreConnectionRequestStore(
                firestore: widget._firestore,
              ),
              legacy: FirebaseConnectionRequestStore(
                messagesStore: widget._messagesRepository,
              ),
              mirrorWritesToLegacy: widget.mirrorRequestWritesToLegacy,
            )
          : FirebaseConnectionRequestStore(
              messagesStore: widget._messagesRepository,
            ));
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _appCubit = AppCubit(
      messagesRepository: widget._messagesRepository,
      connectionRequestRepository: _connectionRequestStore,
      skillTreeRepository: widget._skillTreeRepository,
      resourcesRepository: widget._resourcesRepository,
      horseProfileRepository: widget._horseProfileRepository,
      riderProfileRepository: widget._riderProfileRepository,
      authenticationRepository: widget._authenticationRepository,
      accountDeletionRepository: _accountDeletionRepository,
      submitCoachingAction: _connections.submit,
      fetchConnection: (id) async {
        final firestore = widget._firestore ?? FirebaseFirestore.instance;
        final snap = await firestore
            .collection('CoachingConnections')
            .doc(id)
            .get();
        return snap.data();
      },
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
        RepositoryProvider<LogbookConnectionRepository>.value(
          value: _connections,
        ),
        RepositoryProvider<MediaStorageRepository>(
          create: (_) => widget._mediaStorageRepository ?? CloudRepository(),
        ),
        RepositoryProvider<ApiKeyProvider>(
          create: (_) => widget._keysRepository ?? KeysRepository(),
        ),
        RepositoryProvider<MessagesStore>.value(
          value: widget._messagesRepository,
        ),
        RepositoryProvider<ConnectionRequestStore>.value(
          value: _connectionRequestStore,
        ),
        if (widget._messagesRepository case final MessagesRepository repo)
          RepositoryProvider<MessagesRepository>.value(value: repo),
        RepositoryProvider<SkillTreeStore>.value(
          value: widget._skillTreeRepository,
        ),
        if (widget._skillTreeRepository case final SkillTreeRepository repo)
          RepositoryProvider<SkillTreeRepository>.value(value: repo),
        RepositoryProvider<ResourcesStore>.value(
          value: widget._resourcesRepository,
        ),
        if (widget._resourcesRepository case final ResourcesRepository repo)
          RepositoryProvider<ResourcesRepository>.value(value: repo),
        RepositoryProvider<RiderProfileStore>.value(
          value: widget._riderProfileRepository,
        ),
        if (widget._riderProfileRepository
            case final RiderProfileRepository repo)
          RepositoryProvider<RiderProfileRepository>.value(value: repo),
        RepositoryProvider<LogbookRiderProfileRepository>.value(
          value: widget._riderProfileRepository,
        ),
        RepositoryProvider<HorseProfileStore>.value(
          value: widget._horseProfileRepository,
        ),
        if (widget._horseProfileRepository
            case final HorseProfileRepository repo)
          RepositoryProvider<HorseProfileRepository>.value(value: repo),
        RepositoryProvider<AuthGateway>.value(
          value: widget._authenticationRepository,
        ),
        RepositoryProvider<AccountDeletionRepository>.value(
          value: _accountDeletionRepository,
        ),
        if (widget._authenticationRepository
            case final AuthenticationRepository repo)
          RepositoryProvider<AuthenticationRepository>.value(value: repo),
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
            final gradients = Theme.of(context).extension<SurfaceGradients>();
            return DecoratedBox(
              decoration: BoxDecoration(gradient: gradients?.background),
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
