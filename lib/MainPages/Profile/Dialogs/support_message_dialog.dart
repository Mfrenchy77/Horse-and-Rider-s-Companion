import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';

class SupportMessageDialog extends StatelessWidget {
  const SupportMessageDialog({
    super.key,
    required this.homeCubit,
    required this.state,
  });
  final HomeCubit homeCubit;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    {
      return Scaffold(
        body: AlertDialog(
          title: const Text('Send Message to Support'),
          content: TextFormField(
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            onChanged: homeCubit.messageToSupportChanged,
            decoration: const InputDecoration(
              hintText: 'Enter your message here',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: homeCubit.sendMessageToSupport,
              child: const Text('Send'),
            ),
          ],
        ),
      );
    }
  }
}
