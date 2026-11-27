// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_contribution_auth.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_image_contribution_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_suggestion_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:image_picker/image_picker.dart';

import '../support/app_test_harness.dart';

class _TrackingDictionaryStore extends InMemoryDictionaryStore {
  _TrackingDictionaryStore({
    super.publishedEntries,
    super.suggestions,
    super.contributorDirectory,
  });

  final List<List<String>> resolveCalls = [];

  @override
  Future<Map<String, Map<String, dynamic>>> resolveContributorIdentities(
    List<String> uids,
  ) {
    resolveCalls.add(List<String>.from(uids));
    return super.resolveContributorIdentities(uids);
  }
}

class _FakeMediaStorage implements MediaStorageRepository {
  @override
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) async => null;

  @override
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) async => null;

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return 'https://firebasestorage.googleapis.com/v0/b/demo/o/'
        '${Uri.encodeComponent(path)}?alt=media&token=tok';
  }

  @override
  Future<void> deleteByUrl(String url) async {}
}

Uint8List _minimalPng() => Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x00,
  0x00,
  0x02,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x72,
  0xB6,
  0x0D,
  0x24,
  0x00,
  0x00,
  0x00,
  0x12,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x40,
  0x00,
  0xC0,
  0xFF,
  0x0F,
  0x05,
  0x00,
  0x09,
  0xFB,
  0x03,
  0xFD,
  0xE7,
  0x63,
  0x7A,
  0x8F,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<DictionaryEntry> seedEntries;
  late AppTestHarness harness;

  setUp(() async {
    DictionaryRepository.invalidateCache();
    seedEntries = await DictionaryRepository.cachedEntries();
    harness = await AppTestHarness.create();
  });

  tearDown(() => harness.close());

  Widget wrap(Widget child) => BlocProvider<AppCubit>.value(
    value: harness.cubit,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: mainThemeDark,
      home: child,
    ),
  );

  void signIn({
    String uid = 'uid-rider',
    String email = 'rider@example.com',
    String authName = 'Auth Name',
    String profileName = 'Profile Rider',
    bool admin = false,
  }) {
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(id: uid, email: email, name: profileName),
        user: User(
          id: uid,
          email: email,
          name: authName,
          isGuest: false,
          emailVerified: true,
          isAdmin: admin,
        ),
      ),
    );
  }

  group('Automatic Dictionary Contributor Identity & Public Attribution', () {
    testWidgets(
      'users with an existing profile name never enter their name manually across suggestions, edits, or image contributions, and privacy checkbox defaults unchecked',
      (tester) async {
        tester.view.physicalSize = const Size(980, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signIn(profileName: 'Morgan Saddle', authName: 'Morgan Auth');
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final store = InMemoryDictionaryStore(
          publishedEntries: seedEntries,
          activeContributorUid: 'uid-rider',
          contributorDirectory: {
            'uid-rider': {
              'displayName': 'Morgan Saddle',
              'email': 'rider@example.com',
              'source': 'profile',
            },
          },
        );
        final repo = DictionaryRepository(store: store);

        // 1. New term suggestion: unchecked by default -> submits privately without publicName.
        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: DictionarySuggestionDialog(
                repository: repo,
                availableCategories: const ['Gaits'],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final consentBox = tester.widget<CheckboxListTile>(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        expect(consentBox.value, isFalse);
        expect(
          find.text('Credit me publicly if this contribution is approved'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryPublicNameField')),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const Key('newTermField_term')),
          'Volte',
        );
        await tester.enterText(
          find.byKey(const Key('newTermField_definition')),
          'A small balanced circle typically six meters across.',
        );
        await tester.ensureVisible(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        await tester.tap(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        await tester.pumpAndSettle();

        // Automatically previews profile display name; manual field never shown.
        expect(
          find.byKey(const Key('dictionaryPublicCreditPreview')),
          findsOneWidget,
        );
        expect(
          find.text('Proposed public credit: Morgan Saddle'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryPublicNameField')),
          findsNothing,
        );

        final submitBtn = find.byKey(
          const Key('dictionarySubmitSuggestionButton'),
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(store.executedActions.last.$2['recognitionConsent'], isTrue);
        expect(
          store.executedActions.last.$2.containsKey('publicName'),
          isFalse,
        );

        // 2. Improvement/edit dialog uses automatic profile credit in Review Changes too.
        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: DictionarySuggestionDialog(
                key: const Key('editModeDialog'),
                repository: repo,
                entry: canter,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('suggestionField_explanation')),
          'Describe inside bend cleanly across disciplines.',
        );
        await tester.ensureVisible(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        await tester.tap(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('dictionaryReviewChangesButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Public credit if approved: Morgan Saddle'),
          findsOneWidget,
        );

        // 3. Image contribution dialog never asks for manual name when profile has a display name.
        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: DictionaryImageContributionDialog(
                repository: repo,
                entry: canter,
                mediaStorage: _FakeMediaStorage(),
                pickImages: () async => [
                  (name: 'diagram.png', bytes: _minimalPng()),
                ],
                processImage: ({required bytes, required fileName}) async =>
                    ProcessedDictionaryImage(
                      fileName: fileName,
                      bytes: bytes,
                      contentType: 'image/png',
                      sha256: 'a'.padRight(64, '0'),
                      originalByteLength: bytes.length,
                      wasResized: false,
                    ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('dictionaryPickCommunityImagesButton')),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('dictionaryImageRightsCheckbox')),
        );
        await tester.tap(
          find.byKey(const Key('dictionaryImageRightsCheckbox')),
        );
        await tester.ensureVisible(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        await tester.tap(
          find.byKey(const Key('dictionaryRecognitionConsentCheckbox')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryPublicCreditPreview')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryPublicNameField')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'falls back cleanly when profile name is missing, rejects emails, and allows blank fallback or profile setup link',
      (tester) async {
        tester.view.physicalSize = const Size(980, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Missing profile name -> falls back to Auth display name if suitable.
        signIn(profileName: '', authName: 'Jordan Trail');
        final identityWithAuth = DictionaryContributorIdentity.fromAppState(
          harness.cubit.state,
        );
        expect(identityWithAuth.resolvedPublicDisplayName, 'Jordan Trail');
        expect(identityWithAuth.hasSuitablePublicName, isTrue);

        // 2. Email-only / guest / missing names -> exposes missing-name notice & optional fallback.
        signIn(profileName: 'rider@example.com', authName: 'Guest');
        var openedProfile = false;
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final formKey = GlobalKey<FormState>();

        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: Form(
                key: formKey,
                child: Builder(
                  builder: (context) => DictionaryContributorAttributionSection(
                    identity: DictionaryContributorIdentity.fromContext(
                      context,
                    ),
                    requireRightsConfirmation: false,
                    rightsConfirmed: true,
                    onRightsChanged: (_) {},
                    recognitionConsent: true,
                    onRecognitionConsentChanged: (_) {},
                    publicNameController: controller,
                    busy: false,
                    onOpenProfile: () => openedProfile = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryMissingProfileNameNotice')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryOpenProfileForNameButton')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryPublicNameField')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('dictionaryOpenProfileForNameButton')),
        );
        expect(openedProfile, isTrue);

        // Rejects email addresses typed into fallback field.
        await tester.enterText(
          find.byKey(const Key('dictionaryPublicNameField')),
          'leak@example.com',
        );
        expect(formKey.currentState!.validate(), isFalse);

        // Leaving optional fallback blank validates cleanly (publishes without credit).
        await tester.enterText(
          find.byKey(const Key('dictionaryPublicNameField')),
          '',
        );
        expect(formKey.currentState!.validate(), isTrue);
      },
    );

    testWidgets(
      'DictionaryAdminPage shows private contributor audit metadata, batches legacy UID resolution, opens contributor history, and keeps public entries private',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 980);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signIn(
          uid: 'uid-admin',
          email: 'admin@example.com',
          profileName: 'Chief Editor',
          admin: true,
        );

        final store = _TrackingDictionaryStore(
          publishedEntries: seedEntries,
          contributorDirectory: {
            'uid-legacy-1': {
              'displayName': 'Legacy Cowboy',
              'email': 'legacy@example.com',
              'source': 'auth',
            },
          },
          suggestions: [
            {
              'id': 'sug-snap-1',
              'term': 'Canter',
              'termId': 'canter',
              'kind': 'image_contribution',
              'status': 'submitted',
              'rightsConfirmed': true,
              'recognitionConsent': false,
              'publicName': null,
              'contributorUid': 'uid-alex-1',
              'contributorSnapshot': {
                'displayName': 'Alex Bridle',
                'email': 'alex.bridle@example.com',
                'source': 'profile',
              },
              'createdAt': '2026-11-26T15:30:00Z',
              'submittedImages': [
                {
                  'id': 'img1',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-alex-1%2Fsug-snap-1%2Flead.png?alt=media&token=t1',
                  'caption': 'Left lead frame',
                  'reviewStatus': 'pending',
                },
              ],
            },
            {
              'id': 'sug-legacy-1',
              'term': 'Green',
              'termId': 'green',
              'kind': 'correction',
              'proposal': 'Clarify introductory ranch usage.',
              'status': 'published',
              'recognitionConsent': true,
              'publicName': 'Legacy Cowboy',
              'contributorUid': 'uid-legacy-1',
              'createdAt': '2026-11-20T10:15:00Z',
            },
            {
              'id': 'sug-legacy-2',
              'term': 'Trot',
              'termId': 'trot',
              'kind': 'missing_term',
              'proposal': 'Two-beat diagonal gait.',
              'status': 'submitted',
              'recognitionConsent': false,
              'contributorUid': 'uid-legacy-1',
              'createdAt': '2026-11-21T12:00:00Z',
            },
          ],
        );
        final repo = DictionaryRepository(store: store);

        await tester.pumpWidget(wrap(DictionaryAdminPage(repository: repo)));
        await tester.pumpAndSettle();

        // Single batched lookup resolves legacy UID once without per-card N+1 calls.
        expect(store.resolveCalls, hasLength(1));
        expect(store.resolveCalls.single, ['uid-legacy-1']);

        // Snapshot submission shows full private identity & private credit preference.
        expect(
          find.byKey(const Key('adminContributorPanel_sug-snap-1')),
          findsOneWidget,
        );
        expect(find.textContaining('Alex Bridle'), findsOneWidget);
        expect(find.textContaining('alex.bridle@example.com'), findsOneWidget);
        expect(find.textContaining('uid-alex-1'), findsOneWidget);
        expect(
          find.textContaining('No (private — do not credit publicly)'),
          findsWidgets,
        );

        // Legacy submissions show resolved account details, badge, and history count.
        expect(find.textContaining('legacy@example.com'), findsWidgets);
        expect(find.text('Resolved from account'), findsWidgets);
        expect(find.text('2 submissions · 1 published'), findsWidgets);

        // Clicking Contributor history opens full chronological history dialog.
        final historyBtn = find.descendant(
          of: find.byKey(const Key('adminContributorPanel_sug-legacy-1')),
          matching: find.text('Contributor history'),
        );
        await tester.ensureVisible(historyBtn);
        await tester.tap(historyBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('adminContributorHistoryDialog')),
          findsOneWidget,
        );
        expect(
          find.text('Contributor History · Legacy Cowboy'),
          findsOneWidget,
        );
        await tester.tap(find.text('Close').last);
        await tester.pumpAndSettle();

        // Approve & publish unchecked image submission keeps attribution off public entry.
        final quickPublishBtn = find.byKey(
          const Key('approveAndPublishButton_sug-snap-1'),
        );
        await tester.ensureVisible(quickPublishBtn);
        await tester.tap(quickPublishBtn);
        await tester.pumpAndSettle();
        final publishAction = find.byKey(
          const Key('confirmApproveAndPublishButton'),
        );
        await tester.ensureVisible(publishAction);
        await tester.tap(publishAction);
        await tester.pumpAndSettle();

        final published = await store.loadPublishedEntries();
        final canterEntry = published.firstWhere((e) => e.id == 'canter');
        expect(canterEntry.data.toString(), isNot(contains('alex.bridle')));
        expect(canterEntry.data.toString(), isNot(contains('uid-alex-1')));
        expect(canterEntry.data['attributions'], isEmpty);
      },
    );

    testWidgets(
      'Approve & Publish succeeds on seeded DictionaryEntries without publishedAt (Withers regression) and preserves stale revision protection',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 980);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signIn(
          uid: 'uid-admin',
          email: 'admin@example.com',
          profileName: 'Chief Editor',
          admin: true,
        );

        // Simulate Firestore-seeded "withers": bundled: false, revision: 1, no publishedAt.
        final bundledWithers = DictionaryRepository.resolve(
          seedEntries,
          'withers',
        )!;
        final seededFirestoreWithers = DictionaryEntry({
          ...bundledWithers.data,
          'revision': 1,
          'status': 'published',
        });
        expect(seededFirestoreWithers.bundled, isFalse);
        expect(seededFirestoreWithers.publishedRevision, 0);
        expect(seededFirestoreWithers.storedRevision, 1);

        final store = _TrackingDictionaryStore(
          publishedEntries: [
            for (final e in seedEntries)
              if (e.id == 'withers') seededFirestoreWithers else e,
          ],
          suggestions: [
            {
              'id': 'sug-withers-1',
              'term': 'Withers',
              'termId': 'withers',
              'kind': 'image_contribution',
              'status': 'submitted',
              'rightsConfirmed': true,
              'recognitionConsent': false,
              'contributorUid': 'uid-rider',
              'contributorSnapshot': {
                'displayName': 'Morgan Saddle',
                'email': 'rider@example.com',
                'source': 'profile',
              },
              'createdAt': '2026-11-26T16:00:00Z',
              'submittedImages': [
                {
                  'id': 'img_withers',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-rider%2Fsug-withers-1%2Fwithers.png?alt=media&token=tw1',
                  'caption': 'Measuring height at the withers',
                  'reviewStatus': 'pending',
                },
              ],
            },
          ],
        );
        final repo = DictionaryRepository(store: store);

        await tester.pumpWidget(wrap(DictionaryAdminPage(repository: repo)));
        await tester.pumpAndSettle();

        final approvePublishBtn = find.byKey(
          const Key('approveAndPublishButton_sug-withers-1'),
        );
        await tester.ensureVisible(approvePublishBtn);
        await tester.tap(approvePublishBtn);
        await tester.pumpAndSettle();

        final confirmBtn = find.byKey(
          const Key('confirmApproveAndPublishButton'),
        );
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('approveAndPublishSuccessView')),
          findsOneWidget,
        );
        final publishAction = store.executedActions.singleWhere(
          (call) =>
              call.$1 == 'editDictionary' &&
              call.$2['action'] == 'approve_and_publish',
        );
        expect(publishAction.$2['expectedRevision'], 1);

        final updatedWithers = (await store.loadPublishedEntries()).firstWhere(
          (e) => e.id == 'withers',
        );
        expect(updatedWithers.storedRevision, 2);
        expect(updatedWithers.data['media'], hasLength(1));

        // Concurrency protection remains enforced when expectedRevision is stale.
        await repo.call('submitDictionarySuggestion', {
          'submissionId': 'sug-withers-2',
          'term': 'Withers',
          'termId': 'withers',
          'kind': 'image_contribution',
          'rightsConfirmed': true,
          'submittedImages': [
            {
              'id': 'img_withers_2',
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-rider%2Fsug-withers-2%2Fwithers2.png?alt=media&token=tw2',
              'caption': 'Saddle clearance',
            },
          ],
        });
        await expectLater(
          () => repo.approveAndPublishImages(
            suggestionId: 'sug-withers-2',
            expectedRevision: 1,
            imageDecisions: [
              {'id': 'img_withers_2', 'status': 'approved'},
            ],
          ),
          throwsStateError,
        );
      },
    );

    testWidgets(
      'admins can suspend and restore a contributor with backend enforcement, private audit trail, and preserved existing contributions',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 980);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signIn(
          uid: 'uid-admin',
          email: 'admin@example.com',
          profileName: 'Chief Editor',
          admin: true,
        );

        final store = _TrackingDictionaryStore(
          publishedEntries: seedEntries,
          suggestions: [
            {
              'id': 'sug-mod-target-1',
              'term': 'Withers',
              'termId': 'withers',
              'kind': 'missing_term',
              'proposal': 'Ridge between shoulder blades.',
              'status': 'submitted',
              'recognitionConsent': false,
              'contributorUid': 'uid-member-9',
              'contributorSnapshot': {
                'displayName': 'Casey Bridle',
                'email': 'casey@example.com',
                'source': 'profile',
              },
              'createdAt': '2026-11-26T14:00:00Z',
            },
          ],
        );
        final repo = DictionaryRepository(store: store);

        await tester.pumpWidget(wrap(DictionaryAdminPage(repository: repo)));
        await tester.pumpAndSettle();

        // 1. Suspend contributor from the private contributor panel.
        final suspendBtn = find.byKey(
          const Key('adminModerateContributorButton_uid-member-9'),
        );
        await tester.ensureVisible(suspendBtn);
        await tester.tap(suspendBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('adminContributorModerationDialog')),
          findsOneWidget,
        );
        // Blank reason is rejected on suspend.
        await tester.tap(
          find.byKey(const Key('confirmContributorModerationButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a private reason for this moderation action.'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('adminModerationReasonField')),
          'Multiple off-topic submissions.',
        );
        await tester.tap(
          find.byKey(const Key('confirmContributorModerationButton')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dictionary suspended'), findsOneWidget);
        expect(
          find.text('Suspension reason: Multiple off-topic submissions.'),
          findsOneWidget,
        );
        // Existing contribution remains intact.
        expect(find.text('Withers'), findsOneWidget);

        // Backend enforcement rejects new submissions from suspended UID.
        await expectLater(
          () => repo.call('submitDictionarySuggestion', {
            'submissionId': 'sug-blocked-99',
            'term': 'Poll',
            'proposal': 'Area behind the ears.',
            'kind': 'missing_term',
            'contributorUid': 'uid-member-9',
            'recognitionConsent': false,
          }),
          throwsStateError,
        );

        // 2. Open Contributor history -> shows private moderation audit trail & Restore option.
        final historyBtn = find.descendant(
          of: find.byKey(const Key('adminContributorPanel_sug-mod-target-1')),
          matching: find.text('Contributor history'),
        );
        await tester.ensureVisible(historyBtn);
        await tester.tap(historyBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('adminContributorModerationHistory')),
          findsOneWidget,
        );
        expect(find.textContaining('Suspended'), findsWidgets);
        await tester.tap(find.text('Close').last);
        await tester.pumpAndSettle();

        // 3. Restore contributor privileges -> submission works again and audit trail grows.
        final restoreBtn = find.byKey(
          const Key('adminModerateContributorButton_uid-member-9'),
        );
        await tester.ensureVisible(restoreBtn);
        await tester.tap(restoreBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('adminModerationReasonField')),
          'Reviewed expectations together.',
        );
        await tester.tap(
          find.byKey(const Key('confirmContributorModerationButton')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dictionary suspended'), findsNothing);
        await repo.call('submitDictionarySuggestion', {
          'submissionId': 'sug-after-restore',
          'term': 'Poll',
          'proposal': 'Top of the head between the ears.',
          'kind': 'missing_term',
          'contributorUid': 'uid-member-9',
          'recognitionConsent': false,
        });
        final audit = await store.loadContributorModerationHistory(
          'uid-member-9',
        );
        expect(audit, hasLength(2));
        expect(audit.first['action'], 'restore');
        expect(audit.last['action'], 'suspend');
      },
    );
  });
}
