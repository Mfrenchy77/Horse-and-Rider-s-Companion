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
  });

  final bool isGuest;
  final String? name;
  final bool? verified;
  final bool isEditState;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final LevelState levelState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
            ),
          ],
          color: levelState == LevelState.PROFICIENT
              ? verified ?? false
                  ? Colors.yellow
                  : Colors.blue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
                top: 8,
                left: 16,
                right: 16,
              ),
              child: Text(
                name ?? '',
              ),
            ),
            Visibility(
              visible: isEditState && !isGuest,
              child: PopupMenuButton<String>(
                iconSize: 18,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Text('Edit'),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
