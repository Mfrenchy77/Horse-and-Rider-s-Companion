import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_progress_badge.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/skill_level_select_confirmation_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_resources_list.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillLevelView extends StatelessWidget {
  const SkillLevelView({super.key, required this.skillId});

  final String? skillId;

  Future<void> _verify(
    BuildContext context,
    CoachingConnection link,
    Skill skill,
    LevelState? level,
    String subject,
  ) async {
    final removing = level == null;
    final label = level == LevelState.LEARNING ? 'Learning' : 'Proficient';
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (context) => AppGlassDialog(
        title: Text(removing ? 'Remove verification?' : 'Verify skill'),
        content: Text(
          removing
              ? 'Remove your verification for ${skill.skillName}? '
                    'The recorded skill level will stay the same.'
              : 'Verify ${skill.skillName} as $label for $subject? '
                    'This will add a verification to the logbook.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              removing ? 'Remove verification' : 'Confirm verification',
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    final connections = context.read<ConnectionsCubit>();
    final app = context.read<AppCubit>();
    final result = await connections.submit({
      'action': removing ? 'removeSkillVerification' : 'verifySkill',
      'id': link.id,
      'version': link.version,
      'recordId': ViewUtils.createId(),
      'skillId': skill.id,
      if (level != null) 'level': level.name,
    });
    if (!context.mounted) return;
    final saved = result?['verified'] == !removing;
    if (saved && link.kind == 'rider') {
      final viewed = app.state.viewingProfile;
      if (viewed?.email.toLowerCase() == link.learner) {
        await app.refreshViewedRider(viewed!.email);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? (removing ? 'Verification removed.' : 'Skill verified.')
              : connections.state.actionFeedback ??
                    'Could not update verification. Try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final skill = state.skill;
    if (skill == null || (skillId != null && skillId != skill.id)) {
      return const Center(child: Text('Skill Not Found'));
    }
    final theme = Theme.of(context);
    final rider = state.isViewing ? state.viewingProfile : state.usersProfile;
    final horse = state.isForRider ? null : state.horseProfile;
    final level = getLevelState(
      skill: skill,
      profile: rider,
      horseProfile: horse,
    );
    final verified = isVerified(
      skill: skill,
      profile: rider,
      horseProfile: horse,
    );
    final connectionState = context.watch<ConnectionsCubit?>()?.state;
    final coachingLink =
        state.isGuest ||
            connectionState?.email != state.usersProfile?.email.toLowerCase()
        ? null
        : switch ((state.isForRider, skill.rider)) {
            (true, true) when state.isViewing && rider != null =>
              connectionState?.instructorFor(rider.email),
            (false, false) when horse != null && !horse.isArchived =>
              connectionState?.connections
                  .where(
                    (link) =>
                        link.kind == 'horse' &&
                        link.status == 'accepted' &&
                        link.coach == connectionState.email &&
                        link.horseId == horse.id &&
                        link.learner == horse.currentOwnerId.toLowerCase() &&
                        link.ownershipVersion == horse.ownershipVersion,
                  )
                  .firstOrNull,
            _ => null,
          };
    final levels = state.isForRider ? rider?.skillLevels : horse?.skillLevels;
    final recorded = levels
        ?.where((entry) => entry.skillId == skill.id)
        .firstOrNull;
    final canRemove =
        coachingLink != null &&
        ((verified ?? false) || level == LevelState.VERIFIED) &&
        recorded?.lastEditBy?.toLowerCase() == coachingLink.coach;
    final subject = state.isForRider ? rider?.name : horse?.name;
    final canWrite = context.read<AppCubit>().canWriteProfileRecords();
    final difficulty = skill.difficulty == DifficultyState.All
        ? 'All levels'
        : skill.difficulty.name;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Text(
            '${skill.category.name.replaceAll('_', ' ')} · $difficulty',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTokens.accentColor(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            skill.skillName,
            style: AppTokens.sectionTitleStyle(context).copyWith(fontSize: 24),
          ),
          Text(
            subject == null ? 'Progress' : 'Progress · $subject',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          SkillProgressBadge(level: level, verified: verified ?? false),
          if (coachingLink != null && subject != null)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (canRemove)
                  OutlinedButton.icon(
                    onPressed: (connectionState?.actionInProgress ?? false)
                        ? null
                        : () => _verify(
                            context,
                            coachingLink,
                            skill,
                            null,
                            subject,
                          ),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Remove verification'),
                  ),
                for (final (label, target) in [
                  ('Verify as learning', LevelState.LEARNING),
                  ('Verify as proficient', LevelState.PROFICIENT),
                ])
                  FilledButton.tonalIcon(
                    onPressed: (connectionState?.actionInProgress ?? false)
                        ? null
                        : () => _verify(
                            context,
                            coachingLink,
                            skill,
                            target,
                            subject,
                          ),
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(label),
                  ),
              ],
            ),
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
                        : () => showAppGlassDialog<void>(
                            context: context,
                            builder: (_) => SkillLevelSelectedConfimationDialog(
                              key: const Key('levelSelectedConfirmationDialog'),
                              levelState: target,
                            ),
                          ),
                    child: Text(label),
                  ),
              ],
            ),
          const Divider(),
          Text(
            'Resources',
            style: AppTokens.sectionTitleStyle(context).copyWith(fontSize: 20),
          ),
          SkillResouresList(
            key: const Key('skillResourcesList'),
            skillId: skill.id,
          ),
        ],
      ),
    );
  }
}
