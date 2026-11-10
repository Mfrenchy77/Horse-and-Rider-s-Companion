import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

class CommentPositiveRatingButton extends StatelessWidget {
  const CommentPositiveRatingButton({
    super.key,
    required this.onTap,
    required this.comment,
    required this.resource,
    required this.usersProfile,
  });
  final Comment comment;
  final void Function() onTap;
  final Resource resource;
  final RiderProfile? usersProfile;
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;

    if (usersProfile == null) {
      return IconButton(
        icon: const Icon(Icons.thumb_up_outlined),
        onPressed: () {
          context.read<AppCubit>().createError(
            'You must be logged in to rate a comment',
          );
        },
      );
    } else {
      return BlocListener<CommentCubit, CommentState>(
        listenWhen: (previous, current) =>
            previous.positiveStatus != current.positiveStatus,
        listener: (context, state) {
          if (state.positiveStatus == PositiveStatus.success) {
            onTap();
          } else if (state.positiveStatus == PositiveStatus.failure) {
            context.read<AppCubit>().createError(
              'Could not save your comment rating. Please try again.',
            );
          }
        },
        child: BlocBuilder<CommentCubit, CommentState>(
          builder: (context, state) {
            final cubit = context.read<CommentCubit>();
            final rater = cubit.getUserRatingForComment(comment);
            final selected = rater?.isSelected ?? false;
            final busy =
                state.positiveStatus == PositiveStatus.loading ||
                state.negativeStatus == NegativeStatus.loading;
            return state.positiveStatus == PositiveStatus.loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : IconButton(
                    tooltip: 'Recommend comment',
                    icon: Icon(
                      selected ? Icons.thumb_up : Icons.thumb_up_outlined,
                    ),
                    color: selected
                        ? HorseAndRidersTheme().getTheme().colorScheme.primary
                        : isDark
                        ? Colors.grey.shade300
                        : Colors.black54,
                    onPressed: busy
                        ? null
                        : () => cubit.reccomendComment(comment: comment),
                  );
          },
        ),
      );
    }
  }
}
