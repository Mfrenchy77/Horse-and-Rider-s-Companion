import 'dart:async';
import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Article/cubit/create_article_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class _Picker extends FilePickerPlatform {
  PlatformFile? file;
  Exception? error;
  FileType? requestedType;
  List<String>? extensions;

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
    requestedType = type;
    extensions = allowedExtensions;
    if (error != null) throw error!;
    return file;
  }
}

final class _File extends PlatformFile {
  _File(this.name, {this.failReading = false});

  @override
  final String name;
  final bool failReading;
  final bytes = Uint8List.fromList([1, 2, 3]);

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
  Future<Uint8List> readAsBytes() async {
    if (failReading) throw Exception('cannot read file');
    return bytes;
  }
}

class _Storage extends Mock implements FirebaseStorage {}

class _Reference extends Mock implements Reference {}

class _Snapshot extends Mock implements TaskSnapshot {}

class _Upload extends Fake implements UploadTask {
  _Upload(this.snapshot);
  @override
  final TaskSnapshot snapshot;

  @override
  Future<T> then<T>(
    FutureOr<T> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) => Future.value(snapshot).then(onValue, onError: onError);
}

void main() {
  late FilePickerPlatform originalPicker;
  late _Picker picker;
  late _Storage storage;
  late MockResourcesRepository repository;
  late CreateArticleCubit article;
  late CreateResourceDialogCubit resource;

  setUpAll(() => registerFallbackValue(SettableMetadata()));
  setUp(() {
    originalPicker = FilePickerPlatform.instance;
    picker = _Picker();
    FilePickerPlatform.instance = picker;
    storage = _Storage();
    repository = MockResourcesRepository();
    when(repository.newId).thenReturn('article-id');
    article = CreateArticleCubit(
      resourcesRepository: repository,
      storage: storage,
      user: RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com'),
    );
    resource = CreateResourceDialogCubit(
      isEdit: false,
      resource: null,
      skills: const [],
      usersProfile: null,
      resourcesRepository: repository,
      storage: storage,
    );
  });
  tearDown(() async {
    FilePickerPlatform.instance = originalPicker;
    await article.close();
    await resource.close();
  });

  test('PDF selection reads bytes and preserves the filename', () async {
    final file = _File('guide.pdf');
    picker.file = file;
    await resource.pickPdf();
    expect(picker.requestedType, FileType.custom);
    expect(picker.extensions, ['pdf']);
    expect(resource.state.pdfName, 'guide.pdf');
    expect(resource.state.pdfBytes, file.bytes);
    expect(resource.state.pdfPicking, isFalse);
    expect(resource.state.isError, isFalse);
  });

  test('cancelling replacement keeps the previously selected PDF', () async {
    picker.file = _File('guide.pdf');
    await resource.pickPdf();
    picker.file = null;
    await resource.pickPdf();
    expect(resource.state.pdfName, 'guide.pdf');
    expect(resource.state.pdfPicking, isFalse);
    expect(resource.state.isError, isFalse);
  });

  test('PDF read errors are reported and leave no selected file', () async {
    picker.file = _File('guide.pdf', failReading: true);
    await resource.pickPdf();
    expect(resource.state.isError, isTrue);
    expect(resource.state.error, contains('cannot read file'));
    expect(resource.state.pdfPicking, isFalse);
    expect(resource.state.pdfBytes, isNull);
  });

  test(
    'picker errors are reported without leaving PDF picking active',
    () async {
      picker.error = Exception('picker unavailable');
      await resource.pickPdf();
      expect(resource.state.error, contains('picker unavailable'));
      expect(resource.state.pdfPicking, isFalse);
      expect(resource.state.isError, isTrue);
    },
  );

  test('cancelling cover selection does not upload anything', () async {
    await article.pickAndUploadCover();
    expect(picker.requestedType, FileType.image);
    expect(article.state.status, ArticleCreateStatus.idle);
    verifyZeroInteractions(storage);
  });

  test('cover read errors are reported without starting an upload', () async {
    picker.file = _File('cover.png', failReading: true);
    await article.pickAndUploadCover();
    expect(article.state.status, ArticleCreateStatus.failure);
    expect(article.state.errorMessage, contains('cannot read file'));
    verifyZeroInteractions(storage);
  });

  test(
    'cover uploads use the selected bytes and signed-in email path',
    () async {
      final file = _File('cover.png');
      picker.file = file;
      final root = _Reference();
      final target = _Reference();
      final snapshot = _Snapshot();
      when(() => storage.ref()).thenReturn(root);
      when(
        () => root.child('covers/r@example.com/article-id/cover.png'),
      ).thenReturn(target);
      when(
        () => target.putData(file.bytes, any()),
      ).thenAnswer((_) => _Upload(snapshot));
      when(() => snapshot.ref).thenReturn(target);
      when(
        target.getDownloadURL,
      ).thenAnswer((_) async => 'https://example.com/cover');

      await article.pickAndUploadCover();

      expect(article.state.status, ArticleCreateStatus.idle);
      expect(article.state.coverImageUrl, 'https://example.com/cover');
      expect(article.state.createdResourceId, 'article-id');
      verify(() => target.putData(file.bytes, any())).called(1);
    },
  );
}
