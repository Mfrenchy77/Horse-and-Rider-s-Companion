import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Dialogs/mesage_contact_search_dialog.dart';

class MessagesSearchButton extends StatelessWidget {
  const MessagesSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Search',
      icon: const Icon(Icons.search),
      onPressed: () {
        // Search the messages
        showDialog<MesssageContactsSearchDialog>(
          context: context,
          builder: (context) => MesssageContactsSearchDialog(
            user: context.read<AppCubit>().state.usersProfile!,
          ),
        );
      },
    );
  }
}
