import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_web_view.dart';

class ResourceWebPage extends StatelessWidget {
  const ResourceWebPage({
    super.key,
    required this.url,
    required this.title,
  });

  static const urlPathParams = 'url';
  static const titlePathParams = 'title';
  static const path = 'WebView/:url/:title';
  static const name = 'ResourceWebPage';

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        debugPrint(
          'Resource Web Page Pop Invoked: $didPop, result: $result',
        );
      },
      child: ResourceWebView(
        key: const Key('resourceWebView'),
        url: url,
        title: title,
      ),
    );
  }
}
