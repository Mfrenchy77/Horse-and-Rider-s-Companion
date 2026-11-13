import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

class SkillProgressBadge extends StatelessWidget {
  const SkillProgressBadge({
    super.key,
    required this.level,
    this.verified = false,
  });

  final LevelState level;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (label, icon, background, foreground) = switch (level) {
      LevelState.NO_PROGRESS => (
        'Not started',
        Icons.circle_outlined,
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      LevelState.LEARNING => (
        'Learning',
        Icons.school_outlined,
        const Color(0xFFDCEBFF),
        const Color(0xFF193E72),
      ),
      LevelState.PROFICIENT || LevelState.VERIFIED => (
        'Proficient',
        Icons.check_circle_outline,
        const Color(0xFFD4F3E3),
        const Color(0xFF14533A),
      ),
    };
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _badge(theme, label, icon, background, foreground),
        if (verified || level == LevelState.VERIFIED)
          _badge(
            theme,
            'Verified',
            Icons.verified,
            const Color(0xFFFFD54F),
            const Color(0xFF553700),
          ),
      ],
    );
  }

  Widget _badge(
    ThemeData theme,
    String label,
    IconData icon,
    Color fill,
    Color ink,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: ink),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
