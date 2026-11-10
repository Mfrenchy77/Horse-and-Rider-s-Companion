import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

void main() {
  late MockResourcesRepository repository;
  late CommentCubit cubit;
  final user = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');
  Comment comment({
    String id = 'c',
    String? parent,
    int? rating = 10,
    List<BaseListItem>? votes,
  }) => Comment(
    id: id,
    user: BaseListItem(id: 'author@example.com'),
    date: DateTime.utc(2025),
    rating: rating,
    comment: 'Original',
    parentId: parent,
    editedDate: null,
    resourceId: 'resource',
    usersWhoRated: votes ?? const [],
  );
  CommentCubit create({
    Comment? editing,
    List<Comment> comments = const [],
    ResourcesRepository? ratingRepository,
    RiderProfile? profile,
  }) => CommentCubit(
    comment: editing,
    resource: Resource(id: 'resource', comments: comments),
    usersProfile: profile ?? user,
    resourcesRepository: ratingRepository ?? repository,
  );
  setUpAll(() => registerFallbackValue(Resource(id: 'fallback')));
  setUp(() {
    repository = MockResourcesRepository();
    when(
      () => repository.createOrUpdateResource(resource: any(named: 'resource')),
    ).thenAnswer((_) async {});
    cubit = create();
  });
  tearDown(() => cubit.close());

  Resource savedResource() =>
      verify(
            () => repository.createOrUpdateResource(
              resource: captureAny(named: 'resource'),
            ),
          ).captured.single
          as Resource;

  test(
    'new comments preserve the resource and record author and trimmed body',
    () async {
      final original = cubit.state.resource!;
      cubit.updateCommentMessage('  Helpful advice  ');
      await cubit.sendComment();
      final saved = savedResource();
      expect(saved.comments?.single.comment, 'Helpful advice');
      expect(saved.comments?.single.user?.id, user.email);
      expect(saved.comments?.single.resourceId, original.id);
      expect(saved.comments?.single.parentId, isNull);
      expect(original.comments, isEmpty);
      expect(cubit.state.status, CommentStatus.success);
    },
  );
  test('replies link to their parent', () async {
    await cubit.close();
    final parent = comment();
    cubit = create(editing: parent, comments: [parent])
      ..updateCommentMessage('A reply');
    await cubit.sendComment();
    expect(savedResource().comments?.last.parentId, parent.id);
  });
  test(
    // ignore: lines_longer_than_80_chars
    'edits preserve author, original date, rating and parent without changing original',
    () async {
      await cubit.close();
      final original = comment(parent: 'parent');
      cubit = create(editing: original, comments: [original])
        ..setEdit(isEdit: true)
        ..updateCommentMessage('Edited');
      await cubit.sendComment();
      final saved = savedResource().comments!.single;
      expect(saved.id, original.id);
      expect(saved.comment, 'Edited');
      expect(saved.user?.id, original.user?.id);
      expect(saved.date, original.date);
      expect(saved.parentId, 'parent');
      expect(saved.rating, 10);
      expect(saved.editedDate, isNotNull);
      expect(original.comment, 'Original');
    },
  );
  test('failed comment writes do not change the in-memory resource', () async {
    cubit.updateCommentMessage('New comment');
    when(
      () => repository.createOrUpdateResource(resource: any(named: 'resource')),
    ).thenAnswer((_) async => throw Exception('offline'));
    await cubit.sendComment();
    expect(cubit.state.status, CommentStatus.initial);
    expect(cubit.state.resource?.comments, isEmpty);
  });

  for (final oldVote in [-1, 0, 1]) {
    for (final clicked in [-1, 1]) {
      test(
        'comment vote transitions from $oldVote when clicking $clicked',
        () async {
          await cubit.close();
          final original = comment(
            votes: List.unmodifiable([
              BaseListItem(
                id: 'other@example.com',
                isSelected: true,
                isCollapsed: false,
              ),
              if (oldVote != 0)
                BaseListItem(
                  id: user.email,
                  isSelected: oldVote == 1,
                  isCollapsed: oldVote == -1,
                ),
            ]),
          );
          final ratingRepository = ResourcesRepository(
            firestore: FakeFirebaseFirestore(),
          );
          await ratingRepository.createOrUpdateResource(
            resource: Resource(id: 'resource', comments: [original]),
          );
          cubit = create(
            comments: [original],
            ratingRepository: ratingRepository,
          );
          if (clicked == 1) {
            await cubit.reccomendComment(comment: original);
          } else {
            await cubit.dontReccomendComment(comment: original);
          }
          final nextVote = oldVote == clicked ? 0 : clicked;
          final saved = (await ratingRepository.getResourceById(
            'resource',
          ))!.comments!.single;
          expect(saved.rating, 10 - oldVote + nextVote);
          expect(
            saved.usersWhoRated?.where((v) => v.id == 'other@example.com'),
            hasLength(1),
          );
          expect(original.rating, 10);
          expect(original.usersWhoRated?.length, oldVote == 0 ? 1 : 2);
        },
      );
    }
  }
  test(
    'failed rating writes leave the original score and vote unchanged',
    () async {
      await cubit.close();
      final original = comment(votes: const []);
      cubit = create(comments: [original]);
      when(
        () => repository.rateComment(
          resourceId: 'resource',
          commentId: 'c',
          userEmail: user.email,
          vote: 1,
        ),
      ).thenAnswer((_) async => throw Exception('offline'));
      await cubit.reccomendComment(comment: original);
      expect(original.rating, 10);
      expect(original.usersWhoRated, isEmpty);
      expect(cubit.state.positiveStatus, PositiveStatus.failure);
    },
  );
  test('rapid duplicate votes do not create overlapping writes', () async {
    await cubit.close();
    final original = comment();
    cubit = create(comments: [original]);
    final pending = Completer<Comment>();
    when(
      () => repository.rateComment(
        resourceId: 'resource',
        commentId: 'c',
        userEmail: user.email,
        vote: 1,
      ),
    ).thenAnswer((_) => pending.future);
    final first = cubit.reccomendComment(comment: original);
    final second = cubit.reccomendComment(comment: original);
    pending.complete(
      original.copyWith(
        rating: 11,
        usersWhoRated: [BaseListItem(id: user.email, isSelected: true)],
      ),
    );
    await Future.wait([first, second]);
    verify(
      () => repository.rateComment(
        resourceId: 'resource',
        commentId: 'c',
        userEmail: user.email,
        vote: 1,
      ),
    ).called(1);
  });

  test('empty user emails cannot submit a rating', () async {
    await cubit.close();
    final original = comment();
    cubit = create(
      comments: [original],
      profile: RiderProfile(id: 'guest', name: 'Guest', email: ' '),
    );
    await cubit.reccomendComment(comment: original);
    verifyZeroInteractions(repository);
  });

  test(
    'rating controls read the latest local vote, not a stale comment',
    () async {
      await cubit.close();
      final original = comment();
      final saved = original.copyWith(
        rating: 11,
        usersWhoRated: [BaseListItem(id: user.email, isSelected: true)],
      );
      when(
        () => repository.rateComment(
          resourceId: 'resource',
          commentId: 'c',
          userEmail: user.email,
          vote: 1,
        ),
      ).thenAnswer((_) async => saved);
      cubit = create(comments: [original]);
      await cubit.reccomendComment(comment: original);
      expect(cubit.getUserRatingForComment(original)?.isSelected, isTrue);
    },
  );
}
