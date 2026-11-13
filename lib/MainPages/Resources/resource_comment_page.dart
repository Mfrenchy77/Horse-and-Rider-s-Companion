// lib/MainPages/Resources/resource_comment_page.dart
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
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
  String? _loadFailure;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_updateCurrentParentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadResource();
    });
  }

  @override
  void didUpdateWidget(covariant ResourceCommentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _isInitialized = false;
      _currentParentIndex = -1;
      _loadFailure = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadResource();
      });
    }
  }

  Resource? _findResource(AppState state) {
    if (state.resource?.id == widget.id) return state.resource;
    for (final resource in state.resources) {
      if (resource.id == widget.id) return resource;
    }
    return null;
  }

  Future<void> _loadResource() async {
    final cubit = context.read<AppCubit>();
    final id = widget.id;
    if (cubit.getResourceById(id) != null) return;
    try {
      final resource = await cubit.fetchResource(id);
      if (!mounted || widget.id != id) return;
      if (resource != null) {
        if (cubit.getResourceById(id) == null) cubit.selectResource(resource);
      } else {
        setState(() => _loadFailure = 'This resource could not be found.');
      }
    } catch (_) {
      if (mounted && widget.id == id) {
        setState(() => _loadFailure = 'Could not load this resource.');
      }
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _updateCurrentParentIndex,
    );
    super.dispose();
  }

  // ----- Back / URL handling -----
  void _goBackToResources() {
    // Pop the pushed comments route so the resource-summary Hero has the
    // original card as its destination. A directly opened URL has no route to
    // pop, so it falls back to the resources list.
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.read<AppCubit>().resetFromResource();
    context.goNamed(ResourcesPage.name);
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

  void _buildListItems(List<Comment> baseComments) {
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

      // CommentItem renders the full reply thread. Adding replies here too
      // would display the same comment more than once.
    }

    _listItems.add(_ListItem(type: _ListItemType.padding));

    if (!_isInitialized &&
        _parentCommentIndexes.isNotEmpty &&
        _currentParentIndex == -1) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _parentCommentIndexes.isEmpty) return;
        setState(() {
          _currentParentIndex = 0;
        });
        if (_itemScrollController.isAttached) {
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
    return BlocConsumer<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.resources != current.resources &&
          current.resource?.id != widget.id,
      listener: (context, state) {
        context.read<AppCubit>().getResourceById(widget.id);
      },
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final resource = _findResource(state);

        if (resource == null) {
          return PopScope<void>(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) {
                cubit.resetFromResource();
                return;
              }
              _goBackToResources();
            },
            child: _loadFailure == null
                ? const LoadingPage(key: Key('LoadingPage'))
                : Scaffold(
                    appBar: ThemedAppBar(
                      title: const Text('Resource'),
                      leading: BackButton(onPressed: _goBackToResources),
                    ),
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_loadFailure!),
                          TextButton(
                            onPressed: () {
                              setState(() => _loadFailure = null);
                              _loadResource();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        }

        final baseComments = cubit.getBaseComments(resource);
        _buildListItems(baseComments);

        final isAtFirstParent = _currentParentIndex <= 0;
        final isAtLastParent =
            _currentParentIndex >= _parentCommentIndexes.length - 1;

        return PopScope<void>(
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
                appBar: ThemedAppBar(
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
                              final isCurrent =
                                  _parentCommentIndexes.isNotEmpty &&
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

enum _ListItemType { header, parentComment, padding }

class _ListItem {
  _ListItem({required this.type, this.comment});
  final _ListItemType type;
  final Comment? comment;
}
