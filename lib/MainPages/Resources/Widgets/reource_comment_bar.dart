import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/sort_comments_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/create_comment_dialog.dart';

class ResourceCommentBar extends StatelessWidget {
  const ResourceCommentBar({super.key, required this.resource});
  final Resource resource;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                IconButton.outlined(
                  onPressed: () {},
                  icon: Text('${resource.rating}'),
                ),
                const Text('Rating'),
              ],
            ),
            Column(
              children: [
                IconButton.outlined(
                  onPressed: () {},
                  icon: Text('${resource.comments?.length ?? 0}'),
                ),
                const Text('Comments'),
              ],
            ),
            Column(
              children: [
                IconButton.outlined(
                  onPressed: state.usersProfile == null
                      ? null
                      : () {
                          showDialog<AlertDialog>(
                            context: context,
                            builder: (_) => BlocProvider(
                              create: (_) => CommentCubit(
                                comment: null,
                                resource: resource,
                                usersProfile: state.usersProfile!,
                              )..setEdit(isEdit: false),
                              child: CreateCommentDialog(
                                key: const Key('CreateCommentDialog_fromBar'),
                                isEdit: false,
                                resource: resource,
                                usersProfile: state.usersProfile!,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.send),
                ),
                const Text('Comment'),
              ],
            ),
            Column(
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    showDialog<AlertDialog>(
                      context: context,
                      builder: (context) => const SortCommentsDialog(
                        key: Key('SortCommentsDialog'),
                      ),
                    );
                  },
                ),
                Text(context.read<AppCubit>().state.commentSortState.name),
              ],
            ),
          ],
        );
      },
    );
  }
}
