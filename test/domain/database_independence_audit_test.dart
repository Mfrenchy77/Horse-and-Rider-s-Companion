// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:image_picker/image_picker.dart';

import '../support/app_test_harness.dart';

class _InMemoryMediaStorage implements MediaStorageRepository {
  final Map<String, Uint8List> uploads = {};
  final List<String> deleted = [];

  @override
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) async => null;

  @override
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) async => null;

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    uploads[path] = bytes;
    return 'https://cdn.example.org/$path';
  }

  @override
  Future<void> deleteByUrl(String url) async => deleted.add(url);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    DictionaryRepository.defaultStore = null;
    DictionaryRepository.invalidateCache();
  });

  group('Provider-independent Dictionary operations without Firebase', () {
    testWidgets(
      'full Dictionary lifecycle (load, search, detail, suggestion, admin draft/publish/unpublish, media upload, reactive highlighting) runs without Firebase',
      (tester) async {
        expect(Firebase.apps, isEmpty);

        final store = InMemoryDictionaryStore(
          publishedEntries: [
            DictionaryEntry({
              'id': 'trot',
              'slug': 'trot',
              'term': 'Trot',
              'definition': 'A symmetrical two-beat diagonal gait.',
              'explanation': 'Opposite front and hind legs move together.',
              'synonyms': ['jog'],
              'categories': ['Gaits'],
              'examples': ['Ride a calm trot.'],
              'media': [
                {
                  'url': 'https://cdn.example.org/dictionary/trot.png',
                  'label': 'Diagonal footfall sequence',
                },
              ],
              'status': 'published',
              'contextual': true,
              'revision': 1,
            }),
          ],
          skillLabels: {'rider.mounted.trot': 'Rider · Trot'},
        );
        DictionaryRepository.defaultStore = store;
        final repo = DictionaryRepository(store: store);

        // 1. Load, search (including synonym), and resolve individual entry.
        final initial = await DictionaryRepository.cachedEntries();
        expect(initial, hasLength(1));
        expect(
          DictionaryRepository.search(initial, query: 'jog').single.id,
          'trot',
        );
        expect(DictionaryRepository.resolve(initial, 'jog')?.id, 'trot');

        // 2. Submit a community suggestion and verify admin inbox loads it.
        await repo.call('submitDictionarySuggestion', {
          'id': 'sug-1',
          'term': 'Cavaletti',
          'proposal': 'Low raised poles used to build rhythm and balance.',
          'kind': 'missing_term',
        });
        final suggestions = await repo.loadSuggestions();
        expect(suggestions, hasLength(1));
        expect(suggestions.single['term'], 'Cavaletti');

        // 3. Save a draft (must stay private & never auto-highlight).
        await repo.call('editDictionary', {
          'action': 'save_draft',
          'id': 'cavaletti',
          'entry': {
            'id': 'cavaletti',
            'slug': 'cavaletti',
            'term': 'Cavaletti',
            'definition': 'Low raised poles used for rhythm.',
            'synonyms': <String>[],
            'categories': ['Training'],
            'contextual': true,
          },
        });
        expect((await repo.loadDraft('cavaletti'))?.published, isFalse);
        expect(await repo.loadEntryRevisions('cavaletti'), hasLength(1));

        // 4. Mount an open contextual text screen; 'trot' highlights, draft 'cavaletti' does not.
        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: ContextualDictionaryText(
                  text: 'Warm up at a calm trot before riding cavaletti.',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextButton, 'trot'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'cavaletti'), findsNothing);

        // 5. Publish 'Cavaletti' via store & refresh reactive cache -> open screen updates!
        await repo.call('editDictionary', {
          'action': 'publish',
          'id': 'cavaletti',
          'entry': {
            'id': 'cavaletti',
            'slug': 'cavaletti',
            'term': 'Cavaletti',
            'definition': 'Low raised poles used for rhythm.',
            'synonyms': <String>[],
            'categories': ['Training'],
            'contextual': true,
          },
        });
        await DictionaryRepository.refreshCachedEntries();
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextButton, 'cavaletti'), findsOneWidget);

        // 6. Unpublish 'Cavaletti' -> highlight disappears on refresh.
        await repo.call('editDictionary', {
          'action': 'unpublish',
          'id': 'cavaletti',
        });
        await DictionaryRepository.refreshCachedEntries();
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextButton, 'cavaletti'), findsNothing);

        // 7. Public Dictionary detail & Admin page render via InMemoryDictionaryStore + InMemoryMediaStorage.
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            isGuest: false,
            usersProfile: RiderProfile(
              id: 'admin',
              email: 'admin@example.com',
              name: 'Admin',
            ),
            user: const User(
              id: 'uid-admin',
              email: 'admin@example.com',
              name: 'Admin',
              isGuest: false,
              emailVerified: true,
              isAdmin: true,
            ),
          ),
        );
        final mediaStorage = _InMemoryMediaStorage();
        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: DictionaryPage(slug: 'trot', repository: repo),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Trot'), findsOneWidget);
        expect(find.text('Diagonal footfall sequence'), findsOneWidget);

        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: DictionaryAdminPage(
                repository: repo,
                mediaStorage: mediaStorage,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cavaletti'), findsOneWidget);
        expect(Firebase.apps, isEmpty);
      },
    );
  });

  group('Provider-independent Skill Tree 2.0 operations without Firebase', () {
    testWidgets(
      'curriculum loading, assessment progress, instructor verification, drafts, suggestions, and SkillTreeV2View run without Firebase',
      (tester) async {
        expect(Firebase.apps, isEmpty);

        final inMemoryStore = InMemorySkillTreeV2Store();
        final hybridStore = HybridCurriculumSkillTreeV2Store(
          primaryStore: inMemoryStore,
        );
        final skillRepo = SkillTreeV2Repository(store: hybridStore);

        // 1. Load full V2 curriculum from local assets (zero Firestore reads).
        final families = (await tester.runAsync(skillRepo.fetchFamilies))!;
        final skills = (await tester.runAsync(skillRepo.fetchSkills))!;
        expect(families, hasLength(33));
        expect(skills, hasLength(84));

        // 2. Record independent Rider progress and instructor verification.
        await skillRepo.setLevelProgress(
          subject: SkillSubject.rider,
          profileDocId: 'rider-1',
          skillId: 'rider.mounted.trot',
          level: DifficultyState.Intermediate,
          state: LevelState.PROFICIENT,
          actorUid: 'rider-1',
          actorName: 'Alex Rider',
        );
        inMemoryStore.applyVerificationLocally(
          subject: SkillSubject.rider,
          profileDocId: 'rider-1',
          skillId: 'rider.mounted.trot',
          skillName: 'Trot',
          level: DifficultyState.Intermediate,
          verified: true,
          coachUid: 'coach-1',
          coachName: 'Coach Alex',
        );

        final progress = await skillRepo.fetchProgress(
          subject: SkillSubject.rider,
          profileDocId: 'rider-1',
        );
        final verifications = await skillRepo.fetchVerifications(
          subject: SkillSubject.rider,
          profileDocId: 'rider-1',
        );
        final events = await skillRepo.fetchVerificationEvents(
          subject: SkillSubject.rider,
          profileDocId: 'rider-1',
        );
        expect(
          progress['rider.mounted.trot']
              ?.levels[DifficultyState.Intermediate]
              ?.state,
          LevelState.PROFICIENT,
        );
        expect(
          verifications['rider.mounted.trot']
              ?.levels[DifficultyState.Intermediate]
              ?.verifiedByName,
          'Coach Alex',
        );
        expect(events, hasLength(1));

        // 3. Drafts & Suggestions work through provider-independent stores.
        final draftStore = InMemorySkillTreeDraftStore();
        final draftRepo = SkillTreeDraftRepository(store: draftStore);
        final savedDraft = await draftRepo.saveDraft(
          SkillTreeCurriculumDraft(families: families, skills: skills),
        );
        expect(savedDraft.skills, hasLength(84));
        expect((await draftRepo.fetchDraft())?.families, hasLength(33));

        final suggestionsStore = InMemorySkillTreeSuggestionsStore();
        await suggestionsStore.submitSuggestion(
          const SkillTreeSuggestionDraft(
            subject: 'rider',
            realm: 'Mounted',
            contributionCategory: SuggestionCategory.newSkillProposal,
            title: 'Garrocha Balance',
            description:
                'Add a short introductory safety note about carrying a pole.',
          ),
        );
        expect(
          await suggestionsStore.fetchMySuggestions(submitterUid: 'local-user'),
          hasLength(1),
        );

        // 4. SkillTreeV2View renders using injected repository without Firebase.
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);
        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: SkillTreeV2View(repository: skillRepo),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(SkillTreeV2View), findsOneWidget);
        expect(
          find.byKey(const Key('skillTreeV2AppBarBackButton')),
          findsOneWidget,
        );
        expect(Firebase.apps, isEmpty);
      },
    );
  });
}
