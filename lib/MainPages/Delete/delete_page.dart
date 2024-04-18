import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

class DeletePage extends StatelessWidget {
  const DeletePage({super.key});

  static const String name = 'Delete';
  static const String path = 'Delete';
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        //enter email to and password to delete account
        return AlertDialog(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: state.deleteEmail.isNotValid
                          ? null
                          : () {
                              //delete account
                              cubit.deleteAccount();
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
