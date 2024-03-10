import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_comment_llist.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_info_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';

class ResourceCommentPage extends StatelessWidget {
  const ResourceCommentPage({super.key, required this.id});

  static const path = 'Comments/:resourceId';
  // static const guestResourceCommentPath = 'GuestCommentPage/:resourceId';
  // static const horseResourceCommentPath = 'HorseCommentPage/:resourceId';

  // static const userProfileResourceName = 'UserProfileResourcePage';
  // static const horseProfileResourceName = 'HorseProfileResourcePage';
  // static const guestProfileResourceName = 'GuestProfileResourcePage';

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
          const ResourceInfoBar(
            key: Key('ResourceInfoBar'),
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
