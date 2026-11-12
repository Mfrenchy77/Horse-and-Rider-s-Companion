import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';

/// Assumes `ConversationsSort` is your enum with:
/// createdDate, lastupdatedDate, unread, oldest
class MessagesSortDialog extends StatelessWidget {
  const MessagesSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        void submit(ConversationsSort? value) {
          if (value == null) return;
          cubit.sortConversations(value);
          Navigator.of(context).pop();
        }

        return OceanCoralAppDialog(
          title: const Text('Sort Messages By:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ConversationsSort>(
                title: const Text('Newest'),
                value: ConversationsSort.createdDate,
                groupValue: state.conversationsSort,
                onChanged: submit,
              ),
              RadioListTile<ConversationsSort>(
                title: const Text('Recently Updated'),
                value: ConversationsSort.lastupdatedDate,
                groupValue: state.conversationsSort,
                onChanged: submit,
              ),
              RadioListTile<ConversationsSort>(
                title: const Text('Unread'),
                value: ConversationsSort.unread,
                groupValue: state.conversationsSort,
                onChanged: submit,
              ),
              RadioListTile<ConversationsSort>(
                title: const Text('Oldest'),
                value: ConversationsSort.oldest,
                groupValue: state.conversationsSort,
                onChanged: submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
