import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/comment_sorting.dart';

class ResourceCommentList extends StatelessWidget {
  const ResourceCommentList({
    super.key,
    required this.resource,
    required this.scrollController,
  });
  final Resource resource;
  final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.resource != current.resource ||
          previous.commentSortState != current.commentSortState ||
          previous.resourceComments != current.resourceComments,
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final activeResource = state.resource;
        if (activeResource == null) {
          return const Text('No Comments, Yet');
        }
        final baseComments = sortCommentsBy(
          cubit.getBaseComments(activeResource),
          state.commentSortState,
        );
        if (baseComments.isEmpty) {
          return const Text('No Comments, Yet');
        }
        return ListView.builder(
          controller: scrollController,
          shrinkWrap: true,
          itemCount: baseComments.length,
          itemBuilder: (context, index) {
            final comment = baseComments[index];
            return CommentItem(
              key: comment.id != null ? Key(comment.id!) : null,
              comment: comment,
            );
          },
        );
      },
    );
  }
}
