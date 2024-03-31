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
    var isPositiveSelected = false;
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
      return BlocProvider(
        create: (context) => CommentCubit(
          comment: comment,
          resource: resource,
          usersProfile: usersProfile!,
        ),
        child: BlocListener<CommentCubit, CommentState>(
          listener: (context, state) {
            if (state.positiveStatus == PositiveStatus.success) {
              //refresh the widget
              onTap();
            }
          },
          child: BlocBuilder<CommentCubit, CommentState>(
            builder: (context, state) {
              final cubit = context.read<CommentCubit>();
              final rater = cubit.getUserRatingForComment(comment);
              isPositiveSelected = rater?.isSelected ?? false;
              return state.positiveStatus == PositiveStatus.loading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: Icon(
                        isPositiveSelected
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                      ),
                      color: isPositiveSelected
                          ? HorseAndRidersTheme().getTheme().colorScheme.primary
                          : isDark
                              ? Colors.grey.shade300
                              : Colors.black54,
                      onPressed: () {
                        cubit.reccomendComment(comment: comment);
                      },
                    );
            },
          ),
        ),
      );
    }
  }
}
