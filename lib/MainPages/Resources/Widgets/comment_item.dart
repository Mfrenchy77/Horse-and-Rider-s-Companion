import 'package:database_repository/database_repository.dart'; // Make sure this import is correct based on your project
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_negative_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_positive_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_relpy_button.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/util_methodsd.dart';

class CommentItem extends StatefulWidget {
  const CommentItem({
    super.key,
    required this.comment,
  });

  final Comment comment;

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _isActionsVisible = false;

  void _toggleActionsVisibility() {
    setState(() {
      _isActionsVisible = !_isActionsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isParent = widget.comment.parentId != null;

    return BlocListener<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.resources != current.resources,
      listener: (context, state) {
        setState(() {
          debugPrint('CommentItem: Resources Updated');
        });
      },
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final cubit = context.read<AppCubit>();
          final childComments = cubit.getChildComments(
            parentComment: widget.comment,
          );
          final commentResource = cubit.getResourceById(
            widget.comment.resourceId!,
          );

          if (commentResource == null) {
            return const SizedBox.shrink();
          } else {
            return InkWell(
              onTap: _toggleActionsVisibility,
              // This is the box that will show if
              // the comment id a child of the parent comment
              child: ColoredBox(
                color: HorseAndRidersTheme().getTheme().primaryColor,
                child: Padding(
                  padding: EdgeInsets.only(left: isParent ? 5 : 0),
                  child: Column(
                    children: [
                      ColoredBox(
                        color: HorseAndRidersTheme()
                            .getTheme()
                            .scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // This is the row that will show the rating,
                            // user name, and when the comment was made
                            Padding(
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: Row(
                                children: [
                                  Text(widget.comment.rating.toString()),
                                  smallGap(),
                                  TextButton(
                                    onPressed: widget.comment.user?.id == null
                                        ? null
                                        : () => context.pushNamed(
                                              ViewingProfilePage.name,
                                              pathParameters: {
                                                ViewingProfilePage.pathParams:
                                                    widget.comment.user!.id!,
                                              },
                                            ),
                                    child: Text(
                                      widget.comment.user?.name ?? '',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  smallGap(),
                                  Text(
                                    calculateTimeDifferenceBetween(
                                      referenceDate: widget.comment.date,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // This is the text that will show the comment
                            Padding(
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                widget.comment.comment ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            smallGap(),
                            // This is the row that will show the actions
                            // hidden by default
                            Visibility(
                              visible: _isActionsVisible,
                              child: Column(
                                children: [
                                  Divider(
                                    color: HorseAndRidersTheme()
                                        .getTheme()
                                        .primaryColor,
                                    endIndent: 5,
                                    indent: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      CommentPositiveRatingButton(
                                        onTap: _toggleActionsVisibility,
                                        key: const Key(
                                          'positive_rating_button',
                                        ),
                                        comment: widget.comment,
                                        resource: commentResource,
                                        usersProfile: state.usersProfile,
                                      ),
                                      CommentNegativeButton(
                                        onTap: _toggleActionsVisibility,
                                        key: const Key(
                                          'negative_rating_button',
                                        ),
                                        comment: widget.comment,
                                        resource: commentResource,
                                        usersProfile: state.usersProfile,
                                      ),
                                      CommentReplyButton(
                                        onTap: _toggleActionsVisibility,
                                        key: const Key('reply_button'),
                                        comment: widget.comment,
                                        resource: commentResource,
                                        usersProfile: state.usersProfile,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // List of child comments
                            if (childComments.isNotEmpty)
                              for (final Comment child in childComments)
                                CommentItem(
                                  comment: child,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
