// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';

class ResourceWebView extends StatefulWidget {
  const ResourceWebView({
    super.key,
    required this.url,
    required this.title,
    this.resourceId,
  });

  final String url;
  final String title;
  final String? resourceId;

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

  bool _loading = true;
  double? _progress;
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

  void _startLoading() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _progress = null;
    });
  }

  void _finishLoading() {
    if (!mounted || !_loading) return;
    setState(() => _loading = false);
  }

  void _updateProgress(int percent) {
    if (percent >= 100) {
      _finishLoading();
      return;
    }
    if (!mounted || !_loading || percent <= 0) return;
    setState(() => _progress = percent / 100);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = youtubeWatchUri(widget.url) != null;
    final externalOnly = shouldOpenResourceExternally(widget.url);
    void openExternally() =>
        context.read<AppCubit>().openResource(url: widget.url);

    return PopScope(
      canPop: false, // we’ll decide what “back” means
      onPopInvokedWithResult: (didPop, _) async {
        // If something else already popped us, nothing to do.
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: ThemedAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          title: Text(widget.title),
          bottom: !isVideo && !externalOnly && _loading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    key: const Key('resourceWebProgress'),
                    value: _progress,
                    semanticsLabel: 'Loading web page',
                    minHeight: 4,
                  ),
                )
              : null,
          actions: [
            if (widget.resourceId case final id? when id.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Resource comments',
                onPressed: () => context.pushNamed(
                  ResourceCommentPage.name,
                  pathParameters: {ResourceCommentPage.pathParams: id},
                ),
              ),
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: openExternally,
              tooltip: 'Open in Browser',
            ),
          ],
        ),
        body: isVideo
            ? Center(
                child: FilledButton.icon(
                  onPressed: openExternally,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch on YouTube'),
                ),
              )
            : externalOnly
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      const Text(
                        'Open this resource in a new browser tab.',
                        textAlign: TextAlign.center,
                      ),
                      FilledButton.icon(
                        onPressed: openExternally,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Open in browser'),
                      ),
                    ],
                  ),
                ),
              )
            : InAppWebView(
                key: _webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: _settings,
                onWebViewCreated: (controller) => _controller = controller,
                onLoadStart: (_, _) => _startLoading(),
                onLoadStop: (_, _) => _finishLoading(),
                onProgressChanged: (_, percent) => _updateProgress(percent),
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame ?? true) _finishLoading();
                  debugPrint('Web error: $error');
                },
                onReceivedHttpError: (_, request, _) {
                  if (request.isForMainFrame ?? false) _finishLoading();
                },
                onConsoleMessage: (_, msg) => debugPrint('Console: $msg'),
              ),
      ),
    );
  }
}
