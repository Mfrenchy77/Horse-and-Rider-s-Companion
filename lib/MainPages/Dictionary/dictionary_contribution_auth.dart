// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Resolves whether the current user is signed in with a verified email and can
/// contribute community definitions, improvements, or educational images.
class DictionaryContributorIdentity {
  const DictionaryContributorIdentity({
    required this.isSignedIn,
    required this.emailVerified,
    required this.uid,
  });

  factory DictionaryContributorIdentity.fromContext(BuildContext context) {
    final appState = context.watch<AppCubit?>()?.state;
    final user = appState?.user;
    final signedIn =
        appState != null &&
        !appState.isGuest &&
        user != null &&
        !user.isGuest &&
        user.id.isNotEmpty;
    return DictionaryContributorIdentity(
      isSignedIn: signedIn,
      emailVerified: signedIn && user.emailVerified,
      uid: signedIn ? user.id : '',
    );
  }

  final bool isSignedIn;
  final bool emailVerified;
  final String uid;

  bool get canContribute => isSignedIn && emailVerified;
}

/// Clear friendly guidance for signed-out or unverified visitors who tap a
/// Dictionary contribution action.
class DictionaryContributionAuthPrompt extends StatelessWidget {
  const DictionaryContributionAuthPrompt({
    super.key,
    required this.identity,
    required this.contributionLabel,
  });

  final DictionaryContributorIdentity identity;
  final String contributionLabel;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final isUnverified = identity.isSignedIn && !identity.emailVerified;

    return Column(
      key: const Key('dictionaryAuthRequiredPrompt'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Icon(
              isUnverified
                  ? Icons.mark_email_unread_outlined
                  : Icons.account_circle_outlined,
              size: 28,
              color: AppTokens.accentColor(context),
            ),
            Expanded(
              child: Text(
                isUnverified
                    ? 'Verify your email address before submitting '
                          '$contributionLabel. Once verified, you can track '
                          'your submissions anytime.'
                    : 'Sign in or create a free account to $contributionLabel. '
                          'Signing in helps keep the Dictionary accurate, '
                          'protects image rights, and lets you track the '
                          'review status of your contributions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Text(
          'Your email address is never shown publicly. Public recognition '
          'always remains optional.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: secondaryColor),
        ),
        if (!isUnverified)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('dictionaryCreateAccountButton'),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Create a free account'),
                onPressed: () {
                  final router = GoRouter.maybeOf(context);
                  Navigator.pop(context);
                  router?.go('${AuthPage.path}?mode=register');
                },
              ),
              OutlinedButton.icon(
                key: const Key('dictionarySignInButton'),
                icon: const Icon(Icons.login_outlined, size: 18),
                label: const Text('Sign in'),
                onPressed: () {
                  final router = GoRouter.maybeOf(context);
                  Navigator.pop(context);
                  router?.go('${AuthPage.path}?mode=login');
                },
              ),
            ],
          ),
      ],
    );
  }
}

/// Shared contributor rights confirmation (when images are attached) and
/// opt-in public attribution controls.
class DictionaryContributorAttributionSection extends StatelessWidget {
  const DictionaryContributorAttributionSection({
    super.key,
    required this.requireRightsConfirmation,
    required this.rightsConfirmed,
    required this.onRightsChanged,
    required this.recognitionConsent,
    required this.onRecognitionConsentChanged,
    required this.publicNameController,
    required this.busy,
    this.errorText,
  });

  final bool requireRightsConfirmation;
  final bool rightsConfirmed;
  final ValueChanged<bool> onRightsChanged;
  final bool recognitionConsent;
  final ValueChanged<bool> onRecognitionConsentChanged;
  final TextEditingController publicNameController;
  final bool busy;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        if (requireRightsConfirmation)
          Material(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CheckboxListTile(
              key: const Key('dictionaryImageRightsCheckbox'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              value: rightsConfirmed,
              onChanged: busy
                  ? null
                  : (value) => onRightsChanged(value ?? false),
              title: const Text(
                'Confirm image permissions & review',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'I confirm that I created these images or have permission to '
                  "submit them, I grant Horse & Rider's Companion "
                  'non-exclusive permission to display them in the Dictionary '
                  '(I keep my copyright — no copyright transfer), and I '
                  'understand submissions are reviewed before publication.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                ),
              ),
            ),
          ),
        CheckboxListTile(
          key: const Key('dictionaryRecognitionConsentCheckbox'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: recognitionConsent,
          title: const Text('Credit me publicly if approved (optional)'),
          onChanged: busy
              ? null
              : (value) => onRecognitionConsentChanged(value ?? false),
        ),
        if (recognitionConsent)
          TextFormField(
            key: const Key('dictionaryPublicNameField'),
            controller: publicNameController,
            maxLength: 80,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Public attribution name',
              hintText: 'Name shown if published (never use an email)',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty || value.contains('@')
                ? 'Use a public display name without an email address.'
                : null,
          ),
        Text(
          'Submissions are linked privately to your account so you can track '
          'editorial status. Your email address is never shown publicly.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: secondaryColor),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              key: const Key('dictionaryContributionError'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
