import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';
import 'package:horseandriderscompanion/Utilities/util_methodsd.dart';

/// This is the widget that will be used to display the list of messages
class MessagesListItem extends StatelessWidget {
  const MessagesListItem({super.key, required this.conversation});
  final Group conversation;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final parties = conversation.parties..remove(state.usersProfile?.name);
        final fromText = parties.join(', ');
        final textColor = cubit.groupTextColor(conversation: conversation);
        return ListTile(
          onTap: () {
            cubit.setConversation(conversation);
            context.goNamed(
              MessagePage.name,
              pathParameters: {MessagePage.pathParams: conversation.id},
            );
          },
          trailing: Text(
            calculateTimeDifferenceBetween(
              referenceDate: conversation.lastEditDate,
            ),
            style: TextStyle(color: textColor),
          ),
          leading: ProfilePhoto(
            size: 40,
            profilePicUrl: conversation.recentMessage?.senderProfilePicUrl,
          ),
          title: Text(
            fromText,
            style: TextStyle(
              color: textColor,
            ),
          ),
          subtitle: Text(
            conversation.recentMessage?.sender == state.usersProfile?.name
                ? 'You: ${conversation.recentMessage?.message}'
                : conversation.recentMessage?.message ?? '',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        );
      },
    );
  }
}
