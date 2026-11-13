import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comment backend-neutral model and CommentFirestoreMapper', () {
    final createdAt = DateTime(2026, 5, 11, 10, 15);
    final editedAt = DateTime(2026, 5, 11, 12, 30);

    test('constructs, copies, and round-trips via fromMap/toMap', () {
      final original = Comment(
        id: 'c1',
        user: BaseListItem(
          id: 'author@example.com',
          name: 'Author',
          imageUrl: 'https://example.com/avatar.png',
          date: createdAt,
        ),
        date: createdAt,
        rating: 5,
        comment: 'Helpful breakdown',
        parentId: 'c0',
        editedDate: editedAt,
        resourceId: 'res-1',
        usersWhoRated: [
          BaseListItem(
            id: 'rater@example.com',
            isSelected: true,
            date: editedAt,
          ),
        ],
      );

      final map = original.toMap();
      expect(map['date'], createdAt.toIso8601String());
      expect(map['editedDate'], editedAt.toIso8601String());

      final decoded = Comment.fromMap(map);
      expect(decoded.id, 'c1');
      expect(decoded.parentId, 'c0');
      expect(decoded.resourceId, 'res-1');
      expect(decoded.rating, 5);
      expect(decoded.comment, 'Helpful breakdown');
      expect(decoded.date, createdAt);
      expect(decoded.editedDate, editedAt);
      expect(decoded.user?.id, 'author@example.com');
      expect(decoded.user?.date, createdAt);
      expect(decoded.usersWhoRated, hasLength(1));
      expect(decoded.usersWhoRated?.first.id, 'rater@example.com');
      expect(decoded.usersWhoRated?.first.isSelected, isTrue);

      final copied = decoded.copyWith(rating: 6, parentId: 'c-root');
      expect(copied.rating, 6);
      expect(copied.parentId, 'c-root');
    });

    test('fromJson/fromMap support DateTime, ISO, epoch ms, and nulls', () {
      final fromIso = Comment.fromJson({
        'id': 'c-iso',
        'date': createdAt.toIso8601String(),
        'editedDate': null,
        'rating': null,
        'comment': 'Reply',
        'parentId': null,
        'resourceId': 'res-1',
        'user': null,
        'usersWhoRated': null,
      });
      final fromEpoch = Comment.fromMap({
        'id': 'c-epoch',
        'date': createdAt.millisecondsSinceEpoch,
        'editedDate': editedAt.millisecondsSinceEpoch,
      });

      expect(fromIso.date, createdAt);
      expect(fromIso.editedDate, isNull);
      expect(fromIso.user, isNull);
      expect(fromIso.usersWhoRated, isNull);
      expect(fromEpoch.date, createdAt);
      expect(fromEpoch.editedDate, editedAt);
    });

    test(
      'CommentFirestoreMapper deserializes Timestamps and serializes '
      'identically for toFirestore and toJson',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('Comments').doc('c-ts').set({
          'id': 'c-ts',
          'date': Timestamp.fromDate(createdAt),
          'editedDate': Timestamp.fromDate(editedAt),
          'rating': 3,
          'comment': 'Nice drill',
          'parentId': 'c-parent',
          'resourceId': 'res-1',
          'user': {
            'id': 'rider@example.com',
            'name': 'Rider',
            'date': Timestamp.fromDate(createdAt),
          },
          'usersWhoRated': [
            {
              'id': 'voter@example.com',
              'isSelected': true,
              'date': Timestamp.fromDate(editedAt),
            },
          ],
        });

        final snap = await fake.collection('Comments').doc('c-ts').get();
        final loaded = CommentFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'c-ts');
        expect(loaded.date, createdAt);
        expect(loaded.editedDate, editedAt);
        expect(loaded.user?.id, 'rider@example.com');
        expect(loaded.user?.date, createdAt);
        expect(loaded.usersWhoRated?.first.date, editedAt);

        expect(CommentFirestoreMapper.toFirestore(loaded), {
          'id': 'c-ts',
          'date': createdAt,
          'user': {
            'id': 'rider@example.com',
            'name': 'Rider',
            'date': createdAt,
          },
          'rating': 3,
          'comment': 'Nice drill',
          'parentId': 'c-parent',
          'editedDate': editedAt,
          'resourceId': 'res-1',
          'usersWhoRated': [
            {
              'id': 'voter@example.com',
              'date': editedAt,
              'isSelected': true,
            },
          ],
        });

        final minimal = Comment(
          id: null,
          user: null,
          date: createdAt,
          rating: null,
          comment: null,
          parentId: null,
          editedDate: null,
          resourceId: null,
          usersWhoRated: null,
        );
        expect(
          CommentFirestoreMapper.toFirestore(minimal),
          {'date': createdAt},
        );
        expect(CommentFirestoreMapper.toJson(minimal), {
          'id': null,
          'date': createdAt,
          'rating': null,
          'comment': null,
          'parentId': null,
          'user': null,
          'editedDate': null,
          'resourceId': null,
          'usersWhoRated': null,
        });
      },
    );

    test(
      'Resource preserves nested comments and replies through Firestore',
      () async {
        final fake = FakeFirebaseFirestore();
        final repo = ResourcesRepository(firestore: fake);

        final parent = Comment(
          id: 'c1',
          user: BaseListItem(id: 'u1@example.com', name: 'User 1'),
          date: createdAt,
          rating: 1,
          comment: 'Root comment',
          parentId: null,
          editedDate: null,
          resourceId: 'r1',
          usersWhoRated: const [],
        );
        final reply = Comment(
          id: 'c2',
          user: BaseListItem(id: 'u2@example.com', name: 'User 2'),
          date: editedAt,
          rating: 0,
          comment: 'Reply comment',
          parentId: 'c1',
          editedDate: null,
          resourceId: 'r1',
          usersWhoRated: const [],
        );
        final resource = Resource(
          id: 'r1',
          name: 'Test Resource',
          comments: [parent, reply],
        );

        await repo.createOrUpdateResource(resource: resource);
        final loaded = await repo.getResourceById('r1');

        expect(loaded?.comments, hasLength(2));
        expect(loaded?.comments?[0].id, 'c1');
        expect(loaded?.comments?[0].date, createdAt);
        expect(loaded?.comments?[1].id, 'c2');
        expect(loaded?.comments?[1].parentId, 'c1');
        expect(loaded?.comments?[1].date, editedAt);
      },
    );
  });
}
