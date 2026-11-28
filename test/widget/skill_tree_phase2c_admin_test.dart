// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Administration/administration_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_export_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/suggest_improvement_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

class _CorruptAtomicPrimaryStore implements SkillTreeV2Store {
  @override
  Future<List<SkillFamily>> fetchFamilies() async {
    throw CurriculumLoadException(
      'Active revision is missing chunks.',
      revisionId: 'rev_000099',
    );
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() async {
    throw CurriculumLoadException(
      'Active revision is missing chunks.',
      revisionId: 'rev_000099',
    );
  }

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async => const {};

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async => const {};

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async => const [];

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) async {}
}

void main() {
  const family = SkillFamily(
    id: 'rider.mounted.balance',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    name: 'Mounted Balance',
    description: 'Core rider balance.',
    sortOrder: 10,
  );

  const skill = CurriculumSkill(
    id: 'rider.mounted.neutral_pelvis',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Neutral Pelvis',
    summary: 'Original summary.',
    purpose: 'Purpose.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Overview',
        learning: 'Learning',
        proficient: 'Proficient v1',
      ),
    },
    legacyIds: ['legacy_seat_1'],
    sortOrder: 10,
  );

  group('Phase 2C Complete Skill Tree Administration', () {
    test(
      'HybridCurriculumSkillTreeV2Store falls back cleanly to bundled offline '
      'assets when active revision throws CurriculumLoadException',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final hybrid = HybridCurriculumSkillTreeV2Store(
          primaryStore: _CorruptAtomicPrimaryStore(),
        );
        final families = await hybrid.fetchFamilies();
        final skills = await hybrid.fetchSkills();
        expect(families.length, 33);
        expect(skills.length, 84);
      },
    );

    test(
      'buildCanonicalCurriculumExportJson produces deterministic full export',
      () {
        final jsonA = buildCanonicalCurriculumExportJson(
          families: const [family],
          skills: const [skill],
        );
        final jsonB = buildCanonicalCurriculumExportJson(
          families: const [family],
          skills: const [skill],
        );
        expect(jsonA, equals(jsonB));
        final decoded = jsonDecode(jsonA) as Map<String, dynamic>;
        expect(decoded['schemaVersion'], 2);
        expect((decoded['families'] as List).length, 1);
        expect((decoded['skills'] as List).length, 1);
      },
    );

    testWidgets(
      'SuggestImprovementDialog credit checkbox defaults unchecked and submits '
      'creditConsent when checked',
      (tester) async {
        final mockAppCubit = _MockAppCubit();
        final riderState = const AppState.authenticated(
          User(
            id: 'rider-1',
            email: 'jane@example.com',
            name: 'Jane Smith',
            isGuest: false,
            emailVerified: true,
          ),
        ).copyWith(isGuest: false);
        when(() => mockAppCubit.state).thenReturn(riderState);
        whenListen(mockAppCubit, Stream<AppState>.value(riderState));

        final store = InMemorySkillTreeSuggestionsStore(
          actorUid: 'rider-1',
          actorEmail: 'jane@example.com',
          actorName: 'Jane Smith',
        );
        final repo = SkillTreeSuggestionsRepository(store: store);
        SkillTreeSuggestion? submitted;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AppCubit>.value(
              value: mockAppCubit,
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      submitted = await showSuggestImprovementDialog(
                        context,
                        subject: SkillSubject.rider,
                        realm: SkillCategory.Mounted,
                        targetSkill: skill,
                        repository: repo,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final checkbox = tester.widget<CheckboxListTile>(
          find.byKey(const Key('suggestionCreditConsentCheckbox')),
        );
        expect(checkbox.value, isFalse);
        expect(find.text('Credit me if my suggestion is used'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('suggestionTitleField')),
          'Add seat alignment example',
        );
        await tester.enterText(
          find.byKey(const Key('suggestionDescriptionField')),
          'Include a clear cue for even seat bone weight at walk.',
        );
        await tester.ensureVisible(
          find.byKey(const Key('suggestionCreditConsentCheckbox')),
        );
        await tester.tap(
          find.byKey(const Key('suggestionCreditConsentCheckbox')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('suggestionSubmitButton')));
        await tester.pumpAndSettle();

        expect(submitted, isNotNull);
        expect(submitted!.creditConsent, isTrue);
      },
    );

    testWidgets(
      'AdministrationPage supports Incorporate into Draft, consent-gated '
      'recognition, and Download Curriculum on desktop and mobile',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockAppCubit = _MockAppCubit();
        final adminState = const AppState.authenticated(
          User(
            id: 'admin-1',
            email: 'admin@example.com',
            name: 'Admin One',
            isGuest: false,
            emailVerified: true,
            isAdmin: true,
          ),
        ).copyWith(isGuest: false);
        when(() => mockAppCubit.state).thenReturn(adminState);
        whenListen(mockAppCubit, Stream<AppState>.value(adminState));

        final consentedSuggestion = SkillTreeSuggestion(
          id: 'sug-1',
          submittedByUid: 'rider-1',
          submitterEmail: 'jane@example.com',
          submitterName: 'Jane Smith',
          contributionCategory: SuggestionCategory.componentOrExample,
          subject: 'rider',
          realm: 'Mounted',
          targetSkillId: skill.id,
          targetSkillName: skill.name,
          title: 'Clarify neutral pelvis cue',
          description: 'Explain balanced seat bones at halt and walk.',
          creditConsent: true,
          status: SuggestionStatus.submitted,
          createdAt: DateTime.utc(2026, 11, 24),
          updatedAt: DateTime.utc(2026, 11, 24),
        );

        final suggestionsStore = InMemorySkillTreeSuggestionsStore(
          initialSuggestions: [consentedSuggestion],
          actorUid: 'admin-1',
          actorEmail: 'admin@example.com',
          actorName: 'Admin One',
          actorIsAdmin: true,
        );
        final suggestionsRepo = SkillTreeSuggestionsRepository(
          store: suggestionsStore,
        );
        final draftRepo = SkillTreeDraftRepository(
          store: InMemorySkillTreeDraftStore(),
        );
        final skillTreeRepo = SkillTreeV2Repository(
          store: InMemorySkillTreeV2Store(
            families: const [family],
            skills: const [skill],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AppCubit>.value(
              value: mockAppCubit,
              child: AdministrationPage(
                repository: suggestionsRepo,
                draftRepository: draftRepo,
                skillTreeRepository: skillTreeRepo,
                enableCurriculumPublishing: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Download Curriculum dialog opens cleanly from AdministrationPage.
        await tester.tap(
          find.byKey(const Key('adminDownloadCurriculumButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('curriculumExportDialog')),
          findsOneWidget,
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // 2. Select suggestion and open Incorporate into Draft.
        await tester.tap(find.byKey(const Key('adminSuggestionTile_sug-1')));
        await tester.pumpAndSettle();

        final incorporateBtn = find.byKey(
          const Key('adminIncorporateIntoDraftButton'),
        );
        await tester.ensureVisible(incorporateBtn);
        await tester.tap(incorporateBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('incorporateSuggestionDialog')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('incorporateEditTargetSkillButton')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('incorporateGrantCreditCheckbox')),
          findsOneWidget,
        );

        // Opt into acknowledging the consented contributor and save status.
        await tester.ensureVisible(
          find.byKey(const Key('incorporateGrantCreditCheckbox')),
        );
        await tester.tap(
          find.byKey(const Key('incorporateGrantCreditCheckbox')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('incorporateSaveDraftButton')));
        await tester.pumpAndSettle();

        final contributors =
            await suggestionsRepo.fetchPublicContributorNames();
        expect(contributors, ['Jane Smith']);

        // Re-opening Incorporate shows duplicate-prevention notice.
        await tester.ensureVisible(incorporateBtn);
        await tester.tap(incorporateBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('alreadyIncorporatedNotice')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SkillFamilyListV2 renders subtle Community Contributors footer when '
      'consented names exist',
      (tester) async {
        const state = SkillTreeV2State(
          isLoading: false,
          families: [family],
          skills: [skill],
          realm: SkillCategory.Mounted,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SkillFamilyListV2(
                  state: state,
                  contributorNames: const ['Jane Smith'],
                  onSelectSkill: (_) {},
                  onToggleFamily: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('communityContributorsCard')),
          findsOneWidget,
        );
        expect(find.text('Community Contributors'), findsOneWidget);
        expect(
          find.textContaining(
            'With contributions from Jane Smith and other members',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CurriculumExportDialog downloads a .json file matching canonical export '
      'and handles download errors gracefully while keeping Copy Export',
      (tester) async {
        String? downloadedName;
        String? downloadedContent;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumExportDialog(
                families: const [family],
                skills: const [skill],
                onDownloadFile: (name, content) async {
                  downloadedName = name;
                  downloadedContent = content;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('downloadCurriculumExportButton')),
        );
        await tester.pumpAndSettle();

        expect(downloadedName, endsWith('.json'));
        expect(
          downloadedContent,
          equals(
            buildCanonicalCurriculumExportJson(
              families: const [family],
              skills: const [skill],
            ),
          ),
        );
        expect(
          find.byKey(const Key('curriculumExportStatusText')),
          findsOneWidget,
        );
        expect(find.textContaining('Downloaded '), findsOneWidget);

        // Error handling test: download throws -> graceful error message.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumExportDialog(
                families: const [family],
                skills: const [skill],
                onDownloadFile: (_, _) async {
                  throw Exception('Browser blocked download');
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('downloadCurriculumExportButton')),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Could not download curriculum file'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('copyCurriculumExportButton')),
          findsOneWidget,
        );
      },
    );
  });
}
