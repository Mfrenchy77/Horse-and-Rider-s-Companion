import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/sort_comments_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/create_comment_dialog.dart';

class ResourceCommentBar extends StatelessWidget {
  const ResourceCommentBar({super.key, required this.resource});

  final Resource resource;
  @override
  Widget build(BuildContext context) {
    // row that has the number of likes, number of comments, a button to make a comment, and a button to sort the comments
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // number of likes

            // a cirlce with the rating in th middle, under the cirlce says"Rating"

            Column(
              children: [
                IconButton.outlined(
                  onPressed: () {},
                  icon: Text('${resource.rating}'),
                ),
                const Text('Rating'),
              ],
            ),
            // Cirlce with the number of comments in the middle, under the cirlce says "Comments"
            Column(
              children: [
                IconButton.outlined(
                  onPressed: () {},
                  icon: Text('${resource.comments?.length}'),
                ),
                const Text('Comments'),
              ],
            ),

            // button to make a comment
            Column(
              children: [
                IconButton.outlined(
                  onPressed: state.usersProfile == null
                      ? null
                      : () {
                          showDialog<AlertDialog>(
                            context: context,
                            builder: (context) => CreateCommentDialog(
                              key: const Key(
                                'CreateCommentDialogforResourceCommentBar',
                              ),
                              isEdit: false,
                              resource: resource,
                              usersProfile: state.usersProfile!,
                            ),
                          );
                        },
                  icon: const Icon(Icons.send),
                ),
                const Text('Reply'),
              ],
            ),
            // button to sort the comments
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
                Text(state.commentSortState.name),
              ],
            ),
          ],
        );
      },
    );
  }
}
