import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// A [StatefulWidget] that displays a web view of a resource.
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
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _controller;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: true,
    allowsInlineMediaPlayback: true,
  );
  double progress = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              debugPrint('Loading $url');
            },
            onReceivedError: (controller, request, error) {
              debugPrint('Error: $error');
            },
            onProgressChanged: (controller, progress) {
              debugPrint('Progress: $progress');
              setState(() {
                this.progress = progress / 100;
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('Console Message: $consoleMessage');
            },
          ),
          if (progress < 1)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
        ],
      ),
    );
  }
}
