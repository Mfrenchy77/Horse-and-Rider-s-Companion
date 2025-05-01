import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// A widget that returns the icon for the resource based on the category
///  and difficulty.
class ResourceIcon extends StatelessWidget {
  const ResourceIcon({
    super.key,
    required this.category,
    required this.difficulty,
  });
  final SkillCategory? category;
  final DifficultyState? difficulty;

  @override
  Widget build(BuildContext context) {
    IconData? iconData;
    switch (category) {
      case SkillCategory.In_Hand:
        iconData = HorseAndRiderIcons.inhand;
        break;
      case SkillCategory.Husbandry:
        iconData = HorseAndRiderIcons.husbandry;
        break;
      case SkillCategory.Mounted:
        iconData = HorseAndRiderIcons.riding;
        break;
      case SkillCategory.Other:
        break;
      case null:
        break;
    }

    return Icon(
      iconData,
      color: _color(difficulty),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: .5),
          offset: const Offset(1, 1),
        ),
      ],
    );
  }

  Color _color(DifficultyState? difficulty) {
    switch (difficulty) {
      case DifficultyState.Introductory:
        return Colors.green;
      case DifficultyState.Intermediate:
        return Colors.yellow;
      case DifficultyState.Advanced:
        return Colors.red;
      case DifficultyState.All:
        return Colors.transparent;
      case null:
        return Colors.transparent;
    }
  }
}
