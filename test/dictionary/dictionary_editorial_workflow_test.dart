// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:photo_view/photo_view.dart';

import '../support/app_test_harness.dart';

class _ControlledDictionaryStore extends InMemoryDictionaryStore {
  _ControlledDictionaryStore({super.publishedEntries, super.suggestions});

  bool failApproveAndPublish = false;
  bool holdApproveAndPublish = false;
  int approveAndPublishCount = 0;

  @override
  Future<void> executeAction(
    String actionName,
    Map<String, dynamic> data,
  ) async {
    if (actionName == 'editDictionary' &&
        data['action'] == 'approve_and_publish') {
      approveAndPublishCount++;
      if (holdApproveAndPublish) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (failApproveAndPublish) {
        throw StateError('Simulated publication failure');
      }
    }
    return super.executeAction(actionName, data);
  }
}

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

  void signInVerifiedAdmin() {
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
  }

  void signInOrdinaryMember() {
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(
          id: 'member',
          email: 'member@example.com',
          name: 'Regular Rider',
        ),
        user: const User(
          id: 'uid-member',
          email: 'member@example.com',
          name: 'Regular Rider',
          isGuest: false,
          emailVerified: true,
        ),
      ),
    );
  }

  group('Streamlined Dictionary Editorial Workflow', () {
    testWidgets(
      'permission enforcement blocks ordinary users and Approve & Publish preserves full-size preview, hero selection, partial multi-image approval, and audit history',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Permission enforcement: ordinary verified user is blocked.
        signInOrdinaryMember();
        await tester.pumpWidget(wrap(const DictionaryAdminPage()));
        await tester.pumpAndSettle();
        expect(find.text('Administrator access required.'), findsOneWidget);
        expect(find.byKey(const Key('dictionaryAdminNewButton')), findsNothing);

        // 2. Sign in as verified administrator with an existing published image
        // on Canter and a multi-image submission with metadata.
        signInVerifiedAdmin();
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final enrichedCanter = DictionaryEntry({
          ...canter.data,
          'revision': 1,
          'publishedAt': '2026-11-20T00:00:00Z',
          'media': [
            {
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fexisting.png?alt=media&token=e1',
              'label': 'Original stride overview',
            },
          ],
        });
        final store = _ControlledDictionaryStore(
          publishedEntries: [
            for (final entry in seedEntries)
              if (entry.id == 'canter') enrichedCanter else entry,
          ],
          suggestions: [
            {
              'id': 'sug-quick-multi-1',
              'term': 'Canter',
              'termId': 'canter',
              'kind': 'image_contribution',
              'status': 'submitted',
              'rightsConfirmed': true,
              'recognitionConsent': true,
              'publicName': 'Sam Horsemanship',
              'contributorUid': 'uid-sam',
              'submittedImages': [
                {
                  'id': 'img_gallery',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-sam%2Fsug-quick-multi-1%2Fcadence.jpg?alt=media&token=t1',
                  'caption': 'Soft arena cadence',
                  'explanation': 'Calm rhythmic stride on loose rein.',
                  'imageType': 'photograph',
                  'reviewStatus': 'pending',
                },
                {
                  'id': 'img_hero',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-sam%2Fsug-quick-multi-1%2Ffootfall.png?alt=media&token=t2',
                  'caption': 'Inside lead footfall diagram',
                  'explanation': 'Clarifies 3-beat footfall sequence.',
                  'imageType': 'diagram',
                  'reviewStatus': 'pending',
                },
                {
                  'id': 'img_reject',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-sam%2Fsug-quick-multi-1%2Fblurry.jpg?alt=media&token=t3',
                  'caption': 'Out-of-focus shot',
                  'imageType': 'photograph',
                  'reviewStatus': 'pending',
                },
              ],
            },
          ],
        );
        final repo = DictionaryRepository(store: store);

        await tester.pumpWidget(wrap(DictionaryAdminPage(repository: repo)));
        await tester.pumpAndSettle();

        // Direct inbox thumbnails, metadata, contributor credit, and permissions badge.
        expect(
          find.byKey(const Key('adminSubmittedImages_sug-quick-multi-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('adminRightsBadge_sug-quick-multi-1')),
          findsOneWidget,
        );
        expect(find.text('Permissions confirmed'), findsOneWidget);
        expect(find.text('Public credit: Sam Horsemanship'), findsOneWidget);
        expect(find.text('Soft arena cadence'), findsOneWidget);
        expect(
          find.text('Clarifies 3-beat footfall sequence.'),
          findsOneWidget,
        );

        // Full-size PhotoView preview directly from inbox without navigating away.
        await tester.ensureVisible(
          find.byKey(
            const Key('adminSubmittedImageZoom_sug-quick-multi-1_img_hero'),
          ),
        );
        await tester.tap(
          find.byKey(
            const Key('adminSubmittedImageZoom_sug-quick-multi-1_img_hero'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(PhotoView), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Primary Approve & Publish button appears directly on image submission.
        final quickPublishBtn = find.byKey(
          const Key('approveAndPublishButton_sug-quick-multi-1'),
        );
        await tester.ensureVisible(quickPublishBtn);
        await tester.tap(quickPublishBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('approveAndPublishPreviewSummary')),
          findsOneWidget,
        );

        // Select second submitted image as hero & reject blurry third image.
        final useAsHeroBtn = find.byKey(
          const Key('selectHero_submitted_img_hero'),
        );
        await tester.ensureVisible(useAsHeroBtn);
        await tester.tap(useAsHeroBtn);
        await tester.pumpAndSettle();

        final rejectBtn = find.byKey(
          const Key('quickRejectImg_sug-quick-multi-1_img_reject'),
        );
        await tester.ensureVisible(rejectBtn);
        await tester.tap(rejectBtn);
        await tester.pumpAndSettle();

        // Preview reflects selected hero, gallery count (2), and rejected count (1).
        expect(
          find.text('Hero image: Inside lead footfall diagram'),
          findsOneWidget,
        );
        expect(find.textContaining('Gallery images: 2'), findsOneWidget);
        expect(find.textContaining('Rejected images: 1'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('quickPublishNote')),
          'Lead diagram selected as hero; blurry photo rejected.',
        );

        // Confirm & Publish atomically.
        await tester.tap(
          find.byKey(const Key('confirmApproveAndPublishButton')),
        );
        await tester.pumpAndSettle();

        expect(store.approveAndPublishCount, 1);
        expect(
          find.byKey(const Key('approveAndPublishSuccessView')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryQueueEmptyMessage')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('closeAfterPublishButton')));
        await tester.pumpAndSettle();

        // Verify published Canter media order: hero at [0], existing + gallery at [1..2].
        final updatedEntries = await repo.load();
        final updatedCanter = DictionaryRepository.resolve(
          updatedEntries,
          'canter',
        )!;
        final media = (updatedCanter.data['media'] as List<dynamic>)
            .cast<Map<dynamic, dynamic>>();
        expect(media, hasLength(3));
        expect(media[0]['label'], 'Inside lead footfall diagram');
        expect(media[0]['imageType'], 'diagram');
        expect(media[0]['attribution'], 'Sam Horsemanship');
        expect(media[1]['label'], 'Original stride overview');
        expect(media[2]['label'], 'Soft arena cadence');

        // Review history preserves both decision & publication audit events.
        final historyBtn = find.widgetWithText(TextButton, 'History');
        await tester.ensureVisible(historyBtn);
        await tester.tap(historyBtn);
        await tester.pumpAndSettle();
        expect(find.text('published'), findsWidgets);
        expect(find.text('partially approved'), findsWidgets);
        expect(
          find.text('Lead diagram selected as hero; blurry photo rejected.'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'duplicate publication protection, publication failure handling, and Next Submission queue flow behave safely',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInVerifiedAdmin();
        final store = _ControlledDictionaryStore(
          publishedEntries: seedEntries,
          suggestions: [
            {
              'id': 'sug-queue-1',
              'term': 'Canter',
              'termId': 'canter',
              'kind': 'image_contribution',
              'status': 'submitted',
              'rightsConfirmed': true,
              'submittedImages': [
                {
                  'id': 'img_one',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fu1%2Fsug-queue-1%2Fone.png?alt=media&token=1',
                  'caption': 'Canter lead stride',
                  'imageType': 'photograph',
                  'reviewStatus': 'pending',
                },
              ],
            },
            {
              'id': 'sug-queue-2',
              'term': 'Withers',
              'termId': 'withers',
              'kind': 'image_contribution',
              'status': 'submitted',
              'rightsConfirmed': true,
              'submittedImages': [
                {
                  'id': 'img_two',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fu2%2Fsug-queue-2%2Ftwo.png?alt=media&token=2',
                  'caption': 'Withers confirmation landmark',
                  'imageType': 'diagram',
                  'reviewStatus': 'pending',
                },
              ],
            },
          ],
        );
        final repo = DictionaryRepository(store: store);

        await tester.pumpWidget(wrap(DictionaryAdminPage(repository: repo)));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryPendingQueueBar')),
          findsOneWidget,
        );
        expect(
          find.text('2 pending submissions ready for review'),
          findsOneWidget,
        );

        // Open Approve & Publish on first submission.
        await tester.tap(
          find.byKey(const Key('approveAndPublishButton_sug-queue-1')),
        );
        await tester.pumpAndSettle();

        // 1. Publication failure displays error cleanly and leaves live Canter untouched.
        store.failApproveAndPublish = true;
        await tester.tap(
          find.byKey(const Key('confirmApproveAndPublishButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('quickPublishErrorBanner')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('approveAndPublishSuccessView')),
          findsNothing,
        );
        expect(
          DictionaryRepository.resolve(
            await repo.load(),
            'canter',
          )!.data['media'],
          isEmpty,
        );

        // 2. Recover and double-tap rapidly while request is held in flight ->
        // duplicate click protection executes backend action only once.
        store
          ..failApproveAndPublish = false
          ..holdApproveAndPublish = true
          ..approveAndPublishCount = 0;

        await tester.tap(
          find.byKey(const Key('confirmApproveAndPublishButton')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('confirmApproveAndPublishButton')),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(store.approveAndPublishCount, 1);
        expect(
          find.byKey(const Key('approveAndPublishSuccessView')),
          findsOneWidget,
        );

        // 3. Republishing an already-published submission at repository level fails cleanly.
        store.holdApproveAndPublish = false;
        await expectLater(
          () => repo.approveAndPublishImages(
            suggestionId: 'sug-queue-1',
            expectedRevision: 1,
            imageDecisions: [
              {'id': 'img_one', 'status': 'approved'},
            ],
          ),
          throwsStateError,
        );

        // 4. Click "Next Submission" to jump straight to Withers (#2).
        await tester.tap(
          find.byKey(const Key('nextSubmissionAfterPublishButton')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Approve & Publish · Withers'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('confirmApproveAndPublishButton')),
        );
        await tester.pumpAndSettle();

        // Queue is now empty: clear completion message is shown.
        expect(
          find.byKey(const Key('dictionaryQueueEmptyMessage')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('closeAfterPublishButton')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('inboxQueueCaughtUpBanner')),
          findsOneWidget,
        );
      },
    );
  });
}
