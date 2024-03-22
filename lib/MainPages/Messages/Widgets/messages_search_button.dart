import 'package:flutter/material.dart';

class MessagesSearchButton extends StatelessWidget {
  const MessagesSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Search',
      icon: const Icon(Icons.search),
      onPressed: () {
        // Search the messages
        // showDialog<MesssageContactsSearchDialog>(
        //   context: context,
        //   builder: (context) => MesssageContactsSearchDialog(
        //     user: context.read<AppCubit>().state.usersProfile!,
        //   ),
        // );
      },
    );
  }
}
