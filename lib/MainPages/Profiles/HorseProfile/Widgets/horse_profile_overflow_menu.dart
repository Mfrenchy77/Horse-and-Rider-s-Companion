import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_sale_panel.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';

class HorseProfileOverFlowMenu extends StatefulWidget {
  const HorseProfileOverFlowMenu({super.key});

  @override
  State<HorseProfileOverFlowMenu> createState() =>
      _HorseProfileOverFlowMenuState();
}

class _HorseProfileOverFlowMenuState extends State<HorseProfileOverFlowMenu> {
  bool _working = false;

  Future<void> _manageHorse(String action, HorseProfile horse) async {
    if (_working) return;
    final repository = context.read<ConnectionRepository>();
    setState(() => _working = true);
    try {
      final request = await _horseActionRequest(action, horse);
      if (!mounted || request == null) return;
      final cubit = context.read<AppCubit>();
      if (!cubit.isOwner() || cubit.state.horseProfile?.id != horse.id) return;
      final result = await repository.submit({'horseId': horse.id, ...request});
      if (!mounted) return;
      final message = switch (action) {
        'listing' => 'Sale listing saved.',
        'unlist' => 'Sale listing removed.',
        'transfer' => 'Transfer request sent.',
        _ when result['incoming'] == true =>
          'Review the existing incoming request.',
        _ when result['status'] == 'accepted' =>
          'This connection is already active.',
        _ => 'Request sent.',
      };
      _showMessage(message);
    } on ConnectionFailure catch (error) {
      if (!mounted) return;
      final message = switch ((action, error.message)) {
        ('listing' || 'unlist', 'Invalid connection ID.') =>
          'Sale listings require an updated Firebase service.',
        ('transfer', 'Invalid connection ID.') =>
          'Ownership transfers are unavailable in'
              ' this version of the Firebase service.',
        _ => error.message,
      };
      context.read<AppCubit>().createError(message);
    } catch (_) {
      if (mounted) {
        context.read<AppCubit>().createError(
          'The change could not be saved. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, Object?>?> _horseActionRequest(
    String action,
    HorseProfile horse,
  ) async {
    switch (action) {
      case 'listing':
        final listing = await showDialog<HorseSaleListing>(
          context: context,
          builder: (_) => HorseSaleListingDialog(listing: horse.saleListing),
        );
        if (listing == null) return null;
        return {
          'action': 'setSaleListing',
          'listing': {
            'price': listing.price,
            'location': listing.location,
            'description': listing.description,
          },
        };
      case 'unlist':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => OceanCoralAppDialog(
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
        return (confirmed ?? false)
            ? {'action': 'setSaleListing', 'listing': null}
            : null;
      default:
        final transfer = action == 'transfer';
        final email = await showDialog<String>(
          context: context,
          builder: (_) => _TrainerEmailDialog(transfer: transfer),
        );
        if (email == null) return null;
        return transfer
            ? {'action': 'sendTransfer', 'recipientEmail': email}
            : {'action': 'send', 'kind': 'horse', 'coachEmail': email};
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final horse = state.horseProfile;
        if (!cubit.isOwner() || state.isGuest || horse == null) {
          return const SizedBox.shrink();
        }
        final canManage =
            !horse.isArchived && context.read<ConnectionRepository?>() != null;
        return PopupMenuButton<String>(
          enabled: !_working,
          itemBuilder: (_) => [
            if (!horse.isArchived)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (canManage) ...[
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
              const PopupMenuItem(
                value: 'invite',
                child: Text('Invite trainer'),
              ),
            ],
            if (horse.isArchived)
              const PopupMenuItem(
                value: 'restore',
                child: Text('Restore horse'),
              )
            else
              const PopupMenuItem(
                value: 'archive',
                child: Text('Archive horse'),
              ),
            if (horse.archiveStatus == 'archived')
              const PopupMenuItem(
                value: 'deceased',
                child: Text('Mark as deceased'),
              ),
          ],
          onSelected: (value) async {
            if (['listing', 'unlist', 'transfer', 'invite'].contains(value)) {
              await _manageHorse(value, horse);
              return;
            }
            if (value == 'edit') {
              await showDialog<AddHorseDialog>(
                context: context,
                builder: (_) => AddHorseDialog(
                  horseProfile: horse,
                  userProfile: state.usersProfile!,
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
            final status = await showDialog<String>(
              context: context,
              builder: (context) => OceanCoralAppDialog(
                title: Text(
                  markDeceased
                      ? 'Mark this horse as deceased?'
                      : 'Archive this horse?',
                ),
                content: Text(
                  markDeceased
                      ? 'The horse stays in Archived horses '
                            'with its full logbook.'
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
  Widget build(BuildContext context) => OceanCoralAppDialog(
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
