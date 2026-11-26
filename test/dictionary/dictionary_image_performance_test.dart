// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_image_contribution_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:image_picker/image_picker.dart';

import '../support/app_test_harness.dart';

Uint8List _pngWithSize(int width, int height) {
  final out = Uint8List(24)
    ..setRange(0, 8, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..setRange(8, 12, [0x00, 0x00, 0x00, 0x0D])
    ..setRange(12, 16, [0x49, 0x48, 0x44, 0x52]); // IHDR
  ByteData.sublistView(out, 16, 24)
    ..setUint32(0, width)
    ..setUint32(4, height);
  return out;
}

Uint8List _jpegWithSize(int width, int height, {int sofMarker = 0xC0}) {
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xE0, 0x00, 0x04, 0x00, 0x00, // APP0 segment
    0xFF, sofMarker, 0x00, 0x0B, 0x08,
    (height >> 8) & 0xFF,
    height & 0xFF,
    (width >> 8) & 0xFF,
    width & 0xFF,
    0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01,
    0xFF, 0xD9, // EOI
  ]);
}

Uint8List _webpVp8WithSize(int width, int height) {
  return Uint8List.fromList([
    0x52, 0x49, 0x46, 0x46, 0x16, 0x00, 0x00, 0x00, // RIFF
    0x57, 0x45, 0x42, 0x50, // WEBP
    0x56, 0x50, 0x38, 0x20, // 'VP8 '
    0x0A, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00,
    0x9D, 0x01, 0x2A, // sync code
    width & 0xFF, (width >> 8) & 0x3F,
    height & 0xFF, (height >> 8) & 0x3F,
  ]);
}

Uint8List _webpVp8lWithSize(int width, int height) {
  final packed = (width - 1) | ((height - 1) << 14);
  return Uint8List.fromList([
    0x52, 0x49, 0x46, 0x46, 0x18, 0x00, 0x00, 0x00, // RIFF
    0x57, 0x45, 0x42, 0x50, // WEBP
    0x56, 0x50, 0x38, 0x4C, // 'VP8L'
    0x09, 0x00, 0x00, 0x00,
    0x2F, // signature
    packed & 0xFF,
    (packed >> 8) & 0xFF,
    (packed >> 16) & 0xFF,
    (packed >> 24) & 0xFF,
    0x00, 0x00, 0x00, 0x00, 0x00,
  ]);
}

Uint8List _webpVp8xWithSize(int width, int height) {
  final w = width - 1;
  final h = height - 1;
  return Uint8List.fromList([
    0x52, 0x49, 0x46, 0x46, 0x16, 0x00, 0x00, 0x00, // RIFF
    0x57, 0x45, 0x42, 0x50, // WEBP
    0x56, 0x50, 0x38, 0x58, // 'VP8X'
    0x0A, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    w & 0xFF,
    (w >> 8) & 0xFF,
    (w >> 16) & 0xFF,
    h & 0xFF,
    (h >> 8) & 0xFF,
    (h >> 16) & 0xFF,
  ]);
}

class _ControlledMediaStorage implements MediaStorageRepository {
  Completer<String>? pendingUpload;
  void Function(double progress)? latestOnProgress;
  bool failNextUpload = false;
  int uploadCalls = 0;

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
    uploadCalls++;
    latestOnProgress = onProgress;
    onProgress?.call(0);
    if (failNextUpload) {
      failNextUpload = false;
      throw StateError('Simulated upload failure');
    }
    if (pendingUpload != null) {
      return pendingUpload!.future;
    }
    onProgress?.call(1);
    return 'https://firebasestorage.googleapis.com/v0/b/demo/o/${Uri.encodeComponent(path)}?alt=media&token=t$uploadCalls';
  }

  @override
  Future<void> deleteByUrl(String url) async {}
}

class _CountingDictionaryRepo extends DictionaryRepository {
  _CountingDictionaryRepo(this.entries);

  final List<DictionaryEntry> entries;
  int callCount = 0;
  Completer<void>? pendingSubmit;

  @override
  Future<List<DictionaryEntry>> load() async => entries;

