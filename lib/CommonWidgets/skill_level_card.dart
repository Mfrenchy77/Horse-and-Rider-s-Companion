import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';

Widget skillLevelCard({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
  required SkillLevel skillLevel,
}) {
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
                    if (skillLevel.verified) Colors.yellow else Colors.blue,
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
                  final skill = state.allSkills?.firstWhere(
                    (element) => element?.id == skillLevel.skillId,
                  );

                  homeCubit.navigateToSkillLevel(
                    isSplitScreen: MediaQuery.of(context).size.width > 1200,
                    skill: skill,
                  );
                },
        ),
      ),
    ),
  );
}
