import 'package:database_repository/database_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Article/cubit/create_article_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockResources extends Mock implements ResourcesRepository {}

class MockStorage extends Mock implements FirebaseStorage {}

void main() {
  late MockResources repo;
  late CreateArticleCubit cubit;
  final user = RiderProfile(id: 'u', name: 'Rider', email: 'r@example.com');
  setUpAll(() => registerFallbackValue(Resource(id: 'fallback')));
  setUp(() {
    repo = MockResources();
    when(repo.newId).thenReturn('article-id');
    when(() => repo.createArticle(resource: any(named: 'resource')))
        .thenAnswer((_) async {});
    cubit = CreateArticleCubit(
      resourcesRepository: repo,
      mediaStorage: CloudRepository(storage: MockStorage()),
      user: user,
    );
  });
  tearDown(() => cubit.close());

  void validForm() {
    cubit
      ..titleChanged('  Training guide  ')
      ..descriptionChanged(' A useful guide ')
      ..editorUpdated(
        deltaJson: '[{"insert":"Useful training content\n"}]',
        plainTextLength: 24,
      );
  }

  for (final length in [0, 2, 121]) {
    test('rejects title length $length', () async {
      validForm();
      cubit.titleChanged('a' * length);
      await cubit.submit();
      expect(cubit.state.errorMessage, isNotNull);
      verifyNever(() => repo.createArticle(resource: any(named: 'resource')));
    });
  }
  test('requires at least twenty characters of content', () async {
    cubit
      ..titleChanged('Title')
      ..editorUpdated(deltaJson: '[]', plainTextLength: 19);
    await cubit.submit();
    verifyNever(() => repo.createArticle(resource: any(named: 'resource')));
  });
  test('trims tags, ignores duplicates and enforces the six-tag limit', () {
    cubit
      ..addTag(' training ')
      ..addTag('training')
      ..addTag(' ');
    expect(cubit.state.tags, ['training']);
    for (var i = 0; i < 6; i++) {
      cubit.addTag('tag$i');
    }
    expect(cubit.state.tags, hasLength(6));
    expect(cubit.state.errorMessage, contains('6 tags'));
    cubit.removeTag('training');
    expect(cubit.state.tags, hasLength(5));
  });
  for (final publish in [true, false]) {
    test('saves article as ${publish ? 'published' : 'pending'} with author',
        () async {
      validForm();
      await cubit.submit(publishNow: publish);
      final saved = verify(
        () => repo.createArticle(resource: captureAny(named: 'resource')),
      ).captured.single as Resource;
      expect(saved.id, 'article-id');
      expect(saved.name, 'Training guide');
      expect(saved.description, 'A useful guide');
      expect(saved.type, ResourceType.article);
      expect(
        saved.status,
        publish ? ResourceStatus.published : ResourceStatus.pending,
      );
      expect(saved.authorId, user.email);
      expect(saved.authorName, user.name);
      expect(cubit.state.status, ArticleCreateStatus.success);
    });
  }
  test('guests cannot submit', () async {
    await cubit.close();
    cubit = CreateArticleCubit(
      resourcesRepository: repo,
      mediaStorage: CloudRepository(storage: MockStorage()),
    );
    validForm();
    await cubit.submit();
    expect(cubit.state.errorMessage, contains('signed in'));
    verifyNever(() => repo.createArticle(resource: any(named: 'resource')));
  });
  test('reports database failures', () async {
    validForm();
    when(() => repo.createArticle(resource: any(named: 'resource')))
        .thenAnswer((_) async => throw Exception('offline'));
    await cubit.submit();
    expect(cubit.state.status, ArticleCreateStatus.failure);
    expect(cubit.state.errorMessage, contains('Could not save'));
  });
}
