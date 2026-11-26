import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/manage_invitations_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/pending_invitation_storage.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Public landing and redemption page for personalized invitation links
/// (`/invite/<token>`).
class InvitePage extends StatefulWidget {
  /// Creates an [InvitePage].
  const InvitePage({
    required this.token,
    this.repository,
    this.onConnectionAction,
    super.key,
  });

  /// GoRouter path pattern.
  static const path = '/invite/:$tokenParam';

  /// GoRouter route name.
  static const name = 'InvitePage';

  /// Route path parameter key for the invitation token.
  static const tokenParam = 'token';

  /// Raw token from `/invite/<token>`.
  final String token;

  /// Optional override for dependency injection in tests.
  final InvitationRepository? repository;

  /// Optional override for accepting or declining a pending coaching
  /// connection without needing a live [ConnectionsCubit].
  final Future<Map<String, dynamic>?> Function(Map<String, Object?> payload)?
  onConnectionAction;

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  InvitationPreview? _preview;
  InvitationRedemptionResult? _redemption;
  bool _loadingPreview = true;
  bool _redeeming = false;
  bool _submittingDecision = false;
  String? _errorMessage;
  String? _errorCode;
  String? _decisionState; // 'accepted' | 'declined'
  String? _attemptedUidTokenKey;

  InvitationRepository? get _repository {
    if (widget.repository != null) return widget.repository;
    try {
      return context.read<InvitationRepository?>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    if (PendingInvitationStorage.isValidTokenFormat(widget.token)) {
      unawaited(PendingInvitationStorage.saveToken(widget.token));
    }
    unawaited(_loadPreview());
  }

  @override
  void didUpdateWidget(covariant InvitePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _preview = null;
      _redemption = null;
      _errorMessage = null;
      _errorCode = null;
      _decisionState = null;
      _attemptedUidTokenKey = null;
      if (PendingInvitationStorage.isValidTokenFormat(widget.token)) {
        unawaited(PendingInvitationStorage.saveToken(widget.token));
      }
      unawaited(_loadPreview());
    }
  }

