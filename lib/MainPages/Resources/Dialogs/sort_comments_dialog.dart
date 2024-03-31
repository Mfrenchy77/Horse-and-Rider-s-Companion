import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class SortCommentsDialog extends StatelessWidget {
  const SortCommentsDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        /// list of radio buttons to sort the comments
        return AlertDialog(
          title: const Text('Sort Comments'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<CommentSortState>(
                toggleable: true,
                selected: state.commentSortState == CommentSortState.Recent,
                title: const Text('Newest'),
                value: CommentSortState.Recent,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  cubit.sortComments(CommentSortState.Recent);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<CommentSortState>(
                title: const Text('Oldest'),
                value: CommentSortState.Oldest,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  // sort the comments by oldest
                  cubit.sortComments(CommentSortState.Oldest);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<CommentSortState>(
                toggleable: true,
                selected: state.commentSortState == CommentSortState.Best,
                title: const Text('Highest Rated'),
                value: CommentSortState.Best,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  // sort the comments by most positive
                  cubit.sortComments(CommentSortState.Best);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<CommentSortState>(
                toggleable: true,
                selected: state.commentSortState == CommentSortState.Worst,
                title: const Text('Most Controversial'),
                value: CommentSortState.Worst,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  debugPrint('Sort value: $value');
                  // sort the comments by least positive
                  cubit.sortComments(CommentSortState.Worst);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
