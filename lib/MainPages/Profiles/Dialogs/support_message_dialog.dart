import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';

class SupportMessageDialog extends StatelessWidget {
  const SupportMessageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    {
      return BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final homeCubit = context.read<HomeCubit>();
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
        },
      );
    }
  }
}