  Future<void> _loadPreview() async {
    final repo = _repository;
    if (repo == null) {
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _errorMessage = 'Invitations are unavailable right now.';
      });
      return;
    }

    setState(() {
      _loadingPreview = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      final preview = await repo.getInvitationPreview(widget.token);
      if (!mounted) return;
      if (!preview.tokenValid ||
          preview.status == InvitationStatus.expired ||
          preview.status == InvitationStatus.revoked ||
          preview.status == InvitationStatus.used ||
          preview.status == InvitationStatus.invalid) {
        if (!preview.canRedeem) {
          unawaited(PendingInvitationStorage.clearToken());
        }
      }
      setState(() {
        _preview = preview;
        _loadingPreview = false;
      });
      _maybeAutoRedeem(context.read<AppCubit>().state);
    } catch (e, st) {
      AppLogger.warning(
        LogCategory.navigation,
        'Failed to load invitation preview',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _errorMessage = e is InvitationException
            ? e.message
            : 'Could not load this invitation. Please try again.';
        _errorCode = e is InvitationException ? e.code : null;
      });
    }
  }

  bool _isVerifiedSignedIn(AppState appState) =>
      !appState.isGuest &&
      appState.user.isNotEmpty &&
      appState.user.emailVerified;

  bool _isUnverifiedSignedIn(AppState appState) =>
      appState.user.isNotEmpty &&
      !appState.user.isGuest &&
      !appState.user.emailVerified;

  void _maybeAutoRedeem(AppState appState) {
    if (!mounted || _loadingPreview || _redeeming || _redemption != null) {
      return;
    }
    final preview = _preview;
    if (preview == null || !preview.tokenValid || !preview.canRedeem) {
      return;
    }
    if (!_isVerifiedSignedIn(appState)) return;

    final attemptKey = '${appState.user.id}:${widget.token.trim()}';
    if (_attemptedUidTokenKey == attemptKey) return;
    _attemptedUidTokenKey = attemptKey;
    unawaited(_redeemInvitation());
  }

  Future<void> _redeemInvitation() async {
    final repo = _repository;
    if (repo == null) return;
    setState(() {
      _redeeming = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      final result = await repo.redeemInvitation(widget.token);
      await PendingInvitationStorage.clearToken();
      if (!mounted) return;
      AppLogger.info(
        LogCategory.app,
        'Invitation redeemed (${result.outcome.name})',
      );
      setState(() {
        _redemption = result;
        _redeeming = false;
      });
    } on InvitationException catch (e) {
      if (e.code == 'not-found' ||
          e.code == 'failed-precondition' ||
          e.code == 'permission-denied') {
        await PendingInvitationStorage.clearToken();
      }
      if (!mounted) return;
      setState(() {
        _redeeming = false;
        _errorMessage = e.message;
        _errorCode = e.code;
      });
    } catch (e, st) {
      AppLogger.warning(
        LogCategory.app,
        'Unexpected invitation redemption error',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _redeeming = false;
        _errorMessage = 'Could not process this invitation. Please try again.';
      });
    }
  }

  Future<void> _submitDecision(String action) async {
    final redemption = _redemption;
    final connectionId = redemption?.connectionId;
    if (redemption == null || connectionId == null || _submittingDecision) {
      return;
    }
    final connectionVersion = redemption.connectionVersion;
    final requestDocId = redemption.requestDocId;

    final actionHandler =
        widget.onConnectionAction ?? context.read<ConnectionsCubit?>()?.submit;
    if (actionHandler == null) {
      setState(() {
        _errorMessage = 'Coaching connection service is unavailable right now.';
      });
      return;
    }

    setState(() {
      _submittingDecision = true;
      _errorMessage = null;
    });

    try {
      final response = await actionHandler({
        'action': action,
        'id': connectionId,
        if (connectionVersion != null) 'version': connectionVersion,
        if (requestDocId != null) 'requestDocId': requestDocId,
      });
      if (!mounted) return;
      if (response == null) {
        final fallbackError = context
            .read<ConnectionsCubit?>()
            ?.state
            .actionFeedback;
        setState(() {
          _submittingDecision = false;
          _errorMessage =
              fallbackError ?? 'Could not update the connection request.';
        });
        return;
      }
      setState(() {
        _submittingDecision = false;
        _decisionState = action == 'accept' ? 'accepted' : 'declined';
      });
    } on ConnectionFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submittingDecision = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submittingDecision = false;
        _errorMessage = 'Could not update the connection request. Try again.';
      });
    }
  }

  Future<void> _goToAuth(String mode) async {
    await PendingInvitationStorage.saveToken(widget.token);
    if (!mounted) return;
    final uri = Uri(
      path: AuthPage.path,
      queryParameters: {'mode': mode, 'invite': widget.token.trim()},
    );
    context.go(uri.toString());
  }

  Future<void> _continueWithoutSigningIn() async {
    await PendingInvitationStorage.clearToken();
    if (!mounted) return;
    context.go(ProfilePage.path);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return BlocListener<AppCubit, AppState>(
      listenWhen: (prev, curr) =>
          prev.user.id != curr.user.id ||
          prev.user.emailVerified != curr.user.emailVerified ||
          prev.isGuest != curr.isGuest ||
          prev.status != curr.status,
      listener: (context, state) {
        if (_isVerifiedSignedIn(state)) {
          _maybeAutoRedeem(state);
        }
      },
      child: Scaffold(
        appBar: ThemedAppBar(
          leading: IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go(ProfilePage.path),
          ),
          title: const Text('Invitation'),
        ),
        body: SizedBox.expand(
          child: AppScaffoldBackdrop(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? AppTokens.spaceMd : AppTokens.spaceLg,
                vertical: AppTokens.spaceLg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppTokens.spaceMd,
                    children: [
                      const Center(
                        child: Logo(
                          screenName: "Horse & Rider's Companion",
                          forceDark: true,
                        ),
                      ),
                      _buildCard(context, appState),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppState appState) {
    if (_loadingPreview || _redeeming) {
      return AppSurfaceCard(
        key: const Key('inviteLoadingCard'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppTokens.spaceMd,
          children: [
            const CircularProgressIndicator(),
            Text(
              _redeeming
                  ? 'Preparing your invitation...'
                  : 'Loading invitation details...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    final preview = _preview;
    if (preview == null) {
      return _buildUnavailableCard(
        context,
        title: 'Invitation unavailable',
        message: _errorMessage ?? 'This invitation link could not be loaded.',
        canRetry: true,
      );
    }

    if (!preview.tokenValid || (!preview.canRedeem && _redemption == null)) {
      return _buildUnavailablePreviewCard(context, preview);
    }

    // Verified recipient has already redeemed or hit a redemption error.
    if (_redemption != null) {
      return _buildRedemptionResultCard(context, _redemption!);
    }

    if (_errorMessage != null && _isVerifiedSignedIn(appState)) {
      return _buildErrorAfterAttemptCard(context, preview, appState);
    }

    // Unverified user: preserve context and let them verify right here.
    if (_isUnverifiedSignedIn(appState)) {
      return _buildVerificationPendingCard(context, preview, appState);
    }

    // Signed-out or guest visitor: public preview + auth CTAs.
    return _buildPublicPreviewCard(context, preview);
  }

  Widget _buildInviterHeader(
    BuildContext context, {
    required String name,
    String? photoUrl,
    bool isTrainer = false,
    String? location,
    InvitationType? type,
  }) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);
    final isStudent = type == InvitationType.studentConnection;

    return Row(
      spacing: AppTokens.spaceMd,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: accent.withValues(alpha: 0.2),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Icon(
                  isStudent ? Icons.school_rounded : Icons.person_outline,
                  color: accent,
                  size: 28,
                )
              : null,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                name,
                style: AppTokens.sectionTitleStyle(
                  context,
                ).copyWith(fontSize: 20),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isStudent ? 'Student Invitation' : 'Community Invitation',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isTrainer)
                    Text(
                      'Instructor / Trainer',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                  if (location != null && location.isNotEmpty)
                    Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublicPreviewCard(
    BuildContext context,
    InvitationPreview preview,
  ) {
    final theme = Theme.of(context);
    final inviterName = preview.inviterDisplayName ?? 'A member';
    final isStudent = preview.type == InvitationType.studentConnection;

    return AppSurfaceCard(
      key: const Key('invitePublicPreviewCard'),
      useDoubleGradient: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceMd,
        children: [
          _buildInviterHeader(
            context,
            name: inviterName,
            photoUrl: preview.inviterPhotoUrl,
            isTrainer: preview.inviterIsTrainer,
            location: preview.inviterLocation,
            type: preview.type,
          ),
          Text(
            isStudent
                ? '$inviterName invited you to connect as their student'
                : "$inviterName invited you to join Horse & Rider's Companion",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (preview.personalMessage != null &&
              preview.personalMessage!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Text(
                '"${preview.personalMessage!}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Text(
            isStudent
                ? "Horse & Rider's Companion helps riders, horse owners, and "
                      'instructors track horsemanship skills, training notes, '
                      'and milestones across every discipline.\n\n'
                      'Note: Accepting this link does not automatically add an '
                      'instructor to your profile. After creating an account '
                      'or signing in, you will be asked to explicitly accept '
                      'or decline the student connection request.'
                : 'Track rider and horse horsemanship skills, record training '
                      'sessions in your logbook, and explore curated '
                      'educational resources for every equestrian discipline.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
              height: 1.45,
            ),
          ),
          Wrap(
            spacing: AppTokens.spaceSm + 4,
            runSpacing: AppTokens.spaceSm,
            children: [
              FilledButton(
                key: const Key('inviteCreateAccountButton'),
                onPressed: () => _goToAuth('register'),
                child: const Text('Create Account'),
              ),
              OutlinedButton(
                key: const Key('inviteSignInButton'),
                onPressed: () => _goToAuth('login'),
                child: const Text('Sign In'),
              ),
              TextButton(
                key: const Key('inviteExploreGuestButton'),
                onPressed: _continueWithoutSigningIn,
                child: const Text('Explore without signing in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPendingCard(
    BuildContext context,
    InvitationPreview preview,
    AppState appState,
  ) {
    final theme = Theme.of(context);
    final email = appState.user.email;
    return AppSurfaceCard(
      key: const Key('inviteEmailVerificationCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceMd,
        children: [
          _buildInviterHeader(
            context,
            name: preview.inviterDisplayName ?? 'Member',
            photoUrl: preview.inviterPhotoUrl,
            isTrainer: preview.inviterIsTrainer,
            type: preview.type,
          ),
          Text(
            'Verify your email to continue your invitation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            email.isEmpty
                ? 'We sent a verification email to your address. Once your '
                      'email is verified, your invitation will continue '
                      'automatically.'
                : 'We sent a verification email to $email. Open your inbox '
                      'and click the verification link, then return here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
              height: 1.45,
            ),
          ),
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceSm,
            children: [
              FilledButton.icon(
                key: const Key('inviteCheckVerificationButton'),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("I've Verified — Continue"),
                onPressed: () =>
                    context.read<AppCubit>().refreshEmailVerificationStatus(),
              ),
              OutlinedButton(
                key: const Key('inviteResendVerificationButton'),
                onPressed: () =>
                    context.read<AppCubit>().resendEmailVerification(),
                child: const Text('Resend Email'),
              ),
              TextButton(
                key: const Key('inviteSignOutButton'),
                onPressed: () => context.read<AppCubit>().logOutRequested(),
                child: const Text('Use Another Account'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionResultCard(
    BuildContext context,
    InvitationRedemptionResult result,
  ) {
    final theme = Theme.of(context);

    if (_decisionState == 'accepted') {
      return AppSurfaceCard(
        key: const Key('inviteDecisionAcceptedCard'),
        useDoubleGradient: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppTokens.spaceMd,
          children: [
            _buildInviterHeader(
              context,
              name: result.inviterDisplayName,
              photoUrl: result.inviterPhotoUrl,
              isTrainer: true,
              type: result.type,
            ),
            Text(
              'You are now connected with ${result.inviterDisplayName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Your instructor can now view your profile progress and add '
              'lesson notes and skill verifications. You can manage or end '
              'this connection anytime from your profile.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceSm,
              children: [
                FilledButton(
                  key: const Key('inviteGoToProfileButton'),
                  onPressed: () => context.go(ProfilePage.path),
                  child: const Text('Go to My Profile'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(HorseAndRiderIcons.horseSkillIcon, size: 18),
                  label: const Text('Explore Skill Tree'),
                  onPressed: () => context.go(SkillTreePage.path),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_decisionState == 'declined') {
      return AppSurfaceCard(
        key: const Key('inviteDecisionDeclinedCard'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppTokens.spaceMd,
          children: [
            Text(
              'Connection Request Declined',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'You declined the student connection request from '
              '${result.inviterDisplayName}. No coaching relationship was '
              'created.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
            Wrap(
              spacing: AppTokens.spaceSm,
              children: [
                FilledButton(
                  key: const Key('inviteGoToProfileButton'),
                  onPressed: () => context.go(ProfilePage.path),
                  child: const Text('Go to My Profile'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (result.requiresConnectionDecision) {
      return AppSurfaceCard(
        key: const Key('inviteStudentDecisionCard'),
        useDoubleGradient: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppTokens.spaceMd,
          children: [
            _buildInviterHeader(
              context,
              name: result.inviterDisplayName,
              photoUrl: result.inviterPhotoUrl,
              isTrainer: true,
              type: InvitationType.studentConnection,
            ),
            Text(
              'Review Student Connection Request',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${result.inviterDisplayName} would like to connect with you as '
              'their student.\n\n'
              'If you accept, they can view your riding and horse skill '
              'progress, record lesson notes, and verify completed skill '
              'levels. You can decline now or end the connection anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.secondaryTextColor(context),
                height: 1.45,
              ),
            ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            Wrap(
              spacing: AppTokens.spaceSm + 4,
              runSpacing: AppTokens.spaceSm,
              children: [
                FilledButton(
                  key: const Key('inviteAcceptConnectionButton'),
                  onPressed: _submittingDecision
                      ? null
                      : () => _submitDecision('accept'),
                  child: _submittingDecision
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept Connection'),
                ),
                OutlinedButton(
                  key: const Key('inviteDeclineConnectionButton'),
                  onPressed: _submittingDecision
                      ? null
                      : () => _submitDecision('decline'),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final title = switch (result.outcome) {
      InvitationRedemptionOutcome.redeemedGeneral =>
        "Welcome to Horse & Rider's Companion!",
      InvitationRedemptionOutcome.alreadyRedeemedGeneral => 'Welcome Back!',
      InvitationRedemptionOutcome.alreadyConnected =>
        'Already Connected with ${result.inviterDisplayName}',
      InvitationRedemptionOutcome.previouslyDeclined =>
        'Invitation Previously Declined',
      InvitationRedemptionOutcome.pendingConnectionCreated ||
      InvitationRedemptionOutcome.pendingConnectionExisting =>
        'Student Connection Request',
    };

    return AppSurfaceCard(
      key: const Key('inviteOutcomeCard'),
      useDoubleGradient: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceMd,
        children: [
          _buildInviterHeader(
            context,
            name: result.inviterDisplayName,
            photoUrl: result.inviterPhotoUrl,
            type: result.type,
          ),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            result.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceSm,
            children: [
              FilledButton(
                key: const Key('inviteGoToProfileButton'),
                onPressed: () => context.go(ProfilePage.path),
                child: const Text('Go to My Profile'),
              ),
              OutlinedButton.icon(
                icon: const Icon(HorseAndRiderIcons.horseSkillIcon, size: 18),
                label: const Text('Explore Skill Tree'),
                onPressed: () => context.go(SkillTreePage.path),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailablePreviewCard(
    BuildContext context,
    InvitationPreview preview,
  ) {
    final title = switch (preview.status) {
      InvitationStatus.expired => 'Invitation Expired',
      InvitationStatus.revoked => 'Invitation Revoked',
      InvitationStatus.used => 'Invitation Already Used',
      InvitationStatus.invalid => 'Invalid Invitation Link',
      _ => 'Invitation Unavailable',
    };
    return _buildUnavailableCard(
      context,
      key: const Key('inviteUnavailableCard'),
      title: title,
      message: preview.statusMessage.isNotEmpty
          ? preview.statusMessage
          : 'This invitation link is no longer active.',
      canRetry: false,
    );
  }

  Widget _buildErrorAfterAttemptCard(
    BuildContext context,
    InvitationPreview preview,
    AppState appState,
  ) {
    final isSelfInvite =
        _errorMessage?.toLowerCase().contains('your own invitation') ?? false;
    return AppSurfaceCard(
      key: const Key('inviteRedeemErrorCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceMd,
        children: [
          Text(
            isSelfInvite
                ? 'This is your invitation link'
                : 'Unable to continue',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            _errorMessage ?? 'Could not complete invitation redemption.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceSm,
            children: [
              if (isSelfInvite && !appState.isGuest)
                FilledButton(
                  onPressed: () => ManageInvitationsDialog.show(
                    context,
                    repository: _repository,
                  ),
                  child: const Text('Manage Invitations'),
                )
              else if (_errorCode == 'unavailable' ||
                  _errorCode == 'deadline-exceeded')
                FilledButton(
                  onPressed: _redeemInvitation,
                  child: const Text('Retry'),
                ),
              OutlinedButton(
                onPressed: () => context.go(ProfilePage.path),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(
    BuildContext context, {
    Key? key,
    required String title,
    required String message,
    required bool canRetry,
  }) {
    return AppSurfaceCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceMd,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceSm,
            children: [
              if (canRetry)
                FilledButton(
                  onPressed: _loadPreview,
                  child: const Text('Retry'),
                ),
              OutlinedButton(
                onPressed: () => context.go(ProfilePage.path),
                child: const Text('Return to App'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
