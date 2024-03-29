import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/error_view.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/reource_comment_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_comment_llist.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_info_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';

class ResourceCommentPage extends StatelessWidget {
  const ResourceCommentPage({super.key, required this.id});

  static const pathParams = 'resourceId';
  static const name = 'ResourceCommentPage';
  static const path = 'Comments/:resourceId';

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final resource = cubit.getResourceById(id);

        final baseComments = cubit.getBaseComments(state.resourceComments);
        //cubit.sortComments(state.commentSortState);
        final scrollController = ScrollController();

        if (resource == null) {
          return PopScope(
            child: const ErrorView(
              key: Key('ErrorViewforResourceCommentPage'),
            ),
            onPopInvoked: (didPop) =>
                context.read<AppCubit>().resetFromResource(),
          );
        } else {
          cubit.getResourceComments(resource);
          return PopScope(
            onPopInvoked: (didPop) =>
                context.read<AppCubit>().resetFromResource(),
            child: Stack(
              children: [
                Scaffold(
                  appBar: AppBar(
                    title: const Text('Resource Comment Page'),
                  ),
                  body: ListView.builder(
                    // we want the list to be scrollable with the comment page header at the top
                    // and the comment list below it
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: baseComments!.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CommentPageHeader(
                          resource: resource,
                          key: const Key('CommentPageHeader'),
                        );
                      } else {
                        return CommentItem(
                          key: Key(baseComments[index - 1].id!),
                          comment: baseComments[index - 1],
                        );
                      }
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          child: const Icon(Icons.arrow_drop_up),
                          onPressed: () {
                            // this buttom should scroll to the previous index of the list
                            // Scroll to the previous index of the list
                            var currentPosition = scrollController.offset;
                            var itemHeight =
                                100.0; // Change with your actual item height
                            var newPosition = currentPosition - itemHeight;
                            if (newPosition < 0) {
                              newPosition = 0;
                            }
                            scrollController.animateTo(
                              newPosition,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        FloatingActionButton(
                          child: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            // Scroll to the next index of the list
                            var currentPosition = scrollController.offset;
                            var itemHeight =
                                100.0; // Change with your actual item height
                            var newPosition = currentPosition + itemHeight;
                            scrollController.animateTo(
                              newPosition,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
