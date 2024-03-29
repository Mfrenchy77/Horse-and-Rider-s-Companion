import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';

class ResourceCommentList extends StatelessWidget {
  const ResourceCommentList(
      {super.key, required this.resource, required this.scrollController});
  final Resource resource;
  final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final baseComments = cubit.getBaseComments(state.resourceComments);
        cubit.sortComments(state.commentSortState);
        return baseComments == null || baseComments.isEmpty
            ? const Text('No Comments, Yet')
            : ListView(
                controller: scrollController,
                shrinkWrap: true,
                children: baseComments
                    .map(
                      (comment) => CommentItem(
                        key: Key(comment.id!),
                        comment: comment,
                      ),
                    )
                    .toList(),
              );
      },
    );
  }
}
