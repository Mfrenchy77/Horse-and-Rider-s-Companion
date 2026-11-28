import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockResources extends Mock implements ResourcesRepository {}

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
    'SkillTreePage always mounts permanent Skill Tree without legacy toggle',
    (tester) async {
      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: BlocProvider<AppCubit>.value(
            value: mockAppCubit,
            child: const MaterialApp(home: SkillTreePage()),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .byKey(const Key('skillTreeV2PageView'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      expect(find.byKey(const Key('skillTreeV2PageView')), findsOneWidget);
      expect(find.byKey(const Key('skillTreeView')), findsNothing);
    },
  );

  testWidgets('SkillTreePage renders without an outer Scaffold', (
    tester,
  ) async {
    final mockAppCubit = _MockAppCubit();
    final appState = authenticatedRiderState();
    when(() => mockAppCubit.state).thenReturn(appState);

    await tester.pumpWidget(
      SettingsControllerScope(
        controller: settings,
        child: BlocProvider<AppCubit>.value(
          value: mockAppCubit,
          child: const MaterialApp(home: SkillTreePage()),
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
    expect(find.byKey(const Key('skillTreeV2Realm_Husbandry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rider has 4 realms, Horse has 2 realms and browses freely', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockAppCubit = _MockAppCubit();
    final appState = authenticatedRiderState();
    when(() => mockAppCubit.state).thenReturn(appState);

    await tester.pumpWidget(wrapV2(appCubit: mockAppCubit));
    await tester.pumpAndSettle();

    // Rider realms: Husbandry, In-Hand, Mounted, Theory & Knowledge
    expect(find.byKey(const Key('skillTreeV2Realm_Husbandry')), findsOneWidget);
    expect(find.byKey(const Key('skillTreeV2Realm_In_Hand')), findsOneWidget);
    expect(find.byKey(const Key('skillTreeV2Realm_Mounted')), findsOneWidget);
    expect(find.byKey(const Key('skillTreeV2Realm_Other')), findsOneWidget);

    // No completion percentages on families and no Rider/Horse toggle
    expect(find.textContaining('%'), findsNothing);
    expect(find.byKey(const Key('skillTreeV2SubjectSelector')), findsNothing);

    // Re-mount in Horse context without a selected HorseProfile
    final horseState = authenticatedRiderState().copyWith(isForRider: false);
    when(() => mockAppCubit.state).thenReturn(horseState);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(wrapV2(appCubit: mockAppCubit));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skillTreeV2Realm_In_Hand')), findsOneWidget);
    expect(find.byKey(const Key('skillTreeV2Realm_Mounted')), findsOneWidget);
    expect(find.byKey(const Key('skillTreeV2Realm_Husbandry')), findsNothing);
    expect(find.byKey(const Key('skillTreeV2Realm_Other')), findsNothing);
    expect(find.textContaining('No horse profile selected'), findsOneWidget);

    // Shoulder-In offers Intermediate & Advanced, not Introductory
    await tester.tap(find.byKey(const Key('skillTreeV2Realm_Mounted')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const Key('skillFamilyHeader_horse.mounted.lateral_movements'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('skillFamilyHeader_horse.mounted.lateral_movements'),
      ),
    );
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
      find.byKey(const Key('levelTab_horse.mounted.shoulder_in_Introductory')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('levelTab_horse.mounted.shoulder_in_Intermediate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('levelTab_horse.mounted.shoulder_in_Advanced')),
      findsOneWidget,
    );
  });

  testWidgets('Self-assessment, verification, search, summary & matrix work', (
    tester,
  ) async {
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
      find.byKey(
        const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('skillCard_rider.husbandry.grooming')),
    );
    await tester.pumpAndSettle();

    // Self-assess Introductory as Proficient
    await tester.ensureVisible(
      find.byKey(
        const Key('assessProficient_rider.husbandry.grooming_Introductory'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('assessProficient_rider.husbandry.grooming_Introductory'),
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

    // Switch to My Skills view
    await tester.ensureVisible(find.text('My Skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Skills'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 Proficient'), findsOneWidget);
    expect(find.textContaining('1 Instructor Verified'), findsOneWidget);
    expect(find.text('Browse category'), findsWidgets);
    expect(
      find.byKey(const Key('mySkillCard_rider.husbandry.grooming')),
      findsOneWidget,
    );

    // Authorized instructor can open Review Verifications grid
    await tester.tap(find.byKey(const Key('reviewVerificationsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('matrixFilter_verified')));
    await tester.pumpAndSettle();
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(430, 850));
    await tester.pumpAndSettle();
    expect(find.text('Grooming'), findsOneWidget);
  });

  testWidgets(
    'App-bar back and system back return from detail before exiting Skill Tree',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(
        wrapV2(appCubit: mockAppCubit, surfaceSize: const Size(430, 850)),
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
      final forehandCard = find.byKey(
        const Key('skillCard_rider.in_hand.turn_on_forehand'),
      );
      await tester.ensureVisible(forehandCard);
      await tester.pumpAndSettle();
      await tester.tap(forehandCard);
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
      expect(forehandCard, findsOneWidget);
      verifyNever(() => mockAppCubit.changeIndex(any()));

      // Re-open detail and test system Back (Navigator.maybePop)
      await tester.ensureVisible(forehandCard);
      await tester.pumpAndSettle();
      await tester.tap(forehandCard);
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

  testWidgets('Legacy Resources appear under V2 skills before catalogue load', (
    tester,
  ) async {
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
      () => mockResources.getResourcesForSkill(skillId: any(named: 'skillId')),
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
      find.byKey(
        const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
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
  });

  testWidgets(
    'Uses custom horse icon, two-tab navigation, Category terminology, '
    'Handling & Care family, empty states, Horse Skills, and instructor access',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(
        wrapV2(appCubit: mockAppCubit, enableLocalInstructorPreview: false),
      );
      await tester.pumpAndSettle();

      // No Rider/Horse toggle in profile-context mode
      expect(find.byKey(const Key('skillTreeV2SubjectSelector')), findsNothing);
      expect(find.text('Rider Skills · Alex Rider'), findsOneWidget);

      // Two-tab navigation: Explore Skills | My Skills
      expect(find.text('Explore Skills'), findsOneWidget);
      expect(find.text('My Skills'), findsOneWidget);
      expect(find.text('Browse'), findsNothing);
      expect(find.text('Summary'), findsNothing);
      expect(find.text('Matrix'), findsNothing);
      expect(find.text('Skill Overview'), findsNothing);

      // Rider My Skills empty state + unauthorized user sees no Review
      // Verifications button
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "You haven't started tracking any skills yet. "
          'Explore the Skill Tree to get started.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reviewVerificationsButton')), findsNothing);

      // Empty state action returns to Explore Skills
      await tester.tap(find.byKey(const Key('mySkillsEmptyExploreButton')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
        ),
        findsOneWidget,
      );

      // Open Horse Profile context: custom horse icon & Handling & Care family
      final horseState = authenticatedRiderState().copyWith(isForRider: false);
      when(() => mockAppCubit.state).thenReturn(horseState);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        wrapV2(appCubit: mockAppCubit, enableLocalInstructorPreview: false),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(HorseAndRiderIcons.horseIcon), findsOneWidget);
      expect(find.byIcon(Icons.pets_outlined), findsNothing);
      expect(find.text('Handling & Care'), findsOneWidget);
      expect(find.text('Cooperative Care'), findsNothing);

      // Horse Skills heading and horse-specific empty state
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      expect(find.text('Horse Skills'), findsWidgets);
      expect(
        find.text(
          'No horse skills have been started yet. '
          'Explore the Skill Tree to get started.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Skill families default collapsed, toggle independently, reset on '
    'context switch, preserve on return, and auto-expand for search',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.pumpWidget(
        wrapV2(appCubit: mockAppCubit, surfaceSize: const Size(430, 850)),
      );
      await tester.pumpAndSettle();

      // Collapsed by default: family headers & chevrons visible, skills hidden
      expect(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.health_first_aid'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsNothing,
      );
      expect(find.byIcon(Icons.expand_more), findsWidgets);

      // Expand two families simultaneously
      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.health_first_aid'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.health_first_aid'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.first_aid')),
        findsOneWidget,
      );

      // Collapse the second family again
      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.health_first_aid'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.first_aid')),
        findsNothing,
      );

      // Open a skill on mobile and return: first family stays expanded
      await tester.ensureVisible(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillDetailV2_rider.husbandry.grooming')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('skillTreeV2AppBarBackButton')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.first_aid')),
        findsNothing,
      );

      // Search auto-expands matching family without altering saved expansion
      await tester.enterText(
        find.byKey(const Key('skillTreeV2SearchField')),
        'first aid',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.first_aid')),
        findsOneWidget,
      );

      // Clearing search restores previous expansion state
      await tester.enterText(
        find.byKey(const Key('skillTreeV2SearchField')),
        '',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.first_aid')),
        findsNothing,
      );

      // Switching category resets expansion to collapsed
      await tester.tap(find.byKey(const Key('skillTreeV2Realm_In_Hand')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skillTreeV2Realm_Husbandry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        findsNothing,
      );
    },
  );

  testWidgets('Per-level progress stays independent across Grooming levels, '
      'level chips show status, and My Skills shows both levels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockAppCubit = _MockAppCubit();
    final appState = authenticatedRiderState();
    when(() => mockAppCubit.state).thenReturn(appState);

    await tester.pumpWidget(
      wrapV2(appCubit: mockAppCubit, enableLocalInstructorPreview: false),
    );
    await tester.pumpAndSettle();

    // 1. Open Rider -> Husbandry -> Grooming
    await tester.tap(
      find.byKey(
        const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('skillCard_rider.husbandry.grooming')),
    );
    await tester.pumpAndSettle();

    // 2. Set Introductory to Proficient
    await tester.ensureVisible(
      find.byKey(
        const Key('assessProficient_rider.husbandry.grooming_Introductory'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('assessProficient_rider.husbandry.grooming_Introductory'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Marked as Proficient.'), findsOneWidget);

    // 3. Switch to Intermediate and set it to Learning
    await tester.ensureVisible(
      find.byKey(const Key('levelTab_rider.husbandry.grooming_Intermediate')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('levelTab_rider.husbandry.grooming_Intermediate')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const Key('assessLearning_rider.husbandry.grooming_Intermediate'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('assessLearning_rider.husbandry.grooming_Intermediate'),
      ),
    );
    await tester.pumpAndSettle();

    // Level selector chips show both statuses simultaneously
    expect(find.text('Introductory · Proficient'), findsOneWidget);
    expect(find.text('Intermediate · Learning'), findsOneWidget);

    // 4. Return to Introductory and confirm Proficient remains selected
    await tester.ensureVisible(
      find.byKey(const Key('levelTab_rider.husbandry.grooming_Introductory')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('levelTab_rider.husbandry.grooming_Introductory')),
    );
    await tester.pumpAndSettle();
    final introProficientChip = tester.widget<ChoiceChip>(
      find.byKey(
        const Key('assessProficient_rider.husbandry.grooming_Introductory'),
      ),
    );
    expect(introProficientChip.selected, isTrue);

    // 5. Open My Skills and confirm Grooming displays both levels
    await tester.ensureVisible(find.text('My Skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Skills'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mySkillCard_rider.husbandry.grooming')),
      findsOneWidget,
    );
    expect(find.text('Introductory · Proficient'), findsOneWidget);
    expect(find.text('Intermediate · Learning'), findsOneWidget);

    // 6. Return to Grooming and confirm neither assessment was overwritten
    await tester.tap(
      find.byKey(const Key('mySkillCard_rider.husbandry.grooming')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Introductory · Proficient'), findsOneWidget);
    expect(find.text('Intermediate · Learning'), findsOneWidget);
  });

  testWidgets(
    'Default preview store saves locally without Firestore and persists '
    'across My Skills and rebuilds',
    (tester) async {
      SkillTreeV2View.resetPreviewStoreForTest();
      addTearDown(SkillTreeV2View.resetPreviewStoreForTest);

      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedRiderState();
      when(() => mockAppCubit.state).thenReturn(appState);

      final settings = SettingsController(SettingsService());
      await settings.loadSettings();

      Widget buildDefaultPreview() => SettingsControllerScope(
        controller: settings,
        child: BlocProvider<AppCubit>.value(
          value: mockAppCubit,
          child: const MaterialApp(home: SkillTreeV2View()),
        ),
      );

      Future<void> pumpUntilPreviewLoaded() async {
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump();
          if (find
              .byKey(const Key('skillTreeV2PreviewBanner'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(buildDefaultPreview());
      await pumpUntilPreviewLoaded();

      // Preview banner clearly distinguishes local session storage
      expect(find.byKey(const Key('skillTreeV2PreviewBanner')), findsOneWidget);

      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(
          const Key('assessLearning_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('assessLearning_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Could not save assessment. Please try again.'),
        findsNothing,
      );
      expect(find.text('Marked as Learning.'), findsOneWidget);

      // Navigate to My Skills and verify saved locally
      await tester.ensureVisible(find.text('My Skills'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mySkillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );

      // Rebuild SkillTreeV2View to simulate tab switch within session
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(buildDefaultPreview());
      await pumpUntilPreviewLoaded();
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mySkillCard_rider.husbandry.grooming')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Profile-context navigation scopes progress to Rider, viewed Student, '
    'and Horse profiles without leaking or falling back',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final controller = StreamController<AppState>.broadcast();
      addTearDown(controller.close);

      final riderState = authenticatedRiderState();
      final studentProfile = RiderProfile(
        id: 'sam@example.com',
        name: 'Sam Student',
        email: 'sam@example.com',
        picUrl: '',
      );
      final viewedStudentState = riderState.copyWith(
        isForRider: true,
        isViewing: true,
        viewingProfile: studentProfile,
      );
      final cometHorse = HorseProfile(
        id: 'horse-comet',
        name: 'Comet',
        currentOwnerId: 'alex@example.com',
        currentOwnerName: 'Alex Rider',
      );
      final horseState = riderState.copyWith(
        isForRider: false,
        isViewing: false,
        horseProfile: cometHorse,
      );

      whenListen(mockAppCubit, controller.stream, initialState: riderState);

      await tester.pumpWidget(wrapV2(appCubit: mockAppCubit));
      await tester.pumpAndSettle();

      // 1. Own Rider Profile records progress on Grooming
      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('skillCard_rider.husbandry.grooming')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(
          const Key('assessProficient_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('assessProficient_rider.husbandry.grooming_Introductory'),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Switch to viewing another Rider (Sam Student)
      when(() => mockAppCubit.state).thenReturn(viewedStudentState);
      controller.add(viewedStudentState);
      await tester.pumpAndSettle();

      expect(find.text('Rider Skills · Sam Student'), findsOneWidget);
      await tester.ensureVisible(find.text('My Skills'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      // Sam Student has no progress (Alex Rider's progress did not leak)
      expect(find.byKey(const Key('mySkillsEmptyState')), findsOneWidget);
      expect(
        find.byKey(const Key('mySkillCard_rider.husbandry.grooming')),
        findsNothing,
      );

      // 3. Switch to Horse Profile (Comet)
      when(() => mockAppCubit.state).thenReturn(horseState);
      controller.add(horseState);
      await tester.pumpAndSettle();

      expect(find.text('Horse Skills · Comet'), findsOneWidget);
      expect(find.byKey(const Key('skillTreeV2Realm_In_Hand')), findsOneWidget);
      expect(find.byKey(const Key('skillTreeV2Realm_Husbandry')), findsNothing);
      await tester.ensureVisible(find.text('My Skills'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mySkillsEmptyState')), findsOneWidget);
      expect(
        find.text(
          'No skills have been tracked for Comet yet. '
          'Explore the Skill Tree to get started.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Desktop resets only detail scroll on related-skill navigation and '
    'preserves scroll on same-skill assessment updates',
    (tester) async {
      const surfaceSize = Size(1200, 520);
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      when(() => mockAppCubit.state).thenReturn(authenticatedRiderState());
      await tester.pumpWidget(
        wrapV2(appCubit: mockAppCubit, surfaceSize: surfaceSize),
      );
      await tester.pumpAndSettle();

      // Expand the first family in Husbandry so the list is scrollable.
      final safetyHeader = find.byKey(
        const Key('skillFamilyHeader_rider.husbandry.safety_handling'),
      );
      await tester.ensureVisible(safetyHeader);
      await tester.pumpAndSettle();
      await tester.tap(safetyHeader);
      await tester.pumpAndSettle();

      final listScrollFinder = find.byKey(const Key('skillTreeV2ListScroll'));
      final detailScrollFinder = find.byKey(
        const Key('skillTreeV2DetailScroll'),
      );
      expect(listScrollFinder, findsOneWidget);
      expect(detailScrollFinder, findsOneWidget);

      final listScroll = tester.widget<SingleChildScrollView>(listScrollFinder);
      final detailScroll = tester.widget<SingleChildScrollView>(
        detailScrollFinder,
      );

      // Scroll the left skill list down independently.
      listScroll.controller!.jumpTo(40);
      await tester.pump();
      expect(listScroll.controller!.offset, greaterThan(0));

      // Scroll the right detail panel down toward Related skills.
      final maxDetail = detailScroll.controller!.position.maxScrollExtent;
      expect(maxDetail, greaterThan(0));
      detailScroll.controller!.jumpTo(maxDetail);
      await tester.pump();
      expect(detailScroll.controller!.offset, greaterThan(0));

      // Tap a Related Skill ActionChip inside the detail panel.
      final firstChip = find
          .descendant(of: detailScrollFinder, matching: find.byType(ActionChip))
          .first;
      await tester.ensureVisible(firstChip);
      await tester.pumpAndSettle();
      expect(detailScroll.controller!.offset, greaterThan(0));
      await tester.tap(firstChip);
      await tester.pumpAndSettle();

      // Detail scroll resets to 0 while list scroll stays at its offset.
      expect(detailScroll.controller!.offset, 0);
      expect(listScroll.controller!.offset, greaterThan(0));

      // Scroll detail down again and update assessment on the same skill;
      // scroll position must NOT reset.
      final newMaxDetail = detailScroll.controller!.position.maxScrollExtent;
      if (newMaxDetail > 0) {
        detailScroll.controller!.jumpTo(newMaxDetail);
        await tester.pump();
        final beforeAssess = detailScroll.controller!.offset;
        expect(beforeAssess, greaterThan(0));

        await tester.ensureVisible(find.text('Learning'));
        await tester.pumpAndSettle();
        final afterEnsure = detailScroll.controller!.offset;
        await tester.tap(find.text('Learning'));
        await tester.pumpAndSettle();

        expect(detailScroll.controller!.offset, afterEnsure);
      }

      // Rapid consecutive related-skill taps stay at top with no glitches.
      for (var i = 0; i < 2; i++) {
        final chip = find.descendant(
          of: detailScrollFinder,
          matching: find.byType(ActionChip),
        );
        if (chip.evaluate().isNotEmpty) {
          await tester.ensureVisible(chip.first);
          await tester.pump();
          await tester.tap(chip.first);
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();
      expect(detailScroll.controller!.offset, 0);
    },
  );

  testWidgets(
    'Mobile resets detail scroll to top when navigating via Related skills',
    (tester) async {
      const surfaceSize = Size(390, 600);
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      when(() => mockAppCubit.state).thenReturn(authenticatedRiderState());
      await tester.pumpWidget(
        wrapV2(appCubit: mockAppCubit, surfaceSize: surfaceSize),
      );
      await tester.pumpAndSettle();

      final safetyHeader = find.byKey(
        const Key('skillFamilyHeader_rider.husbandry.safety_handling'),
      );
      await tester.ensureVisible(safetyHeader);
      await tester.pumpAndSettle();
      await tester.tap(safetyHeader);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Safe Handling & Restraint'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Safe Handling & Restraint'));
      await tester.pumpAndSettle();

      final mobileScrollFinder = find.byKey(const Key('skillTreeV2View'));
      final mobileScroll = tester.widget<SingleChildScrollView>(
        mobileScrollFinder,
      );
      final maxExtent = mobileScroll.controller!.position.maxScrollExtent;
      expect(maxExtent, greaterThan(0));

      mobileScroll.controller!.jumpTo(maxExtent);
      await tester.pump();
      expect(mobileScroll.controller!.offset, greaterThan(0));

      final relatedChip = find
          .descendant(of: mobileScrollFinder, matching: find.byType(ActionChip))
          .first;
      await tester.ensureVisible(relatedChip);
      await tester.pumpAndSettle();
      expect(mobileScroll.controller!.offset, greaterThan(0));
      await tester.tap(relatedChip);
      await tester.pumpAndSettle();

      expect(mobileScroll.controller!.offset, 0);
      expect(find.byKey(const Key('skillDetailV2BackButton')), findsOneWidget);
    },
  );

  testWidgets(
    'Resource Edit & Link Skills respect ownership/editor permissions and '
    'Associated Skills modal uses blurred glass barrier',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final otherResource = Resource(
        id: 'res-other',
        name: 'Other Author Guide',
        url: 'https://example.com/other',
        type: ResourceType.link,
        rating: 4,
        numberOfRates: 1,
        authorId: 'other@example.com',
        skillTreeIds: const ['rider.husbandry.safe_handling'],
      );
      final ownResource = Resource(
        id: 'res-own',
        name: 'Alex Handling Guide',
        url: 'https://example.com/own',
        type: ResourceType.link,
        rating: 5,
        numberOfRates: 2,
        authorId: 'alex@example.com',
        skillTreeIds: const ['rider.husbandry.safe_handling'],
      );

      final mockAppCubit = _MockAppCubit();
      final baseState = authenticatedRiderState().copyWith(
        hasResourceCatalogue: true,
        resources: [otherResource, ownResource],
      );
      when(() => mockAppCubit.state).thenReturn(baseState);
      when(() => mockAppCubit.isNewResource(any())).thenReturn(false);
      when(() => mockAppCubit.isRatingPositive(any())).thenReturn(false);
      when(() => mockAppCubit.isRatingNegative(any())).thenReturn(false);
      when(() => mockAppCubit.canEditResource(any())).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.first as Resource).id == 'res-own',
      );

      final mockResourcesRepo = _MockResources();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ResourcesStore?>.value(value: null),
            RepositoryProvider<ResourcesRepository>.value(
              value: mockResourcesRepo,
            ),
          ],
          child: wrapV2(appCubit: mockAppCubit),
        ),
      );
      await tester.pumpAndSettle();

      final safetyHeader = find.byKey(
        const Key('skillFamilyHeader_rider.husbandry.safety_handling'),
      );
      await tester.ensureVisible(safetyHeader);
      await tester.pumpAndSettle();
      await tester.tap(safetyHeader);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('skillCard_rider.husbandry.safe_handling')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Related Resources (2)'), findsOneWidget);
      expect(find.text('Alex Handling Guide'), findsOneWidget);

      // Standalone Edit Resource & Link Skills buttons beneath cards are gone.
      expect(
        find.byKey(const Key('linkResourceSkillsButton_res-other')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('linkResourceSkillsButton_res-own')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('editResourceButton_res-other')),
        findsNothing,
      );
      expect(find.byKey(const Key('editResourceButton_res-own')), findsNothing);

      // Unauthorized resource overflow menu hides Edit Resource & Manage Links.
      final otherMenu = find.byKey(const Key('resourceOverflowMenu_res-other'));
      await tester.ensureVisible(otherMenu);
      await tester.pumpAndSettle();
      await tester.tap(otherMenu);
      await tester.pumpAndSettle();
      expect(find.text('Edit Resource'), findsNothing);
      expect(find.text('Manage Skill Links'), findsNothing);
      expect(find.text('Report'), findsOneWidget);
      await tester.tapAt(const Offset(600, 10));
      await tester.pumpAndSettle();

      // Authorized resource overflow menu exposes Edit Resource (not Manage
      // Skill Links) and opens the blurred modal.
      final ownMenu = find.byKey(const Key('resourceOverflowMenu_res-own'));
      await tester.ensureVisible(ownMenu);
      await tester.pumpAndSettle();
      await tester.tap(ownMenu);
      await tester.pumpAndSettle();
      expect(find.text('Edit Resource'), findsOneWidget);
      expect(find.text('Manage Skill Links'), findsNothing);
      await tester.tap(find.text('Edit Resource'));
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Associated skills icon button opens compact blurred Associated skills
      // dialog with Manage Links for authorized owner.
      final assocButtons = find.byTooltip('Associated skills');
      await tester.ensureVisible(assocButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(assocButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Associated skills'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsWidgets);
      expect(find.byKey(const Key('manageSkillLinksButton')), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Ordinary user cannot see admin curriculum edit controls in menu.
      await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillTreeV2MenuToggleAdminEdit')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'SkillTreePage.openSkill routes Rider and Horse links (including legacy '
    'IDs and level) into Skill Tree at top of detail and legacy URLs redirect',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockAppCubit = _MockAppCubit();
      final horse = HorseProfile(
        id: 'horse-comet',
        name: 'Comet',
        currentOwnerId: 'alex@example.com',
      );
      final controller = StreamController<AppState>.broadcast();
      addTearDown(controller.close);
      var currentState = authenticatedRiderState(horseProfile: horse);
      whenListen(mockAppCubit, controller.stream, initialState: currentState);
      when(() => mockAppCubit.state).thenAnswer((_) => currentState);
      when(
        () =>
            mockAppCubit.setSkillSubject(isForRider: any(named: 'isForRider')),
      ).thenAnswer((invocation) {
        final isForRider = invocation.namedArguments[#isForRider] as bool;
        currentState = currentState.copyWith(isForRider: isForRider);
        controller.add(currentState);
      });

      late GoRouter router;
      router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: SkillTreePage.path,
            name: SkillTreePage.name,
            builder: (context, state) {
              final skillId =
                  state.uri.queryParameters[SkillTreePage.skillPathParam];
              final levelParam = state.uri.queryParameters['level'];
              final level = levelParam == null
                  ? null
                  : DifficultyState.values
                        .where((l) => l.name == levelParam)
                        .firstOrNull;
              return SkillTreePage(
                initialSkillId: skillId,
                initialLevel: level,
              );
            },
            routes: [
              GoRoute(
                path: SkillTreePage.legacySkillsListPath,
                redirect: (_, state) {
                  if (state.uri.path.contains(
                    '/${SkillTreePage.legacySkillsListPath}/Skill:',
                  )) {
                    return null;
                  }
                  return SkillTreePage.path;
                },
                routes: [
                  GoRoute(
                    path: SkillTreePage.legacySkillLevelPath,
                    redirect: (_, state) => Uri(
                      path: SkillTreePage.path,
                      queryParameters: {
                        SkillTreePage.skillPathParam:
                            state.pathParameters[SkillTreePage
                                .skillPathParam] ??
                            '',
                      },
                    ).toString(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final mockResourcesRepo = _MockResources();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ResourcesStore?>.value(value: null),
            RepositoryProvider<ResourcesRepository>.value(
              value: mockResourcesRepo,
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: SettingsControllerScope(
              controller: settings,
              child: BlocProvider<AppCubit>.value(
                value: mockAppCubit,
                child: MaterialApp.router(routerConfig: router),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> pumpUntilV2Loaded() async {
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump();
          if (find.byKey(const Key('skillTreeV2View')).evaluate().isNotEmpty) {
            break;
          }
        }
        await tester.pumpAndSettle();
      }

      // 1. Rider legacy skill ID + Intermediate level -> opens at top.
      SkillTreePage.openSkill(
        router,
        'rider.husbandry.pick_hooves',
        level: DifficultyState.Intermediate,
      );
      await pumpUntilV2Loaded();

      expect(find.byKey(const Key('skillTreeV2PageView')), findsOneWidget);
      expect(
        find.byKey(const Key('skillDetailV2_rider.husbandry.grooming')),
        findsOneWidget,
      );
      final detailScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('skillTreeV2DetailScroll')),
      );
      expect(detailScroll.controller!.offset, 0);

      // Scroll detail down, then navigate to a Horse legacy skill ID.
      detailScroll.controller!.jumpTo(80);
      await tester.pump();
      expect(detailScroll.controller!.offset, greaterThan(0));

      // 2. Horse legacy skill ID -> switches to Horse context, opens Sidepass,
      //    and resets detail scroll to 0.
      SkillTreePage.openSkill(router, 'horse.mounted.sidepass_horse');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('skillDetailV2_horse.mounted.sidepass')),
        findsOneWidget,
      );
      expect(find.text('Horse Skills · Comet'), findsOneWidget);
      expect(detailScroll.controller!.offset, 0);

      // 3. Legacy /SkillTree/Skills/Skill:<id> deep link redirects cleanly.
      router.go('/SkillTree/Skills/Skill:rider.husbandry.pick_hooves');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillDetailV2_rider.husbandry.grooming')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Self-assessment persists Leading, Seat Balance, and Horse Longeing',
    (tester) async {
      final mockAppCubit = _MockAppCubit();
      final horse = HorseProfile(
        id: 'horse-star-1',
        name: 'Star',
        currentOwnerId: 'alex@example.com',
        currentOwnerName: 'Alex Rider',
      );
      when(() => mockAppCubit.state).thenReturn(
        authenticatedRiderState(horseProfile: horse).copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex Rider',
            email: 'alex@example.com',
            isGuest: false,
            emailVerified: true,
          ),
        ),
      );

      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: BlocProvider<AppCubit>.value(
            value: mockAppCubit,
            child: MaterialApp(
              home: SkillTreeV2View(
                repository: repository,
                initialSkillId: 'rider.in_hand.leading',
                initialLevel: DifficultyState.Intermediate,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .byKey(const Key('skillDetailV2_rider.in_hand.leading'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      // Mark Leading Intermediate Proficient.
      await tester.ensureVisible(
        find.byKey(
          const Key('assessProficient_rider.in_hand.leading_Intermediate'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('assessProficient_rider.in_hand.leading_Intermediate'),
        ),
      );
      await tester.pumpAndSettle();

      final riderProgress = await store.fetchProgress(
        subject: SkillSubject.rider,
        profileDocId: 'alex@example.com',
      );
      expect(
        riderProgress['rider.in_hand.leading']
            ?.levels[DifficultyState.Intermediate]
            ?.state,
        LevelState.PROFICIENT,
      );

      // Mark Wave 3 skill (Seat Balance) Introductory Learning.
      await store.setLevelProgress(
        subject: SkillSubject.rider,
        profileDocId: 'alex@example.com',
        skillId: 'rider.mounted.seat_balance',
        level: DifficultyState.Introductory,
        state: LevelState.LEARNING,
        actorUid: 'uid-alex',
        actorName: 'Alex Rider',
      );
      await store.setLevelProgress(
        subject: SkillSubject.horse,
        profileDocId: 'horse-star-1',
        skillId: 'horse.in_hand.longeing',
        level: DifficultyState.Introductory,
        state: LevelState.LEARNING,
        actorUid: 'uid-alex',
        actorName: 'Alex Rider',
      );
      expect(
        (await store.fetchProgress(
          subject: SkillSubject.rider,
          profileDocId: 'alex@example.com',
        ))['rider.mounted.seat_balance']
            ?.levels[DifficultyState.Introductory]
            ?.state,
        LevelState.LEARNING,
      );
      expect(
        (await store.fetchProgress(
          subject: SkillSubject.horse,
          profileDocId: 'horse-star-1',
        ))['horse.in_hand.longeing']
            ?.levels[DifficultyState.Introductory]
            ?.state,
        LevelState.LEARNING,
      );
    },
  );

  testWidgets(
    'SkillTreeV2View shows actionable permission error when saving assessment '
    'fails',
    (tester) async {
      // Verify actionable error mapping on RepositoryException.
      final failingStore = _ErroringV2Store(store);
      final failingRepo = SkillTreeV2Repository(store: failingStore);
      final mockFailAppCubit = _MockAppCubit();
      when(() => mockFailAppCubit.state).thenReturn(
        authenticatedRiderState().copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex Rider',
            email: 'alex@example.com',
            isGuest: false,
            emailVerified: true,
          ),
        ),
      );
      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: BlocProvider<AppCubit>.value(
            value: mockFailAppCubit,
            child: MaterialApp(
              home: SkillTreeV2View(
                key: const ValueKey('failing-v2-view'),
                repository: failingRepo,
                initialSkillId: 'rider.in_hand.leading',
                initialLevel: DifficultyState.Intermediate,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .byKey(const Key('skillDetailV2_rider.in_hand.leading'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      await tester.ensureVisible(
        find.byKey(
          const Key('assessLearning_rider.in_hand.leading_Intermediate'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('assessLearning_rider.in_hand.leading_Intermediate'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Please verify your email or sign in again.'),
        findsOneWidget,
      );

      // Verify remaining RepositoryFailureKind branches via SkillTreeV2Cubit.
      final cubit = SkillTreeV2Cubit(repository: failingRepo);
      addTearDown(cubit.close);
      failingStore.nextErrorKind = RepositoryFailureKind.unavailable;
      expect(
        await cubit.setSelfAssessment(
          skillId: 'rider.in_hand.leading',
          level: DifficultyState.Intermediate,
          levelState: LevelState.LEARNING,
          profileDocId: 'alex@example.com',
          actorUid: 'uid-alex',
        ),
        isFalse,
      );
      expect(
        cubit.state.actionMessage,
        contains('network is unavailable'),
      );

      failingStore.nextErrorKind = RepositoryFailureKind.unexpected;
      expect(
        await cubit.setSelfAssessment(
          skillId: 'rider.in_hand.leading',
          level: DifficultyState.Intermediate,
          levelState: LevelState.LEARNING,
          profileDocId: 'alex@example.com',
          actorUid: 'uid-alex',
        ),
        isFalse,
      );
      expect(
        cubit.state.actionMessage,
        'Could not save assessment. Please try again.',
      );
    },
  );
}

class _ErroringV2Store implements SkillTreeV2Store {
  _ErroringV2Store(this._delegate);
  final InMemorySkillTreeV2Store _delegate;
  RepositoryFailureKind nextErrorKind = RepositoryFailureKind.permissionDenied;

  @override
  Future<List<SkillFamily>> fetchFamilies() => _delegate.fetchFamilies();

  @override
  Future<List<CurriculumSkill>> fetchSkills() => _delegate.fetchSkills();

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) => _delegate.fetchProgress(subject: subject, profileDocId: profileDocId);

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) => _delegate.fetchVerifications(
    subject: subject,
    profileDocId: profileDocId,
  );

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) => _delegate.fetchVerificationEvents(
    subject: subject,
    profileDocId: profileDocId,
  );

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) async {
    throw RepositoryException(
      kind: nextErrorKind,
      message: 'Simulated failure ($nextErrorKind).',
      code: nextErrorKind.name,
    );
  }
}
