import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuth extends Mock implements AuthenticationRepository {}

class _MockSkills extends Mock implements SkillTreeRepository {}

class _MockResources extends Mock implements ResourcesRepository {}

class _MockMessages extends Mock implements MessagesRepository {}

class _MockRiders extends Mock implements RiderProfileRepository {}

class _MockHorses extends Mock implements HorseProfileRepository {}

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Resource());
  });

  late SettingsController settings;
  late InMemorySkillTreeV2Store store;
  late SkillTreeV2Repository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    settings = SettingsController(SettingsService());
    await settings.loadSettings();
    store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    repository = SkillTreeV2Repository(store: store);
  });

  tearDown(() {
    settings.dispose();
  });

  Widget wrapV2({
    required AppCubit appCubit,
    Size surfaceSize = const Size(1200, 900),
    bool enableLocalInstructorPreview = true,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: SettingsControllerScope(
        controller: settings,
        child: BlocProvider<AppCubit>.value(
          value: appCubit,
          child: MaterialApp(
            home: SkillTreeV2View(
              repository: repository,
              enableLocalInstructorPreview: enableLocalInstructorPreview,
            ),
          ),
        ),
      ),
    );
  }

  AppState authenticatedRiderState({HorseProfile? horseProfile}) {
    final rider = RiderProfile(
      id: 'alex@example.com',
      name: 'Alex Rider',
      email: 'alex@example.com',
      picUrl: '',
    );
    return const AppState.authenticated(
      User(id: 'uid-alex', name: 'Alex Rider', email: 'alex@example.com'),
    ).copyWith(
      isGuest: false,
      usersProfile: rider,
      horseProfile: horseProfile,
      hasResourceCatalogue: true,
      resources: const <Resource>[],
    );
  }

  testWidgets(
    'feature flag defaults to false and preserves legacy SkillTreeView',
    (tester) async {
    final auth = _MockAuth();
    final skills = _MockSkills();
    final resources = _MockResources();
    when(() => auth.currentUser).thenReturn(User.empty);
    when(() => auth.user).thenAnswer((_) => const Stream.empty());
    when(skills.getSkills).thenAnswer((_) => const Stream.empty());
    when(resources.getResources).thenAnswer((_) => const Stream.empty());
    final appCubit = AppCubit(
      authenticationRepository: auth,
      skillTreeRepository: skills,
      resourcesRepository: resources,
      messagesRepository: _MockMessages(),
      riderProfileRepository: _MockRiders(),
      horseProfileRepository: _MockHorses(),
    );
    addTearDown(appCubit.close);

    expect(settings.skillTreeV2Enabled, isFalse);

    await tester.pumpWidget(
      SettingsControllerScope(
        controller: settings,
        child: BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const MaterialApp(home: Scaffold(body: SkillTreePage())),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('skillTreeView')), findsOneWidget);
    expect(find.byKey(const Key('skillTreeV2PageView')), findsNothing);
  });

  testWidgets(
    'SkillTreePage with V2 enabled renders without an outer Scaffold',
    (tester) async {
      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await settings.updateSkillTreeV2Enabled(enabled: true);
      expect(settings.skillTreeV2Enabled, isTrue);

      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: BlocProvider<AppCubit>.value(
            value: mockAppCubit,
            child: const MaterialApp(
              home: SkillTreePage(),
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .byKey(const Key('skillTreeV2Realm_Husbandry'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      expect(find.byKey(const Key('skillTreeV2PageView')), findsOneWidget);
      expect(
        find.byKey(const Key('skillTreeV2Realm_Husbandry')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Rider has 4 realms, Horse has 2 realms and browses freely',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(wrapV2(appCubit: mockAppCubit));
      await tester.pumpAndSettle();

      // Rider realms: Husbandry, In-Hand, Mounted, Theory & Knowledge
      expect(
        find.byKey(const Key('skillTreeV2Realm_Husbandry')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('skillTreeV2Realm_In_Hand')), findsOneWidget);
      expect(find.byKey(const Key('skillTreeV2Realm_Mounted')), findsOneWidget);
      expect(find.byKey(const Key('skillTreeV2Realm_Other')), findsOneWidget);

      // No completion percentages on families
      expect(find.textContaining('%'), findsNothing);

      // Switch to Horse without a selected HorseProfile
      await tester.tap(find.text('Horse'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('skillTreeV2Realm_In_Hand')), findsOneWidget);
      expect(find.byKey(const Key('skillTreeV2Realm_Mounted')), findsOneWidget);
      expect(find.byKey(const Key('skillTreeV2Realm_Husbandry')), findsNothing);
      expect(find.byKey(const Key('skillTreeV2Realm_Other')), findsNothing);
      expect(
        find.textContaining('Browsing Horse curriculum freely'),
        findsOneWidget,
      );

      // Shoulder-In offers Intermediate & Advanced, not Introductory
      await tester.tap(find.byKey(const Key('skillTreeV2Realm_Mounted')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('skillCard_horse.mounted.shoulder_in')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('skillCard_horse.mounted.shoulder_in')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('levelTab_horse.mounted.shoulder_in_Introductory'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const Key('levelTab_horse.mounted.shoulder_in_Intermediate'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('levelTab_horse.mounted.shoulder_in_Advanced')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Self-assessment, verification, search, summary & matrix work',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(wrapV2(appCubit: mockAppCubit));
      await tester.pumpAndSettle();

      // Search by component terminology ("hoof picking" -> Grooming)
      await tester.enterText(
        find.byKey(const Key('skillTreeV2SearchField')),
        'hoof picking',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
      );
      await tester.pumpAndSettle();

      // Self-assess Introductory as Proficient
      await tester.ensureVisible(
        find.byKey(
          const Key(
            'assessProficient_rider.husbandry.grooming_Introductory',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key(
            'assessProficient_rider.husbandry.grooming_Introductory',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify as Instructor
      await tester.ensureVisible(
        find.byKey(
          const Key('verifyLevel_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('verifyLevel_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Verified by Alex Rider'), findsOneWidget);

      // Switch to Summary view
      await tester.ensureVisible(find.text('Summary'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 Proficient'), findsOneWidget);
      expect(find.textContaining('1 Instructor Verified'), findsOneWidget);
      expect(find.text('Browse category'), findsWidgets);

      // Switch to Skill Overview view and verify on mobile width too
      await tester.ensureVisible(find.text('Skill Overview'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skill Overview'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('matrixFilter_verified')));
      await tester.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Grooming'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(430, 850));
      await tester.pumpAndSettle();
      expect(find.text('Grooming'), findsOneWidget);
    },
  );

  testWidgets(
    'App-bar back and system back return from detail before exiting Skill Tree',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(
        wrapV2(
          appCubit: mockAppCubit,
          surfaceSize: const Size(430, 850),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to In-Hand realm and enter a search filter
      await tester.tap(find.byKey(const Key('skillTreeV2Realm_In_Hand')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('skillTreeV2SearchField')),
        'forehand',
      );
      await tester.pumpAndSettle();

      // Open skill detail on mobile
      await tester.tap(
        find.byKey(const Key('skillCard_rider.in_hand.turn_on_forehand')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillDetailV2_rider.in_hand.turn_on_forehand')),
        findsOneWidget,
      );

      // Tapping app-bar Back returns to Skill Tree browsing (does not exit)
      await tester.tap(find.byKey(const Key('skillTreeV2AppBarBackButton')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillDetailV2_rider.in_hand.turn_on_forehand')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('skillCard_rider.in_hand.turn_on_forehand')),
        findsOneWidget,
      );
      verifyNever(() => mockAppCubit.changeIndex(any()));

      // Re-open detail and test system Back (Navigator.maybePop)
      await tester.tap(
        find.byKey(const Key('skillCard_rider.in_hand.turn_on_forehand')),
      );
      await tester.pumpAndSettle();
      final context = tester.element(
        find.byKey(const Key('skillDetailV2_rider.in_hand.turn_on_forehand')),
      );
      await Navigator.of(context).maybePop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillDetailV2_rider.in_hand.turn_on_forehand')),
        findsNothing,
      );
      verifyNever(() => mockAppCubit.changeIndex(any()));

      // From root browsing state, app-bar Back exits Skill Tree
      await tester.tap(find.byKey(const Key('skillTreeV2AppBarBackButton')));
      await tester.pumpAndSettle();
      verify(() => mockAppCubit.changeIndex(0)).called(1);
    },
  );

  testWidgets(
    'Legacy Resources appear under V2 skills before catalogue load',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final mockResources = _MockResources();
      final hoofResource = Resource(
        id: 'res-hoof',
        name: 'Hoof Picking Guide',
        url: 'https://example.com/hoof',
        type: ResourceType.link,
        rating: 5,
        numberOfRates: 10,
        skillTreeIds: const ['rider.husbandry.pick_hooves'],
      );
      final legacyIdResource = Resource(
        id: 'res-legacy-id',
        name: 'Legacy Hoof Video',
        url: 'https://example.com/legacy-hoof',
        type: ResourceType.link,
        rating: 4,
        numberOfRates: 4,
        skillTreeIds: const ['legacy-doc-99'],
      );
      final legacySkill = Skill(
        id: 'legacy-doc-99',
        skillName: 'Pick hooves',
        category: SkillCategory.Husbandry,
        rider: true,
        position: 1,
        description: '',
        learningDescription: '',
        proficientDescription: '',
        lastEditBy: 'admin',
        lastEditDate: DateTime(2026),
      );

      when(
        () => mockResources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((invocation) {
        final id = invocation.namedArguments[#skillId] as String;
        if (id == 'rider.husbandry.pick_hooves') {
          return Stream.value([hoofResource]);
        }
        if (id == 'legacy-doc-99') {
          return Stream.value([legacyIdResource]);
        }
        return Stream.value(const <Resource>[]);
      });

      final appState = authenticatedRiderState().copyWith(
        hasResourceCatalogue: false,
        resources: const <Resource>[],
        allSkills: [legacySkill],
      );
      when(() => mockAppCubit.state).thenReturn(appState);
      when(() => mockAppCubit.isNewResource(any())).thenReturn(false);
      when(() => mockAppCubit.canEditResource(any())).thenReturn(false);
      when(() => mockAppCubit.isRatingPositive(any())).thenReturn(false);
      when(() => mockAppCubit.isRatingNegative(any())).thenReturn(false);

      await tester.pumpWidget(
        RepositoryProvider<ResourcesStore?>.value(
          value: mockResources,
          child: wrapV2(appCubit: mockAppCubit),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Related Resources (2)'), findsOneWidget);
      expect(find.text('Hoof Picking Guide'), findsOneWidget);
      expect(find.text('Legacy Hoof Video'), findsOneWidget);
    },
  );

  testWidgets(
    'Uses custom horse icon, Category terminology, Skill Overview tab, '
    'and Handling & Care family',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(wrapV2(appCubit: mockAppCubit));
      await tester.pumpAndSettle();

      // Custom horse icon instead of generic paw icon
      expect(find.byIcon(HorseAndRiderIcons.horseIcon), findsOneWidget);
      expect(find.byIcon(Icons.pets_outlined), findsNothing);

      // Skill Overview tab instead of Matrix
      expect(find.text('Skill Overview'), findsOneWidget);
      expect(find.text('Matrix'), findsNothing);

      // Horse In-Hand family renamed to Handling & Care
      await tester.tap(find.text('Horse'));
      await tester.pumpAndSettle();
      expect(find.text('Handling & Care'), findsOneWidget);
      expect(find.text('Cooperative Care'), findsNothing);

      // Summary uses Category terminology
      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();
      expect(find.text('Browse category'), findsWidgets);
      expect(find.text('Browse realm'), findsNothing);
    },
  );
}
