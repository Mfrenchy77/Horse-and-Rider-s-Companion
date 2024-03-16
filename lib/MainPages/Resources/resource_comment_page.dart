import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_comment_llist.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_info_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';

class ResourceCommentPage extends StatelessWidget {
  const ResourceCommentPage({super.key, required this.id});

  static const pathParams = 'resourceId';
  static const name = 'ResourceCommentPage';
  static const path = 'Comments/:resourceId';

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Comment Page'),
      ),
      body: Column(
        children: [
          ResourceRatingButtons(
            resource: context.read<AppCubit>().state.resource!,
          ),
          Divider(
            color: Theme.of(context).primaryColor,
            endIndent: 5,
            indent: 5,
          ),
          ResourceInfoBar(
            resource: context.read<AppCubit>().state.resource!,
            key: const Key('ResourceInfoBar'),
          ),
          smallGap(),
          Divider(
            color: Theme.of(context).primaryColor,
            endIndent: 5,
            indent: 5,
          ),
          smallGap(),
          const ResourceCommentList(
            key: Key('ResourceCommentList'),
          ),
        ],
      ),
    );
  }
}
