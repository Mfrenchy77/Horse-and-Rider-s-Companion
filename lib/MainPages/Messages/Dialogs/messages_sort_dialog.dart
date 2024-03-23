import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class MessagesSortDialog extends StatelessWidget {
  const MessagesSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return AlertDialog(
          title: const Text('Sort Messages By:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ConversationsSort>(
                title: const Text('Newest'),
                value: ConversationsSort.createdDate,
                groupValue: state.conversationsSort,
                onChanged: (value) {
                  cubit.sortConversations(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ConversationsSort>(
                title: const Text('Recently Updated'),
                value: ConversationsSort.lastupdatedDate,
                groupValue: state.conversationsSort,
                onChanged: (value) {
                  cubit.sortConversations(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ConversationsSort>(
                title: const Text('Unread'),
                value: ConversationsSort.unread,
                groupValue: state.conversationsSort,
                onChanged: (value) {
                  cubit.sortConversations(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ConversationsSort>(
                title: const Text('Oldest'),
                value: ConversationsSort.oldest,
                groupValue: state.conversationsSort,
                onChanged: (value) {
                  cubit.sortConversations(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
