import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_negative_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_positive_rating_button.dart';

/// Both voting directions share one pending write and the latest saved vote.
class CommentRatingButtons extends StatefulWidget {
  const CommentRatingButtons({
    required this.comment,
    required this.resource,
    required this.usersProfile,
    required this.onSaved,
    super.key,
  });

  final Comment comment;
  final Resource resource;
  final RiderProfile? usersProfile;
  final VoidCallback onSaved;

  @override
  State<CommentRatingButtons> createState() => _CommentRatingButtonsState();
}

class _CommentRatingButtonsState extends State<CommentRatingButtons> {
  CommentCubit? _cubit;

  @override
  void initState() {
    super.initState();
    _createCubit();
  }

  void _createCubit() {
    final profile = widget.usersProfile;
    _cubit = profile == null
        ? null
        : CommentCubit(
            comment: widget.comment,
            resource: widget.resource,
            usersProfile: profile,
            resourcesRepository: context.read<ResourcesRepository>(),
          );
  }

  @override
  void didUpdateWidget(CommentRatingButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usersProfile?.email != widget.usersProfile?.email ||
        oldWidget.resource.id != widget.resource.id ||
        oldWidget.comment.id != widget.comment.id) {
      final previous = _cubit;
      if (previous != null) unawaited(previous.close());
      _createCubit();
    } else if (!identical(oldWidget.resource, widget.resource)) {
      _cubit?.updateResource(widget.resource);
    }
  }

  @override
  void dispose() {
    final cubit = _cubit;
    if (cubit != null) unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      children: [
        Expanded(
          child: CommentPositiveRatingButton(
            key: const Key('positive_rating_button'),
            comment: widget.comment,
            resource: widget.resource,
            usersProfile: widget.usersProfile,
            onTap: widget.onSaved,
          ),
        ),
        Expanded(
          child: CommentNegativeButton(
            key: const Key('negative_rating_button'),
            comment: widget.comment,
            resource: widget.resource,
            usersProfile: widget.usersProfile,
            onTap: widget.onSaved,
          ),
        ),
      ],
    );
    final cubit = _cubit;
    return cubit == null
        ? buttons
        : BlocProvider.value(value: cubit, child: buttons);
  }
}
