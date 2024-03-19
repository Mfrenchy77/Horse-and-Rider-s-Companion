// ignore_for_file: cast_nullable_to_non_nullable, non_constant_identifier_names, lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_list.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_text_field.dart';

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
                : null,
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
              : const Stack(
                  children: [
                    MessageList(
                      key: Key('MessageList'),
                    ),
                    MessageTextField(
                      key: Key('MessageTextField'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
