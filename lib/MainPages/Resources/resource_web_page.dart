// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_web_view.dart';

class ResourceWebPage extends StatelessWidget {
  const ResourceWebPage({
    super.key,
    required this.url,
    required this.title,
    this.resourceId,
  });

  // Simple helper to build from GoRouter state
  ResourceWebPage.fromState(GoRouterState s)
    : url = s.pathParameters[urlPathParams]!,
      title = s.pathParameters[titlePathParams]!,
      resourceId = s.uri.queryParameters[resourceIdQueryParam],
      super(key: null);

  static const name = 'ResourceWebPage';
  static const path = 'Web/:$urlPathParams/:$titlePathParams';

  static const urlPathParams = 'url';
  static const titlePathParams = 'title';
  static const resourceIdQueryParam = 'resourceId';

  final String url;
  final String title;
  final String? resourceId;

  @override
  Widget build(BuildContext context) => ResourceWebView(
    key: ValueKey(url),
    url: url,
    title: title,
    resourceId: resourceId,
  );
}
