import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_negative_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_positive_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_rating_buttons.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

void main() {
  late MockResourcesRepository repository;
  late CommentCubit cubit;
  late Comment comment;
  late Resource resource;
  late Completer<Comment> pending;
  late AppTestHarness harness;
  final rider = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');

  setUpAll(() => registerFallbackValue(Resource(id: 'fallback')));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    harness = await AppTestHarness.create();
    repository = MockResourcesRepository();
    pending = Completer<Comment>();
    when(
      () => repository.rateComment(
        resourceId: 'resource',
        commentId: 'comment',
        userEmail: rider.email,
        vote: any(named: 'vote'),
      ),
    ).thenAnswer((_) => pending.future);
    comment = Comment(
      id: 'comment',
      user: BaseListItem(id: 'author@example.com'),
      date: DateTime.utc(2025),
      rating: 0,
      comment: 'Helpful advice',
      parentId: null,
      editedDate: null,
      resourceId: 'resource',
      usersWhoRated: const [],
    );
    resource = Resource(id: 'resource', comments: [comment]);
    cubit = CommentCubit(
      comment: comment,
      resource: resource,
      usersProfile: rider,
      resourcesRepository: repository,
    );
  });
  tearDown(() async {
    if (!pending.isCompleted) pending.complete(comment);
    await cubit.close();
    await harness.close();
  });

  Comment voted({required bool? positive}) => comment.copyWith(
    rating: positive == null
        ? 0
        : positive
        ? 1
        : -1,
    usersWhoRated: [
      if (positive != null)
        BaseListItem(
          id: rider.email,
          isSelected: positive,
          isCollapsed: !positive,
        ),
    ],
  );

  Future<void> pumpShared(
    WidgetTester tester, {
    required VoidCallback onSaved,
    Resource? snapshot,
    bool guest = false,
    bool wholeComment = false,
  }) => tester.pumpWidget(
    RepositoryProvider<ResourcesRepository>.value(
      value: repository,
      child: BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          home: Scaffold(
            body: wholeComment
                ? CommentItem(comment: comment)
                : CommentRatingButtons(
                    comment: snapshot?.comments?.single ?? comment,
                    resource: snapshot ?? resource,
                    usersProfile: guest ? null : rider,
                    onSaved: onSaved,
                  ),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool positive,
    required VoidCallback onSaved,
  }) => tester.pumpWidget(
    RepositoryProvider<ResourcesRepository>.value(
      value: repository,
      child: BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: positive
                ? CommentPositiveRatingButton(
                    comment: comment,
                    resource: resource,
                    usersProfile: rider,
                    onTap: onSaved,
                  )
                : CommentNegativeButton(
                    comment: comment,
                    resource: resource,
                    usersProfile: rider,
                    onTap: onSaved,
                  ),
          ),
        ),
      ),
    ),
  );

  for (final positive in [true, false]) {
    final name = positive ? 'positive' : 'negative';
    testWidgets('$name callback fires once after saving, never while loading', (
      tester,
    ) async {
      pending = Completer<Comment>();
      var calls = 0;
      await pumpButton(tester, positive: positive, onSaved: () => calls++);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(calls, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(
        comment.copyWith(
          rating: positive ? 1 : -1,
          usersWhoRated: [
            BaseListItem(
              id: rider.email,
              isSelected: positive,
              isCollapsed: !positive,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(
        find.byIcon(positive ? Icons.thumb_up : Icons.thumb_down),
        findsOneWidget,
      );
    });
  }

  testWidgets('both directions are disabled while a shared vote is saving', (
    tester,
  ) async {
    pending = Completer<Comment>();
    var calls = 0;
    await pumpShared(tester, onSaved: () => calls++);
    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pump();
    expect(calls, 0);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    verify(
      () => repository.rateComment(
        resourceId: 'resource',
        commentId: 'comment',
        userEmail: rider.email,
        vote: 1,
      ),
    ).called(1);
    pending.complete(voted(positive: true));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
  });

  testWidgets('switching votes and removing a vote update both icons once', (
    tester,
  ) async {
    final responses = [
      voted(positive: true),
      voted(positive: false),
      voted(positive: null),
    ];
    when(
      () => repository.rateComment(
        resourceId: 'resource',
        commentId: 'comment',
        userEmail: rider.email,
        vote: any(named: 'vote'),
      ),
    ).thenAnswer((_) async => responses.removeAt(0));
    var calls = 0;
    await pumpShared(tester, onSaved: () => calls++);
    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    await tester.tap(find.byIcon(Icons.thumb_down));
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
  });

  testWidgets('fresh snapshots update selection without saved callbacks', (
    tester,
  ) async {
    var calls = 0;
    await pumpShared(tester, onSaved: () => calls++);
    await pumpShared(
      tester,
      onSaved: () => calls++,
      snapshot: resource.copyWith(comments: [voted(positive: false)]),
    );
    await tester.pump();
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(calls, 0);
    verifyZeroInteractions(repository);
  });

  testWidgets('failed votes show an error and allow retry', (tester) async {
    pending = Completer<Comment>();
    var calls = 0;
    await pumpShared(tester, onSaved: () => calls++);
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pump();
    pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(harness.cubit.state.isError, isTrue);
    expect(harness.cubit.state.errorMessage, contains('Please try again'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);

    pending = Completer<Comment>();
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pump();
    pending.complete(voted(positive: false));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
  });

  testWidgets('guests cannot write votes', (tester) async {
    await pumpShared(tester, onSaved: () {}, guest: true);
    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pump();
    expect(harness.cubit.state.errorMessage, contains('logged in'));
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pump();
    verifyZeroInteractions(repository);
  });

  testWidgets('saving a downvote hides the comment actions exactly once', (
    tester,
  ) async {
    pending = Completer<Comment>();
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        usersProfile: rider,
        resource: resource,
        resources: [resource],
      ),
    );
    await pumpShared(tester, onSaved: () {}, wholeComment: true);
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(voted(positive: false));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.thumb_down), findsNothing);
    expect(find.byIcon(Icons.thumb_down_outlined), findsNothing);
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
  });
}
