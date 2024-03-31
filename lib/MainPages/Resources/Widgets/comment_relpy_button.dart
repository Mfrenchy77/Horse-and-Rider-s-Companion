import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/create_comment_dialog.dart';

class CommentReplyButton extends StatelessWidget {
  const CommentReplyButton({
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
    return IconButton(
      icon: const Icon(Icons.reply),
      onPressed: () {
        if (usersProfile == null) {
          context.read<AppCubit>().createError('You must be logged in'
              ' to reply to a comment');
          return;
        } else {
          debugPrint('Reply to Comment: ${comment.id}');
          showDialog<AlertDialog>(
            context: context,
            builder: (context) => CreateCommentDialog(
              isEdit: false,
              comment: comment,
              resource: resource,
              usersProfile: usersProfile!,
            ),
          );
          onTap();
        }
      },
    );
  }
}
