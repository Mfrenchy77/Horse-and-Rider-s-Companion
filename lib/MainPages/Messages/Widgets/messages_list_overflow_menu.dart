import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Dialogs/messages_sort_dialog.dart';

class MessagesListOverflowMenu extends StatelessWidget {
  const MessagesListOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (context) {
        return [
          const PopupMenuItem<int>(
            value: 0,
            child: Text('Sort'),
          ),
        ];
      },
      onSelected: (value) {
        switch (value) {
          case 0:
            // Sort the messages
            showDialog<AlertDialog>(
              context: context,
              builder: (context) => const MessagesSortDialog(
                key: Key('messagesSortDialog'),
              ),
            );
            break;
        }
      },
    );
  }
}
