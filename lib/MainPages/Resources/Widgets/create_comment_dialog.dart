import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class CreateCommentDialog extends StatelessWidget {
  const CreateCommentDialog({
    super.key,
    this.comment,
    required this.isEdit,
    required this.resource,
    required this.usersProfile,
  });

  /// The comment that the user is commenting on
  final bool isEdit;
  final Comment? comment;
  final Resource resource;
  final RiderProfile usersProfile;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentCubit(
        comment: comment,
        resource: resource,
        usersProfile: usersProfile,
      ),
      child: BlocBuilder<CommentCubit, CommentState>(
        builder: (context, state) {
          final cubit = context.read<CommentCubit>()..setEdit(isEdit: isEdit);
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // If this is a reply to a comment, show the comment and make it selectable

                if (comment != null && !isEdit) ...[
                  SelectableText(comment!.comment ?? ''),
                  Divider(
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                    color: HorseAndRidersTheme().getTheme().primaryColor,
                  ),
                ],
                TextFormField(
                  minLines: 1,
                  maxLines: 20,
                  initialValue: isEdit ? comment?.comment : null,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  autofocus: true,
                  onChanged: cubit.updateCommentMessage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    label: Text('Comment'),
                    hintText: 'Write a comment',
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.send),
                    onPressed: state.commentMessage.length < 3
                        ? null
                        : () => _sendComment(
                              context: context,
                              cubit: cubit,
                            ),
                    label: const Text('Send Comment'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

void _sendComment({
  required BuildContext context,
  required CommentCubit cubit,
}) {
  cubit.sendComment();
  Navigator.of(context).pop();
}
