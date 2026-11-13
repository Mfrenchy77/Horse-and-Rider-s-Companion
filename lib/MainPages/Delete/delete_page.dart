import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

class DeletePage extends StatefulWidget {
  const DeletePage({super.key});
  static const name = 'DeletePage';
  static const path = '/Delete';

  @override
  State<DeletePage> createState() => _DeletePageState();
}

class _DeletePageState extends State<DeletePage> {
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AppCubit>().resetAccountDeletionStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.accountDeletionStatus != current.accountDeletionStatus,
      listener: (context, state) {
        if (state.accountDeletionStatus == AccountDeletionUiStatus.completed ||
            state.accountDeletionStatus == AccountDeletionUiStatus.scheduled) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final status = state.accountDeletionStatus;
        final isBusy = status == AccountDeletionUiStatus.inProgress;
        final needsReauth =
            status == AccountDeletionUiStatus.requiresRecentLogin;

        return AlertDialog(
          title: const Text('Delete Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently removes your login, rider profile, '
                  'profile photo, private logbook entries, and device tokens.',
                ),
                const SizedBox(height: 8),
                const Text(
                  "Owned horses are transferred to the Horse & Rider's "
                  'Companion administrative account to preserve shared '
                  'training history, and your name/email are anonymized on '
                  'published resources and comments.',
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: !isBusy,
                  onChanged: cubit.emailChanged,
                  decoration: const InputDecoration(
                    labelText: 'Confirm your email',
                    hintText: 'Enter your account email',
                  ),
                ),
                if (needsReauth) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Please verify your identity again to complete deletion:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    enabled: !isBusy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: isBusy
                            ? null
                            : () => cubit.reauthenticateForDeletionWithPassword(
                                _passwordController.text,
                              ),
                        child: const Text('Verify Password'),
                      ),
                      OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : cubit.reauthenticateForDeletionWithGoogle,
                        child: const Text('Verify with Google'),
                      ),
                    ],
                  ),
                ],
                if (state.accountDeletionError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.accountDeletionError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (isBusy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isBusy ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: !isBusy && state.deleteEmail.isValid
                  ? cubit.deleteAccount
                  : null,
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
