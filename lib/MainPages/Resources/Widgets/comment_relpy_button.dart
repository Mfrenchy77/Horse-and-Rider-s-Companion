// ignore_for_file: file_names
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/create_comment_dialog.dart';

class CommentReplyButton extends StatelessWidget {
  const CommentReplyButton({
    super.key,
    required this.comment,
    required this.resource,
    required this.usersProfile,
    this.onTap,
  });

  final Comment comment; // parent to reply to
  final Resource resource; // resource holding the thread
  final RiderProfile? usersProfile; // null => disabled
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = usersProfile == null;
    return IconButton(
      tooltip: disabled ? 'Sign in to reply' : 'Reply',
      onPressed: disabled
          ? null
          : () {
              onTap?.call();
              showDialog<AlertDialog>(
                context: context,
                builder: (_) => BlocProvider(
                  create: (_) => CommentCubit(
                    comment: comment, // reply to this
                    resource: resource,
                    usersProfile: usersProfile!,
                  )..setEdit(isEdit: false),
                  child: CreateCommentDialog(
                    key: const Key('CreateCommentDialog_reply'),
                    isEdit: false,
                    resource: resource,
                    usersProfile: usersProfile!,
                    comment: comment, // parent reference for UI
                  ),
                ),
              );
            },
      icon: const Icon(Icons.reply),
    );
  }
}
