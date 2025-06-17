import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// A card to display a skill level.
class SkillLevelCard extends StatelessWidget {
  const SkillLevelCard({
    super.key,
    required this.onTap,
    this.onPrereqIconTap,
    required this.category,
    required this.difficulty,
    required this.skillLevel,
    this.hasUnmetPrerequisites = false,
  });

  final VoidCallback? onTap;
  final SkillLevel skillLevel;
  final SkillCategory category;
  final DifficultyState difficulty;
  final bool hasUnmetPrerequisites;
  final VoidCallback? onPrereqIconTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _buildGradient(skillLevel),
                color: _buildBackgroundColor(skillLevel),
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
          if (hasUnmetPrerequisites)
            Positioned(
              top: -4,
              right: -4,
              child: InkWell(
                onTap: onPrereqIconTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outlined,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color? _buildBackgroundColor(SkillLevel skillLevel) {
  if (skillLevel.levelState == LevelState.PROFICIENT) {
    return skillLevel.verified ? Colors.yellow : Colors.blue;
  }

  return null; // fallback to transparent
}

Gradient? _buildGradient(SkillLevel skillLevel) {
  if (skillLevel.levelState == LevelState.LEARNING) {
    final fillColor = skillLevel.verified ? Colors.yellow : Colors.blue;

    return LinearGradient(
      stops: const [0.48, 0.52],
      colors: [
        fillColor,
        Colors.transparent,
      ],
    );
  }

  return null;
}

Widget _icon(SkillCategory category, DifficultyState difficulty) {
  switch (category) {
    case SkillCategory.Mounted:
      return Icon(
        HorseAndRiderIcons.riding,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(1, 1),
          ),
        ],
      );
    case SkillCategory.In_Hand:
      return Icon(
        HorseAndRiderIcons.inhand,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(1, 1),
          ),
        ],
      );
    case SkillCategory.Husbandry:
      return Icon(
        HorseAndRiderIcons.husbandry,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(1, 1),
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