  @override
  Future<void> call(String function, Map<String, dynamic> data) async {
    callCount++;
    if (pendingSubmit != null) {
      await pendingSubmit!.future;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<DictionaryEntry> seedEntries;
  late AppTestHarness harness;

  setUp(() async {
    DictionaryImageProcessor.clearCache();
    DictionaryRepository.invalidateCache();
    seedEntries = await DictionaryRepository.cachedEntries();
    harness = await AppTestHarness.create();
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(
          id: 'uid-contrib',
          email: 'rider@example.com',
          name: 'Rider',
        ),
        user: const User(
          id: 'uid-contrib',
          email: 'rider@example.com',
          name: 'Rider',
          isGuest: false,
          emailVerified: true,
        ),
      ),
    );
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

  group('DictionaryImageProcessor performance optimizations', () {
    test(
      'reads PNG, JPEG (baseline & progressive), and WebP dimensions without decoding',
      () {
        expect(
          DictionaryImageProcessor.readDimensions(
            _pngWithSize(1280, 720),
            'image/png',
          ),
          (width: 1280, height: 720),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            _pngWithSize(4000, 3000),
            'image/png',
          ),
          (width: 4000, height: 3000),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            _jpegWithSize(1600, 900),
            'image/jpeg',
          ),
          (width: 1600, height: 900),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            _jpegWithSize(3200, 2400, sofMarker: 0xC2),
            'image/jpeg',
          ),
          (width: 3200, height: 2400),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            _webpVp8WithSize(1024, 768),
            'image/webp',
          ),
          (width: 1024, height: 768),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            _webpVp8lWithSize(1440, 1080),
            'image/webp',
          ),
          (width: 1440, height: 1080),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            _webpVp8xWithSize(2048, 1536),
            'image/webp',
          ),
          (width: 2048, height: 1536),
        );
        expect(
          DictionaryImageProcessor.readDimensions(
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
            'image/png',
          ),
          isNull,
        );
      },
    );

    test(
      'skips decoding when <= maxDimension and caches repeated processing by hash',
      () async {
        final png = _pngWithSize(1600, 1200);
        final first = await DictionaryImageProcessor.process(
          bytes: png,
          fileName: 'Half Halt.png',
          precomputedRawHash: 'hash-1600x1200',
        );
        expect(first.wasResized, isFalse);
        expect(first.sha256, 'hash-1600x1200');
        expect(first.contentType, 'image/png');

        final second = await DictionaryImageProcessor.process(
          bytes: png,
          fileName: 'Half Halt.png',
          precomputedRawHash: 'hash-1600x1200',
        );
        expect(identical(first, second), isTrue);
      },
    );
  });

  group('DictionaryImageContributionDialog responsiveness & rebuild isolation', () {
    testWidgets(
      'upload progress updates progress bar without rebuilding dialog or using full-res thumbnails',
      (tester) async {
        final storage = _ControlledMediaStorage()
          ..pendingUpload = Completer<String>();
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final repo = _CountingDictionaryRepo([canter]);

        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => DictionaryImageContributionDialog(
                          repository: repo,
                          entry: canter,
                          mediaStorage: storage,
                          pickImages: () async => [
                            (
                              name: 'canter_frame.jpg',
                              bytes: _jpegWithSize(1600, 900),
                            ),
                          ],
                        ),
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

        await tester.tap(
          find.byKey(const Key('dictionaryPickCommunityImagesButton')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));

        expect(
          find.byKey(const Key('communityPendingImage_0')),
          findsOneWidget,
        );
        expect(storage.latestOnProgress, isNotNull);

        // Verify thumbnail uses a bounded ResizeImage rather than full-res MemoryImage.
        final thumbnailWidget = tester.widget<Image>(
          find.byKey(const Key('communityImageThumbnail_0')),
        );
        expect(thumbnailWidget.image, isA<ResizeImage>());
        final resizedProvider = thumbnailWidget.image as ResizeImage;
        expect(resizedProvider.width, lessThanOrEqualTo(180));

        // Check that rapid upload progress updates leave unrelated form fields
        // and card Elements untouched without parent rebuilds.
        final noteFinder = find.byKey(const Key('imageContributionNoteField'));
        final noteRenderBefore = tester.renderObject(noteFinder);
        final cardElementBefore = tester.element(
          find.byKey(const Key('communityPendingImage_0')),
        );

        // Emit 30 rapid upload progress updates (< 60ms apart).
        for (var i = 1; i <= 30; i++) {
          storage.latestOnProgress!(i / 30);
        }
        await tester.pump();

        expect(find.text('Uploading 100%'), findsOneWidget);
        expect(tester.renderObject(noteFinder), same(noteRenderBefore));
        expect(
          tester.element(find.byKey(const Key('communityPendingImage_0'))),
          same(cardElementBefore),
        );

        // Unrelated AppCubit emission does not clear form state or crash.
        harness.cubit.emit(harness.cubit.state.copyWith(index: 2));
        await tester.pump();
        expect(
          tester.widget<TextFormField>(noteFinder).controller!.text,
          isEmpty,
        );

        storage.pendingUpload!.complete(
          'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_submissions%2Fuid-contrib%2Fsub%2Fcanter_frame.jpg?alt=media&token=ok',
        );
        await tester.pumpAndSettle();
        expect(find.text('Uploaded and ready for review'), findsOneWidget);
      },
    );

    testWidgets('retrying a failed upload does not reprocess the image', (
      tester,
    ) async {
      final storage = _ControlledMediaStorage()..failNextUpload = true;
      final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
      final repo = _CountingDictionaryRepo([canter]);
      var processCalls = 0;

      await tester.pumpWidget(
        wrap(
          DictionaryImageContributionDialog(
            repository: repo,
            entry: canter,
            mediaStorage: storage,
            pickImages: () async => [
              (name: 'lead.png', bytes: _pngWithSize(1400, 900)),
            ],
            processImage: ({required bytes, required fileName}) async {
              processCalls++;
              return DictionaryImageProcessor.process(
                bytes: bytes,
                fileName: fileName,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('dictionaryPickCommunityImagesButton')),
      );
      await tester.pumpAndSettle();

      expect(processCalls, 1);
      expect(
        find.byKey(const Key('communityImageUploadError_0')),
        findsOneWidget,
      );

      // Retry upload -> uses previously prepared bytes without calling processImage again.
      await tester.tap(find.text('Retry upload'));
      await tester.pumpAndSettle();

      expect(processCalls, 1);
      expect(storage.uploadCalls, 2);
      expect(find.text('Uploaded and ready for review'), findsOneWidget);
    });

    testWidgets(
      'displays immediate visual submitting state and prevents duplicate submissions',
      (tester) async {
        final storage = _ControlledMediaStorage();
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final repo = _CountingDictionaryRepo([canter])
          ..pendingSubmit = Completer<void>();

        await tester.pumpWidget(
          wrap(
            DictionaryImageContributionDialog(
              repository: repo,
              entry: canter,
              mediaStorage: storage,
              pickImages: () async => [
                (name: 'stride.png', bytes: _pngWithSize(1200, 800)),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('dictionaryPickCommunityImagesButton')),
        );
        await tester.pumpAndSettle();

        final rightsCheckbox = find.byKey(
          const Key('dictionaryImageRightsCheckbox'),
        );
        await tester.ensureVisible(rightsCheckbox);
        await tester.tap(rightsCheckbox);
        await tester.pumpAndSettle();

        final submitFinder = find.byKey(
          const Key('submitImageContributionButton'),
        );
        await tester.ensureVisible(submitFinder);
        await tester.tap(submitFinder);
        await tester.pump();

        expect(find.text('Submitting…'), findsOneWidget);
        expect(
          find.descendant(
            of: submitFinder,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

        // Rapid second tap while submitting does not trigger another call.
        await tester.tap(submitFinder, warnIfMissed: false);
        await tester.pump();
        expect(repo.callCount, 1);

        repo.pendingSubmit!.complete();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryImageContributionSuccess')),
          findsOneWidget,
        );
      },
    );
  });
}
