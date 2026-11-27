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
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/ability_summary_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_icon.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

/// Wraps a SkillTreeV2Store so tests verify browsing, expanding families, and
/// switching Explore / My Skills trigger zero extra backend reads.
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
  List<Resource> resources = const [],
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
    resources: resources,
  );
}

Future<InMemorySkillTreeV2Store> _createSeededProgressStore({
  required List<SkillFamily> families,
  required List<CurriculumSkill> skills,
}) async {
  const profileId = 'alex@example.com';
  final inner = InMemorySkillTreeV2Store(
    families: families,
    skills: skills,
    initialVerifications: {
      'rider:$profileId': {
        'rider.husbandry.grooming': SkillVerificationRecord(
          skillId: 'rider.husbandry.grooming',
          levels: {
            DifficultyState.Introductory: LevelVerification(
              verifiedByUid: 'coach-sam',
              verifiedByName: 'Coach Sam',
              verifiedAt: DateTime(2026, 11, 21),
            ),
          },
        ),
      },
    },
  );
  await inner.setLevelProgress(
    subject: SkillSubject.rider,
    profileDocId: profileId,
    skillId: 'rider.husbandry.grooming',
    level: DifficultyState.Introductory,
    state: LevelState.PROFICIENT,
    actorUid: 'uid-alex',
  );
  await inner.setLevelProgress(
    subject: SkillSubject.rider,
    profileDocId: profileId,
    skillId: 'rider.husbandry.grooming',
    level: DifficultyState.Intermediate,
    state: LevelState.LEARNING,
    actorUid: 'uid-alex',
  );
  await inner.setLevelProgress(
    subject: SkillSubject.rider,
    profileDocId: profileId,
    skillId: 'rider.husbandry.safe_handling',
    level: DifficultyState.Introductory,
    state: LevelState.LEARNING,
    actorUid: 'uid-alex',
  );
  return inner;
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
}) {
  final dark = themeOverride ?? mainThemeDark;
  return SettingsControllerScope(
    controller: settings,
    child: BlocProvider<AppCubit>.value(
      value: appCubit,
      child: MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: dark,
        darkTheme: dark,
        themeMode: dark.brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        builder: disableAnimations
            ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
            : null,
        home: SkillTreeV2View(repository: repo),
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

  group('Phase 3 Skill Tree 2.0 Visual Redesign', () {
    test('maps all 32 curriculum families to 26 unique clean SVG assets', () {
      final jsonText = File('curriculum/v2/families.json').readAsStringSync();
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      expect(decoded.length, 32);

      final familyIds = [
        for (final entry in decoded)
          (entry as Map<String, dynamic>)['id'] as String,
      ];

      for (final familyId in familyIds) {
        expect(
          SkillFamilyIconAssets.assetForFamily(familyId),
          isNotNull,
          reason: 'Missing SVG asset mapping for $familyId',
        );
      }

      final uniqueAssets = {
        for (final id in familyIds) SkillFamilyIconAssets.assetForFamily(id)!,
      };
      expect(uniqueAssets.length, 26);

      // Verify the 6 shared Mounted families share artwork across subjects.
      for (final sharedSuffix in const [
        'mounted.gaits_rhythm_transitions',
        'mounted.steering_bend_direction',
        'mounted.pivots_body_control',
        'mounted.lateral_movements',
        'mounted.terrain_obstacles',
        'mounted.object_handling',
      ]) {
        expect(
          SkillFamilyIconAssets.assetForFamily('rider.$sharedSuffix'),
          equals(SkillFamilyIconAssets.assetForFamily('horse.$sharedSuffix')),
        );
      }

      // Verify SVG quality & size budget on disk (< 25 KB, pure vector #000).
      for (final assetPath in uniqueAssets) {
        final file = File(assetPath);
        expect(file.existsSync(), isTrue, reason: '$assetPath missing');
        expect(file.lengthSync(), lessThan(25 * 1024));
        final content = file.readAsStringSync();
        expect(content, contains('viewBox="0 0 256 256"'));
        expect(content, contains('fill="#000000"'));
        expect(content, isNot(contains('<image')));
        expect(content, isNot(contains('fill="#ffffff"')));
      }
    });

    testWidgets(
      'SkillFamilyIcon dynamically tints dark/light/selected/disabled and '
      'falls back cleanly for unknown families',
      (tester) async {
        for (final theme in [mainThemeDark, mainThemeLight]) {
          for (final iconState in SkillFamilyIconState.values) {
            late Color expectedColor;
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: Builder(
                    builder: (context) {
                      expectedColor = SkillFamilyIcon.resolveColor(
                        context,
                        state: iconState,
                      );
                      return SkillFamilyIconBadge(
                        familyId: 'rider.husbandry.safety_handling',
                        fallbackRealm: SkillCategory.Husbandry,
                        state: iconState,
                        semanticLabel: 'Safety icon',
                      );
                    },
                  ),
                ),
              ),
            );
            await tester.pump();
            final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
            expect(
              svg.colorFilter,
              ColorFilter.mode(expectedColor, BlendMode.srcIn),
            );
          }
        }

        // Fallback realm glyph when an unlisted custom family is rendered.
        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: const Scaffold(
              body: SkillFamilyIcon(
                familyId: 'custom.experimental.family',
                fallbackRealm: SkillCategory.Mounted,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(SvgPicture), findsNothing);
        expect(find.byType(Icon), findsOneWidget);
      },
    );

    testWidgets(
      'Explore Skills omits progress bars/collapsed descriptions and keeps '
      'compact skill rows while My Skills displays icons and progress',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final inner = await _createSeededProgressStore(
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

        final readsAfterLoad =
            counting.curriculumReads +
            counting.progressReads +
            counting.verificationReads;

        // Explore Skills must not show personal progress bars.
        expect(find.byType(SkillFamilyListV2), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('4 skills'), findsOneWidget);
        expect(find.text('2 skills'), findsWidgets);
        expect(find.text('1 skill'), findsWidgets);
        expect(
          find.textContaining('Routine grooming, hooves, coats'),
          findsNothing,
        );

        // Expand Daily Care & Grooming: description & compact rows appear,
        // without 2-line skill summaries inside rows.
        await tester.tap(
          find.byKey(
            const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
          ),
        );
        await tester.pumpAndSettle();

        final groomingSummary = allSkills
            .firstWhere((s) => s.id == 'rider.husbandry.grooming')
            .summary;
        expect(
          find.byKey(const Key('skillCard_rider.husbandry.grooming')),
          findsOneWidget,
        );
        expect(find.text('Intro'), findsWidgets);
        // Full summary stays in SkillDetailV2Panel, not in the compact row.
        expect(
          find.textContaining(groomingSummary, findRichText: true),
          findsNothing,
        );

        // Selecting a skill opens full detail content.
        await tester.tap(
          find.byKey(const Key('skillCard_rider.husbandry.grooming')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SkillDetailV2Panel), findsOneWidget);
        expect(
          find.textContaining(groomingSummary, findRichText: true),
          findsOneWidget,
        );

        // Return to list and switch to My Skills: progress bars & family icons.
        await tester.tap(find.byKey(const Key('skillDetailV2BackButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('My Skills'));
        await tester.pumpAndSettle();

        expect(find.byType(AbilitySummaryV2View), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsWidgets);
        expect(find.byType(SkillFamilyIconBadge), findsWidgets);
        expect(find.textContaining('proficient'), findsWidgets);
        expect(find.textContaining('verified'), findsWidgets);

        // Zero additional backend reads during UI navigation/toggles.
        final readsAfterNav =
            counting.curriculumReads +
            counting.progressReads +
            counting.verificationReads;
        expect(readsAfterNav, readsAfterLoad);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders 1-column mobile (320px), 2-column tablet grid with row drawer '
      '(768px), 1-column tablet search, desktop master-detail (1280px), and '
      'supports reduced motion & accessible touch targets',
      (tester) async {
        final inner = await _createSeededProgressStore(
          families: allFamilies,
          skills: allSkills,
        );
        final repo = SkillTreeV2Repository(store: inner);
        final mockAppCubit = _MockAppCubit();
        when(() => mockAppCubit.state).thenReturn(_buildTestAppState());

        // 1) Narrow Mobile 320x700 + reduced motion + semantics
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        final firstMobileRect = tester.getRect(
          find.byKey(const Key('skillFamily_rider.husbandry.safety_handling')),
        );
        final secondMobileRect = tester.getRect(
          find.byKey(
            const Key('skillFamily_rider.husbandry.daily_care_grooming'),
          ),
        );
        expect(firstMobileRect.height, greaterThanOrEqualTo(48));
        expect(
          secondMobileRect.top,
          greaterThanOrEqualTo(firstMobileRect.bottom),
        );
        expect(tester.takeException(), isNull);

        // 2) Tablet 768x1024 -> 2-column grid + full-width drawer below row 0
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

        final col1Rect = tester.getRect(
          find.byKey(const Key('skillFamily_rider.husbandry.safety_handling')),
        );
        final col2Rect = tester.getRect(
          find.byKey(
            const Key('skillFamily_rider.husbandry.daily_care_grooming'),
          ),
        );
        expect(col1Rect.top, equals(col2Rect.top));
        expect(col1Rect.left, lessThan(col2Rect.left));

        await tester.tap(
          find.byKey(
            const Key('skillFamilyHeader_rider.husbandry.safety_handling'),
          ),
        );
        await tester.pumpAndSettle();
        final skillRect = tester.getRect(
          find.byKey(const Key('skillCard_rider.husbandry.safe_handling')),
        );
        expect(skillRect.top, greaterThan(col1Rect.bottom));
        expect(skillRect.width, greaterThan(col1Rect.width));
        expect(tester.takeException(), isNull);

        // Search on tablet collapses to 1-column results cleanly.
        await tester.enterText(
          find.byKey(const Key('skillTreeV2SearchField')),
          'grooming',
        );
        await tester.pumpAndSettle();
        final searchedSkill = find.byKey(
          const Key('skillCard_rider.husbandry.grooming'),
        );
        expect(searchedSkill, findsOneWidget);
        expect(tester.takeException(), isNull);

        // 3) Desktop 1280x860 -> master-detail split
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.view.physicalSize = const Size(1280, 860);
        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeDark),
          ),
        );
        await tester.pumpAndSettle();

        final listRect = tester.getRect(find.byType(SkillFamilyListV2));
        final detailRect = tester.getRect(find.byType(SkillDetailV2Panel));
        expect(listRect.left, lessThan(detailRect.left));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('captures final visual redesign screenshots when '
        'CAPTURE_FINAL_SCREENSHOTS=1', (tester) async {
      if (Platform.environment['CAPTURE_FINAL_SCREENSHOTS'] != '1') return;

      final theme = _withScreenshotFonts(mainThemeDark);
      final inner = await _createSeededProgressStore(
        families: allFamilies,
        skills: allSkills,
      );
      final repo = SkillTreeV2Repository(store: inner);
      final mockAppCubit = _MockAppCubit();
      when(() => mockAppCubit.state).thenReturn(_buildTestAppState());

      const scratch =
          '/home/matteo/.gemini/antigravity/brain/'
          '9959963d-cf2a-4c61-946a-61af8edc96d7/scratch';

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      // 1) Desktop 1280x860 Master-Detail
      final desktopKey = GlobalKey();
      tester.view.physicalSize = const Size(1280, 860);
      await tester.pumpWidget(
        RepaintBoundary(
          key: desktopKey,
          child: _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: theme,
          ),
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
      await _captureBoundaryPng(
        tester,
        desktopKey,
        '$scratch/final_desktop_master_detail.png',
      );

      // 2) Tablet 768x1024 2-column grid with expanded row drawer
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final tabletKey = GlobalKey();
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        RepaintBoundary(
          key: tabletKey,
          child: _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: theme,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.safety_handling'),
        ),
      );
      await tester.pumpAndSettle();
      await _captureBoundaryPng(
        tester,
        tabletKey,
        '$scratch/final_tablet_grid.png',
      );

      // 3) Mobile 390x844 Explore Skills (expanded)
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final mobileExploreKey = GlobalKey();
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        RepaintBoundary(
          key: mobileExploreKey,
          child: _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: theme,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
        ),
      );
      await tester.pumpAndSettle();
      await _captureBoundaryPng(
        tester,
        mobileExploreKey,
        '$scratch/final_mobile_explore.png',
      );

      // 4) Mobile 390x844 My Skills (icons + progress bars + verification)
      await tester.tap(find.text('My Skills'));
      await tester.pumpAndSettle();
      await _captureBoundaryPng(
        tester,
        mobileExploreKey,
        '$scratch/final_mobile_my_skills.png',
      );
    });

    testWidgets(
      'displays family SVG icon badge in mobile skill detail header in Dark '
      'and Light modes (Rider & Horse) and omits duplicate badge on desktop',
      (tester) async {
        final inner = await _createSeededProgressStore(
          families: allFamilies,
          skills: allSkills,
        );
        final counting = _CountingStore(inner);
        final repo = SkillTreeV2Repository(store: counting);
        final mockAppCubit = _MockAppCubit();
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;

        for (final entry in [
          (theme: mainThemeDark, size: const Size(390, 844)),
          (theme: mainThemeLight, size: const Size(320, 700)),
        ]) {
          tester.view.physicalSize = entry.size;
          when(() => mockAppCubit.state).thenReturn(_buildTestAppState());

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.pumpWidget(
            _wrapTree(
              appCubit: mockAppCubit,
              repo: repo,
              settings: settings,
              themeOverride: _withScreenshotFonts(entry.theme),
            ),
          );
          await tester.pumpAndSettle();

          final readsBeforeOpen =
              counting.curriculumReads +
              counting.progressReads +
              counting.verificationReads;

          final familyHeader = find.byKey(
            const Key('skillFamilyHeader_rider.husbandry.daily_care_grooming'),
          );
          await tester.ensureVisible(familyHeader);
          await tester.pumpAndSettle();
          await tester.tap(familyHeader);
          await tester.pumpAndSettle();
          final groomingCard = find.byKey(
            const Key('skillCard_rider.husbandry.grooming'),
          );
          await tester.ensureVisible(groomingCard);
          await tester.pumpAndSettle();
          await tester.tap(groomingCard);
          await tester.pumpAndSettle();

          final iconFinder = find.byKey(
            const Key(
              'skillDetailV2FamilyIcon_rider.husbandry.daily_care_grooming',
            ),
          );
          expect(iconFinder, findsOneWidget);
          final badge = tester.widget<SkillFamilyIconBadge>(iconFinder);
          expect(badge.badgeSize, inInclusiveRange(32, 40));

          final svg = tester.widget<SvgPicture>(
            find.descendant(of: iconFinder, matching: find.byType(SvgPicture)),
          );
          final titleFinder = find.descendant(
            of: find.byType(SkillDetailV2Panel),
            matching: find.text('Grooming'),
          );
          final iconRect = tester.getRect(iconFinder);
          final titleRect = tester.getRect(titleFinder);
          expect(iconRect.bottom, lessThanOrEqualTo(titleRect.top));

          expect(
            svg.colorFilter,
            ColorFilter.mode(
              SkillFamilyIcon.resolveColor(
                tester.element(iconFinder),
                state: SkillFamilyIconState.selected,
              ),
              BlendMode.srcIn,
            ),
          );

          final readsAfterOpen =
              counting.curriculumReads +
              counting.progressReads +
              counting.verificationReads;
          expect(readsAfterOpen, readsBeforeOpen);
          expect(tester.takeException(), isNull);
        }

        // Horse context on mobile -> displays Horse family SVG badge.
        final horseSkill = allSkills.firstWhere(
          (s) =>
              s.subject == SkillSubject.horse &&
              s.realm == SkillCategory.In_Hand,
        );
        final horseState = _buildTestAppState(
          isForRider: false,
          horseProfile: HorseProfile(id: 'horse-comet', name: 'Comet'),
        );
        when(() => mockAppCubit.state).thenReturn(horseState);
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          _wrapTree(
            appCubit: mockAppCubit,
            repo: repo,
            settings: settings,
            themeOverride: _withScreenshotFonts(mainThemeDark),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(Key('skillFamilyHeader_${horseSkill.familyId}')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('skillCard_${horseSkill.id}')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(Key('skillDetailV2FamilyIcon_${horseSkill.familyId}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Desktop master-detail omits the duplicate detail header badge.
        when(() => mockAppCubit.state).thenReturn(_buildTestAppState());
        tester.view.physicalSize = const Size(1280, 860);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
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
          find.descendant(
            of: find.byType(SkillDetailV2Panel),
            matching: find.byType(SkillFamilyIconBadge),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
