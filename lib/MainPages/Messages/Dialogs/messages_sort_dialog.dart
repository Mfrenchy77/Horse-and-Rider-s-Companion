import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

/// Assumes `ConversationsSort` is your enum with:
/// createdDate, lastupdatedDate, unread, oldest
class MessagesSortDialog extends StatelessWidget {
  const MessagesSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return AlertDialog(
          title: const Text('Sort Messages By:'),
          content: RadioGroup<ConversationsSort>(
            // NEW: centralize selection here (not on each tile)
            groupValue: state.conversationsSort,
            onChanged: (ConversationsSort? value) {
              if (value == null) return;
              cubit.sortConversations(value);
              Navigator.of(context).pop();
            },
            // The children NO LONGER specify groupValue/onChanged.
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ConversationsSort>(
                  title: Text('Newest'),
                  value: ConversationsSort.createdDate,
                ),
                RadioListTile<ConversationsSort>(
                  title: Text('Recently Updated'),
                  value: ConversationsSort.lastupdatedDate,
                ),
                RadioListTile<ConversationsSort>(
                  title: Text('Unread'),
                  value: ConversationsSort.unread,
                ),
                RadioListTile<ConversationsSort>(
                  title: Text('Oldest'),
                  value: ConversationsSort.oldest,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
