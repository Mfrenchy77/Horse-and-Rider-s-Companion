import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';

/// {@template profile_skills}
/// ProfileSkills widget displays the skills of the user or horse
/// {@endtemplate}
class ProfileSkills extends StatelessWidget {
  /// {@macro profile_skills}
  /// Displays the skills of the user or horse
  /// {@macro key}
  const ProfileSkills({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final skillLevels = state.isForRider
            ? state.viewingProfile != null
                ? state.viewingProfile?.skillLevels
                : state.usersProfile?.skillLevels
            : state.horseProfile?.skillLevels;

        return Wrap(
          spacing: 5,
          runSpacing: 5,
          alignment: WrapAlignment.center,
          children: [
            ...skillLevels
                    ?.map(
                      (e) => SkillLevelCard(
                        skillLevel: e,
                      ),
                    )
                    .toList() ??
                [const Text('No Skills')],
          ],
        );
      },
    );
  }
}
