import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/skill_tree_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class SkillDetailV2Panel extends StatelessWidget {
  const SkillDetailV2Panel({
    super.key,
    required this.state,
    required this.skill,
    required this.allResources,
    required this.canSelfAssess,
    required this.selfAssessDisabledReason,
    required this.canVerify,
    required this.onSelectLevel,
    required this.onSelfAssess,
    required this.onVerifyLevel,
    required this.onSelectRelatedSkill,
    required this.onChangeResourceSort,
    this.onSuggestForSkill,
    this.onLogPractice,
    this.isAdminEditMode = false,
    this.onEditSkill,
    this.canEditResource,
    this.onEditResource,
    this.onLinkResourceSkills,
    this.onBack,
  });

  final SkillTreeV2State state;
  final CurriculumSkill skill;
  final List<Resource> allResources;
  final bool canSelfAssess;
  final String? selfAssessDisabledReason;
  final bool canVerify;
  final ValueChanged<DifficultyState> onSelectLevel;
  final void Function(DifficultyState level, LevelState? nextState)
  onSelfAssess;
  final void Function(DifficultyState level, {required bool verified})
  onVerifyLevel;
  final ValueChanged<String> onSelectRelatedSkill;
  final ValueChanged<SkillTreeV2ResourceSort> onChangeResourceSort;
  final VoidCallback? onSuggestForSkill;
  final VoidCallback? onLogPractice;
  final bool isAdminEditMode;
  final VoidCallback? onEditSkill;
  final bool Function(Resource resource)? canEditResource;
  final ValueChanged<Resource>? onEditResource;
  final ValueChanged<Resource>? onLinkResourceSkills;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLevel = state.effectiveSelectedLevel;
    final levelDef = selectedLevel == null
        ? null
        : skill.levelDefinition(selectedLevel);
    final progress = state.progressBySkillId[skill.id];
    final verification = state.verificationsBySkillId[skill.id];
    final family = state.families
        .where((f) => f.id == skill.familyId)
        .firstOrNull;
    final skillEvents = state.verificationEvents
        .where((e) => e.skillId == skill.id)
        .toList();
    final isRetired = skill.status == CurriculumSkillStatus.retired;
    final replacementSkill = skill.replacedBy == null
        ? null
        : state.skills.where((s) => s.id == skill.replacedBy).firstOrNull;

    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return AppSurfaceCard(
      key: Key('skillDetailV2_${skill.id}'),
      padding: EdgeInsets.all(
        isCompact ? AppTokens.spaceMd : AppTokens.spaceLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceMd,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('skillDetailV2BackButton'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to skills'),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceXs,
            children: [
              Text(
                '${subjectDisplayLabel(skill.subject)} · '
                '${realmDisplayLabel(skill.realm)}'
                '${family == null ? '' : ' · ${family.name}'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      style: AppTokens.sectionTitleStyle(
                        context,
                      ).copyWith(fontSize: 22),
                    ),
                  ),
                  if (isAdminEditMode && onEditSkill != null)
                    OutlinedButton.icon(
                      key: Key('editSkillButton_${skill.id}'),
                      onPressed: onEditSkill,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Skill'),
                    ),
                ],
              ),
              ValueListenableBuilder<bool>(
                valueListenable: SkillTreeSpotlightTour.isTourActive,
                builder: (context, tourActive, child) => KeyedSubtree(
                  key:
                      tourActive &&
                          skill.id == SkillTreeSpotlightTour.activeSkillId
                      ? SkillTreeSpotlightTour.descriptionKey
                      : null,
                  child: child!,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppTokens.spaceXs,
                  children: [
                    if (skill.summary.trim().isNotEmpty)
                      ContextualDictionaryText(text: skill.summary),
                    if (skill.purpose.trim().isNotEmpty)
                      ContextualDictionaryText(
                        text: 'Purpose: ${skill.purpose}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTokens.secondaryTextColor(context),
                        ),
                      ),
                    ..._buildAliasesSection(context, skill),
                  ],
                ),
              ),
            ],
          ),
          if (isRetired)
            Container(
              key: const Key('retiredSkillBanner'),
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppTokens.spaceXs,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 18,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: AppTokens.spaceSm),
                      Expanded(
                        child: Text(
                          'This skill has been retired. Historical '
                          'progress and instructor verifications remain '
                          'preserved.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (replacementSkill != null)
                    OutlinedButton.icon(
                      key: const Key('retiredSkillReplacementButton'),
                      onPressed: () =>
                          onSelectRelatedSkill(replacementSkill.id),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text('View replacement: ${replacementSkill.name}'),
                    ),
                ],
              ),
            ),
          if (skill.safety.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppTokens.spaceSm),
                  Expanded(
                    child: ContextualDictionaryText(
                      text: skill.safety.join(' • '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          if (skill.availableLevels.isNotEmpty) ...[
            ValueListenableBuilder<bool>(
              valueListenable: SkillTreeSpotlightTour.isTourActive,
              builder: (context, skillTourActive, child) =>
                  ValueListenableBuilder<int?>(
                    valueListenable: GuestSpotlightTour.activeStep,
                    builder: (context, tourStep, innerChild) => KeyedSubtree(
                      key:
                          skillTourActive &&
                              skill.id == SkillTreeSpotlightTour.activeSkillId
                          ? SkillTreeSpotlightTour.difficultyKey
                          : (tourStep == 3 &&
                                    skill.id ==
                                        GuestSpotlightTour
                                            .activeDifficultySkillId
                                ? GuestSpotlightTour.skillTreeDifficultyKey
                                : null),
                      child: innerChild!,
                    ),
                    child: child,
                  ),
              child: Wrap(
                spacing: AppTokens.spaceXs,
                runSpacing: AppTokens.spaceXs,
                children: [
                  for (final level in skill.availableLevels)
                    _buildLevelChoiceChip(
                      context: context,
                      skill: skill,
                      level: level,
                      selected: selectedLevel == level,
                      selfState: progress?.levels[level]?.state,
                      isVerified:
                          verification?.levels.containsKey(level) ?? false,
                    ),
                ],
              ),
            ),
          ],
          if (selectedLevel != null && levelDef != null) ...[
            _LevelDetailSection(
              skill: skill,
              level: selectedLevel,
              definition: levelDef,
              selfState: progress?.levels[selectedLevel]?.state,
              verification: verification?.levels[selectedLevel],
              canSelfAssess: canSelfAssess,
              selfAssessDisabledReason: selfAssessDisabledReason,
              canVerify: canVerify,
              isSubmitting: state.isSubmitting,
              onSelfAssess: (nextState) =>
                  onSelfAssess(selectedLevel, nextState),
              onVerifyLevel: ({required verified}) =>
                  onVerifyLevel(selectedLevel, verified: verified),
            ),
          ],
          if (skill.relatedSkills.isNotEmpty) ...[
            Text(
              'Related skills',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              spacing: AppTokens.spaceXs,
              runSpacing: AppTokens.spaceXs,
              children: [
                for (final related in skill.relatedSkills)
                  ActionChip(
                    label: Text(_skillNameFor(state.skills, related.skillId)),
                    onPressed: () => onSelectRelatedSkill(related.skillId),
                  ),
              ],
            ),
          ],
          if (skillEvents.isNotEmpty) ...[
            Text(
              'Verification audit history',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final event in skillEvents.take(5))
              Text(
                [
                  if (event.type == VerificationEventType.verified)
                    'Verified'
                  else
                    'Revoked',
                  '(${difficultyDisplayLabel(event.level)}) by',
                  event.actorName,
                  if (event.reason != null && event.reason!.isNotEmpty)
                    '— ${event.reason}',
                ].join(' '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
          ],
          _SkillV2ResourcesSection(
            skill: skill,
            fallbackResources: allResources,
            sort: state.resourceSort,
            onChangeResourceSort: onChangeResourceSort,
            canEditResource: canEditResource,
            onEditResource: onEditResource,
            onLinkResourceSkills: onLinkResourceSkills,
          ),
          if (onLogPractice != null || onSuggestForSkill != null)
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceXs,
              children: [
                if (onLogPractice != null && !isRetired)
                  OutlinedButton.icon(
                    key: const Key('skillDetailV2LogPracticeButton'),
                    onPressed: onLogPractice,
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: const Text('Log Practice'),
                  ),
                if (onSuggestForSkill != null)
                  ValueListenableBuilder<bool>(
                    valueListenable: SkillTreeSpotlightTour.isTourActive,
                    builder: (context, tourActive, child) => KeyedSubtree(
                      key:
                          tourActive &&
                              skill.id == SkillTreeSpotlightTour.activeSkillId
                          ? SkillTreeSpotlightTour.suggestKey
                          : null,
                      child: child!,
                    ),
                    child: OutlinedButton.icon(
                      key: const Key('skillDetailV2SuggestButton'),
                      onPressed: onSuggestForSkill,
                      icon: const Icon(Icons.lightbulb_outline, size: 18),
                      label: const Text('Suggest Improvement for This Skill'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _skillNameFor(List<CurriculumSkill> skills, String id) {
    for (final s in skills) {
      if (s.id == id) return s.name;
    }
    return id;
  }

  Widget _buildLevelChoiceChip({
    required BuildContext context,
    required CurriculumSkill skill,
    required DifficultyState level,
    required bool selected,
    required LevelState? selfState,
    required bool isVerified,
  }) {
    final baseLabel = difficultyDisplayLabel(level);
    final (Icon? avatar, String label) = isVerified
        ? (
            Icon(
              Icons.verified,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            '$baseLabel · Verified',
          )
        : switch (selfState) {
            LevelState.PROFICIENT => (
              const Icon(Icons.check_circle_outline, size: 16),
              '$baseLabel · Proficient',
            ),
            LevelState.LEARNING => (
              const Icon(Icons.school_outlined, size: 16),
              '$baseLabel · Learning',
            ),
            _ => (null, baseLabel),
          };

    return ChoiceChip(
      key: Key('levelTab_${skill.id}_${level.name}'),
      avatar: avatar,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelectLevel(level),
    );
  }

  List<Widget> _buildAliasesSection(
    BuildContext context,
    CurriculumSkill skill,
  ) {
    final primaryLower = skill.name.trim().toLowerCase();
    final seen = <String>{};
    final visibleAliases = <String>[];
    for (final raw in skill.aliases) {
      final trimmed = raw.trim();
      final lower = trimmed.toLowerCase();
      if (trimmed.isEmpty || lower == primaryLower || !seen.add(lower)) {
        continue;
      }
      visibleAliases.add(trimmed);
    }
    if (visibleAliases.isEmpty) return const [];

    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppTokens.secondaryTextColor(context),
    );
    return [
      Text.rich(
        key: const Key('skillDetailAliasesText'),
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(
              text: 'Also known as: ',
              style: baseStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: visibleAliases.join(' · ')),
          ],
        ),
      ),
    ];
  }
}

class _SkillV2ResourcesSection extends StatefulWidget {
  const _SkillV2ResourcesSection({
    required this.skill,
    required this.fallbackResources,
    required this.sort,
    required this.onChangeResourceSort,
    this.canEditResource,
    this.onEditResource,
    this.onLinkResourceSkills,
  });

  final CurriculumSkill skill;
  final List<Resource> fallbackResources;
  final SkillTreeV2ResourceSort sort;
  final ValueChanged<SkillTreeV2ResourceSort> onChangeResourceSort;
  final bool Function(Resource resource)? canEditResource;
  final ValueChanged<Resource>? onEditResource;
  final ValueChanged<Resource>? onLinkResourceSkills;

  @override
  State<_SkillV2ResourcesSection> createState() =>
      _SkillV2ResourcesSectionState();
}

class _SkillV2ResourcesSectionState extends State<_SkillV2ResourcesSection> {
  final Map<String, List<Resource>> _resourcesByLookupId = {};
  final List<StreamSubscription<List<Resource>>> _subscriptions = [];
  Set<String> _subscribedIds = const {};
  bool _isLoading = false;

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void _ensureSubscriptions({
    required bool hasCatalogue,
    required Set<String> lookupIds,
    required ResourcesStore? store,
  }) {
    if (hasCatalogue || store == null) {
      if (_subscriptions.isNotEmpty) {
        _cancelSubscriptions();
        _subscribedIds = const {};
      }
      return;
    }
    if (_subscribedIds.length == lookupIds.length &&
        _subscribedIds.containsAll(lookupIds)) {
      return;
    }
    _cancelSubscriptions();
    _resourcesByLookupId.clear();
    _subscribedIds = lookupIds;
    _isLoading = lookupIds.isNotEmpty;

    for (final id in lookupIds) {
      final sub = store
          .getResourcesForSkill(skillId: id)
          .listen(
            (items) {
              if (!mounted) return;
              setState(() {
                _resourcesByLookupId[id] = items;
                _isLoading = false;
              });
            },
            onError: (_) {
              if (!mounted) return;
              setState(() {
                _resourcesByLookupId.putIfAbsent(id, () => const []);
                _isLoading = false;
              });
            },
          );
      _subscriptions.add(sub);
    }
  }

  List<Resource> _deduplicatedStreamedResources() {
    final byKey = <String, Resource>{};
    for (final list in _resourcesByLookupId.values) {
      for (final resource in list) {
        final key =
            resource.id ??
            '${resource.url ?? ''}|${resource.name ?? ''}|${resource.hashCode}';
        byKey[key] = resource;
      }
    }
    return byKey.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppCubit>().state;
    final store =
        context.read<ResourcesStore?>() ?? context.read<ResourcesRepository?>();
    final lookupIds = effectiveResourceLookupIds(
      skill: widget.skill,
      legacySkills: appState.allSkills,
    );

    _ensureSubscriptions(
      hasCatalogue: appState.hasResourceCatalogue,
      lookupIds: lookupIds,
      store: store,
    );

    final candidateResources = appState.hasResourceCatalogue
        ? (appState.resources.isNotEmpty
              ? appState.resources
              : widget.fallbackResources)
        : (store != null
              ? _deduplicatedStreamedResources()
              : widget.fallbackResources);

    final relatedResources = filterAndRankResourcesForSkill(
      skill: widget.skill,
      allResources: candidateResources,
      legacySkills: appState.allSkills,
      sort: widget.sort,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceSm,
      children: [
        Wrap(
          spacing: AppTokens.spaceSm,
          runSpacing: AppTokens.spaceXs,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Related Resources (${relatedResources.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SegmentedButton<SkillTreeV2ResourceSort>(
              segments: const [
                ButtonSegment(
                  value: SkillTreeV2ResourceSort.helpfulness,
                  label: Text('Helpful'),
                ),
                ButtonSegment(
                  value: SkillTreeV2ResourceSort.newest,
                  label: Text('Newest'),
                ),
              ],
              selected: {widget.sort},
              onSelectionChanged: (sel) =>
                  widget.onChangeResourceSort(sel.first),
            ),
          ],
        ),
        if (_isLoading && relatedResources.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (relatedResources.isEmpty)
          Text(
            'No resources linked to this skill yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          )
        else
          Column(
            spacing: AppTokens.spaceSm,
            children: [
              for (final resource in relatedResources)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppTokens.spaceXs,
                  children: [
                    ResourcesItem(
                      resource: resource,
                      isResourceList: true,
                      fromSkillTree: true,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _LevelDetailSection extends StatelessWidget {
  const _LevelDetailSection({
    required this.skill,
    required this.level,
    required this.definition,
    required this.selfState,
    required this.verification,
    required this.canSelfAssess,
    required this.selfAssessDisabledReason,
    required this.canVerify,
    required this.isSubmitting,
    required this.onSelfAssess,
    required this.onVerifyLevel,
  });

  final CurriculumSkill skill;
  final DifficultyState level;
  final SkillLevelDefinition definition;
  final LevelState? selfState;
  final LevelVerification? verification;
  final bool canSelfAssess;
  final String? selfAssessDisabledReason;
  final bool canVerify;
  final bool isSubmitting;
  final ValueChanged<LevelState?> onSelfAssess;
  final void Function({required bool verified}) onVerifyLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = verification != null;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTokens.radiusMd);

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: isDark
          ? AppTokens.selectedSurfaceDecoration(radius)
          : BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: radius,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceSm,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${difficultyDisplayLabel(level)} Level',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isVerified)
                Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text(
                    'Verified by '
                    '${verification?.verifiedByName ?? 'Instructor'}',
                  ),
                ),
            ],
          ),
          if (isVerified &&
              verification!.standardVersion < definition.standardVersion)
            Text(
              'Verified under Standard v${verification!.standardVersion} '
              '(current: v${definition.standardVersion}).',
              key: const Key('verificationEarlierStandardNote'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
          ValueListenableBuilder<bool>(
            valueListenable: SkillTreeSpotlightTour.isTourActive,
            builder: (context, tourActive, child) => KeyedSubtree(
              key:
                  tourActive && skill.id == SkillTreeSpotlightTour.activeSkillId
                  ? SkillTreeSpotlightTour.criteriaKey
                  : null,
              child: child!,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceSm,
              children: [
                if (definition.overview.trim().isNotEmpty)
                  ContextualDictionaryText(text: definition.overview),
                _CriteriaBlock(
                  title: 'Learning criteria',
                  body: definition.learning,
                ),
                _CriteriaBlock(
                  title: 'Proficient criteria',
                  body: definition.proficient,
                ),
              ],
            ),
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: SkillTreeSpotlightTour.isTourActive,
            builder: (context, tourActive, child) => KeyedSubtree(
              key:
                  tourActive && skill.id == SkillTreeSpotlightTour.activeSkillId
                  ? SkillTreeSpotlightTour.selfAssessKey
                  : null,
              child: child!,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceSm,
              children: [
                Text(
                  'Self-assessment',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Wrap(
                  spacing: AppTokens.spaceXs,
                  runSpacing: AppTokens.spaceXs,
                  children: [
                    ChoiceChip(
                      key: Key('assessLearning_${skill.id}_${level.name}'),
                      label: const Text('Learning'),
                      selected: selfState == LevelState.LEARNING,
                      onSelected: canSelfAssess && !isSubmitting
                          ? (_) => onSelfAssess(LevelState.LEARNING)
                          : null,
                    ),
                    ChoiceChip(
                      key: Key('assessProficient_${skill.id}_${level.name}'),
                      label: const Text('Proficient'),
                      selected: selfState == LevelState.PROFICIENT,
                      onSelected: canSelfAssess && !isSubmitting
                          ? (_) => onSelfAssess(LevelState.PROFICIENT)
                          : null,
                    ),
                    if (selfState != null)
                      ActionChip(
                        key: Key('assessClear_${skill.id}_${level.name}'),
                        label: const Text('Clear'),
                        onPressed: canSelfAssess && !isSubmitting
                            ? () => onSelfAssess(null)
                            : null,
                      ),
                  ],
                ),
                if (!canSelfAssess && selfAssessDisabledReason != null)
                  Text(
                    selfAssessDisabledReason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTokens.secondaryTextColor(context),
                    ),
                  ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: SkillTreeSpotlightTour.isTourActive,
            builder: (context, tourActive, child) => KeyedSubtree(
              key:
                  tourActive && skill.id == SkillTreeSpotlightTour.activeSkillId
                  ? SkillTreeSpotlightTour.verificationKey
                  : null,
              child: child!,
            ),
            child: canVerify
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppTokens.spaceSm,
                    children: [
                      const Divider(),
                      Text(
                        'Instructor verification',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Wrap(
                        spacing: AppTokens.spaceXs,
                        runSpacing: AppTokens.spaceXs,
                        children: [
                          if (!isVerified)
                            FilledButton.tonalIcon(
                              key: Key('verifyLevel_${skill.id}_${level.name}'),
                              onPressed: isSubmitting
                                  ? null
                                  : () => onVerifyLevel(verified: true),
                              icon: const Icon(Icons.verified_outlined),
                              label: const Text('Verify Proficient'),
                            ),
                          if (isVerified)
                            OutlinedButton.icon(
                              key: Key('revokeLevel_${skill.id}_${level.name}'),
                              onPressed: isSubmitting
                                  ? null
                                  : () => onVerifyLevel(verified: false),
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Revoke verification'),
                            ),
                        ],
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      isVerified
                          ? 'Instructor verified by '
                                '${verification?.verifiedByName ?? 'Coach'}.'
                          : 'Instructor verification is recorded by a '
                                'connected instructor.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                  ),
          ),
          if (definition.components.isNotEmpty)
            ValueListenableBuilder<bool>(
              valueListenable: SkillTreeSpotlightTour.isTourActive,
              builder: (context, tourActive, child) => KeyedSubtree(
                key:
                    tourActive &&
                        skill.id == SkillTreeSpotlightTour.activeSkillId
                    ? SkillTreeSpotlightTour.guidanceKey
                    : null,
                child: child!,
              ),
              child: _EducationalComponentsSection(
                key: ValueKey(
                  'educationalComponents_${skill.id}_${level.name}',
                ),
                definition: definition,
              ),
            ),
        ],
      ),
    );
  }
}

class _EducationalComponentsSection extends StatefulWidget {
  const _EducationalComponentsSection({required this.definition, super.key});

  final SkillLevelDefinition definition;

  @override
  State<_EducationalComponentsSection> createState() =>
      _EducationalComponentsSectionState();
}

class _EducationalComponentsSectionState
    extends State<_EducationalComponentsSection> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    SkillTreeSpotlightTour.expandGuidanceRevision.addListener(_onTourExpand);
  }

  @override
  void dispose() {
    SkillTreeSpotlightTour.expandGuidanceRevision.removeListener(_onTourExpand);
    super.dispose();
  }

  void _onTourExpand() {
    if (!mounted || _expanded) return;
    setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expandDuration = AppTokens.motionDuration(context);
    final expandedContent = _expanded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final component in widget.definition.components)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '• ${component.title}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (component.description.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: ContextualDictionaryText(
                            text: component.description,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          )
        : const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Semantics(
          button: true,
          expanded: _expanded,
          label: 'Educational components',
          child: InkWell(
            key: const Key('educationalComponentsToggle'),
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            hoverColor: AppTokens.hoverOverlay(context),
            highlightColor: AppTokens.pressOverlay(context),
            focusColor: AppTokens.focusOverlay(context),
            splashColor: AppTokens.pressOverlay(context),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Educational components '
                      '(guidance only, not separate checkoffs)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceXs),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: expandDuration,
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more,
                      color: AppTokens.secondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expandDuration == Duration.zero)
          expandedContent
        else
          ClipRect(
            child: AnimatedSize(
              duration: expandDuration,
              reverseDuration: AppTokens.motionDuration(
                context,
                const Duration(milliseconds: 150),
              ),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expandedContent,
            ),
          ),
      ],
    );
  }
}

class _CriteriaBlock extends StatelessWidget {
  const _CriteriaBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        ContextualDictionaryText(text: body, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
