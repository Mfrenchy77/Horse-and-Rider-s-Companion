// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Parses a wire difficulty string (`'introductory'`, `'intermediate'`,
/// `'advanced'`) into a [DifficultyState], or returns `null`.
DifficultyState? parsePracticedDifficultyLevel(String? raw) =>
    switch (raw?.toLowerCase()) {
      'introductory' => DifficultyState.Introductory,
      'intermediate' => DifficultyState.Intermediate,
      'advanced' => DifficultyState.Advanced,
      _ => null,
    };

/// Opens a practiced Skill Tree 2.0 skill in [SkillTreeV2View] via [GoRouter]
/// when available, falling back to a direct route push in standalone contexts.
void openPracticedSkillInTree(
  BuildContext context,
  PracticedSkillTag tag, {
  bool popDialogFirst = false,
}) {
  final level = parsePracticedDifficultyLevel(tag.level);
  final router = GoRouter.maybeOf(context);
  if (popDialogFirst && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
  if (router != null) {
    SkillTreeView.openSkill(router, tag.skillId, level: level);
    return;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) =>
          SkillTreeV2View(initialSkillId: tag.skillId, initialLevel: level),
    ),
  );
}

/// Returns the most recent entry (optionally scoped to [horseId] or [horseName])
/// that has non-empty `nextSteps`.
({BaseListItem entry, String nextSteps})? findPreviousNextSteps(
  Iterable<BaseListItem> entries, {
  String? horseId,
  String? horseName,
  String? excludeEntryId,
  bool includeAuthorOnly = true,
}) {
  final normalizedHorseName = horseName?.trim().toLowerCase();
  final candidates = <BaseListItem>[];
  final seenIds = <String>{};

  for (final entry in entries) {
    final id = entry.id;
    if (id != null && excludeEntryId != null && id == excludeEntryId) continue;
    if (id != null && !seenIds.add(id)) continue;
    final info = entry.riderLog;
    if (info == null || entry.riderLogType == RiderLogType.activity) continue;
    if (!includeAuthorOnly && info.authorOnly) continue;
    if (horseId != null) {
      if (info.horseId != horseId) continue;
    } else if (normalizedHorseName != null && normalizedHorseName.isNotEmpty) {
      if (info.horse?.trim().toLowerCase() != normalizedHorseName) continue;
    }
    if (info.nextSteps?.trim().isNotEmpty ?? false) {
      candidates.add(entry);
    }
  }

  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    if (a.date == null) return b.date == null ? 0 : 1;
    if (b.date == null) return -1;
    return b.date!.compareTo(a.date!);
  });
  final latest = candidates.first;
  return (entry: latest, nextSteps: latest.riderLog!.nextSteps!.trim());
}

/// Returns up to [limit] deduplicated recent [PracticedSkillTag]s across
/// [entries] (sorted newest-first).
List<PracticedSkillTag> recentPracticedSkills(
  Iterable<BaseListItem> entries, {
  String? horseId,
  bool includeAuthorOnly = true,
  int limit = 4,
}) {
  final sorted = entries
      .where((entry) {
        final info = entry.riderLog;
        if (info == null || info.practicedSkills.isEmpty) return false;
        if (!includeAuthorOnly && info.authorOnly) return false;
        if (horseId != null && info.horseId != horseId) return false;
        return true;
      })
      .toList()
    ..sort((a, b) {
      if (a.date == null) return b.date == null ? 0 : 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });

  final seen = <String>{};
  final result = <PracticedSkillTag>[];
  for (final entry in sorted) {
    for (final tag in entry.riderLog!.practicedSkills) {
      if (seen.add(tag.skillId)) {
        result.add(tag);
        if (result.length >= limit) return result;
      }
    }
  }
  return result;
}

/// Stable `yyyy-MM` grouping key for timeline month headers.
String? monthGroupKey(DateTime? date) => date == null
    ? null
    : '${date.year}-${date.month.toString().padLeft(2, '0')}';

