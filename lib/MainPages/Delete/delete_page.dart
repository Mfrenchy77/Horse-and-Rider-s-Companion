import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';

class DeletePage extends StatelessWidget {
  const DeletePage({super.key});

  static const String name = 'Delete';
  static const String path = 'Delete';
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final isInvalid = context.select(
      (AppCubit c) => c.state.deleteEmail.isNotValid,
    );

    // This widget is presented as a dialog.
    // Use the app dialog wrapper so gradients/sizing remain consistent.
    return OceanCoralAppDialog(
      title: const Text('Delete Account'),
      content: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: cubit.emailChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'Email',
              ),
            ),
            smallGap(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.tonalIcon(
          onPressed: isInvalid
              ? null
              : () {
                  cubit.deleteAccount();
                  Navigator.pop(context);
                },
          icon: const Icon(Icons.delete),
          label: const Text('Delete Account'),
        ),
      ],
    );
  }
}
