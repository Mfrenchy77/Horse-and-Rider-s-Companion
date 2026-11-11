import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_image.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _ImageClient extends Fake implements HttpClient {
  _ImageClient(this.respond);

  final Future<HttpClientResponse> Function(Uri) respond;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _ImageRequest(() => respond(url));
}

class _ImageRequest extends Fake implements HttpClientRequest {
  _ImageRequest(this.respond);

  final Future<HttpClientResponse> Function() respond;

  @override
  Future<HttpClientResponse> close() => respond();
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  _ImageResponse(this.statusCode, [this.bytes = const []]);

  final List<int> bytes;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final int statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _legacyImage =
    'https://practicalhorsemanmag.com/wp-content/uploads/migrations/'
    'practicalhorseman/PRC-20-0911-AD4a-370.jpg';
const _legacyPage =
    'https://practicalhorsemanmag.com/training/'
    'the-insiders-guide-to-shoulder-in-at-all-levels/';
const _loggedProxy =
    'https://wsrv.nl/?url=https%3A%2F%2Fpracticalhorsemanmag.com'
    '%2Fwp-content%2Fuploads%2Fmigrations%2Fpracticalhorseman'
    '%2FPRC-20-0911-AD4a-370.jpg&w=840&dpr=1.75&we=1&output=webp';

Widget _legacyPreview({String page = _legacyPage}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(devicePixelRatio: 1.75),
    child: SmartImage(
      _loggedProxy,
      resourceUrl: page,
      maxLogicalWidth: 480,
      config: const SmartImageConfig(
        proxyMode: SmartImageProxyMode.always,
        forceWebP: true,
      ),
    ),
  ),
);

