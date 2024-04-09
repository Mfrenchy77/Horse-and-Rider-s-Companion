import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

class SkillLevelSelectedConfimationDialog extends StatelessWidget {
  const SkillLevelSelectedConfimationDialog({
    super.key,
    required this.levelState,
  });
  final LevelState levelState;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return AlertDialog(
          title: const Text('Confirm Skill Level'),
          content: Text(
              'Are you sure you want to set ${state.skill?.skillName} '
              'level to ${levelState.name}${!state.isForRider ? ' for '
                  '${state.horseProfile?.name}' : state.isViewing ? ' '
                  'for ${state.viewingProfile?.name}' : ' for yourself'} ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                cubit.levelSelected(
                  levelState: levelState,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
