import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ResourcesRepository repository;
  final date = DateTime.utc(2025);

  Resource article(
    String id, {
    ResourceStatus status = ResourceStatus.published,
    List<String> tags = const ['training'],
    DateTime? createdAt,
  }) =>
      Resource(
        id: id,
        name: 'Article $id',
        type: ResourceType.article,
        status: status,
        tags: tags,
        createdAt: createdAt ?? date,
        content: 'A useful training article',
        skillTreeIds: ['s1'],
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    repository = ResourcesRepository(firestore: db);
  });

  test('generates distinct nonempty document IDs', () {
    expect(repository.newId(), isNotEmpty);
    expect(repository.newId(), isNot(repository.newId()));
  });

  test('missing resource returns null', () async {
    expect(await repository.getResourceById('missing'), isNull);
  });

  test('create, read, update and delete a link resource', () async {
    final value = Resource(
      id: 'r1',
      name: 'Guide',
      url: 'https://example.com',
      type: ResourceType.link,
      rating: 2,
    );
    await repository.createOrUpdateResource(resource: value);
    expect((await repository.getResources().first).single.name, 'Guide');
    await repository.createOrUpdateResource(
      resource: value.copyWith(name: 'Updated'),
    );
    expect((await repository.getResourceById('r1'))?.name, 'Updated');
    await repository.deleteResource(resource: value);
    expect(await repository.getResources().first, isEmpty);
  });

  test('rejects writes without an ID', () async {
    await expectLater(
      repository.createOrUpdateResource(resource: Resource()),
      throwsArgumentError,
    );
    await expectLater(
      repository.createResourceWithServerTimestamps(resource: Resource()),
      throwsArgumentError,
    );
  });

  test('clears the last skill and tag when updating an existing resource',
      () async {
    final value = article('r1');
    await repository.createOrUpdateResource(resource: value);
    await repository.createOrUpdateResource(
      resource: value.copyWith(skillTreeIds: [], tags: []),
    );
    final saved = await repository.getResourceById('r1');
    expect(saved?.skillTreeIds, isEmpty);
    expect(saved?.tags, isEmpty);
  });

  test('server timestamps are set and creation date is preserved', () async {
    await repository.createResourceWithServerTimestamps(
      resource: article('r1'),
    );
    final data = (await db.collection('Resources').doc('r1').get()).data()!;
    expect(data['createdAt'], Timestamp.fromDate(date));
    expect(data['updatedAt'], isA<Timestamp>());
    await repository.createResourceWithServerTimestamps(
      resource: Resource(id: 'r2'),
    );
    expect((await repository.getResourceById('r2'))?.createdAt, isNotNull);
  });

  test('createArticle enforces article type', () async {
    await repository.createArticle(
      resource: Resource(id: 'r1', type: ResourceType.link),
    );
    expect((await repository.getArticleById('r1'))?.isArticle, isTrue);
    await repository.createOrUpdateResource(
      resource: Resource(id: 'r2', type: ResourceType.pdf),
    );
    expect(await repository.getArticleById('r2'), isNull);
    expect(await repository.getArticleById('missing'), isNull);
  });

  test('published query excludes drafts and filters tags newest first',
      () async {
    for (final value in [
      article('old'),
      article('new', createdAt: date.add(const Duration(days: 1))),
      article('draft', status: ResourceStatus.pending),
      article('other', tags: ['health']),
      Resource(
        id: 'link',
        type: ResourceType.link,
        status: ResourceStatus.published,
      ),
    ]) {
      await repository.createOrUpdateResource(resource: value);
    }
    final results =
        await repository.getPublishedArticles(tagsFilter: ['training']).first;
    expect(results.map((r) => r.id), ['new', 'old']);
  });

  test('article pagination advances without duplicate results', () async {
    for (var i = 0; i < 5; i++) {
      await repository.createOrUpdateResource(
        resource: article('r$i', createdAt: date.add(Duration(days: i))),
      );
    }
    final first = await repository.fetchPublishedArticlesPage(limit: 2);
    final second = await repository.fetchPublishedArticlesPage(
      limit: 2,
      startAfter: first.lastDoc,
    );
    final third = await repository.fetchPublishedArticlesPage(
      limit: 2,
      startAfter: second.lastDoc,
    );
    final end = await repository.fetchPublishedArticlesPage(
      limit: 2,
      startAfter: third.lastDoc,
    );
    expect(
      [...first.items, ...second.items, ...third.items].map((r) => r.id),
      ['r4', 'r3', 'r2', 'r1', 'r0'],
    );
    expect(end.items, isEmpty);
    expect(end.lastDoc, isNull);
  });

  test('content edits preserve unrelated resource fields', () async {
    await repository.createOrUpdateResource(resource: article('r1'));
    await repository.updateArticleContent(
      id: 'r1',
      title: 'Edited',
      content: 'New content',
      tags: [],
      description: 'New summary',
      coverImageUrl: 'https://example.com/cover.png',
    );
    final saved = await repository.getResourceById('r1');
    expect(saved?.name, 'Edited');
    expect(saved?.content, 'New content');
    expect(saved?.tags, isEmpty);
    expect(saved?.skillTreeIds, ['s1']);
    expect(saved?.createdAt?.isAtSameMomentAs(date), isTrue);
  });

  test('status changes and ratings persist separately', () async {
    final value = article('r1');
    await repository.createOrUpdateResource(resource: value);
    await repository.setArticleStatus(
      id: 'r1',
      status: ResourceStatus.rejected,
    );
    expect(
      (await repository.getResourceById('r1'))?.status,
      ResourceStatus.rejected,
    );
    await repository.editResourceRating(
      resource: value,
      userWhoRated: BaseListItem(id: 'rider', isSelected: true),
    );
    final ratings = await db
        .collection('Resources')
        .doc('r1')
        .collection('usersWhoRated')
        .get();
    expect(ratings.docs.single.id, 'rider');
    expect(ratings.docs.single.data()['isSelected'], isTrue);
  });

  test('repository instances use their injected database', () async {
    await repository.createOrUpdateResource(resource: article('r1'));
    final other = ResourcesRepository(firestore: FakeFirebaseFirestore());
    expect(await other.getResources().first, isEmpty);
  });

  group('Resource serialization', () {
    test('legacy records tolerate missing new fields', () {
      final value =
          Resource.fromMap({'name': 'Legacy', 'rating': '3'}, idFromDoc: 'doc');
      expect(value.id, 'doc');
      expect(value.rating, 3);
      expect(value.type, isNull);
      expect(value.skillTreeIds, isEmpty);
    });
    for (final type in ResourceType.values) {
      test('round trips type ${type.name}', () {
        final value = Resource(id: 'r1', type: type);
        expect(Resource.fromJson(value.toJson()).type, type);
      });
    }
    for (final status in ResourceStatus.values) {
      test('round trips status ${status.name}', () {
        final value = Resource(id: 'r1', status: status);
        expect(Resource.fromJson(value.toJson()).status, status);
      });
    }
    test('parses timestamp, date and ISO date inputs', () {
      for (final input in [
        Timestamp.fromDate(date),
        date,
        date.toIso8601String(),
      ]) {
        expect(
          Resource.fromMap({'createdAt': input})
              .createdAt
              ?.isAtSameMomentAs(date),
          isTrue,
        );
      }
      expect(Resource.fromMap({'createdAt': 'bad'}).createdAt, isNull);
    });
    test('constructor and copy isolate skill lists', () {
      final skills = ['s1'];
      final value = Resource(id: 'r1', skillTreeIds: skills);
      skills.add('s2');
      final copy = value.copyWith(name: 'Edited');
      copy.skillTreeIds.add('s3');
      expect(value.skillTreeIds, ['s1']);
    });
  });
}
