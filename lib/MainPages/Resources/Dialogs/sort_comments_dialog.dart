import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';

class SortCommentsDialog extends StatelessWidget {
  const SortCommentsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return OceanCoralAppDialog(
          title: const Text('Sort Comments'),
          content: RadioGroup<CommentSortState>(
            groupValue: state.commentSortState,
            onChanged: (value) {
              if (value == null) return;
              cubit.sortComments(value);
              Navigator.of(context).pop();
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<CommentSortState>(
                  title: Text('Newest'),
                  value: CommentSortState.Recent,
                ),
                RadioListTile<CommentSortState>(
                  title: Text('Oldest'),
                  value: CommentSortState.Oldest,
                ),
                RadioListTile<CommentSortState>(
                  title: Text('Highest Rated'),
                  value: CommentSortState.Best,
                ),
                RadioListTile<CommentSortState>(
                  title: Text('Most Controversial'),
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
