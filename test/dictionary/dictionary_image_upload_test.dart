// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:image_picker/image_picker.dart';

import '../support/app_test_harness.dart';

Uint8List _pngBytes() => Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
]);

Uint8List _jpegBytes() => Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);

Uint8List _webpBytes() => Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, // RIFF....
  0x57, 0x45, 0x42, 0x50, // WEBP
]);

class _FakeMediaStorage implements MediaStorageRepository {
  final List<({String path, Uint8List bytes, String? contentType})> uploads =
      [];
  final List<String> deletedUrls = [];
  bool shouldThrow = false;
  int _counter = 0;

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
    onProgress?.call(0.5);
    if (shouldThrow) {
      throw const MediaStorageException('Permission denied.');
    }
    uploads.add((path: path, bytes: bytes, contentType: contentType));
    onProgress?.call(1);
    _counter++;
    final encoded = Uri.encodeComponent(path);
    return 'https://firebasestorage.googleapis.com/v0/b/demo/o/$encoded?alt=media&token=tok$_counter';
  }

  @override
  Future<void> deleteByUrl(String url) async {
    deletedUrls.add(url);
  }
}

class _RecordingDictionaryRepo extends DictionaryRepository {
  _RecordingDictionaryRepo(this.entries, {super.firestore});

  final List<DictionaryEntry> entries;
  final List<(String, Map<String, dynamic>)> calls = [];

  @override
  Future<Map<String, String>> skillLabels() async => {
    'rider.mounted.canter': 'Rider · Canter / Lope',
  };

  @override
  Future<List<DictionaryEntry>> load() async => entries;