/// Subtle month divider header for chronological timelines.
class LogbookMonthHeader extends StatelessWidget {
  const LogbookMonthHeader({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6, left: 2),
      child: Text(
        DateFormat.yMMMM().format(date),
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppTokens.secondaryTextColor(context),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Compact pill displaying a [SessionFeel] without colliding with status badge
/// semantics.
class LogbookFeelPill extends StatelessWidget {
  const LogbookFeelPill({super.key, required this.feel});

  final SessionFeel feel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, fgColor) = switch (feel) {
      SessionFeel.breakthrough => (
        Icons.auto_awesome_outlined,
        isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      ),
      SessionFeel.steady => (
        Icons.trending_up_rounded,
        isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
      ),
      SessionFeel.working => (
        Icons.psychology_alt_outlined,
        AppTokens.accentColor(context),
      ),
      SessionFeel.recovery => (
        Icons.spa_outlined,
        AppTokens.secondaryTextColor(context),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fgColor.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 4),
          Text(
            feel.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds an optional compact footer row for [LogbookEntryCard] when an entry
/// has structured session metadata (feel, practiced skills, video, or private
/// reflection marker). Returns `null` when none are present.
Widget? buildLogbookEntryFooter(BuildContext context, BaseListItem entry) {
  final info = entry.riderLog;
  if (info == null) return null;
  final hasFeel = info.feel != null;
  final hasSkills = info.practicedSkills.isNotEmpty;
  final hasVideo = info.videoUrl != null;
  final isPrivate = info.authorOnly;
  if (!hasFeel && !hasSkills && !hasVideo && !isPrivate) return null;

  final secondary = AppTokens.secondaryTextColor(context);
  final labelStyle = Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(color: secondary);

  return Wrap(
    spacing: 6,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (isPrivate)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: secondary),
              const SizedBox(width: 4),
              Text('Private', style: labelStyle),
            ],
          ),
        ),
      if (hasFeel) LogbookFeelPill(feel: info.feel!),
      for (final skill in info.practicedSkills.take(2))
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTokens.accentColor(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            skill.levelLabel == null
                ? skill.skillName
                : '${skill.skillName} · ${skill.levelLabel}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTokens.primaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      if (info.practicedSkills.length > 2)
        Text('+${info.practicedSkills.length - 2} more', style: labelStyle),
      if (hasVideo)
        Icon(Icons.play_circle_outline_rounded, size: 15, color: secondary),
    ],
  );
}

///Builds a clean preview string for [LogbookEntryCard], falling back to
///structured takeaways (`highlights`, `focus`, or `nextSteps`) when `notes` is
///empty or matches [title].
String? buildLogbookCardPreview(BaseListItem entry, String title) {
  final notes = entry.name?.trim();
  if (notes != null && notes.isNotEmpty && notes != title) {
    return entry.name;
  }
  final info = entry.riderLog;
  if (info == null) return null;
  for (final (prefix, candidate) in [
    ('Went well: ', info.highlights),
    ('Work on: ', info.focus),
    ('Next: ', info.nextSteps),
  ]) {
    final text = candidate?.trim();
    if (text != null && text.isNotEmpty && text != title) {
      return '$prefix$text';
    }
  }
  return null;
}

/// Compact header summary card surfacing the latest next-session plan and
/// recently practiced Skill Tree 2.0 skills.
class LogbookUpNextCard extends StatelessWidget {
  const LogbookUpNextCard({
    super.key,
    this.nextStepsHit,
    this.recentSkills = const [],
  });

  final ({BaseListItem entry, String nextSteps})? nextStepsHit;
  final List<PracticedSkillTag> recentSkills;

  @override
  Widget build(BuildContext context) {
    if (nextStepsHit == null && recentSkills.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);
    final hit = nextStepsHit;
    final contextParts = <String>[
      if (hit?.entry.riderLog?.horse case final String h when h.isNotEmpty) h,
      if (hit?.entry.date case final DateTime d) DateFormat.MMMd().format(d),
    ];

    return AppSurfaceCard(
      key: const Key('logbookUpNextCard'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hit != null ? 'Next session plan' : 'Recently practiced',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.primaryTextColor(context),
                  ),
                ),
              ),
              if (contextParts.isNotEmpty)
                Text(
                  contextParts.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
            ],
          ),
          if (hit != null)
            Text(
              hit.nextSteps,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.primaryTextColor(context),
                height: 1.4,
              ),
            ),
          if (recentSkills.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in recentSkills)
                  ActionChip(
                    key: Key('upNextSkillChip_${skill.skillId}'),
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.account_tree_outlined, size: 15),
                    label: Text(
                      skill.levelLabel == null
                          ? skill.skillName
                          : '${skill.skillName} · ${skill.levelLabel}',
                    ),
                    onPressed: () => openPracticedSkillInTree(context, skill),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Shows the unified frosted-glass logbook entry detail dialog across Rider
