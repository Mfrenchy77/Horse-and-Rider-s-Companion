import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/reource_comment_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_info_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';

class CommentPageHeader extends StatelessWidget {
  const CommentPageHeader({
    super.key,
    required this.resource,
  });
  final Resource resource;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ResourceRatingButtons(
          resource: resource,
        ),
        Divider(
          color: Theme.of(context).primaryColor,
          endIndent: 5,
          indent: 5,
        ),
        ResourceInfoBar(
          resource: resource,
          key: const Key('ResourceInfoBar'),
        ),
        smallGap(),
        Divider(
          color: Theme.of(context).primaryColor,
          endIndent: 5,
          indent: 5,
        ),
        ResourceCommentBar(
          resource: resource,
          key: const Key('ResourceCommentBar'),
        ),
        Divider(
          color: Theme.of(context).primaryColor,
          endIndent: 5,
          indent: 5,
        ),
      ],
    );
  }
}
