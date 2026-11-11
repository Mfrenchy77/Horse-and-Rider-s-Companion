import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_web_view.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:mocktail/mocktail.dart';

class _WebViewPlatform extends InAppWebViewPlatform {
  late PlatformInAppWebViewWidgetCreationParams callbacks;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    callbacks = params;
    return _WebViewWidget(params);
  }
}

class _WebViewWidget extends PlatformInAppWebViewWidget {
  _WebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError();

  @override
  void dispose() {}
}

class _Controller extends Mock implements InAppWebViewController {}

void main() {
  testWidgets(
    'web view indicates initial load, progress, completion and error',
    (tester) async {
      final platform = _WebViewPlatform();
      InAppWebViewPlatform.instance = platform;
      final controller = _Controller();
      await tester.pumpWidget(
        const MaterialApp(
          home: ResourceWebView(
            url: 'https://example.com/article',
            title: 'Article',
          ),
        ),
      );
      final progress = find.byKey(const Key('resourceWebProgress'));
      expect(tester.widget<LinearProgressIndicator>(progress).value, isNull);

      platform.callbacks.onProgressChanged!(controller, 45);
      await tester.pump();
      expect(tester.widget<LinearProgressIndicator>(progress).value, 0.45);

      platform.callbacks.onLoadStop!(controller, null);
      await tester.pump();
      expect(progress, findsNothing);

      platform.callbacks.onLoadStart!(controller, null);
      await tester.pump();
      expect(tester.widget<LinearProgressIndicator>(progress).value, isNull);

      final url = WebUri('https://example.com/article');
      final error = WebResourceError(
        type: WebResourceErrorType.UNKNOWN,
        description: 'Offline',
      );
      platform.callbacks.onReceivedError!(
        controller,
        WebResourceRequest(url: url, isForMainFrame: false),
        error,
      );
      await tester.pump();
      expect(progress, findsOneWidget);
      platform.callbacks.onReceivedError!(
        controller,
        WebResourceRequest(url: url, isForMainFrame: true),
        error,
      );
      await tester.pump();
      expect(progress, findsNothing);
    },
  );
  testWidgets('web view comments button opens the matching resource', (
    tester,
  ) async {
    InAppWebViewPlatform.instance = _WebViewPlatform();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ResourceWebView(
            url: 'https://example.com/guide',
            title: 'Guide',
            resourceId: 'guide-1',
          ),
        ),
        GoRoute(
          path: '/comments/:${ResourceCommentPage.pathParams}',
          name: ResourceCommentPage.name,
          builder: (_, state) => Scaffold(
            body: Text(state.pathParameters[ResourceCommentPage.pathParams]!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byTooltip('Resource comments'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('guide-1'), findsOneWidget);
  });
  testWidgets(
    'old FEI web links offer a browser tab without mounting an iframe',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResourceWebView(
            url:
                'https://www.fei.org/stories/lifestyle/teach-me/dressage-movements-101-advanced-piaffe-passage-canter-pirouette',
            title: 'Dressage Movements 101 – Advanced',
            resourceId: 'fei-guide',
          ),
        ),
      );
      expect(find.text('Open in browser'), findsOneWidget);
      expect(find.byTooltip('Resource comments'), findsOneWidget);
      expect(find.byType(InAppWebView), findsNothing);
      expect(find.byKey(const Key('resourceWebProgress')), findsNothing);
    },
    skip: !kIsWeb,
  );
}
