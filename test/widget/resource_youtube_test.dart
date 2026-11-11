import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_web_view.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_web_page.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';

import '../support/app_test_harness.dart';

void main() {
  const videoId = 'dQw4w9WgXcQ';
  const watch = 'https://www.youtube.com/watch?v=$videoId';

  test('recognizes playable YouTube paths and exact hostnames', () {
    for (final link in [
      watch,
      'https://youtu.be/$videoId',
      'https://m.youtube.com/shorts/$videoId',
      'https://www.youtube.com/live/$videoId',
      'https://www.youtube-nocookie.com/embed/$videoId',
    ]) {
      expect(youtubeWatchUri(link)?.toString(), watch);
    }
    expect(
      youtubeWatchUri(
        'https://youtu.be/$videoId?t=40&list=playlist',
      )?.queryParameters,
      {'t': '40', 'list': 'playlist', 'v': videoId},
    );
    expect(
      youtubeWatchUri(
        'https://www.youtube.com/embed/$videoId?start=40',
      )?.queryParameters['t'],
      '40',
    );
    expect(
      youtubeWatchUri('https://youtube.com.example/watch?v=$videoId'),
      isNull,
    );
    expect(
      youtubeWatchUri('https://youtu.be/$videoId#t=40s')?.fragment,
      't=40s',
    );
    expect(youtubeWatchUri('https://youtu.be/%FF'), isNull);
    expect(youtubeWatchUri('https://www.youtube.com/@channel'), isNull);
  });

  test('recognizes Facebook links that require an external browser', () {
    expect(
      shouldOpenResourceExternally(
        'https://www.facebook.com/100064451033652/posts/example',
      ),
      isTrue,
    );
    expect(
      shouldOpenResourceExternally('https://m.facebook.com/example'),
      isTrue,
    );
    expect(
      shouldOpenResourceExternally('https://facebook.com.example/post'),
      isFalse,
    );
    expect(
      shouldOpenResourceExternally('https://example.com/facebook'),
      isFalse,
    );
  });

  testWidgets('taps on the card and preview launch YouTube externally', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final calls = <MethodCall>[];
    var launchSucceeds = true;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return launchSucceeds;
      });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final video = Resource(
      id: 'video',
      type: ResourceType.link,
      name: 'Training video',
      url: 'https://youtu.be/$videoId',
      lastEditDate: DateTime.utc(2025),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ResourcesItem(resource: video, isResourceList: false),
          ),
        ),
        GoRoute(
          path: '/comments/:resourceId',
          name: ResourceCommentPage.name,
          builder: (_, __) => const Scaffold(body: Text('Discussion')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Training video'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ResourceImage')));
    await tester.pumpAndSettle();
    expect(calls.map((call) => call.method), ['launch', 'launch']);
    for (final call in calls) {
      final arguments = call.arguments as Map<Object?, Object?>;
      expect(arguments['url'], watch);
      expect(arguments['useSafariVC'], isFalse);
      expect(arguments['useWebView'], isFalse);
    }

    launchSucceeds = false;
    await tester.tap(find.byKey(const Key('ResourceImage')));
    await tester.pumpAndSettle();
    expect(harness.cubit.state.errorMessage, 'Unable to open resource link');

    await tester.tap(find.text('Comments'));
    await tester.pumpAndSettle();
    expect(find.text('Discussion'), findsOneWidget);
  });

  testWidgets('old YouTube web routes render a watch action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResourceWebView(url: watch, title: 'Training'),
      ),
    );
    expect(find.text('Watch on YouTube'), findsOneWidget);
  });

  for (final type in [ResourceType.article, ResourceType.link]) {
    testWidgets('preview tap preserves the route for ${type.name}', (
      tester,
    ) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(
        type == ResourceType.link ? 320 : 1000,
        800,
      );
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final skill = Skill(
        id: 'grooming',
        skillName: 'Grooming',
        rider: true,
        position: 0,
        lastEditBy: 'editor',
        lastEditDate: DateTime.utc(2025),
        description: '',
        learningDescription: '',
        proficientDescription: '',
      );
      harness.cubit.emit(harness.cubit.state.copyWith(allSkills: [skill]));
      final resource = Resource(
        id: 'guide',
        type: type,
        name: 'Training guide',
        authorName: 'Morgan Rider',
        description: 'Practical tips for riders.',
        skillTreeIds: ['grooming'],
        url: 'https://example.com/guide',
        lastEditDate: DateTime.utc(2025),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: ResourcesItem(resource: resource, isResourceList: false),
            ),
          ),
          GoRoute(
            path: '/comments/:resourceId',
            name: ResourceCommentPage.name,
            builder: (_, __) => const Scaffold(body: Text('Article details')),
          ),
          GoRoute(
            path: '/web/:url/:title',
            name: ResourceWebPage.name,
            builder: (_, __) => const Scaffold(body: Text('Web resource')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final preview = find.byKey(const Key('ResourceImage'));
      final image = tester.getRect(preview);
      final card = tester.getRect(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first,
      );
      final title = tester.getRect(find.text('Training guide'));
      expect(image.left, card.left);
      expect(image.right, card.right);
      expect(image.top, card.top);
      expect(title.top, greaterThan(image.bottom));
      expect(find.text('Grooming'), findsOneWidget);
      expect(
        find.text(type == ResourceType.link ? 'example.com' : 'Morgan Rider'),
        findsOneWidget,
      );
      final fallbackImage = find.descendant(
        of: preview,
        matching: find.byType(Image),
      );
      final fallback = tester.widget<Image>(fallbackImage);
      expect(tester.getRect(fallbackImage), image);
      expect(fallback.image, const AssetImage('assets/horse_logo.png'));
      expect(tester.takeException(), isNull);
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(
        find.text(
          type == ResourceType.article ? 'Article details' : 'Web resource',
        ),
        findsOneWidget,
      );
    });
  }
}
