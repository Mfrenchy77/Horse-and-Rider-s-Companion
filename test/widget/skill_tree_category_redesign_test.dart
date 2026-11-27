import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/featured_category_navigation.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_category_illustration.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

class _CountingStore implements SkillTreeV2Store {
  _CountingStore(this._inner);

  final SkillTreeV2Store _inner;

  int curriculumReads = 0;
  int progressReads = 0;
  int verificationReads = 0;

  @override
  Future<List<SkillFamily>> fetchFamilies() {
    curriculumReads++;
    return _inner.fetchFamilies();
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() {
    curriculumReads++;
    return _inner.fetchSkills();
  }

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) {
    progressReads++;
    return _inner.fetchProgress(subject: subject, profileDocId: profileDocId);
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) {
    verificationReads++;
    return _inner.fetchVerifications(
      subject: subject,
      profileDocId: profileDocId,
    );
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) => _inner.fetchVerificationEvents(
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
  }) => _inner.setLevelProgress(
    subject: subject,
    profileDocId: profileDocId,
    skillId: skillId,
    level: level,
    state: state,
    actorUid: actorUid,
    actorName: actorName,
  );
}

AppState _buildTestAppState({
  bool isForRider = true,
  HorseProfile? horseProfile,
}) {
  final rider = RiderProfile(
    id: 'uid-alex',
    email: 'alex@example.com',
    name: 'Alex Rider',
    homeUrl: '',
    picUrl: '',
  );
  return const AppState.authenticated(
    User(id: 'uid-alex', name: 'Alex Rider', email: 'alex@example.com'),
  ).copyWith(
    isGuest: false,
    isForRider: isForRider,
    usersProfile: rider,
    horseProfile: horseProfile,
    hasResourceCatalogue: true,
    resources: const [],
  );
}

ThemeData _withScreenshotFonts(ThemeData base) {
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: (base.chipTheme.labelStyle ?? const TextStyle()).copyWith(
        fontFamily: 'Roboto',
      ),
    ),
  );
}

Future<void> _loadScreenshotFonts() async {
  Future<void> register(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var loadedAny = false;
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
        loadedAny = true;
      }
    }
    if (loadedAny) await loader.load();
  }

  await register('Roboto', [
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf',
  ]);
  await register('Georgia', [
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif.ttf',
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif-Bold.ttf',
  ]);
  await register('MaterialIcons', [
    'build/web/assets/fonts/MaterialIcons-Regular.otf',
  ]);
  await register('HorseAndRiderIcons', ['fonts/HorseAndRiderIcons.ttf']);
}

Widget _wrapTree({
  required AppCubit appCubit,
  required SkillTreeV2Repository repo,
  required SettingsController settings,
  ThemeData? themeOverride,
  bool disableAnimations = false,
  String? initialSkillId,
}) {
  final theme = themeOverride ?? mainThemeDark;
  return SettingsControllerScope(
    controller: settings,
    child: BlocProvider<AppCubit>.value(
      value: appCubit,
      child: MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: theme.brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        builder: disableAnimations
            ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
            : null,
        home: SkillTreeV2View(repository: repo, initialSkillId: initialSkillId),
      ),
    ),
  );
}

