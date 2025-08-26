// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';

class ResourceWebView extends StatefulWidget {
  const ResourceWebView({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<ResourceWebView> createState() => _ResourceWebViewState();
}

class _ResourceWebViewState extends State<ResourceWebView> {
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _controller;

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    isInspectable: true,
    allowsInlineMediaPlayback: true,
  );

  double _progress = 0;
  bool _navigatingAway = false; // throttle duplicate back events

  void _goBackToResources() {
    if (_navigatingAway) return;
    _navigatingAway = true;
    // Use goNamed so the URL changes back to /Resources
    context.goNamed(ResourcesPage.name);
  }

  Future<void> _handleBack() async {
    // If not web and the in-app webview has history, go back inside it first.
    if (!kIsWeb && _controller != null) {
      final canGoBack = await _controller!.canGoBack();
      if (!mounted) return; // avoid BuildContext across async gaps
      if (canGoBack) {
        await _controller!.goBack();
        return; // stay on this page
      }
    }
    // Otherwise navigate back to the list (and update the URL)
    if (!mounted) return;
    _goBackToResources();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // we’ll decide what “back” means
      onPopInvokedWithResult: (didPop, _) async {
        // If something else already popped us, nothing to do.
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => context.push(widget.url),
              tooltip: 'Open in Browser',
            ),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
              key: _webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: _settings,
              onWebViewCreated: (controller) => _controller = controller,
              onLoadStart: (_, __) {},
              onReceivedError: (_, __, error) {
                debugPrint('Web error: $error');
              },
              onProgressChanged: (_, p) {
                setState(() => _progress = p / 100);
              },
              onConsoleMessage: (_, msg) => debugPrint('Console: $msg'),
            ),
            if (_progress < 1)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
