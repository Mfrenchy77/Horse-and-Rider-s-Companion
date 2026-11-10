import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ResourcesRepository repository;
  final date = DateTime.utc(2025);

  Map<String, dynamic> comment(String id, {int? rating = 0}) => {
    'id': id,
    'date': Timestamp.fromDate(date),
    'rating': rating,
    'comment': 'Helpful advice',
    'user': {'id': 'author@example.com'},
    'resourceId': 'resource',
    'parentId': null,
    'editedDate': null,
    'usersWhoRated': <Map<String, dynamic>>[],
    'extraCommentField': 'preserve this',
  };

  setUp(() async {
    db = FakeFirebaseFirestore();
    repository = ResourcesRepository(firestore: db);
    await db.collection('Resources').doc('resource').set({
      'name': 'Latest resource title',
      'skillTreeIds': ['skill'],
      'rating': 20,
      'extraResourceField': 'preserve this too',
      'comments': [comment('first'), comment('second')],
    });
  });

  Future<Comment> rate({
    String id = 'first',
    String user = 'rider@example.com',
    int vote = 1,
  }) => repository.rateComment(
    resourceId: 'resource',
    commentId: id,
    userEmail: user,
    vote: vote,
  );

  test(
    'adding, switching and removing a vote keeps one vote per user',
    () async {
      expect((await rate()).rating, 1);
      final negative = await rate(vote: -1);
      expect(negative.rating, -1);
      expect(negative.usersWhoRated, hasLength(1));
      expect(negative.usersWhoRated!.single.isSelected, isFalse);
      expect(negative.usersWhoRated!.single.isCollapsed, isTrue);
      final removed = await rate(vote: -1);
      expect(removed.rating, 0);
      expect(removed.usersWhoRated, isEmpty);
    },
  );

  test(
    'independent clients read current votes and preserve both users',
    () async {
      final other = ResourcesRepository(firestore: db);
      await rate();
      await other.rateComment(
        resourceId: 'resource',
        commentId: 'first',
        userEmail: 'other@example.com',
        vote: 1,
      );
      final updated = await rate(vote: -1);
      expect(updated.rating, 0);
      expect(
        updated.usersWhoRated!.map((v) => v.id),
        containsAll(['rider@example.com', 'other@example.com']),
      );
    },
  );

  test(
    'rating preserves resource edits, other comments and unknown fields',
    () async {
      await db.collection('Resources').doc('resource').update({
        'name': 'Edited since the comment page opened',
      });
      await rate();
      final data = (await db.collection('Resources').doc('resource').get())
          .data()!;
      expect(data['name'], 'Edited since the comment page opened');
      expect(data['rating'], 20);
      expect(data['skillTreeIds'], ['skill']);
      expect(data['extraResourceField'], 'preserve this too');
      final comments = data['comments'] as List;
      expect(
        (comments[0] as Map<String, dynamic>)['extraCommentField'],
        'preserve this',
      );
      expect(comments[1], comment('second'));
    },
  );

  test('legacy comments with null scores and votes can be rated', () async {
    await db.collection('Resources').doc('resource').update({
      'comments': [
        {...comment('first', rating: null), 'usersWhoRated': null},
      ],
    });
    expect((await rate(vote: -1)).rating, -1);
  });

  test('a removed comment is not recreated by a late vote', () async {
    await db.collection('Resources').doc('resource').update({'comments': []});
    await expectLater(rate(), throwsStateError);
    expect(
      (await db.collection('Resources').doc('resource').get())
          .data()!['comments'],
      isEmpty,
    );
  });

  test('a removed resource is not recreated by a late vote', () async {
    await db.collection('Resources').doc('resource').delete();
    await expectLater(rate(), throwsStateError);
    expect(
      (await db.collection('Resources').doc('resource').get()).exists,
      isFalse,
    );
  });

  test('rejects blank user IDs and invalid vote values', () async {
    await expectLater(rate(user: ' '), throwsArgumentError);
    await expectLater(rate(vote: 0), throwsArgumentError);
    await expectLater(rate(vote: 2), throwsArgumentError);
    expect(
      (await repository.getResourceById('resource'))!.comments!.first.rating,
      0,
    );
  });
}