/// Logbook, Horse Logbook, and Connection History.
///
/// Returns `'edit'` or `'delete'` when those actions are selected.
Future<String?> showLogbookEntryDetailDialog({
  required BuildContext context,
  required BaseListItem entry,
  required String categoryLabel,
  String? fallbackTitle,
  String? attribution,
  String? riderLabel,
  bool canEdit = false,
  bool canDelete = false,
}) {
  final info = entry.riderLog;
  final dateText = entry.date == null
      ? 'Date unavailable'
      : DateFormat.yMMMd().format(entry.date!);
  final heading = (info?.title?.trim().isNotEmpty ?? false)
      ? info!.title!.trim()
      : (fallbackTitle?.trim().isNotEmpty ?? false)
      ? fallbackTitle!.trim()
      : categoryLabel;
  final isShow =
      entry.riderLogType == RiderLogType.show || categoryLabel == 'Show';

  return showAppGlassDialog<String>(
    context: context,
    builder: (dialogContext) => AppGlassDialog(
      title: Text(heading, style: AppTokens.sectionTitleStyle(dialogContext)),
      maxWidth: 560,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label: categoryLabel,
                icon: Icons.bookmark_outline_rounded,
                tone: AppStatusTone.coral,
              ),
              Text(
                dateText,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(dialogContext),
                ),
              ),
              if (isShow && info?.placing != null)
                LogbookPlacingBadge(placing: info!.placing!),
              if (info?.feel != null) LogbookFeelPill(feel: info!.feel!),
              if (info?.authorOnly ?? false)
                const AppStatusBadge(
                  label: 'Private reflection',
                  icon: Icons.lock_outline_rounded,
                ),
            ],
          ),
          if (riderLabel != null || attribution != null) ...[
            const SizedBox(height: 8),
            Text(
              [?riderLabel, ?attribution].join(' · '),
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(dialogContext),
              ),
            ),
          ],
          if (info?.instructor != null)
            _DetailField(label: 'Instructor', value: info!.instructor!),
          if (isShow && info?.placing != null)
            _DetailField(label: 'Placing', value: info!.placing!),
          if (info?.horse != null)
            _DetailField(label: 'Horse', value: info!.horse!),
          if (info != null && info.practicedSkills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practiced skills',
                    style: Theme.of(dialogContext).textTheme.labelLarge
                        ?.copyWith(
                          color: AppTokens.secondaryTextColor(dialogContext),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in info.practicedSkills)
                        ActionChip(
                          key: Key('detailPracticedSkill_${tag.skillId}'),
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(
                            Icons.account_tree_outlined,
                            size: 15,
                          ),
                          label: Text(
                            tag.levelLabel == null
                                ? tag.skillName
                                : '${tag.skillName} · ${tag.levelLabel}',
                          ),
                          onPressed: () => openPracticedSkillInTree(
                            dialogContext,
                            tag,
                            popDialogFirst: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (info?.highlights != null)
            _DetailField(label: 'What went well', value: info!.highlights!),
          if (info?.focus != null)
            _DetailField(label: 'What needs work', value: info!.focus!),
          if (entry.name?.trim().isNotEmpty ?? false)
            _DetailField(label: 'Notes', value: entry.name!),
          if (info?.nextSteps != null)
            _DetailField(
              label: 'Plans for next session',
              value: info!.nextSteps!,
            ),
          if (info?.videoUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: OutlinedButton.icon(
                key: const Key('openTrainingVideoButton'),
                onPressed: () async {
                  final uri = Uri.tryParse(info!.videoUrl!);
                  if (uri == null) return;
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('Watch training video'),
              ),
            ),
        ],
      ),
      actions: [
        AppOutlinedButton(
          onPressed: () => Navigator.pop(dialogContext),
          label: 'Close',
        ),
        if (canEdit)
          AppPrimaryButton(
            onPressed: () => Navigator.pop(dialogContext, 'edit'),
            icon: Icons.edit_outlined,
            label: 'Edit entry',
          ),
        if (canDelete)
          AppDestructiveButton(
            outlined: true,
            onPressed: () => Navigator.pop(dialogContext, 'delete'),
            label: 'Delete entry',
          ),
      ],
    ),
  );
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTokens.secondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.primaryTextColor(context),
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

/// Opens a frosted-glass Skill Tree 2.0 picker allowing the user to tag one or
/// more practiced skills and optional difficulty levels.
Future<List<PracticedSkillTag>?> showPracticedSkillsPickerDialog({
  required BuildContext context,
  required List<PracticedSkillTag> initialSelection,
  SkillSubject? defaultSubject,
}) async {
  SkillTreeV2Repository? repo;
  try {
    repo = context.read<SkillTreeV2Repository?>();
  } catch (_) {
    repo = null;
  }

  Future<List<CurriculumSkill>> loadSkills() async {
    try {
      final fromRepo = await repo?.fetchSkills();
      if (fromRepo != null && fromRepo.isNotEmpty) {
        return fromRepo
            .where((s) => s.status == CurriculumSkillStatus.active)
            .toList();
      }
    } catch (_) {}
    final bundled = await const AssetCurriculumV2Loader().loadSkills();
    return bundled
        .where((s) => s.status == CurriculumSkillStatus.active)
        .toList();
  }

  final skillsFuture = loadSkills();

  if (!context.mounted) return null;
  return showAppGlassDialog<List<PracticedSkillTag>>(
    context: context,
    builder: (_) => _PracticedSkillsPickerDialog(
      skillsFuture: skillsFuture,
      initialSelection: initialSelection,
      defaultSubject: defaultSubject,
    ),
  );
}