  @override
  Future<void> call(String function, Map<String, dynamic> data) async {
    calls.add((function, data));
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

  void signInAdmin() {
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

  group('DictionaryImageValidator', () {
    test(
      'accepts PNG, JPEG, and WebP and rejects invalid formats or sizes',
      () {
        final png = DictionaryImageValidator.validate(
          bytes: _pngBytes(),
          fileName: 'Canter Diagram.PNG',
        );
        expect(png.contentType, 'image/png');
        expect(png.fileName, 'canter-diagram.png');

        final jpg = DictionaryImageValidator.validate(
          bytes: _jpegBytes(),
          fileName: 'lope_photo.jpeg',
        );
        expect(jpg.contentType, 'image/jpeg');
        expect(jpg.fileName, 'lope_photo.jpg');

        final webp = DictionaryImageValidator.validate(
          bytes: _webpBytes(),
          fileName: 'stride.webp',
        );
        expect(webp.contentType, 'image/webp');
        expect(webp.fileName, 'stride.webp');

        expect(
          () => DictionaryImageValidator.validate(
            bytes: Uint8List(0),
            fileName: 'empty.png',
          ),
          throwsFormatException,
        );
        expect(
          () => DictionaryImageValidator.validate(
            bytes: Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
            fileName: 'anim.gif',
          ),
          throwsFormatException,
        );
        expect(
          () => DictionaryImageValidator.validate(
            bytes: _pngBytes(),
            fileName: 'spoofed.jpg',
          ),
          throwsFormatException,
        );
        // Arbitrary text renamed to .png must be rejected.
        expect(
          () => DictionaryImageValidator.validate(
            bytes: Uint8List.fromList('not actually a png'.codeUnits),
            fileName: 'renamed.png',
          ),
          throwsFormatException,
        );
        expect(
          () => DictionaryImageValidator.validate(
            bytes: Uint8List(maxDictionaryImageBytes + 1),
            fileName: 'huge.png',
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'isDictionaryImageUrl distinguishes HTTPS image URLs from non-image links',
      () {
        expect(
          isDictionaryImageUrl(
            'https://firebasestorage.googleapis.com/v0/b/app/o/dictionary_public%2Fcanter%2Fphoto.webp?alt=media&token=123',
          ),
          isTrue,
        );
        expect(isDictionaryImageUrl('http://example.com/photo.png'), isFalse);
        expect(
          isDictionaryImageUrl('https://example.com/article.html'),
          isFalse,
        );
      },
    );
  });

  group('Admin image manager & public inline gallery', () {
    testWidgets(
      'admin preserves existing media, uploads to dictionary_drafts, validates, edits captions, reorders, replaces, removes, and enforces max 8',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInAdmin();
        final storage = _FakeMediaStorage();
        final db = FakeFirebaseFirestore();
        final existingMedia = [
          {
            'url':
                'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fexisting.png?alt=media&token=orig',
            'label': 'Existing footfall diagram',
          },
        ];
        final entries = [
          for (final entry in seedEntries)
            if (entry.id == 'canter')
              DictionaryEntry({...entry.data, 'media': existingMedia})
            else
              entry,
        ];
        final repo = _RecordingDictionaryRepo(entries, firestore: db);

        final queuedPicks = <({String name, Uint8List bytes})?>[
          // 1. Invalid GIF file -> should show validation error
          (
            name: 'bad.gif',
            bytes: Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
          ),
          // 2. Valid JPEG upload
          (name: 'lope_stride.jpg', bytes: _jpegBytes()),
          // 3. Replace index 1 with WebP
          (name: 'better_stride.webp', bytes: _webpBytes()),
          // 4..9. Fill up to 8 images
          for (var i = 0; i < 6; i++)
            (name: 'extra_$i.png', bytes: _pngBytes()),
        ];
        var pickIndex = 0;

        await tester.pumpWidget(
          wrap(
            DictionaryAdminPage(
              firestore: db,
              repository: repo,
              mediaStorage: storage,
              pickImageFile: () async => pickIndex < queuedPicks.length
                  ? queuedPicks[pickIndex++]
                  : null,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Open Edit published definition -> Canter
        await tester.tap(
          find.byKey(const Key('dictionaryAdminEditExistingButton')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Canter'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Existing media is preserved and rendered
        expect(find.text('Images (1/8)'), findsOneWidget);
        expect(find.byKey(const Key('dictionaryMediaItem_0')), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('dictionaryMediaLabel_0')),
              )
              .controller!
              .text,
          'Existing footfall diagram',
        );

        // 1. Attempt invalid upload -> error banner shown, count remains 1/8
        final uploadBtn = find.byKey(const Key('dictionaryUploadImageButton'));
        await tester.ensureVisible(uploadBtn);
        await tester.tap(uploadBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const Key('dictionaryMediaError')), findsOneWidget);
        expect(find.text('Images (1/8)'), findsOneWidget);

        // 2. Upload valid JPEG -> uploads to dictionary_drafts/canter/...
        await tester.tap(uploadBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Images (2/8)'), findsOneWidget);
        expect(
          storage.uploads.last.path,
          startsWith('dictionary_drafts/canter/'),
        );
        expect(storage.uploads.last.contentType, 'image/jpeg');

        // Edit caption on uploaded image
        await tester.enterText(
          find.byKey(const Key('dictionaryMediaLabel_1')),
          'Western lope stride',
        );

        // 3. Replace second image with WebP
        final replaceBtn = find.byKey(const Key('dictionaryMediaReplace_1'));
        await tester.ensureVisible(replaceBtn);
        await tester.tap(replaceBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(storage.uploads.last.contentType, 'image/webp');
        expect(find.text('Images (2/8)'), findsOneWidget);

        // 4. Reorder: move second image up to index 0 (primary OG image)
        final moveUpBtn = find.byKey(const Key('dictionaryMediaMoveUp_1'));
        await tester.ensureVisible(moveUpBtn);
        await tester.tap(moveUpBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('dictionaryMediaLabel_0')),
              )
              .controller!
              .text,
          'Western lope stride',
        );

        // 5. Upload 6 more to hit 8/8 limit; upload button becomes disabled
        for (var i = 0; i < 6; i++) {
          await tester.ensureVisible(uploadBtn);
          await tester.tap(uploadBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Images (8/8)'), findsOneWidget);
        final disabledUploadBtn = tester.widget<OutlinedButton>(uploadBtn);
        expect(disabledUploadBtn.onPressed, isNull);

        // Remove one item -> drops to 7/8
        final removeBtn = find.byKey(const Key('dictionaryMediaRemove_7'));
        await tester.ensureVisible(removeBtn);
        await tester.tap(removeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Images (7/8)'), findsOneWidget);

        // Publish -> passes updated media list with reordered primary image
        final publishBtn = find.byKey(const Key('dictionaryPublishButton'));
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(repo.calls.last.$1, 'editDictionary');
        expect(repo.calls.last.$2['action'], 'publish');
        final sentMedia =
            (repo.calls.last.$2['entry'] as Map)['media'] as List<dynamic>;
        expect(sentMedia, hasLength(7));
        expect((sentMedia[0] as Map)['label'], 'Western lope stride');
        expect((sentMedia[1] as Map)['label'], 'Existing footfall diagram');

        // Verify collision-resistant upload names (24-hex token prefix) and cleanup
        // of replaced/removed session-uploaded draft images (without deleting persisted URL).
        final paths = storage.uploads.map((u) => u.path).toSet();
        expect(paths, hasLength(storage.uploads.length));
        for (final p in paths) {
          expect(
            RegExp('^dictionary_drafts/canter/[0-9a-f]{24}_').hasMatch(p),
            isTrue,
          );
        }
        // Replaced JPEG (upload[0]) + removed PNG (upload[7]) were cleaned up,
        // while the pre-existing persisted URL was never deleted.
        expect(storage.deletedUrls, hasLength(2));
        expect(
          storage.deletedUrls.any((u) => u.contains('existing.png')),
          isFalse,
        );
      },
    );

    testWidgets(
      'new entry locks id after image upload and cleans up session uploads on cancel',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInAdmin();
        final storage = _FakeMediaStorage();
        final db = FakeFirebaseFirestore();
        final repo = _RecordingDictionaryRepo(seedEntries, firestore: db);

        await tester.pumpWidget(
          wrap(
            DictionaryAdminPage(
              firestore: db,
              repository: repo,
              mediaStorage: storage,
              pickImageFile: () async =>
                  (name: 'diagram.png', bytes: _pngBytes()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('dictionaryAdminNewButton')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('dictionaryField_term')),
          'Jog',
        );
        await tester.pumpAndSettle();

        final idFieldBefore = tester.widget<TextFormField>(
          find.byKey(const Key('dictionaryField_id')),
        );
        expect(idFieldBefore.enabled, isTrue);

        final uploadBtn = find.byKey(const Key('dictionaryUploadImageButton'));
        await tester.ensureVisible(uploadBtn);
        await tester.tap(uploadBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          storage.uploads.single.path,
          startsWith('dictionary_drafts/jog/'),
        );

        // Entry ID is now locked while images are attached.
        final idFieldAfter = tester.widget<TextFormField>(
          find.byKey(const Key('dictionaryField_id')),
        );
        expect(idFieldAfter.enabled, isFalse);

        // Changing Term no longer mutates Entry ID.
        await tester.enterText(
          find.byKey(const Key('dictionaryField_term')),
          'Western Jog',
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('dictionaryField_id')),
              )
              .controller!
              .text,
          'jog',
        );

        // Canceling the dialog cleans up the abandoned session draft upload.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(storage.deletedUrls, hasLength(1));
        expect(
          storage.deletedUrls.single,
          contains('dictionary_drafts%2Fjog%2F'),
        );
      },
    );

    testWidgets(
      'public Dictionary detail renders first published image as hero, secondary images inline, and keeps non-image links as buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final enriched = DictionaryEntry({
          ...canter.data,
          'media': [
            {
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fstride.png?alt=media&token=pub1',
              'label': 'Three-beat canter sequence',
            },
            {
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Flead.png?alt=media&token=pub2',
              'label': 'Inside lead alignment',
            },
            {
              'url': 'https://example.com/equine-biomechanics-guide',
              'label': 'Read biomechanics guide',
            },
          ],
        });

        await tester.pumpWidget(
          wrap(
            DictionaryPage(
              slug: 'canter',
              repository: _RecordingDictionaryRepo([enriched]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // First image is in the hero, second image is in the secondary gallery.
        expect(find.byType(SmartImage), findsNWidgets(2));
        expect(find.byKey(const Key('dictionaryHeroImage')), findsOneWidget);
        expect(find.text('Three-beat canter sequence'), findsOneWidget);
        expect(
          find.byKey(const Key('dictionaryInlineImage_0')),
          findsOneWidget,
        );
        expect(find.text('Inside lead alignment'), findsOneWidget);
        // Non-image HTTPS resource remains a clickable link button.
        expect(find.text('Read biomechanics guide'), findsOneWidget);
      },
    );
  });
}
