import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Dialogs/mesage_contact_search_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/messages_list_item.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/messages_list_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/messages_search_button.dart';

/// The list of a user's messages
class MessagesList extends StatelessWidget {
  const MessagesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        // On wide screens, auto-select the first conversation if none selected
        final width = MediaQuery.of(context).size.width;
        final isWide = width >= 840;
        if (isWide &&
            state.conversation == null &&
            state.conversations != null &&
            state.conversations!.isNotEmpty) {
          context
              .read<AppCubit>()
              .setConversation(state.conversations!.first.id);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Messages'),
            actions: const [
              MessagesSearchButton(
                key: Key('messagesSearchButton'),
              ),
              MessagesListOverflowMenu(
                key: Key('messagesListOverflowMenu'),
              ),
            ],
          ),
          body: state.conversationsState == ConversationsState.loading
              ? const LoadingPage()
              : ListView(
                  children: state.conversations
                          ?.map(
                            (Conversation conversation) =>
                                MessagesListItem(conversation: conversation),
                          )
                          .toList() ??
                      [const Text('No Messages')],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog<MesssageContactsSearchDialog>(
                context: context,
                builder: (context) => MesssageContactsSearchDialog(
                  usersProfile: context.read<AppCubit>().state.usersProfile!,
                ),
              );
            },
            tooltip: 'Send a Message',
            child: const Icon(Icons.email),
          ),
        );
      },
    );
  }
}
