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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NOTE: Avoid RadioGroup here.
              // In some Flutter/web builds we've seen RadioGroup descendants behave oddly
              // (especially with toggleable radios). Keeping the classic RadioListTile
              // wiring is more predictable.
              RadioListTile<CommentSortState>(
                title: const Text('Newest'),
                value: CommentSortState.Recent,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  if (value == null) return;
                  cubit.sortComments(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<CommentSortState>(
                title: const Text('Oldest'),
                value: CommentSortState.Oldest,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  if (value == null) return;
                  cubit.sortComments(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<CommentSortState>(
                title: const Text('Highest Rated'),
                value: CommentSortState.Best,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  if (value == null) return;
                  cubit.sortComments(value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<CommentSortState>(
                title: const Text('Most Controversial'),
                value: CommentSortState.Worst,
                groupValue: state.commentSortState,
                onChanged: (value) {
                  if (value == null) return;
                  cubit.sortComments(value);
                  Navigator.of(context).pop();
                },
              ),
            ],
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
