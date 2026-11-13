import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_progress_badge.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Displays recorded skills on rider and horse profiles.
class ProfileSkills extends StatelessWidget {
  const ProfileSkills({super.key, required this.skillLevels});

  final List<SkillLevel>? skillLevels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'No skills recorded yet',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    if (skillLevels?.isNotEmpty != true) return empty;

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final audit = SkillLevelAudit.evaluate(
          profileSkillLevels: skillLevels,
          allSkills: state.allSkills,
        );
        if (!audit.isCatalogReady) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (audit.validLevels.isEmpty) return empty;

        final skills = {
          for (final skill in state.allSkills.whereType<Skill>())
            skill.id: skill,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final level in audit.validLevels)
              _ProfileSkillRow(
                level: level,
                skill: skills[level.skillId]!,
                onTap: state.isGuest
                    ? null
                    : () {
                        context.read<AppCubit>().setSkillTree();
                        context.goNamed(
                          SkillTreeView.skillLevelName,
                          pathParameters: {
                            SkillTreeView.skillPathParam: level.skillId,
                          },
                        );
                      },
              ),
          ],
        );
      },
    );
  }
}

class _ProfileSkillRow extends StatelessWidget {
  const _ProfileSkillRow({
    required this.level,
    required this.skill,
    required this.onTap,
  });

  final SkillLevel level;
  final Skill skill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = switch (skill.category) {
      SkillCategory.Mounted => HorseAndRiderIcons.riding,
      SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
      SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
      SkillCategory.Other => Icons.school_outlined,
    };
    final verified = level.verified || level.levelState == LevelState.VERIFIED;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        horizontalTitleGap: 12,
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: colors.onSecondaryContainer),
          ),
        ),
        title: Text(
          level.skillName,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (skill.difficulty != DifficultyState.All)
                Text(skill.difficulty.name),
              SkillProgressBadge(level: level.levelState, verified: verified),
            ],
          ),
        ),
        trailing: onTap == null
            ? null
            : Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
