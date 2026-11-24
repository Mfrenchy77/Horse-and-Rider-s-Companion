import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class DeletePage extends StatefulWidget {
  const DeletePage({super.key});
  static const name = 'DeletePage';
  static const path = '/Delete';

  @override
  State<DeletePage> createState() => _DeletePageState();
}

class _DeletePageState extends State<DeletePage> {
  final _passwordController = TextEditingController();
  bool _acknowledged = false;

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
        final isGuest = state.isGuest || state.user.isEmpty;

        if (isGuest) {
          return AppGlassDialog(
            title: const Text('Delete Account'),
            content: const AppFeedbackBanner(
              tone: AppStatusTone.warning,
              message:
                  'Sign in to a registered account before requesting account '
                  'deletion.',
            ),
            actions: [
              AppOutlinedButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const AppDestructiveButton(
                label: 'Delete',
                onPressed: null,
              ),
            ],
          );
        }

        final secondaryTextStyle = Theme.of(context).textTheme.bodySmall
            ?.copyWith(
              color: AppTokens.secondaryTextColor(context),
              height: 1.4,
            );

        return AppGlassDialog(
          title: const Text('Delete Account'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppFeedbackBanner(
                    tone: AppStatusTone.warning,
                    message:
                        'Deleting your account is permanent and cannot be '
                        'undone for your rider login and personal profile.',
                  ),
                  const SizedBox(height: AppTokens.spaceMd),
                  _DeletionSummaryItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'Personal data permanently removed',
                    body:
                        'Your login credentials, Rider Profile, private notes '
                        'and personal logbook entries, saved contacts, '
                        'personal Skill Tree progress and verifications, '
                        'profile and cover photos, device notification tokens, '
                        'and local tutorial preferences.',
                    textStyle: secondaryTextStyle,
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  _DeletionSummaryItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Owned horses preserved',
                    body:
                        'Any active, archived, or listed horses you own are '
                        'not deleted. They are transferred to the Horse & '
                        "Rider's Companion administrative account with their "
                        'training histories, horse logbooks, Skill Tree '
                        'progress, instructor verifications, and horse photos '
                        'preserved. Sale listings and your owner access are '
                        'removed, and private horses remain private.',
                    textStyle: secondaryTextStyle,
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  _DeletionSummaryItem(
                    icon: Icons.forum_outlined,
                    title: 'Public & shared contributions',
                    body:
                        'Shared Resources, comments, and Skill Tree '
                        'suggestions remain available with your name and '
                        'email anonymized as "Deleted User." Your Resource '
                        'ratings are removed. Active connections are ended.',
                    textStyle: secondaryTextStyle,
                  ),
                  const SizedBox(height: AppTokens.spaceMd),
                  TextField(
                    key: const Key('deleteAccountEmailField'),
                    enabled: !isBusy,
                    onChanged: cubit.emailChanged,
                    decoration: const InputDecoration(
                      labelText: 'Confirm your email',
                      hintText: 'Enter your account email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  CheckboxListTile(
                    key: const Key('deleteAccountAcknowledgeCheckbox'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _acknowledged,
                    enabled: !isBusy,
                    onChanged: (value) {
                      setState(() => _acknowledged = value ?? false);
                    },
                    title: Text(
                      'I understand my rider account will be permanently '
                      'deleted and my owned horses will transfer to the '
                      'platform administrative account.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.primaryTextColor(context),
                      ),
                    ),
                  ),
                  if (needsReauth) ...[
                    const SizedBox(height: AppTokens.spaceMd),
                    Text(
                      'Please verify your identity again to finish deletion:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTokens.primaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                    TextField(
                      key: const Key('deleteAccountPasswordField'),
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
                              : () => cubit
                                    .reauthenticateForDeletionWithPassword(
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
                    const AppLoadingState(
                      message:
                          'Transferring horse records and deleting account…',
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            AppOutlinedButton(
              label: 'Cancel',
              onPressed: isBusy ? null : () => Navigator.of(context).pop(),
            ),
            AppDestructiveButton(
              key: const Key('deleteAccountConfirmButton'),
              label: state.accountDeletionStatus ==
                      AccountDeletionUiStatus.failure
                  ? 'Retry Delete'
                  : 'Delete',
              onPressed:
                  !isBusy && state.deleteEmail.isValid && _acknowledged
                  ? cubit.deleteAccount
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _DeletionSummaryItem extends StatelessWidget {
  const _DeletionSummaryItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.textStyle,
  });

  final IconData icon;
  final String title;
  final String body;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: AppTokens.accentColor(context),
          ),
        ),
        const SizedBox(width: AppTokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTokens.primaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(body, style: textStyle),
            ],
          ),
        ),
      ],
    );
  }
}
