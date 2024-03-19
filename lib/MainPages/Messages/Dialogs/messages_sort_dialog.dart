import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

class MessagesSortDialog extends StatelessWidget {
  const MessagesSortDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return AlertDialog(
          title: const Text('Sort Messages By:'),
          content: DropdownButton<ConversationsSort>(
            isExpanded: true,
            value: state.conversationsSort,
            onChanged: (ConversationsSort? newValue) {
              if (newValue != null) {
                cubit.sortConversations(newValue);
                Navigator.pop(context);
              }
            },
            items: ConversationsSort.values
                .map<DropdownMenuItem<ConversationsSort>>(
                    (ConversationsSort value) {
              return DropdownMenuItem<ConversationsSort>(
                value: value,
                child: Text(_sortToReadableString(value)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _sortToReadableString(ConversationsSort sort) {
    switch (sort) {
      case ConversationsSort.createdDate:
        return 'Newest';
      case ConversationsSort.lastupdatedDate:
        return 'Recently Updated';
      case ConversationsSort.unread:
        return 'Unread';
    }
  }
}
