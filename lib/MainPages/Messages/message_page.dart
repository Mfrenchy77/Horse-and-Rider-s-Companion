import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_list_view.dart';

/// This is the page that will be displayed
/// when we want to see a message conversation
class MessagePage extends StatefulWidget {
  const MessagePage({super.key, required this.messageId});

  static const name = 'MessagePage';
  static const pathParams = 'messageId';
  static const path = 'Message/:messageId';

  final String messageId;

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  void initState() {
    super.initState();
    _syncConversation();
  }

  @override
  void didUpdateWidget(covariant MessagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId) {
      _syncConversation();
    }
  }

  void _syncConversation() {
    final cubit = context.read<AppCubit>();
    final state = cubit.state;
    if (state.conversations == null) {
      cubit.getConversations();
    }
    if (state.conversations != null &&
        (state.conversation == null ||
            state.conversation!.id != widget.messageId)) {
      cubit.setConversation(widget.messageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.conversations != current.conversations ||
          previous.usersProfile != current.usersProfile,
      listener: (context, state) => _syncConversation(),
      child: const MessagesView(
        isConversations: false,
        key: Key('MessagesListView'),
      ),
    );
  }
}
