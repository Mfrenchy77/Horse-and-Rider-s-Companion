import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';

class HorseProfileOverFlowMenu extends StatelessWidget {
  const HorseProfileOverFlowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final horse = state.horseProfile;
        if (!cubit.isOwner() || state.isGuest || horse == null) {
          return const SizedBox.shrink();
        }
        return PopupMenuButton<String>(
          itemBuilder: (_) => [
            if (!horse.isArchived)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
              builder: (context) => AlertDialog(
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
