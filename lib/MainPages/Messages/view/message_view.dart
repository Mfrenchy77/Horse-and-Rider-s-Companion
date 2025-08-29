// ignore_for_file: cast_nullable_to_non_nullable, non_constant_identifier_names, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_list.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_text_field.dart';
import 'package:horseandriderscompanion/MainPages/Messages/messages_list_page.dart';

/// This is the View that displays the conversation between two users
/// It contains a list of messages and a text field to send a message
class MessageView extends StatelessWidget {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Scaffold(
          appBar: AppBar(
            leading: MediaQuery.of(context).size.width > 840
                ? const SizedBox()
                : BackButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        // Fallback to messages list if no back stack
                        context.goNamed(MessagesPage.name);
                      }
                    },
                  ),
            title: state.conversation == null
                ? null
                : Text(
                    cubit.conversationTitle(),
                  ),
          ),
          body: state.conversation == null
              ? const Center(
                  child: Text('No Conversation Selected'),
                )
              : ColoredBox(
                  // Slightly darker background to improve contrast with bubbles
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Colors.grey.shade400,
                  child: Stack(
                    children: [
                      const MessageList(
                        key: Key('MessageList'),
                      ),
                      if (state.conversation?.recentMessage?.messageType ==
                          MessageType.SUPPORT)
                        const MessageTextField(
                          key: Key('MessageTextField'),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
