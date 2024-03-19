// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_list_view.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    this.messageId,
    super.key,
  });

  static const name = 'Messages';
  static const path = 'Messages';

  // The Id of a message to open
  final String? messageId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        if (state.conversations == null) {
          cubit.getConversations();
        }
        if (messageId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).pushNamed(
              MessagePage.name,
              pathParameters: {MessagePage.pathParams: messageId!},
            );
          });
        }
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