Future<void> _captureBoundaryPng(
  WidgetTester tester,
  GlobalKey key,
  String outputPath, {
  double pixelRatio = 1.5,
}) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData != null) {
      final file = File(outputPath);
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsController settings;
  late List<SkillFamily> allFamilies;
  late List<CurriculumSkill> allSkills;

  setUpAll(() async {
    settings = SettingsController(SettingsService());
    await settings.loadSettings();
    await _loadScreenshotFonts();
    await DictionaryRepository.cachedEntries();
    final baseStore = await const AssetCurriculumV2Loader().loadInMemoryStore();
    allFamilies = await baseStore.fetchFamilies();
    allSkills = await baseStore.fetchSkills();
  });

  group('Animated Skill Tree Category Redesign', () {
    test('bundles all 8 optimized monochrome category SVGs cleanly', () {
      expect(SkillCategoryIllustrationAssets.allAssets.length, 8);
      for (final assetPath in SkillCategoryIllustrationAssets.allAssets) {
        final file = File(assetPath);
        expect(file.existsSync(), isTrue, reason: 'Missing $assetPath');
        expect(file.lengthSync(), lessThan(30 * 1024));
        final svg = file.readAsStringSync();
        expect(svg, contains('viewBox="0 0 384 224"'));
        expect(svg, contains('fill="#000000"'));
        expect(svg, isNot(contains('<image')));
        expect(svg, isNot(contains('fill="#ffffff"')));
      }

      // Real curriculum category counts stay untouched.
      final familiesJson =
          jsonDecode(File('curriculum/v2/families.json').readAsStringSync())
              as List<dynamic>;
      expect(familiesJson.length, 32);

      // Active category mappings for Rider (4) and Horse (2).
      expect(
        SkillCategoryIllustrationAssets.assetFor(
          subject: SkillSubject.rider,
          realm: SkillCategory.Husbandry,
        ),
        SkillCategoryIllustrationAssets.riderHusbandry,
      );
      expect(
        SkillCategoryIllustrationAssets.assetFor(
          subject: SkillSubject.rider,
          realm: SkillCategory.In_Hand,
        ),
        SkillCategoryIllustrationAssets.riderInHand,
      );
      expect(
        SkillCategoryIllustrationAssets.assetFor(
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
        ),
        SkillCategoryIllustrationAssets.riderMounted,
      );
      expect(
        SkillCategoryIllustrationAssets.assetFor(
          subject: SkillSubject.rider,
          realm: SkillCategory.Other,
        ),
        SkillCategoryIllustrationAssets.riderTheoryKnowledge,
      );
      expect(
        SkillCategoryIllustrationAssets.assetFor(
          subject: SkillSubject.horse,
          realm: SkillCategory.In_Hand,
        ),
        SkillCategoryIllustrationAssets.horseInHand,
      );
      expect(
        SkillCategoryIllustrationAssets.assetFor(
          subject: SkillSubject.horse,
          realm: SkillCategory.Mounted,
        ),
        SkillCategoryIllustrationAssets.horseMounted,
      );
    });

    testWidgets(
      'promotes categories smoothly on tap, supports rapid taps, preserves '
      'canonical ordering, and incurs zero extra backend reads',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final inner = InMemorySkillTreeV2Store(
          families: allFamilies,
          skills: allSkills,
        );
        final counting = _CountingStore(inner);
        final repo = SkillTreeV2Repository(store: counting);
        final mockAppCubit = _MockAppCubit();
        when(() => mockAppCubit.state).thenReturn(_buildTestAppState());

        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeDark),
          ),
        );
        await tester.pumpAndSettle();

        final readsAfterInit =
            counting.curriculumReads +
            counting.progressReads +
            counting.verificationReads;

        expect(find.byType(FeaturedCategoryNavigation), findsOneWidget);
        expect(find.byType(SvgPicture), findsWidgets);

        // Initial featured category on Rider is Husbandry.
        final initialFeaturedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Husbandry')),
        );
        final initialInHandRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_In_Hand')),
        );
        final initialMountedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        final initialOtherRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Other')),
        );

        expect(initialFeaturedRect.top, lessThan(initialMountedRect.top));
        expect(
          initialFeaturedRect.width,
          greaterThan(initialMountedRect.width),
        );
        expect(initialInHandRect.left, lessThan(initialMountedRect.left));
        expect(initialMountedRect.left, lessThan(initialOtherRect.left));
        expect(find.text('Husbandry Skill Families'), findsOneWidget);

        // Tap Mounted -> inspect intermediate animation frame & settled result.
        await tester.tap(find.byKey(const Key('skillTreeV2Realm_Mounted')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));

        final midMountedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        expect(midMountedRect.top, lessThan(initialMountedRect.top));
        expect(midMountedRect.top, greaterThan(initialFeaturedRect.top));

        await tester.pumpAndSettle();

        final promotedMountedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        final demotedHusbandryRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Husbandry')),
        );
        final shiftedInHandRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_In_Hand')),
        );
        final shiftedOtherRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Other')),
        );

        expect(promotedMountedRect.top, equals(initialFeaturedRect.top));
        expect(promotedMountedRect.width, equals(initialFeaturedRect.width));
        expect(
          demotedHusbandryRect.top,
          greaterThan(promotedMountedRect.bottom),
        );
        expect(demotedHusbandryRect.left, lessThan(shiftedInHandRect.left));
        expect(shiftedInHandRect.left, lessThan(shiftedOtherRect.left));
        expect(find.text('Mounted Skill Families'), findsOneWidget);
        expect(
          find.byKey(
            const Key('skillFamily_rider.mounted.position_balance_safety'),
          ),
          findsOneWidget,
        );

        // Rapid repeated taps settle accurately on the last tapped realm.
        await tester.tap(find.byKey(const Key('skillTreeV2Realm_In_Hand')));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.byKey(const Key('skillTreeV2Realm_Other')));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpAndSettle();

        final finalOtherRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Other')),
        );
        expect(finalOtherRect.top, equals(initialFeaturedRect.top));
        expect(find.text('Theory & Knowledge Skill Families'), findsOneWidget);

        // Zero additional backend reads during category navigation.
        final readsAfterNav =
            counting.curriculumReads +
            counting.progressReads +
            counting.verificationReads;
        expect(readsAfterNav, readsAfterInit);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'displays actual 2-category navigation for Horse Skills without '
      'fabricating categories',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = SkillTreeV2Repository(
          store: InMemorySkillTreeV2Store(
            families: allFamilies,
            skills: allSkills,
          ),
        );
        final mockAppCubit = _MockAppCubit();
        when(() => mockAppCubit.state).thenReturn(
          _buildTestAppState(
            isForRider: false,
            horseProfile: HorseProfile(id: 'horse-comet', name: 'Comet'),
          ),
        );

        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeDark),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('skillTreeV2Realm_In_Hand')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('skillTreeV2Realm_Husbandry')),
          findsNothing,
        );
        expect(find.byKey(const Key('skillTreeV2Realm_Other')), findsNothing);

        final initialInHandRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_In_Hand')),
        );
        final initialMountedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        expect(initialInHandRect.top, lessThan(initialMountedRect.top));
        expect(initialMountedRect.height, greaterThanOrEqualTo(48));

        await tester.tap(find.byKey(const Key('skillTreeV2Realm_Mounted')));
        await tester.pumpAndSettle();

        final nextMountedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        final nextInHandRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_In_Hand')),
        );
        expect(nextMountedRect.top, lessThan(nextInHandRect.top));
        expect(find.text('Mounted Skill Families'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'preserves selected category across Explore/My Skills, handles search, '
      'deep links, reduced motion, and Light/Dark responsive breakpoints',
      (tester) async {
        final repo = SkillTreeV2Repository(
          store: InMemorySkillTreeV2Store(
            families: allFamilies,
            skills: allSkills,
          ),
        );
        final mockAppCubit = _MockAppCubit();
        when(() => mockAppCubit.state).thenReturn(_buildTestAppState());

        // 1) Deep link directly into a Mounted skill promotes Mounted banner.
        final mountedSkill = allSkills.firstWhere(
          (s) =>
              s.subject == SkillSubject.rider &&
              s.realm == SkillCategory.Mounted,
        );
        tester.view.physicalSize = const Size(1280, 860);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeLight),
            initialSkillId: mountedSkill.id,
          ),
        );
        await tester.pumpAndSettle();

        final mountedDesktopRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        final husbandryDesktopRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Husbandry')),
        );
        expect(
          mountedDesktopRect.width,
          greaterThan(husbandryDesktopRect.width),
        );
        expect(mountedDesktopRect.left, lessThan(husbandryDesktopRect.left));
        expect(find.byType(SkillDetailV2Panel), findsOneWidget);

        // Preserve category when toggling Explore Skills <-> My Skills.
        await tester.tap(find.text('My Skills'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('skillTreeV2ViewModeSelector')),
            matching: find.text('Explore Skills'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mounted Skill Families'), findsOneWidget);

        // Search -> tapping a category clears search and switches category.
        await tester.enterText(
          find.byKey(const Key('skillTreeV2SearchField')),
          'grooming',
        );
        await tester.pumpAndSettle();
        expect(find.text('Search Results'), findsOneWidget);

        await tester.tap(find.byKey(const Key('skillTreeV2Realm_In_Hand')));
        await tester.pumpAndSettle();
        expect(find.text('In-Hand Skill Families'), findsOneWidget);
        expect(find.text('Search Results'), findsNothing);

        // 2) Narrow Mobile 320x700 + Reduced Motion + Light Theme.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.view.physicalSize = const Size(320, 700);
        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeLight),
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('skillTreeV2Realm_Mounted')));
        await tester.pump();
        final immediateMountedRect = tester.getRect(
          find.byKey(const Key('skillTreeV2Realm_Mounted')),
        );
        expect(
          immediateMountedRect.top,
          equals(tester.getRect(find.byType(FeaturedCategoryNavigation)).top),
        );

        // 3) Tablet 768x1024 + Dark Theme.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.view.physicalSize = const Size(768, 1024);
        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeDark),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SkillFamilyListV2), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('captures Skill Tree category screenshots when '
        'CAPTURE_CATEGORY_SCREENSHOTS=1', (tester) async {
      if (Platform.environment['CAPTURE_CATEGORY_SCREENSHOTS'] != '1') return;

      const outDir =
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7';
      final repo = SkillTreeV2Repository(
        store: InMemorySkillTreeV2Store(
          families: allFamilies,
          skills: allSkills,
        ),
      );
      final mockAppCubit = _MockAppCubit();
      final mountedSkill = allSkills.firstWhere(
        (s) =>
            s.subject == SkillSubject.rider && s.realm == SkillCategory.Mounted,
      );

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      Future<void> renderAndSnap({
        required Size size,
        required ThemeData theme,
        required AppState appState,
        required String fileName,
        bool tapMounted = true,
      }) async {
        when(() => mockAppCubit.state).thenReturn(appState);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final key = GlobalKey();
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _wrapTree(
              appCubit: mockAppCubit,
              repo: repo,
              settings: settings,
              themeOverride: _withScreenshotFonts(theme),
              initialSkillId: appState.isForRider && size.width >= 900
                  ? mountedSkill.id
                  : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (tapMounted) {
          await tester.tap(find.byKey(const Key('skillTreeV2Realm_Mounted')));
          await tester.pumpAndSettle();
        }
        await _captureBoundaryPng(tester, key, '$outDir/$fileName');
      }

      final riderState = _buildTestAppState();
      final horseState = _buildTestAppState(
        isForRider: false,
        horseProfile: HorseProfile(id: 'horse-comet', name: 'Comet'),
      );

      await renderAndSnap(
        size: const Size(390, 844),
        theme: mainThemeDark,
        appState: riderState,
        fileName: 'skill_tree_cat_mobile_dark_rider.png',
      );
      await renderAndSnap(
        size: const Size(390, 844),
        theme: mainThemeDark,
        appState: horseState,
        fileName: 'skill_tree_cat_mobile_dark_horse.png',
      );
      await renderAndSnap(
        size: const Size(390, 844),
        theme: mainThemeLight,
        appState: riderState,
        fileName: 'skill_tree_cat_mobile_light_rider.png',
      );
      await renderAndSnap(
        size: const Size(768, 1024),
        theme: mainThemeDark,
        appState: riderState,
        fileName: 'skill_tree_cat_tablet_dark_rider.png',
      );
      await renderAndSnap(
        size: const Size(1280, 860),
        theme: mainThemeDark,
        appState: riderState,
        fileName: 'skill_tree_cat_desktop_dark_rider.png',
        tapMounted: false,
      );
      await renderAndSnap(
        size: const Size(1280, 860),
        theme: mainThemeLight,
        appState: riderState,
        fileName: 'skill_tree_cat_desktop_light_rider.png',
        tapMounted: false,
      );
    });
  });
}
