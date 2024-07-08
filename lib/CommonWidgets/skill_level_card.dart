import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// A card to display a skill level.
class SkillLevelCard extends StatelessWidget {
  const SkillLevelCard({
    super.key,
    required this.onTap,
    required this.category,
    required this.difficulty,
    required this.skillLevel,
  });

  final VoidCallback? onTap;
  final SkillLevel skillLevel;
  final SkillCategory category;
  final DifficultyState difficulty;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: skillLevel.levelState == LevelState.PROFICIENT
                ? skillLevel.verified
                    ? Colors.yellow
                    : Colors.blue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _icon(category, difficulty),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                child: Text(
                  skillLevel.skillName,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _icon(SkillCategory category, DifficultyState difficulty) {
  switch (category) {
    case SkillCategory.Mounted:
      return Icon(
        HorseAndRiderIcons.riding,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(1,1),
          ),
        ],
      );
    case SkillCategory.In_Hand:
      return Icon(
        HorseAndRiderIcons.inhand,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(1,1),
          ),
        ],
      );
    case SkillCategory.Husbandry:
      return Icon(
        HorseAndRiderIcons.husbandry,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(1,1),
          ),
        ],
      );
    case SkillCategory.Other:
      return const Placeholder();
  }
}

Color _color(DifficultyState difficulty) {
  switch (difficulty) {
    case DifficultyState.Introductory:
      return Colors.lightGreen;
    case DifficultyState.Intermediate:
      return Colors.yellow;
    case DifficultyState.Advanced:
      return Colors.red;
    case DifficultyState.All:
      return Colors.transparent;
  }
}
