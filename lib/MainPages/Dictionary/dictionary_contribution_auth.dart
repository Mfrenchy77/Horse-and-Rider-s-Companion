// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Resolves whether the current user is signed in with a verified email and can
/// contribute community definitions, improvements, or educational images.
@immutable
class DictionaryContributorIdentity {
  const DictionaryContributorIdentity({
    required this.isSignedIn,
    required this.emailVerified,
    required this.uid,
    this.profileDisplayName = '',
    this.authDisplayName = '',
  });

  factory DictionaryContributorIdentity.fromAppState(AppState? appState) {
    if (appState == null) {
      return const DictionaryContributorIdentity(
        isSignedIn: false,
        emailVerified: false,
        uid: '',
      );
    }
    final user = appState.user;
    final signedIn = !appState.isGuest && !user.isGuest && user.id.isNotEmpty;
    return DictionaryContributorIdentity(
      isSignedIn: signedIn,
      emailVerified: signedIn && user.emailVerified,
      uid: signedIn ? user.id : '',
      profileDisplayName: signedIn
          ? (appState.usersProfile?.name ?? '').trim()
          : '',
      authDisplayName: signedIn ? user.name.trim() : '',
    );
  }

  factory DictionaryContributorIdentity.fromContext(BuildContext context) {
    final cubit = context.read<AppCubit?>();
    if (cubit == null) {
      return const DictionaryContributorIdentity(
        isSignedIn: false,
        emailVerified: false,
        uid: '',
      );
    }
    if (context is Element && context.debugDoingBuild) {
      return context.select<AppCubit, DictionaryContributorIdentity>(
        (appCubit) =>
            DictionaryContributorIdentity.fromAppState(appCubit.state),
      );
    }
    return DictionaryContributorIdentity.fromAppState(cubit.state);
  }

  /// Sanitizes a candidate public display name, stripping email addresses,
  /// placeholders such as `'guest'`, UIDs, or overlong strings.
  static String sanitizePublicDisplayName(String? raw, {String uid = ''}) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 80 ||
        trimmed.contains('@') ||
        trimmed.toLowerCase() == 'guest' ||
        (uid.isNotEmpty && trimmed == uid)) {
      return '';
    }
    return trimmed;
  }

  final bool isSignedIn;
  final bool emailVerified;
  final String uid;
  final String profileDisplayName;
  final String authDisplayName;

  bool get canContribute => isSignedIn && emailVerified;

  /// Best available public attribution name resolved automatically from the
  /// member's app profile, falling back to their Firebase Auth display name.
  String get resolvedPublicDisplayName {
    final profileName = sanitizePublicDisplayName(profileDisplayName, uid: uid);
    if (profileName.isNotEmpty) return profileName;
    return sanitizePublicDisplayName(authDisplayName, uid: uid);
  }

  bool get hasSuitablePublicName => resolvedPublicDisplayName.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryContributorIdentity &&
          runtimeType == other.runtimeType &&
          isSignedIn == other.isSignedIn &&
          emailVerified == other.emailVerified &&
          uid == other.uid &&
          profileDisplayName == other.profileDisplayName &&
          authDisplayName == other.authDisplayName;

  @override
  int get hashCode => Object.hash(
    isSignedIn,
    emailVerified,
    uid,
    profileDisplayName,
    authDisplayName,
  );
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
    required this.identity,
    required this.requireRightsConfirmation,
    required this.rightsConfirmed,
    required this.onRightsChanged,
    required this.recognitionConsent,
    required this.onRecognitionConsentChanged,
    required this.publicNameController,
    required this.busy,
    this.onOpenProfile,
    this.errorText,
  });

  final DictionaryContributorIdentity identity;
  final bool requireRightsConfirmation;
  final bool rightsConfirmed;
  final ValueChanged<bool> onRightsChanged;
  final bool recognitionConsent;
  final ValueChanged<bool> onRecognitionConsentChanged;
  final TextEditingController publicNameController;
  final bool busy;
  final VoidCallback? onOpenProfile;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final profileName = identity.resolvedPublicDisplayName;
    final hasProfileName = identity.hasSuitablePublicName;

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
          title: const Text(
            'Credit me publicly if this contribution is approved',
          ),
          onChanged: busy
              ? null
              : (value) => onRecognitionConsentChanged(value ?? false),
        ),
        if (recognitionConsent && hasProfileName)
          Container(
            key: const Key('dictionaryPublicCreditPreview'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.35),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Proposed public credit: $profileName',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Using your profile display name. Your email address and '
                  'account ID are never published.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                ),
              ],
            ),
          )
        else if (recognitionConsent)
          Container(
            key: const Key('dictionaryMissingProfileNameNotice'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.35),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'No public display name is set on your profile yet.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                    ),
                    TextButton.icon(
                      key: const Key('dictionaryOpenProfileForNameButton'),
                      onPressed: busy
                          ? null
                          : () {
                              if (onOpenProfile != null) {
                                onOpenProfile!();
                                return;
                              }
                              final router = GoRouter.maybeOf(context);
                              Navigator.maybePop(context);
                              router?.go('/');
                            },
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('Set name in Profile'),
                    ),
                  ],
                ),
                TextFormField(
                  key: const Key('dictionaryPublicNameField'),
                  controller: publicNameController,
                  maxLength: 80,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Optional public attribution name',
                    hintText:
                        'Leave blank to publish without credit (never use an email)',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    if (trimmed.contains('@') ||
                        DictionaryContributorIdentity.sanitizePublicDisplayName(
                          trimmed,
                          uid: identity.uid,
                        ).isEmpty) {
                      return 'Use a public display name without an email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        Text(
          'Submissions are linked privately to your account so you can track '
          'editorial status. Your email address and account ID are never '
          'shown publicly.',
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
