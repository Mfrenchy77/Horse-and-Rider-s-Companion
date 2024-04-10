import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';

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
        // this needs to be protected from being called multiple times
        final resource = cubit.getResourceById(id);

        //cubit.sortComments(state.commentSortState);
        final scrollController = ScrollController();

        if (resource == null) {
          return PopScope(
            child: const LoadingPage(
              key: Key('LoadingPage'),
            ),
            onPopInvoked: (didPop) =>
                context.read<AppCubit>().resetFromResource(),
          );
        } else {
          final baseComments = cubit.getBaseComments(resource);
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
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: baseComments.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CommentPageHeader(
                          resource: resource,
                          key: const Key('CommentPageHeader'),
                        );
                      } else if (index == baseComments.length + 1) {
                        return const SizedBox(height: 500);
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
                          key: const Key('ScrollUpButton'),
                          child: const Icon(Icons.arrow_drop_up),
                          onPressed: () {
                            final currentPosition = scrollController.offset;
                            const itemHeight =
                                100.0; // Change with your actual item height
                            var newPosition = currentPosition - itemHeight;
                            if (newPosition < 0) {
                              newPosition = 0;
                            }
                            scrollController.animateTo(
                              newPosition,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        FloatingActionButton(
                          key: const Key('ScrollDownButton'),
                          child: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            // Scroll to the next index of the list
                            final currentPosition = scrollController.offset;
                            const itemHeight =
                                100.0; // Change with your actual item height
                            final newPosition = currentPosition + itemHeight;
                            scrollController.animateTo(
                              newPosition,
                              duration: const Duration(milliseconds: 500),
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