class _PracticedSkillsPickerDialog extends StatefulWidget {
  const _PracticedSkillsPickerDialog({
    required this.skillsFuture,
    required this.initialSelection,
    this.defaultSubject,
  });

  final Future<List<CurriculumSkill>> skillsFuture;
  final List<PracticedSkillTag> initialSelection;
  final SkillSubject? defaultSubject;

  @override
  State<_PracticedSkillsPickerDialog> createState() =>
      _PracticedSkillsPickerDialogState();
}

class _PracticedSkillsPickerDialogState
    extends State<_PracticedSkillsPickerDialog> {
  late final Map<String, PracticedSkillTag> _selected = {
    for (final tag in widget.initialSelection) tag.skillId: tag,
  };
  late SkillSubject? _subjectFilter = widget.defaultSubject;
  String _query = '';

  void _toggleSkill(CurriculumSkill skill) {
    setState(() {
      if (_selected.containsKey(skill.id)) {
        _selected.remove(skill.id);
      } else {
        final firstLevel = skill.availableLevels.firstOrNull;
        _selected[skill.id] = PracticedSkillTag(
          skillId: skill.id,
          skillName: skill.name,
          subject: skill.subject.name,
          level: firstLevel?.name.toLowerCase(),
        );
      }
    });
  }

  void _setLevel(CurriculumSkill skill, String? level) {
    setState(() {
      _selected[skill.id] = PracticedSkillTag(
        skillId: skill.id,
        skillName: skill.name,
        subject: skill.subject.name,
        level: level,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    return AppGlassDialog(
      key: const Key('practicedSkillsPickerDialog'),
      title: Text(
        'Tag practiced skills',
        style: AppTokens.sectionTitleStyle(context),
      ),
      maxWidth: 600,
      content: SizedBox(
        width: 540,
        child: FutureBuilder<List<CurriculumSkill>>(
          future: widget.skillsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final allSkills = snapshot.data ?? const <CurriculumSkill>[];
            final filtered = allSkills.where((skill) {
              if (_subjectFilter != null && skill.subject != _subjectFilter) {
                return false;
              }
              if (q.isEmpty) return true;
              if (skill.name.toLowerCase().contains(q)) return true;
              return skill.aliases.any((a) => a.toLowerCase().contains(q));
            }).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                TextField(
                  key: const Key('practicedSkillsSearchField'),
                  decoration: const InputDecoration(
                    hintText: 'Search skills or aliases…',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _subjectFilter == null,
                      onSelected: (_) => setState(() => _subjectFilter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Rider'),
                      selected: _subjectFilter == SkillSubject.rider,
                      onSelected: (_) =>
                          setState(() => _subjectFilter = SkillSubject.rider),
                    ),
                    ChoiceChip(
                      label: const Text('Horse'),
                      selected: _subjectFilter == SkillSubject.horse,
                      onSelected: (_) =>
                          setState(() => _subjectFilter = SkillSubject.horse),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No matching skills found.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTokens.secondaryTextColor(context),
                                ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final skill = filtered[index];
                            final picked = _selected[skill.id];
                            final isSelected = picked != null;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CheckboxListTile(
                                    key: Key('pickerSkillTile_${skill.id}'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    value: isSelected,
                                    onChanged: (_) => _toggleSkill(skill),
                                    title: Text(skill.name),
                                    subtitle: Text(
                                      '${subjectDisplayLabel(skill.subject)} · '
                                      '${realmDisplayLabel(skill.realm)}',
                                    ),
                                  ),
                                  if (isSelected &&
                                      skill.availableLevels.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 40,
                                        bottom: 4,
                                      ),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          ChoiceChip(
                                            visualDensity:
                                                VisualDensity.compact,
                                            label: const Text('Any level'),
                                            selected: picked.level == null,
                                            onSelected: (_) =>
                                                _setLevel(skill, null),
                                          ),
                                          for (final lvl
                                              in skill.availableLevels)
                                            ChoiceChip(
                                              key: Key(
                                                'pickerSkillLevel_${skill.id}_${lvl.name.toLowerCase()}',
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              label: Text(
                                                difficultyDisplayLabel(lvl),
                                              ),
                                              selected:
                                                  picked.level ==
                                                  lvl.name.toLowerCase(),
                                              onSelected: (_) => _setLevel(
                                                skill,
                                                lvl.name.toLowerCase(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        AppOutlinedButton(
          onPressed: () => Navigator.pop(context),
          label: 'Cancel',
        ),
        AppPrimaryButton(
          key: const Key('practicedSkillsDoneButton'),
          onPressed: () => Navigator.pop(context, _selected.values.toList()),
          label: _selected.isEmpty
              ? 'Done'
              : 'Done (${_selected.length})',
        ),
      ],
    );
  }
}
