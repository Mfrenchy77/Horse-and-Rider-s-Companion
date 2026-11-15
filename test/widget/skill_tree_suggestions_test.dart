import 'package:authentication_repository/authentication_repository.dart'
    show User;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Administration/administration_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/suggest_improvement_dialog.dart';

import '../support/app_test_harness.dart';

void main() {
  late AppTestHarness harness;
  late InMemorySkillTreeSuggestionsStore suggestionsStore;
  late SkillTreeSuggestionsRepository suggestionsRepo;

  setUp(() async {
    SkillTreeV2View.resetPreviewStoreForTest();
    harness = await AppTestHarness.create();
    suggestionsStore = InMemorySkillTreeSuggestionsStore(
      actorUid: 'rider-1',
      actorEmail: 'rider1@example.com',
      actorName: 'Rider One',
    );
    suggestionsRepo = SkillTreeSuggestionsRepository(store: suggestionsStore);
  });

  tearDown(() => harness.close());

  group('InMemorySkillTreeSuggestionsStore', () {
    test(
      'enforces 10 submissions per 24h and moderator vs admin rules',
      () async {
      for (var i = 0; i < 10; i++) {
        final s = await suggestionsRepo.submitSuggestion(
          SkillTreeSuggestionDraft(
            contributionCategory: SuggestionCategory.componentOrExample,
            subject: 'rider',
            realm: 'Mounted',
            title: 'Suggestion #${i + 1}',
            description: 'Helpful detail for suggestion #${i + 1}.',
          ),
        );
        expect(s.status, SuggestionStatus.submitted);
      }

      await expectLater(
        suggestionsRepo.submitSuggestion(
          const SkillTreeSuggestionDraft(
            contributionCategory: SuggestionCategory.componentOrExample,
            subject: 'rider',
            realm: 'Mounted',
            title: 'Suggestion #11',
            description: 'This should hit the 24-hour rate limit.',
          ),
        ),
        throwsA(
          isA<SkillTreeSuggestionException>().having(
            (e) => e.code,
            'code',
            'resource-exhausted',
          ),
        ),
      );

      final mine = await suggestionsRepo.fetchMySuggestions(
        submitterUid: 'rider-1',
      );
      expect(mine, hasLength(10));

      // Moderator can triage/clarify but cannot approve.
      suggestionsStore
        ..actorUid = 'mod-1'
        ..actorName = 'Mod'
        ..actorIsModerator = true;

      await expectLater(
        suggestionsRepo.reviewSuggestion(
          SuggestionReviewUpdate(
            suggestionId: mine.first.id,
            status: SuggestionStatus.approvedAsNewSkill,
          ),
        ),
        throwsA(
          isA<SkillTreeSuggestionException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );

      final triaged = await suggestionsRepo.reviewSuggestion(
        SuggestionReviewUpdate(
          suggestionId: mine.first.id,
          status: SuggestionStatus.needsClarification,
          privateNote: 'Internal triage note',
          publicResolutionNote: 'Please add level context.',
          includePublicResolutionNote: true,
        ),
      );
      expect(triaged.status, SuggestionStatus.needsClarification);

      // Admin can approve.
      suggestionsStore
        ..actorUid = 'admin-1'
        ..actorName = 'Admin'
        ..actorIsAdmin = true;
      final approved = await suggestionsRepo.reviewSuggestion(
        SuggestionReviewUpdate(
          suggestionId: mine.first.id,
          status: SuggestionStatus.approvedAsNewSkill,
        ),
      );
      expect(approved.status, SuggestionStatus.approvedAsNewSkill);
    });
  });

  group('Community submission UI', () {
    testWidgets(
      'SkillTreeV2View exposes Suggest an Improvement and contextual skill '
      'suggestion with auto-attached context',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const verifiedUser = User(
          id: 'rider-1',
          name: 'Rider One',
          email: 'rider1@example.com',
          isGuest: false,
          emailVerified: true,
        );
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: verifiedUser,
            isGuest: false,
            isForRider: true,
            usersProfile: RiderProfile(
              id: 'rider-1',
              name: 'Rider One',
              email: 'rider1@example.com',
            ),
          ),
        );

        final v2Store = await const AssetCurriculumV2Loader()
            .loadInMemoryStore();
        final v2Repo = SkillTreeV2Repository(store: v2Store);

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SkillTreeSuggestionsRepository>.value(
                value: suggestionsRepo,
              ),
            ],
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp(
                home: SkillTreeV2View(repository: v2Repo),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Permanent header buttons were moved into the app-bar overflow menu.
        expect(
          find.byKey(const Key('skillTreeV2SuggestImprovementButton')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('skillTreeV2MySuggestionsButton')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
          findsOneWidget,
        );

        // Empty My Suggestions dialog should be compact.
        await tester.tap(
          find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Toggle Edit Controls'), findsNothing);
        expect(find.text('Sort'), findsNothing);
        await tester.tap(
          find.byKey(const Key('skillTreeV2MenuMySuggestions')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mySuggestionsDialog')), findsOneWidget);
        expect(
          find.text('You have not submitted any Skill Tree suggestions yet.'),
          findsOneWidget,
        );
        final emptyDialogSize = tester.getSize(
          find
              .descendant(
                of: find.byKey(const Key('mySuggestionsDialog')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(emptyDialogSize.height, lessThan(260));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Open general suggestion dialog from app-bar overflow menu.
        await tester.tap(
          find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('skillTreeV2MenuSuggestImprovement')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('suggestImprovementDialog')),
          findsOneWidget,
        );
        expect(find.text('What would you like to improve?'), findsOneWidget);
        expect(find.text('Suggestion Type'), findsNothing);
        await tester.enterText(
          find.byKey(const Key('suggestionTitleField')),
          'Add ground-tying safety note',
        );
        await tester.enterText(
          find.byKey(const Key('suggestionDescriptionField')),
          'Clarify quick-release knot best practices for beginners.',
        );
        await tester.tap(find.byKey(const Key('suggestionSubmitButton')));
        await tester.pumpAndSettle();

        final submitted = await suggestionsRepo.fetchMySuggestions(
          submitterUid: 'rider-1',
        );
        expect(submitted, hasLength(1));
        expect(submitted.single.subject, 'rider');
        expect(submitted.single.title, 'Add ground-tying safety note');

        // Open My Suggestions from overflow menu and verify it renders.
        await tester.tap(
          find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('skillTreeV2MenuMySuggestions')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mySuggestionsDialog')), findsOneWidget);
        expect(find.text('Add ground-tying safety note'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Search by legacy alias and verify renamed skill + visible aliases +
        // contextual suggestion submission.
        await tester.enterText(
          find.byKey(const Key('skillTreeV2SearchField')),
          'Yield the Forequarters',
        );
        await tester.pumpAndSettle();
        expect(find.text('Turn on the Haunches (In-Hand)'), findsWidgets);
        await tester.tap(find.text('Turn on the Haunches (In-Hand)').first);
        await tester.pumpAndSettle();

        final aliasesTextFinder = find.byKey(
          const Key('skillDetailAliasesText'),
        );
        expect(aliasesTextFinder, findsOneWidget);
        final aliasesWidget = tester.widget<Text>(aliasesTextFinder);
        final aliasesPlain = aliasesWidget.textSpan?.toPlainText() ?? '';
        expect(
          aliasesPlain,
          'Also known as: Yield the Forequarters (In-Hand) · '
          'Move the shoulders over (in-hand)',
        );
        // Rendered as plain secondary text, not Material Chips.
        expect(
          find.descendant(
            of: aliasesTextFinder,
            matching: find.byType(Chip),
          ),
          findsNothing,
        );

        // Contextual suggestion from skill detail panel.
        await tester.ensureVisible(
          find.text('Suggest Improvement for This Skill'),
        );
        await tester.tap(find.text('Suggest Improvement for This Skill'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('suggestImprovementDialog')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('suggestionTitleField')),
          'Clarify shoulder position cue',
        );
        await tester.enterText(
          find.byKey(const Key('suggestionDescriptionField')),
          'Add handler shoulder angle guidance for Turn on the Haunches.',
        );
        await tester.tap(find.byKey(const Key('suggestionSubmitButton')));
        await tester.pumpAndSettle();

        final allSubmitted = await suggestionsRepo.fetchMySuggestions(
          submitterUid: 'rider-1',
        );
        expect(allSubmitted, hasLength(2));
        expect(
          allSubmitted.first.targetSkillId,
          'rider.in_hand.yield_forequarters',
        );
      },
    );

    testWidgets('Guest user is prompted to sign in before suggesting', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(
          value: harness.cubit,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSuggestImprovementDialog(
                  context,
                  subject: SkillSubject.rider,
                  realm: SkillCategory.Mounted,
                  repository: suggestionsRepo,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In Required'), findsOneWidget);
    });

    testWidgets('Hides Also known as when skill has no distinct aliases', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final store = InMemorySkillTreeV2Store(
        families: const [
          SkillFamily(
            id: 'rider.husbandry.test_family',
            subject: SkillSubject.rider,
            realm: SkillCategory.Husbandry,
            name: 'Test Family',
            description: 'Test',
          ),
        ],
        skills: const [
          CurriculumSkill(
            id: 'rider.husbandry.no_alias_skill',
            subject: SkillSubject.rider,
            realm: SkillCategory.Husbandry,
            familyId: 'rider.husbandry.test_family',
            name: 'Basic Leading',
            aliases: ['basic leading', '  '],
            summary: 'Lead calmly.',
            purpose: 'Safety.',
            availableLevels: [DifficultyState.Introductory],
            levels: {
              DifficultyState.Introductory: SkillLevelDefinition(
                overview: 'Overview',
                learning: 'Learning',
                proficient: 'Proficient',
              ),
            },
          ),
        ],
      );
      final repo = SkillTreeV2Repository(store: store);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SkillTreeSuggestionsRepository>.value(
              value: suggestionsRepo,
            ),
          ],
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              home: SkillTreeV2View(repository: repo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Family'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Basic Leading').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('skillDetailAliasesText')), findsNothing);
      expect(find.textContaining('Also known as:'), findsNothing);
    });
  });

  group('Administration entry & inbox role enforcement', () {
    testWidgets(
      'RiderDrawer and RiderProfileOverFlowMenu hide Administration for '
      'ordinary users and show it for staff',
      (tester) async {
        const riderUser = User(
          id: 'u1',
          name: 'Rider',
          email: 'u1@example.com',
          isGuest: false,
          emailVerified: true,
        );
        final profile = RiderProfile(
          id: 'u1',
          name: 'Rider',
          email: 'u1@example.com',
          editor: true, // Legacy editor flag must NOT grant Administration.
        );

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: riderUser,
            isGuest: false,
            usersProfile: profile,
          ),
        );

        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: const MaterialApp(
              home: Scaffold(
                drawer: UserProfileDrawer(),
                body: RiderProfileOverFlowMenu(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open drawer
        tester
            .state<ScaffoldState>(find.byType(Scaffold))
            .openDrawer();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('drawerAdministrationTile')), findsNothing);

        // Promote to moderator -> Administration appears.
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: riderUser.copyWith(isModerator: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('drawerAdministrationTile')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AdministrationPage enforces moderator vs admin status options and '
      'updates audit history',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await suggestionsRepo.submitSuggestion(
          const SkillTreeSuggestionDraft(
            contributionCategory: SuggestionCategory.newSkillProposal,
            subject: 'horse',
            realm: 'In_Hand',
            title: 'Add trailer loading calm wait',
            description: 'Wait calmly at the ramp before stepping up.',
          ),
        );

        // Unauthorized user sees gate message.
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: const User(
              id: 'u1',
              name: 'Rider',
              email: 'u1@example.com',
              isGuest: false,
              emailVerified: true,
            ),
            isGuest: false,
          ),
        );
        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              home: AdministrationPage(
                key: const ValueKey('unauthAdminPage'),
                repository: suggestionsRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Administrator or moderator privileges'),
          findsOneWidget,
        );

        // Moderator sees inbox, private notes, and moderator-only statuses.
        suggestionsStore
          ..actorUid = 'mod-1'
          ..actorName = 'Mod'
          ..actorIsModerator = true;
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: const User(
              id: 'mod-1',
              name: 'Mod',
              email: 'mod@example.com',
              isGuest: false,
              emailVerified: true,
              isModerator: true,
            ),
            isGuest: false,
          ),
        );
        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              home: AdministrationPage(
                key: const ValueKey('modAdminPage'),
                repository: suggestionsRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('administrationPage')), findsOneWidget);
        expect(
          find.textContaining('Moderator permissions:'),
          findsOneWidget,
        );
        expect(
          find.text('Add trailer loading calm wait'),
          findsAtLeastNWidgets(1),
        );

        // Add a private note and save.
        await tester.enterText(
          find.byKey(const Key('adminPrivateNoteField')),
          'Reviewed wording with curriculum guide.',
        );
        await tester.tap(find.byKey(const Key('adminSaveReviewButton')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Reviewed wording with curriculum guide.'),
          findsOneWidget,
        );

        // Admin sees full status dropdown without moderator restriction banner.
        suggestionsStore
          ..actorUid = 'admin-1'
          ..actorName = 'Admin'
          ..actorIsAdmin = true;
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: const User(
              id: 'admin-1',
              name: 'Admin',
              email: 'admin@example.com',
              isGuest: false,
              emailVerified: true,
              isAdmin: true,
            ),
            isGuest: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Moderator permissions:'), findsNothing);
      },
    );
  });
}
