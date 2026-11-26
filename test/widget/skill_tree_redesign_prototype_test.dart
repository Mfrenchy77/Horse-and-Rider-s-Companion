// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';
import 'dart:ui' as ui;

import 'package:authentication_repository/authentication_repository.dart';
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
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_card_prototype.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_icon.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

const String _artifactDir =
    '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7';

bool get _captureScreenshots =>
    Platform.environment['CAPTURE_PROTOTYPE_SCREENSHOTS'] == '1';

Future<void> _loadRealFontsIfAvailable() async {
  Future<void> loadFamily(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var loaded = false;
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        loaded = true;
      }
    }
    if (loaded) await loader.load();
  }

  await loadFamily('Roboto', [
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf',
  ]);
  await loadFamily('Georgia', [
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif.ttf',
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif-Bold.ttf',
  ]);
  await loadFamily('MaterialIcons', [
    'build/web/assets/fonts/MaterialIcons-Regular.otf',
  ]);
  await loadFamily('HorseAndRiderIcons', ['fonts/HorseAndRiderIcons.ttf']);
}

Future<void> _captureBoundary(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String fileName, {
  double pixelRatio = 1.5,
}) async {
  if (!_captureScreenshots) return;
  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data != null) {
      await File(
        '$_artifactDir/$fileName',
      ).writeAsBytes(data.buffer.asUint8List());
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store store;
  late List<SkillFamily> allFamilies;
  late List<CurriculumSkill> allSkills;
  late List<SkillFamily> sampleFamilies;
  late AppTestHarness harness;

  const sampleFamilyIds = [
    'rider.husbandry.safety_handling',
    'rider.husbandry.daily_care_grooming',
    'rider.mounted.gaits_rhythm_transitions',
  ];

  setUpAll(() async {
    await _loadRealFontsIfAvailable();
    await DictionaryRepository.cachedEntries();
    store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    allFamilies = await store.fetchFamilies();
    allSkills = await store.fetchSkills();
    sampleFamilies = [
      for (final id in sampleFamilyIds)
        allFamilies.firstWhere((f) => f.id == id),
    ];
  });

  setUp(() async {
    harness = await AppTestHarness.create();
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        hasResourceCatalogue: true,
        usersProfile: RiderProfile(
          id: 'alex@example.com',
          name: 'Alex Rider',
          email: 'alex@example.com',
        ),
        user: const User(
          id: 'uid-alex',
          email: 'alex@example.com',
          name: 'Alex Rider',
          isGuest: false,
          emailVerified: true,
        ),
      ),
    );
  });

  tearDown(() => harness.close());

  SkillTreeV2State buildSampleState({
    SkillCategory realm = SkillCategory.Husbandry,
    Set<String> expanded = const {},
    String selectedSkillId = 'rider.husbandry.grooming',
  }) {
    final progress = <String, SkillProgressRecord>{
      'rider.husbandry.safe_handling': SkillProgressRecord(
        skillId: 'rider.husbandry.safe_handling',
        subject: SkillSubject.rider,
        levels: {
          DifficultyState.Introductory: LevelProgress(
            state: LevelState.PROFICIENT,
            updatedAt: DateTime(2026, 11),
          ),
        },
      ),
      'rider.husbandry.grooming': SkillProgressRecord(
        skillId: 'rider.husbandry.grooming',
        subject: SkillSubject.rider,
        levels: {
          DifficultyState.Introductory: LevelProgress(
            state: LevelState.PROFICIENT,
            updatedAt: DateTime(2026, 11, 2),
          ),
          DifficultyState.Intermediate: LevelProgress(
            state: LevelState.LEARNING,
            updatedAt: DateTime(2026, 11, 5),
          ),
        },
      ),
      'rider.mounted.walk': SkillProgressRecord(
        skillId: 'rider.mounted.walk',
        subject: SkillSubject.rider,
        levels: {
          DifficultyState.Introductory: LevelProgress(
            state: LevelState.PROFICIENT,
            updatedAt: DateTime(2026, 11, 3),
          ),
        },
      ),
      'rider.mounted.trot': SkillProgressRecord(
        skillId: 'rider.mounted.trot',
        subject: SkillSubject.rider,
        levels: {
          DifficultyState.Introductory: LevelProgress(
            state: LevelState.LEARNING,
            updatedAt: DateTime(2026, 11, 4),
          ),
        },
      ),
    };
    final verifications = <String, SkillVerificationRecord>{
      'rider.husbandry.safe_handling': SkillVerificationRecord(
        skillId: 'rider.husbandry.safe_handling',
        levels: {
          DifficultyState.Introductory: LevelVerification(
            verifiedByUid: 'coach-1',
            verifiedByName: 'Coach Maya',
            connectionId: 'conn-1',
            verifiedAt: DateTime(2026, 11, 10),
          ),
        },
      ),
    };

    return SkillTreeV2State(
      isLoading: false,
      families: sampleFamilies,
      skills: allSkills
          .where((s) => sampleFamilyIds.contains(s.familyId))
          .toList(),
      realm: realm,
      expandedFamilyIds: expanded,
      selectedSkillId: selectedSkillId,
      selectedLevel: DifficultyState.Introductory,
      progressBySkillId: progress,
      verificationsBySkillId: verifications,
    );
  }

  List<CurriculumSkill> skillsFor(SkillFamily fam, SkillTreeV2State st) =>
      st.skills.where((s) => s.familyId == fam.id).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Widget framedThemeCanvas({required ThemeData theme, required Widget child}) {
    final gradients = theme.extension<SurfaceGradients>();
    return Theme(
      data: theme,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradients?.background,
          color: theme.colorScheme.surface,
        ),
        child: child,
      ),
    );
  }

  group('Skill Family Vector Prototype', () {
    testWidgets(
      'renders monochrome SVG assets, recolors cleanly across Dark/Light/Selected/Disabled, and captures specimen',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 920);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final boundaryKey = GlobalKey();
        final sampleState = buildSampleState();

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: mainThemeDark,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 20,
                      children: [
                        Text(
                          '1. Source Monochrome Vector Artwork (Pure #000000 SVG at 88px & 44px)',
                          style: mainThemeLight.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final fam in sampleFamilies)
                              Column(
                                spacing: 8,
                                children: [
                                  Row(
                                    spacing: 12,
                                    children: [
                                      SkillFamilyIcon(
                                        familyId: fam.id,
                                        fallbackRealm: fam.realm,
                                        size: 88,
                                        colorOverride: Colors.black,
                                        semanticLabel: fam.name,
                                      ),
                                      SkillFamilyIcon(
                                        familyId: fam.id,
                                        fallbackRealm: fam.realm,
                                        colorOverride: Colors.black,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    fam.name,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Row(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: framedThemeCanvas(
                                  theme: mainThemeDark,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 12,
                                      children: [
                                        const Text(
                                          '2. Dark Theme Recoloring (Normal · Selected · Disabled)',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        for (final state
                                            in SkillFamilyIconState.values)
                                          Row(
                                            spacing: 16,
                                            children: [
                                              SizedBox(
                                                width: 72,
                                                child: Text(
                                                  state.name.toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.72,
                                                        ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              for (final fam in sampleFamilies)
                                                SkillFamilyIconBadge(
                                                  familyId: fam.id,
                                                  fallbackRealm: fam.realm,
                                                  state: state,
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: framedThemeCanvas(
                                  theme: mainThemeLight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 12,
                                      children: [
                                        Text(
                                          '3. Light Theme Recoloring (Normal · Selected · Disabled)',
                                          style: TextStyle(
                                            color: mainThemeLight
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        for (final state
                                            in SkillFamilyIconState.values)
                                          Row(
                                            spacing: 16,
                                            children: [
                                              SizedBox(
                                                width: 72,
                                                child: Text(
                                                  state.name.toUpperCase(),
                                                  style: TextStyle(
                                                    color: mainThemeLight
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              for (final fam in sampleFamilies)
                                                SkillFamilyIconBadge(
                                                  familyId: fam.id,
                                                  fallbackRealm: fam.realm,
                                                  state: state,
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Expect 3 + 3 + 9 + 9 = 24 SvgPicture widgets rendered cleanly.
        expect(find.byType(SvgPicture), findsNWidgets(24));
        expect(tester.takeException(), isNull);
        expect(sampleState.families, hasLength(3));

        await _captureBoundary(
          tester,
          boundaryKey,
          'prototype_icon_specimen.png',
        );
      },
    );

    testWidgets(
      'mobile prototype reduces collapsed card height, preserves accessibility & reduced motion, and captures mobile comparison',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 920);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // First measure current vs proposed collapsed heights at 390px width.
        final measureState = buildSampleState();
        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      key: const Key('measureCurrentBox'),
                      width: 358,
                      child: SkillFamilyListV2(
                        state: measureState.copyWith(
                          families: sampleFamilies.take(2).toList(),
                          skills: measureState.skills
                              .where(
                                (s) =>
                                    s.familyId !=
                                    'rider.mounted.gaits_rhythm_transitions',
                              )
                              .toList(),
                        ),
                        onSelectSkill: (_) {},
                        onToggleFamily: (_) {},
                      ),
                    ),
                    SizedBox(
                      key: const Key('measureProposedBox'),
                      width: 358,
                      child: Column(
                        spacing: 12,
                        children: [
                          for (final fam in sampleFamilies.take(2))
                            SkillFamilyCardPrototype(
                              family: fam,
                              skills: skillsFor(fam, measureState),
                              progressBySkillId: measureState.progressBySkillId,
                              verificationsBySkillId:
                                  measureState.verificationsBySkillId,
                              isExpanded: false,
                              showProgress: true,
                              onToggle: () {},
                              onSelectSkill: (_) {},
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final currentHeight = tester
            .getSize(find.byKey(const Key('measureCurrentBox')))
            .height;
        final proposedHeight = tester
            .getSize(find.byKey(const Key('measureProposedBox')))
            .height;
        expect(proposedHeight, lessThan(currentHeight));
        // ignore: avoid_print
        print(
          'Measured 2-card collapsed height at 358px: current=${currentHeight.toStringAsFixed(1)}px vs proposed=${proposedHeight.toStringAsFixed(1)}px',
        );

        // Measure cached vector rebuild timing.
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final fam in sampleFamilies)
                      SkillFamilyIconBadge(
                        familyId: fam.id,
                        fallbackRealm: fam.realm,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        sw.stop();
        // ignore: avoid_print
        print('Cached SVG badge rebuild time: ${sw.elapsedMilliseconds}ms');

        // Render 3-column Mobile (390px) Comparison: Current vs Proposed Cards vs 2-Col Grid.
        final boundaryKey = GlobalKey();
        final comparisonState = buildSampleState();
        final expandedDailyCare = sampleFamilies[1];

        Widget phoneShell({
          required String heading,
          required ThemeData theme,
          required Widget body,
        }) {
          final gradients = theme.extension<SurfaceGradients>();
          return SizedBox(
            width: 390,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTokens.glassBorderDark,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      gradient: gradients?.background,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Theme(data: theme, child: body),
                  ),
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: mainThemeDark,
            home: Scaffold(
              backgroundColor: const Color(0xFF040B0D),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: Container(
                      color: const Color(0xFF040B0D),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [
                          phoneShell(
                            heading: 'Current Mobile (Text-Heavy Cards)',
                            theme: mainThemeDark,
                            body: SkillFamilyListV2(
                              state: comparisonState.copyWith(
                                families: sampleFamilies.take(2).toList(),
                                expandedFamilyIds: {expandedDailyCare.id},
                              ),
                              onSelectSkill: (_) {},
                              onToggleFamily: (_) {},
                            ),
                          ),
                          phoneShell(
                            heading:
                                'Proposed Mobile (Illustrated Compact Cards)',
                            theme: mainThemeDark,
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 12,
                              children: [
                                SkillFamilyCardPrototype(
                                  family: sampleFamilies[0],
                                  skills: skillsFor(
                                    sampleFamilies[0],
                                    comparisonState,
                                  ),
                                  progressBySkillId:
                                      comparisonState.progressBySkillId,
                                  verificationsBySkillId:
                                      comparisonState.verificationsBySkillId,
                                  isExpanded: false,
                                  showProgress: true,
                                  onToggle: () {},
                                  onSelectSkill: (_) {},
                                ),
                                SkillFamilyCardPrototype(
                                  family: sampleFamilies[1],
                                  skills: skillsFor(
                                    sampleFamilies[1],
                                    comparisonState,
                                  ),
                                  progressBySkillId:
                                      comparisonState.progressBySkillId,
                                  verificationsBySkillId:
                                      comparisonState.verificationsBySkillId,
                                  isExpanded: true,
                                  selectedSkillId:
                                      comparisonState.selectedSkillId,
                                  showProgress: true,
                                  onToggle: () {},
                                  onSelectSkill: (_) {},
                                ),
                                SkillFamilyCardPrototype(
                                  family: sampleFamilies[2],
                                  skills: skillsFor(
                                    sampleFamilies[2],
                                    comparisonState,
                                  ),
                                  progressBySkillId:
                                      comparisonState.progressBySkillId,
                                  verificationsBySkillId:
                                      comparisonState.verificationsBySkillId,
                                  isExpanded: false,
                                  showProgress: true,
                                  onToggle: () {},
                                  onSelectSkill: (_) {},
                                ),
                              ],
                            ),
                          ),
                          phoneShell(
                            heading: 'Alternative: 2-Column Illustrated Grid',
                            theme: mainThemeDark,
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 12,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 10,
                                  children: [
                                    for (final fam in sampleFamilies.take(2))
                                      Expanded(
                                        child: SkillFamilyGridTilePrototype(
                                          family: fam,
                                          skills: skillsFor(
                                            fam,
                                            comparisonState,
                                          ),
                                          progressBySkillId:
                                              comparisonState.progressBySkillId,
                                          verificationsBySkillId:
                                              comparisonState
                                                  .verificationsBySkillId,
                                          isSelected:
                                              fam.id == expandedDailyCare.id,
                                          showProgress: true,
                                          onTap: () {},
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(
                                  width: 176,
                                  child: SkillFamilyGridTilePrototype(
                                    family: sampleFamilies[2],
                                    skills: skillsFor(
                                      sampleFamilies[2],
                                      comparisonState,
                                    ),
                                    progressBySkillId:
                                        comparisonState.progressBySkillId,
                                    verificationsBySkillId:
                                        comparisonState.verificationsBySkillId,
                                    isSelected: false,
                                    showProgress: true,
                                    onTap: () {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(expandedDailyCare.description),
          findsNWidgets(
            2,
          ), // shown in current (both collapsed+expanded) & expanded proposed
        );
        expect(tester.takeException(), isNull);
        await _captureBoundary(
          tester,
          boundaryKey,
          'prototype_mobile_comparison.png',
        );

        // Light-theme narrow mobile render (390px) + verify interactive expand/select.
        final lightBoundaryKey = GlobalKey();
        var expandedId = sampleFamilies[1].id;
        String? tappedSkillId;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setModalState) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: mainThemeLight,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: lightBoundaryKey,
                    child: framedThemeCanvas(
                      theme: mainThemeLight,
                      child: SizedBox(
                        width: 390,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              Text(
                                'Rider Skills · Light Theme Preview',
                                style: mainThemeLight.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              for (final fam in sampleFamilies)
                                SkillFamilyCardPrototype(
                                  family: fam,
                                  skills: skillsFor(fam, comparisonState),
                                  progressBySkillId:
                                      comparisonState.progressBySkillId,
                                  verificationsBySkillId:
                                      comparisonState.verificationsBySkillId,
                                  isExpanded: expandedId == fam.id,
                                  selectedSkillId:
                                      comparisonState.selectedSkillId,
                                  showProgress: true,
                                  onToggle: () => setModalState(
                                    () => expandedId = expandedId == fam.id
                                        ? ''
                                        : fam.id,
                                  ),
                                  onSelectSkill: (s) =>
                                      setModalState(() => tappedSkillId = s.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _captureBoundary(
          tester,
          lightBoundaryKey,
          'prototype_mobile_light.png',
        );

        // Verify touch target >= 48px and interactive expand + skill selection.
        final headerFinder = find.byKey(
          const Key(
            'prototypeSkillFamilyHeader_rider.husbandry.safety_handling',
          ),
        );
        expect(tester.getSize(headerFinder).height, greaterThanOrEqualTo(48));
        await tester.tap(headerFinder);
        await tester.pumpAndSettle();
        expect(find.text(sampleFamilies[0].description), findsOneWidget);

        await tester.tap(
          find.byKey(
            const Key('prototypeSkillRow_rider.husbandry.safe_handling'),
          ),
        );
        await tester.pump();
        expect(tappedSkillId, 'rider.husbandry.safe_handling');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'handles narrow 320px mobile & reduced motion without overflow and captures desktop split comparison',
      (tester) async {
        // 320px reduced-motion overflow check.
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = buildSampleState(
          expanded: {'rider.mounted.gaits_rhythm_transitions'},
          selectedSkillId: 'rider.mounted.trot',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  spacing: 10,
                  children: [
                    for (final fam in sampleFamilies)
                      SkillFamilyCardPrototype(
                        family: fam,
                        skills: skillsFor(fam, state),
                        progressBySkillId: state.progressBySkillId,
                        verificationsBySkillId: state.verificationsBySkillId,
                        isExpanded: state.expandedFamilyIds.contains(fam.id),
                        selectedSkillId: state.selectedSkillId,
                        showProgress: true,
                        onToggle: () {},
                        onSelectSkill: (_) {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // 1280x780 Desktop Split View prototype with live SkillDetailV2Panel.
        tester.view.physicalSize = const Size(1280, 780);
        final desktopBoundary = GlobalKey();
        final trotSkill = allSkills.firstWhere(
          (s) => s.id == 'rider.mounted.trot',
        );

        final desktopTheme = mainThemeDark.copyWith(
          textTheme: mainThemeDark.textTheme.apply(fontFamily: 'Roboto'),
          chipTheme: mainThemeDark.chipTheme.copyWith(
            labelStyle: mainThemeDark.chipTheme.labelStyle?.copyWith(
              fontFamily: 'Roboto',
            ),
          ),
        );

        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: desktopTheme,
              home: Scaffold(
                body: RepaintBoundary(
                  key: desktopBoundary,
                  child: framedThemeCanvas(
                    theme: desktopTheme,
                    child: SizedBox(
                      width: 1280,
                      height: 780,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 14,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Desktop Prototype: Illustrated Master Rail + Full Educational Detail',
                                  style: mainThemeDark.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const AppStatusBadge(
                                  label: '0 extra Firestore reads',
                                  tone: AppStatusTone.info,
                                ),
                              ],
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 18,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        spacing: 12,
                                        children: [
                                          for (final fam in sampleFamilies)
                                            SkillFamilyCardPrototype(
                                              family: fam,
                                              skills: skillsFor(fam, state),
                                              progressBySkillId:
                                                  state.progressBySkillId,
                                              verificationsBySkillId:
                                                  state.verificationsBySkillId,
                                              isExpanded: state
                                                  .expandedFamilyIds
                                                  .contains(fam.id),
                                              selectedSkillId:
                                                  state.selectedSkillId,
                                              showProgress: true,
                                              onToggle: () {},
                                              onSelectSkill: (_) {},
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: SingleChildScrollView(
                                      child: SkillDetailV2Panel(
                                        state: state,
                                        skill: trotSkill,
                                        allResources: const [],
                                        canSelfAssess: true,
                                        selfAssessDisabledReason: null,
                                        canVerify: false,
                                        onSelectLevel: (_) {},
                                        onSelfAssess: (_, _) {},
                                        onVerifyLevel:
                                            (_, {required verified}) {},
                                        onSelectRelatedSkill: (_) {},
                                        onChangeResourceSort: (_) {},
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(trotSkill.name), findsWidgets);
        expect(tester.takeException(), isNull);

        await _captureBoundary(
          tester,
          desktopBoundary,
          'prototype_desktop_comparison.png',
        );
      },
    );
  });
}
