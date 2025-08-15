import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class SortCommentsDialog extends StatelessWidget {
  const SortCommentsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return AlertDialog(
          title: const Text('Sort Comments'),
          content: RadioGroup<CommentSortState>(
            // NEW: manage selection at the group level (Flutter 3.35+)
            groupValue: state.commentSortState,
            onChanged: (CommentSortState? value) {
              if (value == null) return;
              cubit.sortComments(value);
              Navigator.of(context).pop();
            },
            // Children no longer specify groupValue/onChanged
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<CommentSortState>(
                  toggleable: true,
                  selected: state.commentSortState == CommentSortState.Recent,
                  title: const Text('Newest'),
                  value: CommentSortState.Recent,
                ),
                const RadioListTile<CommentSortState>(
                  title: Text('Oldest'),
                  value: CommentSortState.Oldest,
                ),
                RadioListTile<CommentSortState>(
                  toggleable: true,
                  selected: state.commentSortState == CommentSortState.Best,
                  title: const Text('Highest Rated'),
                  value: CommentSortState.Best,
                ),
                RadioListTile<CommentSortState>(
                  toggleable: true,
                  selected: state.commentSortState == CommentSortState.Worst,
                  title: const Text('Most Controversial'),
                  value: CommentSortState.Worst,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
