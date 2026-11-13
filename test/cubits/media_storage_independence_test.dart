import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Article/cubit/create_article_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _InMemoryMediaStorageRepository implements MediaStorageRepository {
  final Map<String, Uint8List> uploadedBytes = {};
  final Map<String, String?> contentTypes = {};
  final Map<String, XFile?> riderPhotos = {};
  final Map<String, XFile?> horsePhotos = {};
  MediaStorageException? nextError;

  @override
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) async {
    horsePhotos[horseId] = file;
    return file == null ? null : 'https://in-memory.test/horses/$horseId';
  }

  @override
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) async {
    riderPhotos[riderId] = file;
    return file == null ? null : 'https://in-memory.test/riders/$riderId';
  }

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    onProgress?.call(0.5);
    uploadedBytes[path] = bytes;
    contentTypes[path] = contentType;
    onProgress?.call(1);
    return 'https://in-memory.test/$path';
  }
}

class _MockResourcesRepository extends Mock implements ResourcesRepository {}

class _FakeFilePicker extends FilePickerPlatform {
  PlatformFile? file;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return file;
  }
}

final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this.name, this.bytes);

  @override
  final String name;
  final Uint8List bytes;

  @override
  Uri get uri => Uri.parse('memory:/$name');
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int lengthSync() => bytes.length;
  @override
  Future<int?> length() async => bytes.length;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

void main() {
  setUpAll(() => registerFallbackValue(Resource(id: 'fallback')));

  group('MediaStorageRepository backend independence', () {
    late FilePickerPlatform originalPicker;
    late _FakeFilePicker picker;
    late _InMemoryMediaStorageRepository mediaStorage;
    late _MockResourcesRepository resourcesRepo;

    setUp(() {
      originalPicker = FilePickerPlatform.instance;
      picker = _FakeFilePicker();
      FilePickerPlatform.instance = picker;
      mediaStorage = _InMemoryMediaStorageRepository();
      resourcesRepo = _MockResourcesRepository();
      when(resourcesRepo.newId).thenReturn('res-1');
      when(
        () => resourcesRepo.createResourceWithServerTimestamps(
          resource: any(named: 'resource'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      FilePickerPlatform.instance = originalPicker;
    });

    test(
      'CreateArticleCubit uploads cover bytes via MediaStorageRepository',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        picker.file = _FakePlatformFile('cover.png', bytes);
        final cubit = CreateArticleCubit(
          resourcesRepository: resourcesRepo,
          mediaStorage: mediaStorage,
          user: RiderProfile(
            id: 'r1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
        );
        addTearDown(cubit.close);

        await cubit.pickAndUploadCover();

        const expectedPath = 'covers/alex@example.com/res-1/cover.png';
        expect(
          cubit.state.coverImageUrl,
          'https://in-memory.test/$expectedPath',
        );
        expect(cubit.state.status, ArticleCreateStatus.idle);
        expect(mediaStorage.uploadedBytes[expectedPath], bytes);
        expect(mediaStorage.contentTypes[expectedPath], 'image/png');
      },
    );

    test(
      'CreateResourceDialogCubit uploads PDFs and handles errors',
      () async {
        final pdfBytes = Uint8List.fromList([5, 6, 7]);
        picker.file = _FakePlatformFile('guide.pdf', pdfBytes);
        final cubit = CreateResourceDialogCubit(
          isEdit: false,
          resource: null,
          skills: [
            Skill(
              id: 's1',
              skillName: 'Halt',
              description: 'Basic halt',
              learningDescription: 'Learning',
              proficientDescription: 'Proficient',
              lastEditDate: DateTime(2026, 2),
              lastEditBy: 'alex@example.com',
              rider: true,
              position: 0,
            ),
          ],
          usersProfile: RiderProfile(
            id: 'r1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
          resourcesRepository: resourcesRepo,
          mediaStorage: mediaStorage,
          initialInputType: ResourceInputType.pdf,
        );
        addTearDown(cubit.close);

        cubit.titleChanged('Dressage Guide');
        await cubit.pickPdf();
        await cubit.submit();

        const expectedPath = 'resources/pdfs/res-1/guide.pdf';
        expect(cubit.state.submitStatus, ResourceSubmitStatus.success);
        expect(cubit.state.pdfUploadProgress, 1.0);
        expect(mediaStorage.uploadedBytes[expectedPath], pdfBytes);
        expect(mediaStorage.contentTypes[expectedPath], 'application/pdf');

        // Failure path propagates MediaStorageException message cleanly.
        mediaStorage.nextError = const MediaStorageException('Storage offline');
        await cubit.submit();
        expect(cubit.state.submitStatus, ResourceSubmitStatus.error);
        expect(cubit.state.error, 'Storage offline');
      },
    );

    test(
      'InMemoryMediaStorageRepository satisfies rider and horse photo APIs',
      () async {
        final file = XFile.fromData(
          Uint8List.fromList([9, 8, 7]),
          name: 'photo.jpg',
        );
        final riderUrl = await mediaStorage.addRiderPhoto(
          file: file,
          riderId: 'rider@example.com',
        );
        final horseUrl = await mediaStorage.addHorsePhoto(
          file: file,
          horseId: 'horse-1',
        );
        expect(riderUrl, 'https://in-memory.test/riders/rider@example.com');
        expect(horseUrl, 'https://in-memory.test/horses/horse-1');
      },
    );
  });
}
