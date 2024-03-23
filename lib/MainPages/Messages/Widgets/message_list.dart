import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_item.dart';

/// The list of messages in a conversation
class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return state.conversationState == ConversationState.loading
            ? const LoadingPage(
                key: Key('LoadingMessages'),
              )
            : state.messages == null || state.messages!.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: Logo(screenName: 'No messages, yet'),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: ListView(
                      shrinkWrap: true,
                      reverse: true,
                      children: state.messages?.map((message) {
                            debugPrint('Message: ${state.messages?.length}');
                            return MessageItem(
                              message: message,
                              isCurrentUser: cubit.isCurrentUser(message),
                            );
                          }).toList() ??
                          [],
                    ),
                  );
      },
    );
  }
}
