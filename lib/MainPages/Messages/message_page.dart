import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_list_view.dart';

/// This is the page that will be displayed
/// when we want to see a message conversation
class MessagePage extends StatelessWidget {
  const MessagePage({super.key, required this.messageId});

  static const name = 'MessagePage';
  static const pathParams = 'messageId';
  static const path = 'Message/:messageId';

  final String messageId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        if (state.conversations == null) {
          cubit.getConversations();
        }

        // Ensure the requested conversation is
        //selected once conversations are loaded
        if (state.conversations != null &&
            (state.conversation == null ||
                state.conversation!.id != messageId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cubit.setConversation(messageId);
          });
        }

        return const MessagesView(
          isConversations: false,
          key: Key('MessagesListView'),
        );
      },
    );
  }
}
