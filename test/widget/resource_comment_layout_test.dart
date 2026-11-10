import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/scroll_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

void main() {
  late AppTestHarness harness;
  final rider = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');

  Comment comment(String id, {String? parent}) => Comment(
    id: id,
    user: BaseListItem(id: 'author@example.com', name: 'Author'),
    date: DateTime.utc(2025),
    rating: 0,
    comment: 'Comment $id',
    parentId: parent,
    editedDate: null,
    resourceId: 'resource',
    usersWhoRated: const [],
  );

  setUpAll(() => registerFallbackValue(Resource(id: 'fallback')));

  setUp(() async {
    harness = await AppTestHarness.create();
  });
  tearDown(() => harness.close());

  Resource resource(List<Comment> comments) => Resource(
    id: 'resource',
    name: 'Comment layout test',
    rating: 0,
    comments: comments,
  );

  Future<void> pumpPage(WidgetTester tester, Resource value) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        resource: value,
        resources: [value],
        resourceComments: value.comments,
        usersProfile: rider,
      ),
    );
    await tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: harness.resources,
        child: BlocProvider.value(
          value: harness.cubit,
          child: const MaterialApp(home: ResourceCommentPage(id: 'resource')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder row(String id) => find.byWidgetPredicate(
    (widget) => widget is CommentItem && widget.comment.id == id,
  );

  testWidgets('eleven stored comments render exactly eleven comment rows', (
    tester,
  ) async {
    final comments = [
      comment('a'),
      comment('a1', parent: 'a'),
      comment('a2', parent: 'a'),
      comment('a11', parent: 'a1'),
      comment('b'),
      comment('b1', parent: 'b'),
      comment('b2', parent: 'b'),
      comment('c'),
      comment('c1', parent: 'c'),
      comment('d'),
      comment('d1', parent: 'd'),
    ];
    await pumpPage(tester, resource(comments));

    expect(find.byType(CommentItem), findsNWidgets(11));
    for (final item in comments) {
      expect(row(item.id!), findsOneWidget);
      expect(find.text(item.comment!), findsOneWidget);
    }
    expect(find.widgetWithText(IconButton, '11'), findsNWidgets(2));
    expect(harness.cubit.state.resource!.comments, hasLength(11));
    verifyNever(
      () => harness.resources.createOrUpdateResource(
        resource: any(named: 'resource'),
      ),
    );
  });

  testWidgets('nested replies appear once under their parent thread', (
    tester,
  ) async {
    await pumpPage(
      tester,
      resource([
        comment('parent'),
        comment('reply', parent: 'parent'),
        comment('nested', parent: 'reply'),
        comment('next'),
      ]),
    );

    expect(find.byType(CommentItem), findsNWidgets(4));
    final parent = tester.getTopLeft(find.text('Comment parent'));
    final reply = tester.getTopLeft(find.text('Comment reply'));
    final nested = tester.getTopLeft(find.text('Comment nested'));
    final next = tester.getTopLeft(find.text('Comment next'));
    expect(reply.dy, greaterThan(parent.dy));
    expect(nested.dy, greaterThan(reply.dy));
    expect(next.dy, greaterThan(nested.dy));
    expect(reply.dx, greaterThan(parent.dx));
    expect(nested.dx, greaterThan(reply.dx));

    // Use a scrollable viewport when checking the parent navigation controls.
    tester.view.physicalSize = const Size(1000, 600);
    await tester.pumpAndSettle();
    var navigation = tester.widget<ScrollButton>(find.byType(ScrollButton));
    expect(navigation.isAtFirstParent, isTrue);
    navigation.onScrollDown();
    await tester.pumpAndSettle();
    navigation = tester.widget<ScrollButton>(find.byType(ScrollButton));
    expect(navigation.isAtLastParent, isTrue);
    navigation.onScrollUp();
    await tester.pumpAndSettle();
    expect(find.byType(CommentItem), findsNWidgets(4));
  });

  testWidgets('rating a reply updates its single row and leaves others alone', (
    tester,
  ) async {
    final parent = comment('parent');
    final reply = comment('reply', parent: parent.id);
    final other = comment('other');
    final value = resource([parent, reply, other]);
    final rated = reply.copyWith(
      rating: 1,
      usersWhoRated: [BaseListItem(id: rider.email, isSelected: true)],
    );
    when(
      () => harness.resources.rateComment(
        resourceId: 'resource',
        commentId: 'reply',
        userEmail: rider.email,
        vote: 1,
      ),
    ).thenAnswer((_) async => rated);
    await pumpPage(tester, value);

    expect(row('reply'), findsOneWidget);
    await tester.tap(
      find.descendant(of: row('reply'), matching: find.text('0')),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Recommend comment'));
    await tester.pumpAndSettle();
    verify(
      () => harness.resources.rateComment(
        resourceId: 'resource',
        commentId: 'reply',
        userEmail: rider.email,
        vote: 1,
      ),
    ).called(1);

    final updated = value.copyWith(comments: [parent, rated, other]);
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        resource: updated,
        resources: [updated],
        resourceComments: updated.comments,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommentItem), findsNWidgets(3));
    expect(tester.widget<CommentItem>(row('reply')).comment.rating, 1);
    expect(tester.widget<CommentItem>(row('parent')).comment.rating, 0);
    expect(tester.widget<CommentItem>(row('other')).comment.rating, 0);
  });
}
