// lib/MainPages/Resources/resource_comment_page.dart
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_item.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/scroll_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ResourceCommentPage extends StatefulWidget {
  const ResourceCommentPage({super.key, required this.id});

  static const pathParams = 'resourceId';
  static const name = 'ResourceCommentPage';
  static const path = 'Comments/:$pathParams';

  final String id;

  @override
  State<ResourceCommentPage> createState() => _ResourceCommentPageState();
}

class _ResourceCommentPageState extends State<ResourceCommentPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  List<_ListItem> _listItems = [];
  List<int> _parentCommentIndexes = [];
  int _currentParentIndex = -1;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_updateCurrentParentIndex);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions
        .removeListener(_updateCurrentParentIndex);
    super.dispose();
  }

  // ----- Back / URL handling -----
  void _goBackToResources() {
    // Reset UI state in your cubit
    context.read<AppCubit>().resetFromResource();

    // Compute the resources URL explicitly, then go there.
    final router = GoRouter.of(context);
    final location = router.namedLocation(ResourcesPage.name);
    router.go(location); // ensures the browser URL updates on web
  }

  // ----- Scroll logic -----
  void _updateCurrentParentIndex() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final firstVisible = positions
        .where((p) => p.itemTrailingEdge > 0)
        .reduce((min, p) => p.index < min.index ? p : min);

    final idx = firstVisible.index;
    final parentIdx = _parentCommentIndexes.indexOf(idx);
    if (parentIdx != -1 && parentIdx != _currentParentIndex) {
      setState(() => _currentParentIndex = parentIdx);
    }
  }

  void _scrollToNextParent() {
    if (_parentCommentIndexes.isEmpty) return;
    if (_currentParentIndex < _parentCommentIndexes.length - 1) {
      _currentParentIndex++;
      _itemScrollController.scrollTo(
        index: _parentCommentIndexes[_currentParentIndex],
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToPreviousParent() {
    if (_parentCommentIndexes.isEmpty) return;
    if (_currentParentIndex > 0) {
      _currentParentIndex--;
      _itemScrollController.scrollTo(
        index: _parentCommentIndexes[_currentParentIndex],
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _buildListItems(List<Comment> baseComments, Resource resource) {
    _listItems = [];
    _parentCommentIndexes = [];

    _listItems.add(_ListItem(type: _ListItemType.header));
    var currentIndex = 1;

    for (final comment in baseComments) {
      _parentCommentIndexes.add(currentIndex);
      _listItems.add(
        _ListItem(type: _ListItemType.parentComment, comment: comment),
      );
      currentIndex++;

      final childComments =
          context.read<AppCubit>().getChildComments(parentComment: comment);
      for (final child in childComments) {
        _listItems.add(
          _ListItem(type: _ListItemType.childComment, comment: child),
        );
        currentIndex++;
      }
    }

    _listItems.add(_ListItem(type: _ListItemType.padding));

    if (!_isInitialized &&
        _parentCommentIndexes.isNotEmpty &&
        _currentParentIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentParentIndex = 0;
          _isInitialized = true;
        });
        _itemScrollController.scrollTo(
          index: _parentCommentIndexes[0],
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
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
          return PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) {
                cubit.resetFromResource();
                return;
              }
              _goBackToResources();
            },
            child: const LoadingPage(key: Key('LoadingPage')),
          );
        }

        final baseComments = cubit.getBaseComments(resource);
        _buildListItems(baseComments, resource);

        final isAtFirstParent = _currentParentIndex <= 0;
        final isAtLastParent =
            _currentParentIndex >= _parentCommentIndexes.length - 1;

        return PopScope<void>(
          canPop: false, // we override back ourselves
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              cubit.resetFromResource();
              return;
            }
            _goBackToResources();
          },
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('Resource Comment Page'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goBackToResources,
                  ),
                ),
                body: _listItems.isEmpty
                    ? Column(
                        children: [
                          CommentPageHeader(
                            resource: resource,
                            key: const Key('CommentPageHeader'),
                          ),
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
                              final isCurrent = _parentCommentIndexes
                                      .isNotEmpty &&
                                  _currentParentIndex >= 0 &&
                                  _currentParentIndex <
                                      _parentCommentIndexes.length &&
                                  _parentCommentIndexes[_currentParentIndex] ==
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
                                child: CommentItem(comment: item.comment!),
                              );
                            case _ListItemType.padding:
                              return const SizedBox(height: 500);
                          }
                        },
                      ),
              ),
              Positioned(
                bottom: 20,
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
      },
    );
  }
}

enum _ListItemType { header, parentComment, childComment, padding }

class _ListItem {
  _ListItem({required this.type, this.comment});
  final _ListItemType type;
  final Comment? comment;
}
