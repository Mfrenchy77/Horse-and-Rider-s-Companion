// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_list_view.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    this.messageId,
    super.key,
  });

  static const name = 'Messages';
  static const path = 'Messages';

  // The Id of a message to open
  final String? messageId;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String? _pushedMessageId;

  @override
  void initState() {
    super.initState();
    _syncConversations();
    _navigateToMessageIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId) {
      _navigateToMessageIfNeeded();
    }
  }

  void _syncConversations() {
    final cubit = context.read<AppCubit>();
    if (cubit.state.conversations == null) {
      cubit.getConversations();
    }
  }

  void _navigateToMessageIfNeeded() {
    final id = widget.messageId;
    if (id == null || _pushedMessageId == id) return;
    _pushedMessageId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GoRouter.of(context).pushNamed(
        MessagePage.name,
        pathParameters: {MessagePage.pathParams: id},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.usersProfile != current.usersProfile,
      listener: (context, state) => _syncConversations(),
      builder: (context, state) {
        return state.conversations == null
            ? const LoadingPage()
            : const MessagesView(
                isConversations: true,
                key: Key('MessagesListView'),
              );
      },
    );
  }
}
