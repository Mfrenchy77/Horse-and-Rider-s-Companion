import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

class CommentNegativeButton extends StatelessWidget {
  const CommentNegativeButton({
    super.key,
    required this.onTap,
    required this.comment,
    required this.resource,
    required this.usersProfile,
  });

  final Comment comment;
  final Function() onTap;
  final Resource resource;
  final RiderProfile? usersProfile;
  @override
  Widget build(BuildContext context) {
    var isNegativeSelected = false;
    final isDark = SharedPrefs().isDarkMode;

    if (usersProfile == null) {
      return IconButton(
        icon: const Icon(Icons.thumb_down_outlined),
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
        child: BlocBuilder<CommentCubit, CommentState>(
          builder: (context, state) {
            final cubit = context.read<CommentCubit>();
            final rater = cubit.getUserRatingForComment(comment);
            isNegativeSelected = rater?.isCollapsed ?? false;
            return IconButton(
              icon: Icon(
                isNegativeSelected
                    ? Icons.thumb_down
                    : Icons.thumb_down_outlined,
              ),
              color: isNegativeSelected
                  ? Colors.red
                  : isDark
                      ? Colors.grey.shade300
                      : Colors.black54,
              onPressed: () {
                cubit.dontReccomendComment(comment: comment);
                onTap();
              },
            );
          },
        ),
      );
    }
  }
}
