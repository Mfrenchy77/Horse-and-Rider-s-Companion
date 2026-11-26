// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_image_contribution_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_my_contributions_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../support/app_test_harness.dart';

Uint8List _pngBytes([int seed = 1]) => Uint8List.fromList([
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
  seed & 0xFF,
]);

Uint8List _jpegBytes([int seed = 2]) => Uint8List.fromList([
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  seed & 0xFF,
]);

class _FakeCommunityMediaStorage implements MediaStorageRepository {
  final List<({String path, int byteLength, String? contentType})> uploads = [];
  final List<String> deletedUrls = [];
  bool failNextUpload = false;

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
    onProgress?.call(0.35);
    await Future<void>.delayed(Duration.zero);
    if (failNextUpload) {
      failNextUpload = false;
      throw StateError('Simulated network interruption');
    }
    onProgress?.call(1);
    uploads.add((
      path: path,
      byteLength: bytes.length,
      contentType: contentType,
    ));
    return 'https://firebasestorage.googleapis.com/v0/b/demo/o/'
        '${Uri.encodeComponent(path)}?alt=media&token=tok${uploads.length}';
  }

  @override
  Future<void> deleteByUrl(String url) async {
    deletedUrls.add(url);
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

  void signInVerifiedMember() {
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(
          id: 'member',
          email: 'rider@example.com',
          name: 'Alex Trail',
        ),
        user: const User(
          id: 'uid-member-1',
          email: 'rider@example.com',
          name: 'Alex Trail',
          isGuest: false,
          emailVerified: true,
        ),
      ),
    );
  }

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

  group('Community Dictionary Contributions', () {
    testWidgets(
      'signed-out visitors see friendly Create Account & Sign In prompt for Contribute Images',
      (tester) async {
        harness.cubit.emit(harness.cubit.state.copyWith(isGuest: true));
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final repo = DictionaryRepository(
          store: InMemoryDictionaryStore(publishedEntries: seedEntries),
        );

        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: DictionaryImageContributionDialog(
                repository: repo,
                entry: canter,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryAuthRequiredPrompt')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryCreateAccountButton')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('dictionarySignInButton')), findsOneWidget);
        expect(
          find.byKey(const Key('submitImageContributionButton')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'contribute images validates types, deduplicates SHA-256, recovers from failed upload, enforces rights checkbox & max 3, and cleans up removed temp uploads',
      (tester) async {
        tester.view.physicalSize = const Size(900, 980);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInVerifiedMember();
        final storage = _FakeCommunityMediaStorage()..failNextUpload = true;
        final store = InMemoryDictionaryStore(publishedEntries: seedEntries);
        final repo = DictionaryRepository(store: store);
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;

        final img1 = _pngBytes(11);
        final img2 = _jpegBytes(22);
        final img3 = _pngBytes(33);
        final img4 = _jpegBytes(44);
        var batchIndex = 0;
        final pickBatches = <List<DictionaryPickedImage>>[
          // 1. Disallowed GIF -> rejected cleanly with validation error
          [
            (
              name: 'bad.gif',
              bytes: Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
            ),
          ],
          // 2. First upload fails once (retry recovers) + duplicate skipped
          [
            (name: 'footfall_one.png', bytes: img1),
            (name: 'dup.png', bytes: img1),
          ],
          // 3. Add 2 more images to reach max 3, plus a 4th that hits limit notice
          [
            (name: 'stride_two.jpg', bytes: img2),
            (name: 'lead_three.png', bytes: img3),
            (name: 'extra_four.jpg', bytes: img4),
          ],
        ];

        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: DictionaryImageContributionDialog(
                repository: repo,
                entry: canter,
                mediaStorage: storage,
                pickImages: () async => batchIndex < pickBatches.length
                    ? pickBatches[batchIndex++]
                    : const [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final pickBtn = find.byKey(
          const Key('dictionaryPickCommunityImagesButton'),
        );

        // 1. Invalid GIF
        await tester.tap(pickBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryCommunityImageError')),
          findsOneWidget,
        );
        expect(find.text('Images (0/3)'), findsOneWidget);

        // 2. Upload interruption + duplicate skipped
        await tester.tap(pickBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryCommunityImageNotice')),
          findsOneWidget,
        );
        expect(find.text('Images (1/3)'), findsOneWidget);
        final retryFinder = find.text('Retry upload');
        expect(retryFinder, findsOneWidget);

        await tester.ensureVisible(retryFinder);
        await tester.tap(retryFinder);
        await tester.pumpAndSettle();
        expect(retryFinder, findsNothing);
        expect(
          storage.uploads.single.path,
          startsWith('dictionary_submissions/uid-member-1/'),
        );

        // 3. Hit max 3/3 limit (4th image skipped with limit notice)
        await tester.ensureVisible(pickBtn);
        await tester.tap(pickBtn);
        await tester.pumpAndSettle();
        expect(find.text('Images (3/3)'), findsOneWidget);
        expect(tester.widget<OutlinedButton>(pickBtn).onPressed, isNull);

        // Remove 3rd image before submit -> deletes temp upload from storage
        final removeThird = find.byKey(const Key('communityImageRemove_2'));
        await tester.ensureVisible(removeThird);
        await tester.tap(removeThird);
        await tester.pumpAndSettle();
        expect(find.text('Images (2/3)'), findsOneWidget);
        expect(storage.deletedUrls, hasLength(1));

        // Add caption and educational explanation to image 1
        await tester.enterText(
          find.byKey(const Key('communityImageCaption_0')),
          'Right lead alignment',
        );
        await tester.enterText(
          find.byKey(const Key('communityImageExplanation_0')),
          'Shows inside hind leg stepping beneath rider balance.',
        );

        // Submitting without confirming rights must be blocked cleanly
        final submitBtn = find.byKey(
          const Key('submitImageContributionButton'),
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryContributionError')),
          findsOneWidget,
        );

        // Confirm rights & opt in to public attribution (without email)
        final rightsCheckbox = find.byKey(
          const Key('dictionaryImageRightsCheckbox'),
        );
        await tester.ensureVisible(rightsCheckbox);
        await tester.tap(rightsCheckbox);
        await tester.pumpAndSettle();

        final consentCheckbox = find.byKey(
          const Key('dictionaryRecognitionConsentCheckbox'),
        );
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('dictionaryPublicNameField')),
          'Alex Trail',
        );

        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryImageContributionSuccess')),
          findsOneWidget,
        );
        final recorded = store.executedActions.single;
        expect(recorded.$1, 'submitDictionarySuggestion');
        expect(recorded.$2['kind'], 'image_contribution');
        expect(recorded.$2['rightsConfirmed'], isTrue);
        expect(recorded.$2['recognitionConsent'], isTrue);
        expect(recorded.$2['publicName'], 'Alex Trail');
        expect(recorded.$2['submittedImages'], hasLength(2));
        expect(recorded.$2.toString(), isNot(contains('rider@example.com')));

        // Contributor checks "My Contributions" dialog via DictionaryStore
        store.executedActions.clear();
        await repo.call('submitDictionarySuggestion', {
          ...recorded.$2,
          'contributorUid': 'uid-member-1',
        });
        await tester.pumpWidget(
          wrap(
            Scaffold(body: DictionaryMyContributionsDialog(repository: repo)),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryMyContributionsList')),
          findsOneWidget,
        );
        expect(find.textContaining('Right lead alignment'), findsOneWidget);
      },
    );

    testWidgets(
      'admin partially approves subset of community images, classifies type, incorporates without losing existing published media, and public entry opens immersive PhotoView viewer',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInVerifiedAdmin();
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final existingMediaEntry = DictionaryEntry({
          ...canter.data,
          'revision': 1,
          'publishedAt': '2026-11-20T00:00:00Z',
          'media': [
            {
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fexisting.png?alt=media&token=orig',
              'label': 'Published stride overview',
            },
          ],
        });
        final entriesWithMedia = [
          for (final entry in seedEntries)
            if (entry.id == 'canter') existingMediaEntry else entry,
        ];
        final store = InMemoryDictionaryStore(
          publishedEntries: entriesWithMedia,
          suggestions: [
            {
              'id': 'sug-media-partial-1',
              'term': 'Canter',
              'termId': 'canter',
              'kind': 'image_contribution',
              'status': 'submitted',
              'textDecision': 'rejected',
              'proposal': 'Submitted 2 educational images.',
              'contributorUid': 'uid-member-1',
              'recognitionConsent': true,
              'publicName': 'Morgan Rider',
              'baseRevision': 1,
              'submittedImages': [
                {
                  'id': 'img_good',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-member-1%2Fsug-media-partial-1%2Flead.png?alt=media&token=t1',
                  'caption': 'Canter footfall sequence',
                  'explanation': 'Clarifies inside lead footfall order.',
                  'imageType': 'illustrative',
                  'reviewStatus': 'pending',
                },
                {
                  'id': 'img_blurry',
                  'url':
                      'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-member-1%2Fsug-media-partial-1%2Fblurry.jpg?alt=media&token=t2',
                  'caption': 'Blurry photo',
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

        expect(
          find.byKey(const Key('adminSubmittedImages_sug-media-partial-1')),
          findsOneWidget,
        );

        // Open Review / edit images dialog
        final reviewImgsBtn = find.byKey(
          const Key('reviewImagesButton_sug-media-partial-1'),
        );
        await tester.ensureVisible(reviewImgsBtn);
        await tester.tap(reviewImgsBtn);
        await tester.pumpAndSettle();

        // Approve first image & classify as Technical diagram; reject second image
        final approveGood = find.byKey(
          const Key('adminImageApprove_sug-media-partial-1_img_good'),
        );
        await tester.ensureVisible(approveGood);
        await tester.tap(approveGood);
        await tester.pumpAndSettle();

        final rejectBlurry = find.byKey(
          const Key('adminImageReject_sug-media-partial-1_img_blurry'),
        );
        await tester.ensureVisible(rejectBlurry);
        await tester.tap(rejectBlurry);
        await tester.pumpAndSettle();

        final typeDropdown = find.byKey(
          const Key('adminImageType_sug-media-partial-1_img_good'),
        );
        await tester.ensureVisible(typeDropdown);
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Technical diagram').last);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('savePartialReviewButton_sug-media-partial-1')),
        );
        await tester.pumpAndSettle();

        final reviewAction = store.executedActions.last;
        expect(reviewAction.$1, 'editDictionary');
        expect(reviewAction.$2['action'], 'review');
        expect(reviewAction.$2['status'], 'partially_approved');

        // Incorporate approved image into published Canter entry without losing existing media
        final incorporateBtn = find.byKey(
          const Key('incorporateWording_sug-media-partial-1'),
        );
        await tester.ensureVisible(incorporateBtn);
        await tester.tap(incorporateBtn);
        await tester.pumpAndSettle();

        final mediaSection = find.byKey(const Key('dictionaryMediaSection'));
        expect(mediaSection, findsOneWidget);
        expect(find.text('Images (2/8)'), findsOneWidget);
        expect(
          find.descendant(
            of: mediaSection,
            matching: find.text('Published stride overview'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: mediaSection,
            matching: find.text('Canter footfall sequence'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: mediaSection,
            matching: find.text('Blurry photo'),
          ),
          findsNothing,
        );

        // Set the approved community diagram as primary image
        final setPrimaryBtn = find.byKey(
          const Key('dictionaryMediaSetPrimary_1'),
        );
        await tester.ensureVisible(setPrimaryBtn);
        await tester.tap(setPrimaryBtn);
        await tester.pumpAndSettle();

        final publishBtn = find.byKey(const Key('dictionaryPublishButton'));
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        final updatedEntries = await repo.load();
        final publishedCanter = DictionaryRepository.resolve(
          updatedEntries,
          'canter',
        )!;
        final publishedMedia = (publishedCanter.data['media'] as List<dynamic>)
            .cast<Map<dynamic, dynamic>>();
        expect(publishedMedia, hasLength(2));
        expect(publishedMedia[0]['label'], 'Canter footfall sequence');
        expect(publishedMedia[0]['imageType'], 'diagram');
        expect(publishedMedia[0]['attribution'], 'Morgan Rider');
        expect(publishedMedia[1]['label'], 'Published stride overview');

        // Render public Dictionary entry detail & verify multi-image + immersive PhotoView viewer
        await tester.pumpWidget(
          wrap(DictionaryPage(slug: 'canter', repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dictionaryHeroCaption')), findsOneWidget);
        expect(find.text('Technical diagram'), findsOneWidget);
        expect(find.text('Contributed by Morgan Rider'), findsOneWidget);
        expect(
          find.byKey(const Key('dictionaryInlineImage_0')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const Key('dictionaryInlineImage_0')),
        );
        await tester.tap(find.byKey(const Key('dictionaryInlineImage_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(PhotoView), findsOneWidget);
        expect(
          find.byKey(const Key('immersivePhotoMetadataOverlay')),
          findsOneWidget,
        );
      },
    );
  });
}
