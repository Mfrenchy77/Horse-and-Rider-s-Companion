import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

class SkillItem extends StatelessWidget {
  const SkillItem({
    super.key,
    required this.name,
    required this.onTap,
    required this.onEdit,
    required this.isGuest,
    required this.verified,
    required this.levelState,
    required this.isEditState,
    required this.backgroundColor,
  });

  final bool isGuest;
  final String? name;
  final bool? verified;
  final bool isEditState;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Color backgroundColor;
  final LevelState levelState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: levelState == LevelState.PROFICIENT
                ? verified ?? false
                    ? Colors.yellow
                    : Colors.blue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            gradient: levelState == LevelState.LEARNING
                ? LinearGradient(
                    stops: const [0.5, 0.5],
                    colors: [
                      if (verified ?? false) Colors.yellow else Colors.blue,
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name ?? '',
                  style: TextStyle(
                    color: _skillItemTextColor(levelState),
                  ),
                ),
                Visibility(
                  visible: isEditState && !isGuest,
                  child: InkWell(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit,
                      color: _skillItemTextColor(levelState),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The color of the text in the skill item depending on the level state
/// and if the skill is verified black for everyting except, proficient
Color _skillItemTextColor(LevelState levelState) {
  return levelState == LevelState.PROFICIENT ? Colors.white70 : Colors.black;
}
