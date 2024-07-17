import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Returns the icon for the resource based on the category and difficulty
Icon? resourceIcon(SkillCategory? category, DifficultyState difficulty) {
  if (category == SkillCategory.In_Hand) {
    return Icon(
      HorseAndRiderIcons.inhand,
      color: _color(difficulty),
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
        ),
      ],
    );
  } else if (category == SkillCategory.Husbandry) {
    return Icon(
      HorseAndRiderIcons.husbandry,
      color: _color(difficulty),
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
        ),
      ],
    );
  } else if (category == SkillCategory.Mounted) {
    return Icon(
      HorseAndRiderIcons.riding,
      color: _color(difficulty),
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
        ),
      ],
    );
  } else {
    return null;
  }
}

Color _color(DifficultyState difficulty) {
  switch (difficulty) {
    case DifficultyState.Introductory:
      return Colors.lightGreen;
    case DifficultyState.Intermediate:
      return Colors.orange;
    case DifficultyState.Advanced:
      return Colors.red;
    case DifficultyState.All:
      return Colors.transparent;
  }
}
