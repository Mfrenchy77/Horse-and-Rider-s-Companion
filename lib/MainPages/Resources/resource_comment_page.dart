// lib/MainPages/Resources/resource_comment_page.dart

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/scroll_button.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ResourceCommentPage extends StatefulWidget {
  const ResourceCommentPage({super.key, required this.id});

  static const pathParams = 'resourceId';
  static const name = 'ResourceCommentPage';
  static const path = 'Comments/:resourceId';

  final String id;

  @override
  _ResourceCommentPageState createState() => _ResourceCommentPageState();
}

class _ResourceCommentPageState extends State<ResourceCommentPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // List to store all items in the ScrollablePositionedList
  List<_ListItem> _listItems = [];

  // List to store indexes of parent comments
  List<int> _parentCommentIndexes = [];

  // Current parent index
  int _currentParentIndex = -1;

  // Initialization flag
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Listen to item positions to update current parent index
    _itemPositionsListener.itemPositions.addListener(_updateCurrentParentIndex);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions
        .removeListener(_updateCurrentParentIndex);
    super.dispose();
  }

  void _updateCurrentParentIndex() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the first visible item
    final firstVisible = positions
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((min, position) => position.index < min.index ? position : min);

    final visibleIndex = firstVisible.index;

    // Check if the visible index is a parent comment
    final parentIndex = _parentCommentIndexes.indexOf(visibleIndex);
    if (parentIndex != -1 && parentIndex != _currentParentIndex) {
      setState(() {
        _currentParentIndex = parentIndex;
        debugPrint('Current Parent Index Updated: $_currentParentIndex');
      });
    }
  }

  void _scrollToNextParent() {
    debugPrint(
      'Attempting to scroll to next parent.'
      ' Current index: $_currentParentIndex',
    );
    if (_parentCommentIndexes.isEmpty) return;

    if (_currentParentIndex < _parentCommentIndexes.length - 1) {
      _currentParentIndex++;
      final targetIndex = _parentCommentIndexes[_currentParentIndex];
      debugPrint('Scrolling to parent at list index: $targetIndex');
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint(
        'Already at the last parent comment. Triggering wiggle and vibration.',
      );
      // The ScrollButtons widget will handle the wiggle and vibration
    }
  }

  void _scrollToPreviousParent() {
    debugPrint(
      'Attempting to scroll to previous parent.'
      ' Current index: $_currentParentIndex',
    );
    if (_parentCommentIndexes.isEmpty) return;

    if (_currentParentIndex > 0) {
      _currentParentIndex--;
      final targetIndex = _parentCommentIndexes[_currentParentIndex];
      debugPrint('Scrolling to parent at list index: $targetIndex');
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint(
        'Already at the first parent comment. Triggering wiggle and vibration.',
      );
      // The ScrollButtons widget will handle the wiggle and vibration
    }
  }

  void _buildListItems(List<Comment> baseComments, Resource resource) {
    _listItems = [];
    _parentCommentIndexes = [];

    // Start with the header
    _listItems.add(_ListItem(type: _ListItemType.header));

    // Current index starts at 1 (header is at 0)
    var currentIndex = 1;

    for (final comment in baseComments) {
      // Record the index of the parent comment
      _parentCommentIndexes.add(currentIndex);

      // Add the parent comment
      _listItems.add(
        _ListItem(
          type: _ListItemType.parentComment,
          comment: comment,
        ),
      );
      currentIndex++;

      // Add child comments
      final childComments =
          context.read<AppCubit>().getChildComments(parentComment: comment);
      for (final child in childComments) {
        _listItems.add(
          _ListItem(
            type: _ListItemType.childComment,
            comment: child,
          ),
        );
        currentIndex++;
      }
    }

    // Add padding at the end
    _listItems.add(_ListItem(type: _ListItemType.padding));

    // Debugging: Print parent comment indexes
    debugPrint('Parent Comment Indexes: $_parentCommentIndexes');

    // Initialize _currentParentIndex to 0 if there are
    // parent comments and it's not yet initialized
    if (!_isInitialized &&
        _parentCommentIndexes.isNotEmpty &&
        _currentParentIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentParentIndex = 0;
            _isInitialized = true;
          });
          _itemScrollController.scrollTo(
            index: _parentCommentIndexes[0],
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final resource = cubit.getResourceById(widget.id);

        if (resource == null) {
          return PopScope(
            child: const LoadingPage(
              key: Key('LoadingPage'),
            ),
            onPopInvokedWithResult: (didPop, result) {
              debugPrint(
                'Resource Comment Page Pop Invoked: $didPop, result: $result',
              );
              cubit.resetFromResource();
            },
          );
        } else {
          final baseComments = cubit.getBaseComments(resource);

          // Build the list items and record parent indexes
          _buildListItems(baseComments, resource);

          // Determine if at first or last parent comment
          final isAtFirstParent = _currentParentIndex <= 0;
          final isAtLastParent =
              _currentParentIndex >= _parentCommentIndexes.length - 1;

          // Handle edge case where _currentParentIndex might still be -1
          if (!_isInitialized &&
              _parentCommentIndexes.isNotEmpty &&
              _currentParentIndex == -1) {
            // The post-frame callback in _buildListItems handles initialization
          }

          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              debugPrint(
                'Resource Comment Page Pop Invoked: $didPop, result: $result',
              );
              cubit.resetFromResource();
            },
            child: Stack(
              children: [
                Scaffold(
                  appBar: AppBar(
                    title: const Text('Resource Comment Page'),
                  ),
                  body: _listItems.isEmpty
                      ? Column(
                          children: [
                            CommentPageHeader(resource: resource),
                            gap(),
                            const Center(
                              child: Text(
                                'No Comments Yet, Start the Conversation',
                              ),
                            ),
                          ],
                        )
                      : ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          shrinkWrap: true,
                          itemCount: _listItems.length,
                          itemBuilder: (context, index) {
                            final item = _listItems[index];
                            switch (item.type) {
                              case _ListItemType.header:
                                return CommentPageHeader(
                                  resource: resource,
                                  key: const Key('CommentPageHeader'),
                                );
                              case _ListItemType.parentComment:
                                final isCurrent = _parentCommentIndexes[
                                        _currentParentIndex] ==
                                    index;
                                return ColoredBox(
                                  color: isCurrent
                                      ? Colors.blue.withValues(alpha: .1)
                                      : Colors.transparent,
                                  child: CommentItem(
                                    key: Key(item.comment!.id!),
                                    comment: item.comment!,
                                  ),
                                );
                              case _ListItemType.childComment:
                                return Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: CommentItem(
                                    comment: item.comment!,
                                  ),
                                );
                              case _ListItemType.padding:
                                return const SizedBox(height: 500);
                            }
                          },
                        ),
                ),
                Positioned(
                  bottom: 20, // Adjusted for better visibility
                  left: 0,
                  right: 0,
                  child: ScrollButton(
                    isAtFirstParent: isAtFirstParent,
                    isAtLastParent: isAtLastParent,
                    onScrollUp: _scrollToPreviousParent,
                    onScrollDown: _scrollToNextParent,
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

// Helper classes and enums

enum _ListItemType { header, parentComment, childComment, padding }

class _ListItem {
  _ListItem({required this.type, this.comment});
  final _ListItemType type;
  final Comment? comment;
}
