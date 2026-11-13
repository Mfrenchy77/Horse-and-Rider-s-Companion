import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Resource backend-neutral model & Firestore mapper', () {
    final createdAt = DateTime.utc(2025, 1, 15, 8);
    final lastEditDate = DateTime.utc(2025, 2, 20, 14, 30);

    test('toMap and fromMap round-trip all fields & nested models', () {
      final comment = Comment(
        id: 'c1',
        date: createdAt,
        editedDate: null,
        parentId: null,
        rating: 2,
        comment: 'Very helpful',
        resourceId: 'res-1',
        user: BaseListItem(id: 'u1@example.com', name: 'Alex'),
        usersWhoRated: [BaseListItem(id: 'u2@example.com')],
      );
      final rater = BaseListItem(id: 'u3@example.com', name: 'Sam');

      final resource = Resource(
        id: 'res-1',
        url: 'https://example.com/guide',
        name: 'Groundwork Guide',
        type: ResourceType.article,
        tags: const ['groundwork', 'basics'],
        rating: 5,
        status: ResourceStatus.published,
        content: 'Article body',
        comments: [comment],
        authorId: 'author@example.com',
        createdAt: createdAt,
        thumbnail: 'https://example.com/thumb.png',
        lastEditBy: 'author@example.com',
        authorName: 'Coach',
        authorPhoto: 'https://example.com/photo.png',
        description: 'Detailed guide',
        lastEditDate: lastEditDate,
        coverImageUrl: 'https://example.com/cover.png',
        blocksEmbedding: true,
        usersWhoRated: [rater],
        numberOfRates: 1,
        skillTreeIds: const ['skill-1', 'skill-2'],
      );

      final map = resource.toMap();
      expect(map['id'], 'res-1');
      expect(map['createdAt'], createdAt.toIso8601String());
      expect(map['lastEditDate'], lastEditDate.toIso8601String());
      expect(map['type'], 'article');
      expect(map['status'], 'published');
      expect(map['blocksEmbedding'], isTrue);
      expect(map['skillTreeIds'], ['skill-1', 'skill-2']);

      final restored = Resource.fromMap(map);
      expect(restored.id, 'res-1');
      expect(restored.name, 'Groundwork Guide');
      expect(restored.type, ResourceType.article);
      expect(restored.status, ResourceStatus.published);
      expect(restored.createdAt, createdAt);
      expect(restored.lastEditDate, lastEditDate);
      expect(restored.blocksEmbedding, isTrue);
      expect(restored.skillTreeIds, ['skill-1', 'skill-2']);
      expect(restored.tags, ['groundwork', 'basics']);
      expect(restored.comments?.single.comment, 'Very helpful');
      expect(restored.comments?.single.user?.name, 'Alex');
      expect(restored.usersWhoRated?.single.id, 'u3@example.com');

      final minimal = Resource();
      expect(minimal.toMap(), {
        'id': null,
        'skillTreeIds': const <String>[],
        'blocksEmbedding': false,
      });
    });

    test(
      'ResourceFirestoreMapper preserves Firestore format, Timestamps & legacy '
      'fields',
      () async {
        final firestore = FakeFirebaseFirestore();
        final docRef = firestore.collection('Resources').doc('doc-123');
        await docRef.set({
          'name': 'Legacy Video',
          'url': 'https://example.com/video',
          'type': 'video',
          'status': 'pending',
          'rating': '4',
          'numberOfRates': '2',
          'createdAt': Timestamp.fromDate(createdAt),
          'lastEditDate': Timestamp.fromDate(lastEditDate),
          'skillTreeIds': ['s1'],
          'blocksEmbedding': false,
          'usersWhoRated': [
            {'id': 'rater@example.com', 'name': 'Rater'},
          ],
          'comments': [
            {
              'id': 'c1',
              'date': Timestamp.fromDate(createdAt),
              'comment': 'Nice clip',
              'rating': 1,
            },
          ],
        });

        final snap = await docRef.get();
        final loaded = ResourceFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'doc-123');
        expect(loaded.rating, 4);
        expect(loaded.numberOfRates, 2);
        expect(loaded.createdAt, createdAt.toLocal());
        expect(loaded.lastEditDate, lastEditDate.toLocal());
        expect(loaded.usersWhoRated?.single.id, 'rater@example.com');
        expect(loaded.comments?.single.date, createdAt.toLocal());

        final encoded = ResourceFirestoreMapper.toFirestore(loaded);
        expect(encoded['createdAt'], Timestamp.fromDate(createdAt.toLocal()));
        expect(
          encoded['lastEditDate'],
          Timestamp.fromDate(lastEditDate.toLocal()),
        );
        expect(encoded['id'], 'doc-123');
        expect(encoded['skillTreeIds'], ['s1']);
        expect(encoded['blocksEmbedding'], isFalse);
        expect(encoded.containsKey('authorId'), isFalse);
        expect(
          (encoded['comments']! as List).single,
          isA<Map<String, dynamic>>(),
        );
      },
    );
  });
}
