import 'package:collection/collection.dart';
import 'package:database_repository/database_repository.dart'; // Make sure this import is correct based on your project
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/support_message_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_negative_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_positive_rating_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_relpy_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/create_comment_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
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
          )..sort((a, b) => b.date.compareTo(a.date));

          final commentResource = state.resource;

          final usersRating = widget.comment.usersWhoRated?.firstWhereOrNull(
            (BaseListItem element) => element.id == state.usersProfile?.email,
          );
          final hasUserRated = usersRating != null;
          final isPositiveSelected = usersRating?.isSelected ?? false;

          final isDark = SharedPrefs().isDarkMode;
          if (commentResource == null) {
            return const SizedBox.shrink();
          } else {
            return InkWell(
              onTap: _toggleActionsVisibility,
              // This is the box that will show a colored boarder if
              // the comment id a child of the parent comment
              child: ColoredBox(
                color: Theme.of(context).appBarTheme.backgroundColor ??
                    Colors.white,
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
                                  // Rating
                                  Text(
                                    widget.comment.rating.toString(),
                                    style: TextStyle(
                                      color: hasUserRated
                                          ? isPositiveSelected
                                              ? HorseAndRidersTheme()
                                                  .getTheme()
                                                  .colorScheme
                                                  .primary
                                              : Colors.red
                                          : isDark
                                              ? Colors.grey.shade300
                                              : Colors.black54,
                                      //bold
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  smallGap(),
                                  // User name
                                  Text(
                                    widget.comment.user?.name ?? '',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  smallGap(),
                                  // Time since comment was made
                                  Text(
                                    calculateTimeDifferenceBetween(
                                      referenceDate: widget.comment.date,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Comment
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
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Positive rating button
                                    Expanded(
                                      child: CommentPositiveRatingButton(
                                        onTap: _toggleActionsVisibility,
                                        key: const Key(
                                          'positive_rating_button',
                                        ),
                                        comment: widget.comment,
                                        resource: commentResource,
                                        usersProfile: state.usersProfile,
                                      ),
                                    ),
                                    // Negative rating button
                                    Expanded(
                                      child: CommentNegativeButton(
                                        onTap: _toggleActionsVisibility,
                                        key: const Key(
                                          'negative_rating_button',
                                        ),
                                        comment: widget.comment,
                                        resource: commentResource,
                                        usersProfile: state.usersProfile,
                                      ),
                                    ),
                                    // if not user show a button to link
                                    // to the commenters profile
                                    if (state.usersProfile?.email !=
                                        widget.comment.user?.id)
                                      Expanded(
                                        child: IconButton(
                                          color: isDark
                                              ? Colors.grey.shade300
                                              : Colors.black54,
                                          tooltip: 'Open '
                                              '${widget.comment.user?.name}'
                                              "'s Profile",
                                          onPressed: () => context.pushNamed(
                                            ViewingProfilePage.name,
                                            pathParameters: {
                                              ViewingProfilePage.pathParams:
                                                  widget.comment.user!.id!,
                                            },
                                          ),
                                          icon: const Icon(Icons.person),
                                        ),
                                      ),
                                    // Reply button
                                    Expanded(
                                      child: CommentReplyButton(
                                        onTap: _toggleActionsVisibility,
                                        key: const Key('reply_button'),
                                        comment: widget.comment,
                                        resource: commentResource,
                                        usersProfile: state.usersProfile,
                                      ),
                                    ),
                                    // a edit button if the user is the
                                    //owner of the comment
                                    if (state.usersProfile?.email ==
                                        widget.comment.user?.id)
                                      Expanded(
                                        child: IconButton(
                                          color: isDark
                                              ? Colors.grey.shade300
                                              : Colors.black54,
                                          tooltip: 'Edit Comment',
                                          onPressed: () {
                                            showDialog<AlertDialog>(
                                              context: context,
                                              builder: (context) =>
                                                  CreateCommentDialog(
                                                isEdit: true,
                                                resource: commentResource,
                                                usersProfile:
                                                    state.usersProfile!,
                                                comment: widget.comment,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.edit),
                                        ),
                                      ),
                                    // overflow menu with report the comment
                                    PopupMenuButton(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.black54,
                                      ),
                                      onSelected: (String value) {
                                        switch (value) {
                                          case 'Report':
                                            _toggleActionsVisibility();
                                            debugPrint('Report Comment: '
                                                '${widget.comment.id}');
                                            showDialog<AlertDialog>(
                                              context: context,
                                              builder: (context) =>
                                                  const SupportMessageDialog(),
                                            );
                                            break;
                                          default:
                                            break;
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          const PopupMenuItem<String>(
                                            value: 'Report',
                                            child: Text('Report'),
                                          ),
                                        ];
                                      },
                                    ),
                                  ],
                                ),
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
