import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Returns the icon for the resource based on the if the skill is for a rider/horse
///  and difficulty
class SkillTypeIcon extends StatelessWidget {
  const SkillTypeIcon({
    super.key,
    required this.isRider,
    required this.difficulty,
  });
  final bool isRider;
  final DifficultyState? difficulty;

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    if (isRider) {
      iconData = Icons.person;
    } else {
      iconData = HorseAndRiderIcons.horseIcon;
    }

    switch (difficulty) {
      case DifficultyState.Introductory:
        iconColor = Colors.green;
        break;
      case DifficultyState.Intermediate:
        iconColor = Colors.yellow;
        break;
      case DifficultyState.Advanced:
        iconColor = Colors.red;
        break;
      case DifficultyState.All:
        iconColor = Colors.transparent;
        break;
      case null:
        iconColor = Colors.transparent;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: .5),
          offset: const Offset(1, 1),
        ),
      ],
    );
  }
}
