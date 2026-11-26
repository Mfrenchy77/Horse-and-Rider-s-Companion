import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/manage_invitations_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';
import 'package:horseandriderscompanion/Utilities/share_helper_stub.dart'
    if (dart.library.js_interop) 'package:horseandriderscompanion/Utilities/share_helper_web.dart';
import 'package:intl/intl.dart';

/// Frosted-glass dialog for creating and sharing personalized invitations.
class InviteShareDialog extends StatefulWidget {
  /// Creates an [InviteShareDialog].
  const InviteShareDialog({
    this.initialType = InvitationType.general,
    this.repository,
    super.key,
  });

  /// Opens the dialog with an optional starting invitation category.
  static Future<void> show(
    BuildContext context, {
    InvitationType initialType = InvitationType.general,
    InvitationRepository? repository,
  }) {
    final resolvedRepo = repository ?? context.read<InvitationRepository?>();
    return showAppGlassDialog<void>(
      context: context,
      builder: (_) =>
          InviteShareDialog(initialType: initialType, repository: resolvedRepo),
    );
  }

  /// Initial category selected when opening the dialog.
  final InvitationType initialType;

  /// Optional injected repository for testing.
  final InvitationRepository? repository;

  @override
  State<InviteShareDialog> createState() => _InviteShareDialogState();
}

class _InviteShareDialogState extends State<InviteShareDialog> {
  final TextEditingController _noteController = TextEditingController();
  late InvitationType _selectedType;
  InvitationCreateResult? _created;
  bool _creating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _generateInvitation(bool isTrainer) async {
    final repo = widget.repository ?? context.read<InvitationRepository?>();
    if (repo == null) {
      setState(() {
        _errorMessage = 'Invitation service is currently unavailable.';
      });
      return;
    }

    final effectiveType =
        isTrainer && _selectedType == InvitationType.studentConnection
        ? InvitationType.studentConnection
        : InvitationType.general;

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      final created = await repo.createInvitation(
        InvitationCreateRequest(
          type: effectiveType,
          personalMessage: _noteController.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _created = created;
        _creating = false;
      });
    } on InvitationException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _errorMessage = 'Could not create invitation. Please try again.';
      });
    }
  }

  Future<void> _shareInvite({
    required InvitationCreateResult result,
    required String inviterName,
  }) async {
    final url = buildInvitationShareUrl(result.token);
    final message = buildInvitationShareMessage(
      type: result.invitation.type,
      inviterName: inviterName,
      url: url,
      personalMessage: result.invitation.personalMessage,
    );
    final title = result.invitation.type == InvitationType.studentConnection
        ? "Student Invitation — Horse & Rider's Companion"
        : "Join Horse & Rider's Companion";
    final nativeHandler = debugNativeShareOverride ?? tryNativeWebShare;
    final shared = await nativeHandler(title: title, url: url, text: message);
    if (shared || !mounted) return;
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation message and link copied to clipboard'),
      ),
    );
  }

  Future<void> _copyText(String text, String snackbarMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final profile = appState.usersProfile;
    final isTrainer = profile?.isTrainer ?? false;
    final inviterName = profile?.name.trim().isNotEmpty ?? false
        ? profile!.name
        : appState.user.name;

    if (!isTrainer && _selectedType == InvitationType.studentConnection) {
      _selectedType = InvitationType.general;
    }

    final created = _created;
    final shareUrl = created != null
        ? buildInvitationShareUrl(created.token)
        : null;
    final shareMessage = created != null && shareUrl != null
        ? buildInvitationShareMessage(
            type: created.invitation.type,
            inviterName: inviterName,
            url: shareUrl,
            personalMessage: created.invitation.personalMessage,
          )
        : null;

    return AppGlassDialog(
      key: const Key('inviteShareDialog'),
      maxWidth: 480,
      title: Text(
        _selectedType == InvitationType.studentConnection
            ? 'Invite Student'
            : 'Invite Someone',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceMd,
          children: [
            if (created == null) ...[
              if (isTrainer) ...[
                SegmentedButton<InvitationType>(
                  key: const Key('inviteTypeSegmentedButton'),
                  segments: const [
                    ButtonSegment(
                      value: InvitationType.studentConnection,
                      icon: Icon(Icons.school_outlined, size: 18),
                      label: Text('Student'),
                    ),
                    ButtonSegment(
                      value: InvitationType.general,
                      icon: Icon(Icons.group_add_outlined, size: 18),
                      label: Text('General'),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: _creating
                      ? null
                      : (selection) => setState(() {
                          _selectedType = selection.first;
                        }),
                ),
              ],
              Text(
                _selectedType == InvitationType.studentConnection
                    ? 'Create a personal single-use link for your student. '
                          'After they sign in, they can review and accept '
                          'your coaching connection request.'
                    : 'Share a reusable link inviting someone to join '
                          "Horse & Rider's Companion.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              TextField(
                key: const Key('invitePersonalMessageField'),
                controller: _noteController,
                enabled: !_creating,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Personal note (optional)',
                  hintText: 'Add a welcoming note for your invitation...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ] else ...[
              Text(
                created.invitation.isStudentConnection
                    ? 'Your student invitation link is ready.'
                    : 'Your invitation link is ready.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceSm),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: SelectableText(
                  shareUrl!,
                  key: const Key('inviteGeneratedUrlText'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Builder(
                builder: (context) {
                  final expiryStr = DateFormat.yMMMd().format(
                    created.invitation.expiresAt.toLocal(),
                  );
                  return Text(
                    created.invitation.isStudentConnection
                        ? 'Single-use link · Expires $expiryStr'
                        : 'Up to ${created.invitation.maxUses} uses · '
                              'Expires $expiryStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.secondaryTextColor(context),
                    ),
                  );
                },
              ),
              Wrap(
                spacing: AppTokens.spaceSm,
                runSpacing: AppTokens.spaceSm,
                children: [
                  FilledButton.icon(
                    key: const Key('inviteNativeShareButton'),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    onPressed: () =>
                        _shareInvite(result: created, inviterName: inviterName),
                  ),
                  OutlinedButton.icon(
                    key: const Key('inviteCopyLinkButton'),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Link'),
                    onPressed: () =>
                        _copyText(shareUrl, 'Invitation link copied'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('inviteCopyMessageButton'),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Copy Message'),
                    onPressed: () =>
                        _copyText(shareMessage!, 'Invitation message copied'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inviteOpenManagerButton'),
          onPressed: () {
            final repo =
                widget.repository ?? context.read<InvitationRepository?>();
            Navigator.of(context).pop();
            ManageInvitationsDialog.show(context, repository: repo);
          },
          child: const Text('Manage Invitations'),
        ),
        if (created == null) ...[
          TextButton(
            onPressed: _creating ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('inviteGenerateLinkButton'),
            onPressed: _creating ? null : () => _generateInvitation(isTrainer),
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Link'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() {
              _created = null;
              _noteController.clear();
            }),
            child: const Text('Create Another'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }
}
