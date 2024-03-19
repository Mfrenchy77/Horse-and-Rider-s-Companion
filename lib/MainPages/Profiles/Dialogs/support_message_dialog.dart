import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

class SupportMessageDialog extends StatelessWidget {
  const SupportMessageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    {
      return BlocListener<AppCubit, AppState>(
        listener: (context, state) {
          if (state.messageToSupportStatus == MessageToSupportStatus.success) {
            Navigator.of(context).pop();
          }
        },
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            final homeCubit = context.read<AppCubit>();
            return AlertDialog(
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
                if (state.messageToSupportStatus ==
                    MessageToSupportStatus.sending)
                  const CircularProgressIndicator()
                else
                  FilledButton(
                    onPressed: state.errorMessage.isEmpty
                        ? null
                        : homeCubit.sendMessageToSupport,
                    child: const Text('Send'),
                  ),
              ],
            );
          },
        ),
      );
    }
  }
}
