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
    final cubit = context.read<AppCubit>();
    final selected = context.select((AppCubit c) => c.state.conversationsSort);

    void submit(ConversationsSort? value) {
      if (value == null) return;
      cubit.sortConversations(value);
      Navigator.of(context).pop();
    }

    return OceanCoralAppDialog(
      title: const Text('Sort Messages By:'),
      content: RadioGroup<ConversationsSort>(
        groupValue: selected,
        onChanged: submit,
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
  }
}
