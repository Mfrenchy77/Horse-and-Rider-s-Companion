import 'package:authentication_repository/authentication_repository.dart'
    show User;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

void main() {
  late AppTestHarness harness;
  late InMemorySkillTreeDraftStore draftStore;
  late SkillTreeDraftRepository draftRepo;
  late InMemorySkillTreeSuggestionsStore suggestionsStore;
  late SkillTreeSuggestionsRepository suggestionsRepo;

  setUp(() async {
    SkillTreeV2View.resetPreviewStoreForTest();
    harness = await AppTestHarness.create();
    draftStore = InMemorySkillTreeDraftStore(
      actorUid: 'admin-1',
      actorName: 'Admin One',
      actorIsAdmin: true,
    );
    draftRepo = SkillTreeDraftRepository(store: draftStore);
    suggestionsStore = InMemorySkillTreeSuggestionsStore(
      actorUid: 'admin-1',
      actorEmail: 'admin1@example.com',
      actorName: 'Admin One',
      actorIsAdmin: true,
    );
    suggestionsRepo = SkillTreeSuggestionsRepository(store: suggestionsStore);
  });

  tearDown(() => harness.close());

  Widget wrapSkillTree({required SkillTreeV2Repository v2Repo}) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SkillTreeDraftRepository>.value(value: draftRepo),
        RepositoryProvider<SkillTreeSuggestionsRepository>.value(
          value: suggestionsRepo,
        ),
      ],
      child: BlocProvider<AppCubit>.value(
        value: harness.cubit,
        child: MaterialApp(home: SkillTreeV2View(repository: v2Repo)),
      ),
    );
  }

  group('Skill Tree 2.0 Admin Curriculum Draft Editing', () {
    testWidgets(
      'admin can add family and skill in draft, preview, save, and discard '
      'without mutating published curriculum',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const adminUser = User(
          id: 'admin-1',
          name: 'Admin One',
          email: 'admin1@example.com',
          isGuest: false,
          emailVerified: true,
          isAdmin: true,
        );
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: adminUser,
            isGuest: false,
            isForRider: true,
            usersProfile: RiderProfile(
              id: 'admin-1',
              name: 'Admin One',
              email: 'admin1@example.com',
            ),
          ),
        );

        final v2Store = await tester.runAsync(
          () => const AssetCurriculumV2Loader().loadInMemoryStore(),
        );
        final v2Repo = SkillTreeV2Repository(store: v2Store!);
        final publishedFamiliesBefore = await v2Repo.fetchFamilies();
        final publishedSkillsBefore = await v2Repo.fetchSkills();

        await tester.pumpWidget(wrapSkillTree(v2Repo: v2Repo));
        await tester.pumpAndSettle();

        // Enter Draft Mode via overflow menu.
        await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('skillTreeV2MenuAdminEditDraft')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('skillTreeV2MenuAdminEditDraft')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('skillTreeV2AdminDraftBanner')),
          findsOneWidget,
        );
        final publishButton = tester.widget<OutlinedButton>(
          find.byKey(const Key('draftPublishDisabledButton')),
        );
        expect(publishButton.onPressed, isNull);

        // Add a new skill family.
        await tester.tap(find.byKey(const Key('draftAddFamilyButton')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Family Name *'),
          'Admin Test Family',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description'),
          'Draft family for admin workflow verification.',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Add Family'));
        await tester.pumpAndSettle();

        expect(find.text('Admin Test Family'), findsOneWidget);

        // Add a skill inside the newly created family.
        final addSkillBtn = find.byKey(
          const Key('addSkillButton_rider.husbandry.admin_test_family'),
        );
        await tester.ensureVisible(addSkillBtn);
        await tester.tap(addSkillBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Skill Name *'),
          'Admin Draft Skill',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Summary / Description *'),
          'Draft skill summary.',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Purpose / Why It Matters *'),
          'Draft skill purpose.',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Level Overview *'),
          'Introductory overview.',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Learning Standard *'),
          'Learning criteria.',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Proficient Standard *'),
          'Proficient criteria.',
        );

        final addSkillSubmit = find.widgetWithText(FilledButton, 'Add Skill');
        await tester.ensureVisible(addSkillSubmit);
        await tester.tap(addSkillSubmit);
        await tester.pumpAndSettle();

        expect(find.text('Admin Draft Skill'), findsWidgets);

        // Preview diff dialog shows added family and skill.
        final previewBtn = find.byKey(const Key('draftPreviewButton'));
        await tester.ensureVisible(previewBtn);
        await tester.tap(previewBtn);
        await tester.pumpAndSettle();
        expect(find.text('Added Families (1)'), findsOneWidget);
        expect(find.text('Added Skills (1)'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Close'));
        await tester.pumpAndSettle();

        // Save draft to SkillTreeDraftRepository.
        final saveBtn = find.byKey(const Key('draftSaveButton'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        final savedDraft = await draftRepo.fetchDraft();
        expect(savedDraft, isNotNull);
        expect(
          savedDraft!.families.any((f) => f.name == 'Admin Test Family'),
          isTrue,
        );
        expect(
          savedDraft.skills.any((s) => s.name == 'Admin Draft Skill'),
          isTrue,
        );

        // Published curriculum remains untouched.
        final publishedFamiliesAfter = await v2Repo.fetchFamilies();
        final publishedSkillsAfter = await v2Repo.fetchSkills();
        expect(
          publishedFamiliesAfter.length,
          publishedFamiliesBefore.length,
        );
        expect(publishedSkillsAfter.length, publishedSkillsBefore.length);

        // Discard draft and confirm.
        final discardBtn = find.byKey(const Key('draftDiscardButton'));
        await tester.ensureVisible(discardBtn);
        await tester.tap(discardBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
        await tester.pumpAndSettle();

        expect(await draftRepo.fetchDraft(), isNull);
        expect(find.text('Admin Test Family'), findsNothing);
        expect(
          find.byKey(const Key('skillTreeV2AdminDraftBanner')),
          findsNothing,
        );
      },
    );

    for (final isModerator in [true, false]) {
      testWidgets(
        '${isModerator ? 'moderator' : 'ordinary user'} cannot see admin '
        'curriculum edit controls',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final v2Store = await tester.runAsync(
            () => const AssetCurriculumV2Loader().loadInMemoryStore(),
          );
          final v2Repo = SkillTreeV2Repository(store: v2Store!);

          harness.cubit.emit(
            harness.cubit.state.copyWith(
              user: User(
                id: isModerator ? 'mod-1' : 'user-1',
                name: isModerator ? 'Mod' : 'Rider',
                email: isModerator ? 'mod@example.com' : 'user@example.com',
                isGuest: false,
                emailVerified: true,
                isModerator: isModerator,
              ),
              isGuest: false,
              isForRider: true,
              usersProfile: RiderProfile(
                id: isModerator ? 'mod-1' : 'user-1',
                name: isModerator ? 'Mod' : 'Rider',
                email: isModerator ? 'mod@example.com' : 'user@example.com',
              ),
            ),
          );

          await tester.pumpWidget(wrapSkillTree(v2Repo: v2Repo));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.byKey(const Key('skillTreeV2AdminDraftBanner')),
            findsNothing,
          );

          await tester.tap(
            find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.byKey(const Key('skillTreeV2MenuAdminEditDraft')),
            findsNothing,
          );
        },
      );
    }
  });

  group('Profile Creation Navigation Regression', () {
    testWidgets(
      'submitting EditRiderProfileDialog inside GoRouter pops only the '
      'dialog and does not leave a blank screen',
      (tester) async {
        const user = User(
          id: 'new-rider-1',
          name: 'New Rider',
          email: 'newrider@example.com',
          isGuest: false,
          emailVerified: true,
        );
        var profileUpdatedCalled = false;
        registerFallbackValue(
          RiderProfile(
            id: 'fallback',
            name: 'Fallback',
            email: 'fallback@example.com',
          ),
        );
        when(
          () => harness.riders.createOrUpdateRiderProfile(
            riderProfile: any(named: 'riderProfile'),
          ),
        ).thenAnswer((_) async {});

        final router = GoRouter(
          initialLocation: '/Profile',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) =>
                  Scaffold(body: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/Profile',
                      builder: (context, state) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Profile Shell Page'),
                            ElevatedButton(
                              key: const Key('openCreateProfileDialogBtn'),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => EditRiderProfileDialog(
                                    riderProfile: null,
                                    user: user,
                                    onProfileUpdated: () {
                                      profileUpdatedCalled = true;
                                    },
                                  ),
                                );
                              },
                              child: const Text('Open Create Profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RiderProfileRepository>.value(
                value: harness.riders,
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Profile Shell Page'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('openCreateProfileDialogBtn')),
        );
        await tester.pumpAndSettle();

        // Submit the prefilled profile dialog.
        await tester.tap(find.widgetWithText(FilledButton, 'Create Profile'));
        await tester.pumpAndSettle();

        // Dialog is closed, callback fired, and GoRouter shell page remains!
        expect(
          find.widgetWithText(FilledButton, 'Create Profile'),
          findsNothing,
        );
        expect(find.text('Profile Shell Page'), findsOneWidget);
        expect(profileUpdatedCalled, isTrue);
      },
    );
  });
}
