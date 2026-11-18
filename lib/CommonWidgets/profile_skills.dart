import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_progress_badge.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_sync.dart';
import 'package:horseandriderscompanion/Settings/feature_flags.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Displays recorded Skill Tree 2.0 progress and instructor verifications on
/// Rider and Horse profiles, falling back to historical legacy `skillLevels`
/// only when V2 has no recorded entries for the profile.
class ProfileSkills extends StatefulWidget {
  const ProfileSkills({
    super.key,
    required this.skillLevels,
    this.subject,
    this.profileDocId,
    this.repository,
  });

  final List<SkillLevel>? skillLevels;
  final SkillSubject? subject;
  final String? profileDocId;
  final SkillTreeV2Repository? repository;

  @override
  State<ProfileSkills> createState() => _ProfileSkillsState();
}

class _ProfileSkillsState extends State<ProfileSkills> {
  bool _loading = false;
  bool _hasError = false;
  bool _hasV2Source = false;
  List<_V2ProfileSkillEntry> _v2Entries = const [];
  int _requestId = 0;

  bool get _canQueryV2 =>
      widget.subject != null &&
      (widget.profileDocId?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    SkillTreeV2Sync.progressRevision.addListener(_handleProgressRevision);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasV2Source && _canQueryV2) {
      unawaited(_loadV2Skills());
    }
  }

  @override
  void didUpdateWidget(covariant ProfileSkills oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject != widget.subject ||
        oldWidget.profileDocId != widget.profileDocId ||
        oldWidget.repository != widget.repository) {
      unawaited(_loadV2Skills());
    }
  }

  @override
  void dispose() {
    SkillTreeV2Sync.progressRevision.removeListener(_handleProgressRevision);
    super.dispose();
  }

  void _handleProgressRevision() {
    if (!mounted || !_canQueryV2) return;
    unawaited(_loadV2Skills());
  }

  SkillTreeV2Repository? _resolveRepository() {
    if (widget.repository != null) return widget.repository;
    try {
      final provided = context.read<SkillTreeV2Repository?>();
      if (provided != null) return provided;
    } catch (_) {
      // RepositoryProvider is optional in isolated widget tests.
    }
    if (Firebase.apps.isNotEmpty) {
      return SkillTreeV2Repository(
        store: HybridCurriculumSkillTreeV2Store(
          primaryStore: FirestoreSkillTreeV2Store(),
        ),
      );
    }
    return null;
  }

  Future<void> _loadV2Skills() async {
    final subject = widget.subject;
    final profileDocId = widget.profileDocId?.trim();
    if (subject == null || profileDocId == null || profileDocId.isEmpty) {
      if (mounted) {
        setState(() {
          _hasV2Source = false;
          _loading = false;
          _hasError = false;
          _v2Entries = const [];
        });
      }
      return;
    }

    final repo = _resolveRepository();
    if (repo == null) {
      if (mounted) {
        setState(() {
          _hasV2Source = false;
          _loading = false;
          _hasError = false;
          _v2Entries = const [];
        });
      }
      return;
    }

    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _hasV2Source = true;
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final results = await Future.wait<Object>([
        repo.fetchSkills(),
        repo.fetchProgress(subject: subject, profileDocId: profileDocId),
        repo.fetchVerifications(subject: subject, profileDocId: profileDocId),
      ]);
      if (!mounted || requestId != _requestId) return;

      final allSkills = results[0] as List<CurriculumSkill>;
      final progressBySkill = results[1] as Map<String, SkillProgressRecord>;
      final verificationsBySkill =
          results[2] as Map<String, SkillVerificationRecord>;

      final subjectSkills =
          allSkills.where((s) => s.subject == subject).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final entries = <_V2ProfileSkillEntry>[];
      for (final skill in subjectSkills) {
        final progress = progressBySkill[skill.id];
        final verification = verificationsBySkill[skill.id];
        if (progress == null && verification == null) continue;

        final orderedLevels = skill.availableLevels.isNotEmpty
            ? skill.availableLevels
            : const [
                DifficultyState.Introductory,
                DifficultyState.Intermediate,
                DifficultyState.Advanced,
              ];
        for (final level in orderedLevels) {
          final selfState = progress?.levels[level]?.state;
          final levelVerif = verification?.levels[level];
          final hasSelf =
              selfState == LevelState.LEARNING ||
              selfState == LevelState.PROFICIENT;
          final isVerified = levelVerif != null;
          if (!hasSelf && !isVerified) continue;

          final effectiveState = isVerified
              ? LevelState.PROFICIENT
              : selfState!;
          entries.add(
            _V2ProfileSkillEntry(
              skill: skill,
              level: level,
              levelState: effectiveState,
              verified: isVerified,
              verifiedByName: levelVerif?.verifiedByName,
            ),
          );
        }
      }

      setState(() {
        _v2Entries = entries;
        _loading = false;
        _hasError = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      final message = error.toString().toLowerCase();
      final isPermissionDenied = message.contains('permission-denied');
      setState(() {
        _v2Entries = const [];
        _loading = false;
        _hasError = !isPermissionDenied;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = context.select((AppCubit c) => c.state.isGuest);

    if (_hasV2Source && _loading && _v2Entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTokens.spaceMd),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_hasV2Source && _hasError && _v2Entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Could not load Skill Tree progress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
            ),
            TextButton(
              key: const Key('profileSkillsRetryButton'),
              onPressed: _loadV2Skills,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_v2Entries.isNotEmpty) {
      final learningCount = _v2Entries
          .where((e) => !e.verified && e.levelState == LevelState.LEARNING)
          .length;
      final proficientCount = _v2Entries
          .where((e) => e.levelState == LevelState.PROFICIENT)
          .length;
      final verifiedCount = _v2Entries.where((e) => e.verified).length;

      return Column(
        key: const Key('profileSkillsV2List'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceSm,
        children: [
          Wrap(
            spacing: AppTokens.spaceXs,
            runSpacing: AppTokens.spaceXs,
            children: [
              if (learningCount > 0)
                AppStatusBadge(
                  label: '$learningCount Learning',
                  icon: Icons.school_outlined,
                  tone: AppStatusTone.coral,
                ),
              if (proficientCount > 0)
                AppStatusBadge(
                  label: '$proficientCount Proficient',
                  icon: Icons.check_circle_outline,
                  tone: AppStatusTone.success,
                ),
              if (verifiedCount > 0)
                AppStatusBadge(
                  label: '$verifiedCount Verified',
                  icon: Icons.verified,
                  tone: AppStatusTone.warning,
                ),
            ],
          ),
          for (final entry in _v2Entries)
            _ProfileV2SkillRow(
              entry: entry,
              onTap: isGuest
                  ? null
                  : () {
                      context.read<AppCubit>()
                        ..setSkillSubject(
                          isForRider: entry.skill.subject == SkillSubject.rider,
                        )
                        ..setSkillTree();
                      SkillTreeView.openSkill(
                        GoRouter.of(context),
                        entry.skill.id,
                        useV2:
                            SettingsControllerScope.maybeOf(
                              context,
                            )?.skillTreeV2Enabled ??
                            FeatureFlags.kSkillTreeV2Default,
                        level: entry.level,
                      );
                    },
            ),
        ],
      );
    }

    return _LegacyProfileSkillsFallback(
      skillLevels: widget.skillLevels,
      subject: widget.subject,
    );
  }
}

class _V2ProfileSkillEntry {
  const _V2ProfileSkillEntry({
    required this.skill,
    required this.level,
    required this.levelState,
    required this.verified,
    this.verifiedByName,
  });

  final CurriculumSkill skill;
  final DifficultyState level;
  final LevelState levelState;
  final bool verified;
  final String? verifiedByName;
}

class _ProfileV2SkillRow extends StatelessWidget {
  const _ProfileV2SkillRow({required this.entry, required this.onTap});

  final _V2ProfileSkillEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSm);
    final icon = switch (entry.skill.realm) {
      SkillCategory.Mounted => HorseAndRiderIcons.riding,
      SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
      SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
      SkillCategory.Other => Icons.menu_book_outlined,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightInputFill
            : colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppTokens.cardBorderDark.withValues(alpha: 0.65)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('profileSkillV2_${entry.skill.id}_${entry.level.name}'),
          borderRadius: radius,
          hoverColor: AppTokens.hoverOverlay(context),
          highlightColor: AppTokens.pressOverlay(context),
          focusColor: AppTokens.focusOverlay(context),
          splashColor: AppTokens.pressOverlay(context),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMd,
              vertical: AppTokens.spaceSm + 2,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTokens.coralAccent.withValues(alpha: 0.14)
                        : colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isDark
                          ? AppTokens.coralAccent
                          : colors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        entry.skill.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTokens.primaryTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            difficultyDisplayLabel(entry.level),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTokens.secondaryTextColor(context),
                            ),
                          ),
                          SkillProgressBadge(
                            level: entry.levelState,
                            verified: entry.verified,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppTokens.secondaryTextColor(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyProfileSkillsFallback extends StatelessWidget {
  const _LegacyProfileSkillsFallback({
    required this.skillLevels,
    required this.subject,
  });

  final List<SkillLevel>? skillLevels;
  final SkillSubject? subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emptyMessage = subject == SkillSubject.horse
        ? 'No skills recorded yet. Open Skill Tree to track this horse’s '
              'Learning and Proficient milestones.'
        : 'No skills recorded yet. Open Skill Tree to track Learning and '
              'Proficient milestones.';
    final empty = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        emptyMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTokens.secondaryTextColor(context),
          height: 1.4,
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
              _LegacyProfileSkillRow(
                level: level,
                skill: skills[level.skillId]!,
                onTap: state.isGuest
                    ? null
                    : () {
                        context.read<AppCubit>().setSkillTree();
                        final skill = skills[level.skillId];
                        SkillTreeView.openSkill(
                          GoRouter.of(context),
                          level.skillId,
                          useV2:
                              SettingsControllerScope.maybeOf(
                                context,
                              )?.skillTreeV2Enabled ??
                              FeatureFlags.kSkillTreeV2Default,
                          level:
                              skill == null ||
                                  skill.difficulty == DifficultyState.All
                              ? null
                              : skill.difficulty,
                        );
                      },
              ),
          ],
        );
      },
    );
  }
}

class _LegacyProfileSkillRow extends StatelessWidget {
  const _LegacyProfileSkillRow({
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
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSm);
    final icon = switch (skill.category) {
      SkillCategory.Mounted => HorseAndRiderIcons.riding,
      SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
      SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
      SkillCategory.Other => Icons.school_outlined,
    };
    final verified = level.verified || level.levelState == LevelState.VERIFIED;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightInputFill
            : colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppTokens.cardBorderDark.withValues(alpha: 0.65)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: radius),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          horizontalTitleGap: 12,
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTokens.coralAccent.withValues(alpha: 0.14)
                  : colors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 20,
                color: isDark
                    ? AppTokens.coralAccent
                    : colors.onSecondaryContainer,
              ),
            ),
          ),
          title: Text(
            level.skillName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTokens.primaryTextColor(context),
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
              : Icon(
                  Icons.chevron_right,
                  color: AppTokens.secondaryTextColor(context),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
