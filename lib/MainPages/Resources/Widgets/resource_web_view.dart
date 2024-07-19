import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  State<ResourceWebView> createState() => _ResourceWevViewState();
}

class _ResourceWevViewState extends State<ResourceWebView> {
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}
