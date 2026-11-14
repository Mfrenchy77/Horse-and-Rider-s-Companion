import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';

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

        return OceanCoralAppDialog(
          scrollable: true,
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppFeedbackBanner(
                tone: AppStatusTone.warning,
                message:
                    'This permanently removes your login, rider profile, '
                    'profile photo, private logbook entries, and device '
                    'tokens.',
              ),
              const SizedBox(height: AppTokens.spaceSm + 2),
              Text(
                "Owned horses are transferred to the Horse & Rider's "
                'Companion administrative account to preserve shared '
                'training history, and your name/email are anonymized on '
                'published resources and comments.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTokens.spaceMd),
              TextField(
                enabled: !isBusy,
                onChanged: cubit.emailChanged,
                decoration: const InputDecoration(
                  labelText: 'Confirm your email',
                  hintText: 'Enter your account email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (needsReauth) ...[
                const SizedBox(height: AppTokens.spaceMd),
                Text(
                  'Please verify your identity again to complete deletion:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTokens.primaryTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSm),
                TextField(
                  controller: _passwordController,
                  enabled: !isBusy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSm + 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppPrimaryButton(
                      label: 'Verify Password',
                      onPressed: isBusy
                          ? null
                          : () => cubit.reauthenticateForDeletionWithPassword(
                              _passwordController.text,
                            ),
                    ),
                    AppOutlinedButton(
                      label: 'Verify with Google',
                      onPressed: isBusy
                          ? null
                          : cubit.reauthenticateForDeletionWithGoogle,
                    ),
                  ],
                ),
              ],
              if (state.accountDeletionError.isNotEmpty) ...[
                const SizedBox(height: AppTokens.spaceMd),
                AppFeedbackBanner(
                  tone: AppStatusTone.error,
                  message: state.accountDeletionError,
                ),
              ],
              if (isBusy) ...[
                const SizedBox(height: AppTokens.spaceMd),
                const AppLoadingState(message: 'Deleting account…'),
              ],
            ],
          ),
          actions: [
            AppOutlinedButton(
              label: 'Cancel',
              onPressed: isBusy ? null : () => Navigator.of(context).pop(),
            ),
            AppDestructiveButton(
              label: 'Delete',
              onPressed: !isBusy && state.deleteEmail.isValid
                  ? cubit.deleteAccount
                  : null,
            ),
          ],
        );
      },
    );
  }
}
