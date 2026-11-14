import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

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
        return AppGlassDialog(
          title: const Text('Confirm Skill Level'),
          content: Text(
            'Are you sure you want to set ${state.skill?.skillName} '
            'level to ${levelState.name}${!state.isForRider
                ? ' for '
                      '${state.horseProfile?.name}'
                : state.isViewing
                ? ' '
                      'for ${state.viewingProfile?.name}'
                : ' for yourself'} ?',
          ),
          actions: [
            AppOutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              label: 'No',
            ),
            AppPrimaryButton(
              onPressed: () async {
                Navigator.of(context).pop();
                cubit.levelSelected(levelState: levelState);
              },
              label: 'Yes',
            ),
          ],
        );
      },
    );
  }
}
