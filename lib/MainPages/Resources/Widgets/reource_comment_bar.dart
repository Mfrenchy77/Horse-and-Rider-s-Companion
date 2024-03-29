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
            Text('${resource.rating} Rating'),
            // number of comments
            Text('${resource.comments?.length ?? 0} Comments'),
            // button to make a comment
            ElevatedButton(
              onPressed: state.usersProfile == null
                  ? null
                  : () {
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (context) => CreateCommentDialog(
                          resource: resource,
                          usersProfile: state.usersProfile!,
                        ),
                      );
                    },
              child: const Text('Comment'),
            ),
            // button to sort the comments
            ElevatedButton(
              child: const Text('Sort Comments'),
              onPressed: () {
                showDialog<AlertDialog>(
                  context: context,
                  builder: (context) => const SortCommentsDialog(
                    key: Key('SortCommentsDialog'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
