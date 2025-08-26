// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_web_view.dart';

class ResourceWebPage extends StatelessWidget {
  const ResourceWebPage({
    super.key,
    required this.url,
    required this.title,
  });

  // Simple helper to build from GoRouter state
  ResourceWebPage.fromState(GoRouterState s)
      : url = s.pathParameters[urlPathParams]!,
        title = s.pathParameters[titlePathParams]!,
        super(key: null);

  static const name = 'ResourceWebPage';
  static const path = 'Web/:$urlPathParams/:$titlePathParams';

  static const urlPathParams = 'url';
  static const titlePathParams = 'title';

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) => ResourceWebView(url: url, title: title);
}
