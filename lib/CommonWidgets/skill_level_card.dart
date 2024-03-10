import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

/// A card to display a skill level.
class SkillLevelCard extends StatelessWidget {
  const SkillLevelCard({super.key, required this.skillLevel});
  final SkillLevel skillLevel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return SizedBox(
          width: 200,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: skillLevel.levelState == LevelState.PROFICIENT
                    ? skillLevel.verified
                        ? Colors.yellow
                        : Colors.blue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                gradient: skillLevel.levelState == LevelState.LEARNING
                    ? LinearGradient(
                        stops: const [0.5, 0.5],
                        colors: [
                          if (skillLevel.verified)
                            Colors.yellow
                          else
                            Colors.blue,
                          Colors.transparent,
                        ],
                      )
                    : null,
              ),
              child: ListTile(
                title: Text(
                  skillLevel.skillName,
                  textAlign: TextAlign.center,
                ),
                subtitle: Text(
                  '${skillLevel.levelState.toString().split('.').last} '
                  '${skillLevel.verified ? ' \n (Verified by: '
                      '${skillLevel.lastEditBy})' : ''}',
                  textAlign: TextAlign.center,
                ),
                onTap: state.isGuest
                    ? null
                    : () {
                        cubit.navigateToSkillLevel(
                          skill:
                              cubit.getSkillFromSkillName(skillLevel.skillName),
                        );
                      },
              ),
            ),
          ),
        );
      },
    );
  }
}
