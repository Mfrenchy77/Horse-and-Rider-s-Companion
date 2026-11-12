import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_level_select_confirmation_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_resources_list.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillLevelView extends StatelessWidget {
  const SkillLevelView({super.key, required this.skillId});

  final String? skillId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final skill = state.skill;
    if (skill == null || (skillId != null && skillId != skill.id)) {
      return const Center(child: Text('Skill Not Found'));
    }
    final theme = Theme.of(context);
    final level = getLevelState(
      skill: skill,
      profile: state.viewingProfile ?? state.usersProfile,
      horseProfile: state.isForRider ? null : state.horseProfile,
    );
    final canWrite = context.read<AppCubit>().canWriteProfileRecords();
    final difficulty = skill.difficulty == DifficultyState.All
        ? 'All levels'
        : skill.difficulty.name;
    return GradientCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Text(
              '${skill.category.name.replaceAll('_', ' ')} · $difficulty',
              style: theme.textTheme.labelLarge,
            ),
            Text(skill.skillName, style: theme.textTheme.headlineSmall),
            if (skill.description?.trim().isNotEmpty ?? false)
              Text(skill.description!),
            for (final (label, description) in [
              ('Learning', skill.learningDescription),
              ('Proficient', skill.proficientDescription),
            ])
              if (description?.trim().isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium),
                    Text(description!),
                  ],
                ),
            if (state.isGuest)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.login),
                  onPressed: () => context.goNamed(
                    AuthPage.name,
                    queryParameters: {'mode': 'login'},
                  ),
                  label: const Text('Sign in to track progress'),
                ),
              )
            else if (canWrite)
              Wrap(
                key: const Key('skillLevelProgressBar'),
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final (label, target) in [
                    ('Mark as learning', LevelState.LEARNING),
                    ('Mark as proficient', LevelState.PROFICIENT),
                  ])
                    OutlinedButton(
                      onPressed:
                          level == target ||
                              (target == LevelState.PROFICIENT &&
                                  level == LevelState.VERIFIED)
                          ? null
                          : () => showAppDialog<void>(
                              context: context,
                              builder: (_) =>
                                  SkillLevelSelectedConfimationDialog(
                                    key: const Key(
                                      'levelSelectedConfirmationDialog',
                                    ),
                                    levelState: target,
                                  ),
                            ),
                      child: Text(label),
                    ),
                ],
              ),
            const Divider(),
            Text('Resources', style: theme.textTheme.titleLarge),
            SkillResouresList(
              key: const Key('skillResourcesList'),
              skillId: skill.id,
            ),
          ],
        ),
      ),
    );
  }
}
