import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

/// A card to display a skill level.
class SkillLevelCard extends StatelessWidget {
  const SkillLevelCard({
    super.key,
    required this.skillLevel,
    required this.onTap,
  });
  final SkillLevel skillLevel;
  final VoidCallback? onTap;

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
          child: Padding(
            padding:
                const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
            child: Text(
              skillLevel.skillName,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