void main() {
  const source = 'https://media.example.com/horse.jpg?token=a%2Bb&size=2';
  final inner = Uri.http('wsrv.nl', '/', {'url': source});
  final outer =
      '${Uri.https('wsrv.nl', '/', {'url': inner.toString()})}'
      '&amp;w=840&amp;output=webp';

  test('recovers the source from nested and HTML-escaped proxy links', () {
    expect(imageSourceUrl(outer).toString(), source);
    expect(
      imageSourceUrl('https://images.weserv.nl/?url=media.example.com/a.jpg'),
      Uri.https('media.example.com', '/a.jpg'),
    );
    expect(imageSourceUrl('//media.example.com/a.jpg')?.scheme, 'https');
    expect(imageSourceUrl('https://wsrv.nl/?w=840'), isNull);
    expect(imageSourceUrl('javascript:alert(1)'), isNull);
    expect(imageSourceUrl('https://wsrv.nl/?url=%FF'), isNull);
  });

  testWidgets('the first proxy attempt targets the source, not another proxy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmartImage(
          outer,
          config: const SmartImageConfig(
            proxyMode: SmartImageProxyMode.always,
            preferDirectFirst: false,
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final provider = (image.image as ResizeImage).imageProvider as NetworkImage;
    final proxy = Uri.parse(provider.url);
    expect(proxy.host, 'wsrv.nl');
    expect(proxy.queryParameters['url'], source);
    await tester.pumpAndSettle();
    expect(find.text('Image unavailable'), findsOneWidget);
  });

  testWidgets('missing, invalid and failed previews show the decoded shield', (
    tester,
  ) async {
    const asset = AssetImage('assets/horse_logo.png');
    await tester.pumpWidget(const MaterialApp(home: Center()));
    final context = tester.element(find.byType(Center));
    await tester.runAsync(() => precacheImage(asset, context));

    for (final url in [
      '',
      'https://wsrv.nl/?w=840',
      'https://media.example.com/missing-resource-preview.jpg',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: ResourceImage(url: url)),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, asset);
      expect(image.fit, BoxFit.contain);
      expect(image.semanticLabel, contains('Preview unavailable'));
      final rendered = find.byType(RawImage);
      expect(tester.widget<RawImage>(rendered).image, isNotNull);
      expect(tester.getSize(rendered), const Size(200, 150));
      expect(tester.getSize(find.byType(ClipRRect)), const Size(200, 150));
    }
  });

  testWidgets('a decoded photo center-crops to fill wide and narrow frames', (
    tester,
  ) async {
    const url = 'https://media.example.com/preview-photo.png';
    await tester.pumpWidget(const MaterialApp(home: Center()));
    final context = tester.element(find.byType(Center));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final provider = ResizeImage(
      const NetworkImage(
        url,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      ),
      width: (480 * dpr).round(),
    );

    try {
      await tester.runAsync(() async {
        final bytes = await File('assets/horse_background.png').readAsBytes();
        debugNetworkImageHttpClientProvider = () =>
            _ImageClient((_) async => _ImageResponse(200, bytes));
        await precacheImage(provider, context);
      });

      for (final width in [200.0, 110.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: const ResourceImage(url: url),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rendered = find.byType(RawImage);
        final image = tester.widget<RawImage>(rendered);
        expect(image.image, isNotNull);
        expect(image.fit, BoxFit.cover);
        expect(image.alignment, Alignment.center);
        expect(tester.getSize(rendered), Size(width, 150));
        expect(tester.getSize(find.byType(ClipRRect)), Size(width, 150));
      }
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets('an edited image URL replaces the old candidate list', (
    tester,
  ) async {
    Future<void> show(String url) => tester.pumpWidget(
      MaterialApp(
        home: SmartImage(
          url,
          config: const SmartImageConfig(proxyMode: SmartImageProxyMode.none),
        ),
      ),
    );

    await show('https://media.example.com/stale.jpg');
    await tester.pumpAndSettle();
    expect(find.text('Image unavailable'), findsOneWidget);
    await show(source);
    final image = tester.widget<Image>(find.byType(Image));
    final provider = (image.image as ResizeImage).imageProvider as NetworkImage;
    expect(provider.url, source);
  });

  testWidgets('logged preview stops after origin status 0 and proxy 404', (
    tester,
  ) async {
    final attempts = <String>[];
    debugNetworkImageHttpClientProvider = () => _ImageClient((uri) async {
      attempts.add(uri.toString());
      return _ImageResponse(uri.host == 'wsrv.nl' ? 404 : 0);
    });
    try {
      var resolverCalls = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(_legacyPreview());
          await tester.pumpAndSettle();
          expect(attempts, [_legacyImage, _loggedProxy]);
          expect(find.text('Image unavailable'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_legacyPreview());
          await tester.pumpAndSettle();
          expect(attempts, [_legacyImage, _loggedProxy]);
          expect(resolverCalls, 1);
          expect(find.text('Image unavailable'), findsOneWidget);
        },
        () => MockClient((request) async {
          resolverCalls++;
          expect(request.url.toString(), resourceImageResolverEndpoint);
          expect(jsonDecode(request.body), {
            'url': _legacyPage,
            'hint': _legacyImage,
          });
          return http.Response('{"error":"No image found"}', 404);
        }),
      );
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets('shares the one resolved replacement across preview mounts', (
    tester,
  ) async {
    const page = 'https://example.com/resource';
    const replacement = 'https://example.com/current.jpg';
    final replacementResponse = Completer<HttpClientResponse>();
    final attempts = <String>[];
    debugNetworkImageHttpClientProvider = () => _ImageClient((uri) async {
      final url = uri.toString();
      attempts.add(url);
      if (url == replacement) return replacementResponse.future;
      return _ImageResponse(404);
    });
    try {
      var resolverCalls = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(_legacyPreview(page: page));
          await tester.pumpAndSettle();
          expect(attempts, [_legacyImage, _loggedProxy, replacement]);

          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_legacyPreview(page: page));
          await tester.pumpAndSettle();
          expect(attempts, [_legacyImage, _loggedProxy, replacement]);
          expect(resolverCalls, 1);

          replacementResponse.complete(_ImageResponse(404));
          await tester.pumpAndSettle();
          expect(find.text('Image unavailable'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((_) async {
          resolverCalls++;
          return http.Response(jsonEncode({'resolvedUrl': replacement}), 200);
        }),
      );
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
}
