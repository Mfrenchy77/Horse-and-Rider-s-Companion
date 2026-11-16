import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_sale_panel.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';

class HorseProfileOverFlowMenu extends StatelessWidget {
  const HorseProfileOverFlowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();

    // Narrow rebuilds: only depend on the fields we need.
    final isGuest = context.select((AppCubit c) => c.state.isGuest);
    final horse = context.select((AppCubit c) => c.state.horseProfile);
    final userEmail = context.select(
      (AppCubit c) => c.state.usersProfile?.email,
    );
    final busy = context.select(
      (AppCubit c) =>
          c.state.horseManageInProgress &&
          c.state.horseManageHorseId == horse?.id,
    );

    if (horse == null) {
      return const SizedBox.shrink();
    }

    final isOwner =
        !isGuest &&
        userEmail != null &&
        horse.currentOwnerId.toLowerCase() == userEmail.toLowerCase();
    final canSharePublicly = horse.isPublic && !horse.isArchived;
    if (!isOwner && !canSharePublicly) return const SizedBox.shrink();

    final canManage = !horse.isArchived;

    Future<void> manage(String action) async {
      switch (action) {
        case 'listing':
          final listing = await showAppGlassDialog<HorseSaleListing>(
            context: context,
            builder: (_) => HorseSaleListingDialog(listing: horse.saleListing),
          );
          if (listing == null) return;
          await cubit.submitHorseManageAction(
            horse: horse,
            action: 'listing',
            listing: {
              'price': listing.price,
              'location': listing.location,
              'description': listing.description,
            },
          );
          return;
        case 'unlist':
          final confirmed = await showAppGlassDialog<bool>(
            context: context,
            builder: (context) => AppGlassDialog(
              title: const Text('Remove sale listing?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove listing'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          await cubit.submitHorseManageAction(horse: horse, action: 'unlist');
          return;
        case 'toggle_public':
          await cubit.setHorsePublicSharing(
            horse,
            isPublic: !horse.isPublic,
          );
          return;
        default:
          final transfer = action == 'transfer';
          final email = await showAppGlassDialog<String>(
            context: context,
            builder: (_) => _TrainerEmailDialog(transfer: transfer),
          );
          if (email == null) return;
          await cubit.submitHorseManageAction(
            horse: horse,
            action: action,
            recipientEmail: email,
          );
      }
    }

    return PopupMenuButton<String>(
      enabled: !busy,
      itemBuilder: (_) => [
        const PopupMenuItem(
          key: Key('horseMenuShareProfile'),
          value: 'share',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, size: 18),
              SizedBox(width: AppTokens.spaceSm),
              Text('Share Profile'),
            ],
          ),
        ),
        if (isOwner) ...[
          if (!horse.isArchived)
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
          if (canManage) ...[
            PopupMenuItem(
              value: 'toggle_public',
              child: Text(
                horse.isPublic
                    ? 'Make profile private'
                    : 'Enable public sharing',
              ),
            ),
            PopupMenuItem(
              value: 'listing',
              child: Text(
                horse.saleListing == null ? 'List for sale' : 'Edit listing',
              ),
            ),
            if (horse.saleListing != null)
              const PopupMenuItem(
                value: 'unlist',
                child: Text('Remove listing'),
              ),
            if (horse.transferRequestId == null)
              const PopupMenuItem(
                value: 'transfer',
                child: Text('Transfer ownership'),
              ),
            const PopupMenuItem(value: 'invite', child: Text('Invite trainer')),
          ],
          if (horse.isArchived)
            const PopupMenuItem(value: 'restore', child: Text('Restore horse'))
          else
            const PopupMenuItem(value: 'archive', child: Text('Archive horse')),
          if (horse.archiveStatus == 'archived')
            const PopupMenuItem(
              value: 'deceased',
              child: Text('Mark as deceased'),
            ),
        ],
      ],
      onSelected: (value) async {
        if (value == 'share') {
          if (horse.isArchived) {
            await showAppGlassDialog<void>(
              context: context,
              builder: (dialogContext) => AppGlassDialog(
                key: const Key('horseSharePrivateDialog'),
                title: const Text('Cannot Share Archived Profile'),
                content: const Text(
                  'Archived horse profiles cannot be shared publicly.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
            return;
          }
          if (!horse.isPublic) {
            final enableAndShare = await showAppGlassDialog<bool>(
              context: context,
              builder: (dialogContext) => AppGlassDialog(
                key: const Key('horseSharePrivateDialog'),
                title: const Text('Horse Profile is Private'),
                content: Text(
                  isOwner
                      ? 'Public sharing must be enabled before sharing '
                            'this profile link.'
                      : 'This horse profile is private. Only the owner can '
                            'enable public sharing.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(isOwner ? 'Cancel' : 'Close'),
                  ),
                  if (isOwner)
                    FilledButton(
                      key: const Key('horseEnablePublicAndShareButton'),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Enable & Share'),
                    ),
                ],
              ),
            );
            if (enableAndShare != true || !isOwner || !context.mounted) {
              return;
            }
            await cubit.setHorsePublicSharing(horse, isPublic: true);
            if (!context.mounted) return;
          }
          await shareAppLink(
            context,
            title: "${horse.name} — Horse & Rider's Companion",
            dialogTitle: 'Share Horse Profile',
            url: buildHorseShareUrl(horse.id),
          );
          return;
        }
        if ([
          'listing',
          'unlist',
          'transfer',
          'invite',
          'toggle_public',
        ].contains(value)) {
          await manage(value);
          return;
        }
        if (value == 'edit') {
          await showAppGlassDialog<AddHorseDialog>(
            context: context,
            builder: (_) => AddHorseDialog(
              horseProfile: horse,
              userProfile: context.read<AppCubit>().state.usersProfile!,
              editProfile: true,
            ),
          );
          return;
        }
        if (value == 'restore') {
          await cubit.setHorseArchive('active');
          return;
        }
        final markDeceased = value == 'deceased';
        final status = await showAppGlassDialog<String>(
          context: context,
          builder: (context) => AppGlassDialog(
            title: Text(
              markDeceased
                  ? 'Mark this horse as deceased?'
                  : 'Archive this horse?',
            ),
            content: Text(
              markDeceased
                  ? 'The horse stays in Archived horses with its full logbook.'
                  : 'The horse will move to Archived horses. '
                        'You’ll keep ownership and the full logbook.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (!markDeceased)
                TextButton(
                  onPressed: () => Navigator.pop(context, 'deceased'),
                  child: const Text('Archive as deceased'),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  markDeceased ? 'deceased' : 'archived',
                ),
                child: Text(
                  markDeceased ? 'Mark as deceased' : 'Archive horse',
                ),
              ),
            ],
          ),
        );
        if (status != null &&
            context.mounted &&
            cubit.state.horseProfile?.id == horse.id) {
          await cubit.setHorseArchive(status);
        }
      },
    );
  }
}

class _TrainerEmailDialog extends StatefulWidget {
  const _TrainerEmailDialog({this.transfer = false});

  final bool transfer;

  @override
  State<_TrainerEmailDialog> createState() => _TrainerEmailDialogState();
}

class _TrainerEmailDialogState extends State<_TrainerEmailDialog> {
  String _email = '';

  @override
  Widget build(BuildContext context) => AppGlassDialog(
    title: Text(widget.transfer ? 'Transfer ownership' : 'Invite a trainer'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.transfer)
          const Text('You keep ownership until the recipient accepts.'),
        TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: widget.transfer ? 'Recipient email' : 'Trainer email',
          ),
          onChanged: (value) => setState(() => _email = value.trim()),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _email.contains('@')
            ? () => Navigator.pop(context, _email)
            : null,
        child: Text(
          widget.transfer ? 'Send transfer request' : 'Send invitation',
        ),
      ),
    ],
  );
}
