import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/invite_share_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:intl/intl.dart';

/// Dialog displaying invitations created by the signed-in user, conversion
/// summary metrics, and revocation controls.
class ManageInvitationsDialog extends StatefulWidget {
  /// Creates a [ManageInvitationsDialog].
  const ManageInvitationsDialog({this.repository, super.key});

  /// Opens [ManageInvitationsDialog].
  static Future<void> show(
    BuildContext context, {
    InvitationRepository? repository,
  }) {
    final resolvedRepo = repository ?? context.read<InvitationRepository?>();
    return showAppGlassDialog<void>(
      context: context,
      builder: (_) => ManageInvitationsDialog(repository: resolvedRepo),
    );
  }

  /// Optional injected repository for testing.
  final InvitationRepository? repository;

  @override
  State<ManageInvitationsDialog> createState() =>
      _ManageInvitationsDialogState();
}

class _ManageInvitationsDialogState extends State<ManageInvitationsDialog> {
  List<InvitationRecord> _invitations = const [];
  bool _loading = true;
  String? _revokingId;
  String? _errorMessage;

  InvitationRepository? get _repository =>
      widget.repository ?? context.read<InvitationRepository?>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Invitations are unavailable right now.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await repo.listMyInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = list;
        _loading = false;
      });
    } on InvitationException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not load invitations.';
      });
    }
  }

  Future<void> _revoke(InvitationRecord inv) async {
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (confirmCtx) => AppGlassDialog(
        title: const Text('Revoke Invitation?'),
        content: Text(
          inv.isStudentConnection
              ? 'This will invalidate the student invitation link and cancel '
                    'any unaccepted connection request from it.'
              : 'This will prevent anyone else from redeeming this invitation '
                    'link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            key: const Key('confirmRevokeInvitationButton'),
            onPressed: () => Navigator.of(confirmCtx).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _revokingId = inv.id;
      _errorMessage = null;
    });

    try {
      final updated = await _repository!.revokeInvitation(inv.id);
      if (!mounted) return;
      setState(() {
        _invitations = [
          for (final item in _invitations)
            if (item.id == updated.id) updated else item,
        ];
        _revokingId = null;
      });
    } on InvitationException catch (e) {
      if (!mounted) return;
      setState(() {
        _revokingId = null;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _revokingId = null;
        _errorMessage = 'Could not revoke invitation.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTrainer =
        context.select((AppCubit c) => c.state.usersProfile?.isTrainer) ??
        false;
    final metrics = InvitationMetricsSummary.fromInvitations(_invitations);

    return AppGlassDialog(
      key: const Key('manageInvitationsDialog'),
      maxWidth: 660,
      title: const Text('Invitations'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceMd,
          children: [
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceSm,
              children: [
                if (isTrainer)
                  FilledButton.icon(
                    key: const Key('managerNewStudentInviteButton'),
                    icon: const Icon(Icons.school_outlined, size: 18),
                    label: const Text('Invite Student'),
                    onPressed: () {
                      final repo = _repository;
                      Navigator.of(context).pop();
                      InviteShareDialog.show(
                        context,
                        initialType: InvitationType.studentConnection,
                        repository: repo,
                      );
                    },
                  ),
                OutlinedButton.icon(
                  key: const Key('managerNewGeneralInviteButton'),
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('Invite Someone'),
                  onPressed: () {
                    final repo = _repository;
                    Navigator.of(context).pop();
                    InviteShareDialog.show(context, repository: repo);
                  },
                ),
              ],
            ),
            if (!_loading && _invitations.isNotEmpty)
              Wrap(
                key: const Key('invitationMetricsBar'),
                spacing: AppTokens.spaceSm,
                runSpacing: AppTokens.spaceSm,
                children: [
                  _MetricChip(label: 'Created', value: metrics.totalCreated),
                  _MetricChip(label: 'Active', value: metrics.activeCount),
                  _MetricChip(label: 'Joined', value: metrics.totalRedemptions),
                  if (metrics.studentInvitesSent > 0) ...[
                    _MetricChip(
                      label: 'Accepted',
                      value: metrics.studentInvitesAccepted,
                    ),
                    _MetricChip(
                      label: 'Pending',
                      value: metrics.studentInvitesPending,
                    ),
                    _MetricChip(
                      label: 'Declined',
                      value: metrics.studentInvitesDeclined,
                    ),
                  ],
                ],
              ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppTokens.spaceLg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_invitations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spaceMd,
                ),
                child: Text(
                  'You have not created any invitations yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _invitations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _buildRow(context, _invitations[index]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _load, child: const Text('Refresh')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, InvitationRecord inv) {
    final theme = Theme.of(context);
    final statusLabel = switch (inv.status) {
      InvitationStatus.active => 'Active',
      InvitationStatus.pending => 'Pending',
      InvitationStatus.registered => 'Registered (Awaiting Accept)',
      InvitationStatus.accepted => 'Accepted',
      InvitationStatus.declined => 'Declined',
      InvitationStatus.expired => 'Expired',
      InvitationStatus.revoked => 'Revoked',
      InvitationStatus.used => 'Used',
      InvitationStatus.invalid => 'Invalid',
    };
    final dateFmt = DateFormat.yMMMd();
    final details = <String>[
      'Created ${dateFmt.format(inv.createdAt.toLocal())}',
      'Expires ${dateFmt.format(inv.expiresAt.toLocal())}',
      if (inv.isStudentConnection &&
          inv.recipientDisplayName != null &&
          inv.recipientDisplayName!.isNotEmpty)
        'Recipient: ${inv.recipientDisplayName}'
      else if (!inv.isStudentConnection)
        'Joined: ${inv.redemptionCount} / ${inv.maxUses}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceSm,
        children: [
          Icon(
            inv.isStudentConnection
                ? Icons.school_outlined
                : Icons.group_add_outlined,
            size: 20,
            color: AppTokens.accentColor(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      inv.isStudentConnection
                          ? 'Student Invitation'
                          : 'General Invitation',
                      style: theme.textTheme.titleSmall,
                    ),
                    Chip(
                      label: Text(statusLabel),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(
                  details.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
                if (inv.personalMessage != null &&
                    inv.personalMessage!.isNotEmpty)
                  Text(
                    '"${inv.personalMessage!}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (inv.isRevocable)
            TextButton(
              key: Key('revokeInvitation_${inv.id}'),
              onPressed: _revokingId == inv.id ? null : () => _revoke(inv),
              child: const Text('Revoke'),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
