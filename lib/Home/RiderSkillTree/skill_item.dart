import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

Widget skillItem({
  required String? name,
  required VoidCallback onTap,
  required VoidCallback onEdit,
  required bool isEditState,
  required bool isGuest,
  required Color backgroundColor,
  required DifficultyState? difficulty,
}) {
  return InkWell(
    onTap: onTap,
    child: Card(
      color: backgroundColor,
      elevation: 8,
      child: SizedBox(
        width: 150,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name ?? '',
                  style: TextStyle(
                    color: difficulty == DifficultyState.advanced
                        ? Colors.white70
                        : Colors.black,
                  ),
                ),
                Visibility(
                  visible: isEditState && !isGuest,
                  child: InkWell(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit,
                      color: difficulty == DifficultyState.advanced
                          ? Colors.white70
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
