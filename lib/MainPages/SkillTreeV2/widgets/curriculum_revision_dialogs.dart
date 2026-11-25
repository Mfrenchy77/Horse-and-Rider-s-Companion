// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Production safety gate: curriculum publishing and rollback stay disabled
/// unless explicitly enabled at build time for local/staging validation.
const bool kEnableCurriculumPublishing = bool.fromEnvironment(
  'ENABLE_CURRICULUM_PUBLISHING',
);

String _formatRevisionDate(DateTime? dt) {
  if (dt == null) return 'Pending';
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

/// Frosted-glass publication preview and confirmation dialog for administrators.
class CurriculumPublishDialog extends StatefulWidget {
  const CurriculumPublishDialog({
    super.key,
    required this.publishedFamilies,
    required this.publishedSkills,
    required this.draftFamilies,
    required this.draftSkills,
    required this.onPublish,
    this.publishingEnabled = kEnableCurriculumPublishing,
  });

  final List<SkillFamily> publishedFamilies;
  final List<CurriculumSkill> publishedSkills;
  final List<SkillFamily> draftFamilies;
  final List<CurriculumSkill> draftSkills;
  final Future<CurriculumRevisionSummary> Function(String? notes) onPublish;
  final bool publishingEnabled;

  @override
  State<CurriculumPublishDialog> createState() =>
      _CurriculumPublishDialogState();
}

class _CurriculumPublishDialogState extends State<CurriculumPublishDialog> {
  final _notesController = TextEditingController();
  bool _isPublishing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });
    try {
      final revision = await widget.onPublish(_notesController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(revision);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = CurriculumDraftDiff.compute(
      publishedFamilies: widget.publishedFamilies,
      publishedSkills: widget.publishedSkills,
      draftFamilies: widget.draftFamilies,
      draftSkills: widget.draftSkills,
    );
    final hasBlockedDeletions = diff.removedSkills.isNotEmpty;
    final canSubmit =
        widget.publishingEnabled &&
        diff.hasChanges &&
        !hasBlockedDeletions &&
        !_isPublishing;

    return AppGlassDialog(
      title: const Text('Publish Curriculum Update'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceMd,
            children: [
              if (!widget.publishingEnabled)
                Container(
                  key: const Key('publishDisabledNotice'),
                  padding: const EdgeInsets.all(AppTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Text(
                    'Publishing is currently disabled in this environment. '
                    'You can still review changes and prepare release notes.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Text(
                'Publishing saves a permanent curriculum snapshot before '
                'updating live skills. Existing rider and horse progress and '
                'instructor verifications are always preserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              _CurriculumDiffSummaryCard(diff: diff),
              TextField(
                key: const Key('publishNotesField'),
                controller: _notesController,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Publication Notes (optional)',
                  hintText:
                      'Summarize what changed for administrators and trainers',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  key: const Key('publishErrorText'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPublishing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('confirmPublishCurriculumButton'),
          onPressed: canSubmit ? _handlePublish : null,
          icon: _isPublishing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.publish_outlined, size: 18),
          label: Text(_isPublishing ? 'Publishing...' : 'Publish Curriculum'),
        ),
      ],
    );
  }
}

/// Frosted-glass Revision History, Compare Revisions, and Restore dialog.
class CurriculumRevisionHistoryDialog extends StatefulWidget {
  const CurriculumRevisionHistoryDialog({
    super.key,
    required this.draftRepository,
    required this.currentFamilies,
    required this.currentSkills,
    this.publishingEnabled = kEnableCurriculumPublishing,
    this.onRestored,
  });

  final SkillTreeDraftRepository draftRepository;
  final List<SkillFamily> currentFamilies;
  final List<CurriculumSkill> currentSkills;
  final bool publishingEnabled;
  final ValueChanged<CurriculumRevisionSummary>? onRestored;

  @override
  State<CurriculumRevisionHistoryDialog> createState() =>
      _CurriculumRevisionHistoryDialogState();
}

class _CurriculumRevisionHistoryDialogState
    extends State<CurriculumRevisionHistoryDialog> {
  bool _isLoading = true;
  bool _isRestoring = false;
  String? _error;
  List<CurriculumRevisionSummary> _revisions = const [];
  String? _compareFromId;
  String? _compareToId;
  CurriculumDraftDiff? _compareDiff;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _loadRevisions();
  }

  Future<void> _loadRevisions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await widget.draftRepository.fetchRevisions();
      if (!mounted) return;
      setState(() {
        _revisions = list;
        if (list.isNotEmpty) {
          _compareFromId ??= list.last.id;
          _compareToId ??= 'current';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runComparison() async {
    final fromId = _compareFromId;
    final toId = _compareToId;
    if (fromId == null || toId == null || fromId == toId) return;

    setState(() {
      _isComparing = true;
      _error = null;
    });
    try {
      final fromSnap = fromId == 'current'
          ? null
          : await widget.draftRepository.fetchRevisionSnapshot(fromId);
      final toSnap = toId == 'current'
          ? null
          : await widget.draftRepository.fetchRevisionSnapshot(toId);
      if (!mounted) return;

      final fromFamilies = fromSnap?.families ?? widget.currentFamilies;
      final fromSkills = fromSnap?.skills ?? widget.currentSkills;
      final toFamilies = toSnap?.families ?? widget.currentFamilies;
      final toSkills = toSnap?.skills ?? widget.currentSkills;

      setState(() {
        _compareDiff = CurriculumDraftDiff.compute(
          publishedFamilies: fromFamilies,
          publishedSkills: fromSkills,
          draftFamilies: toFamilies,
          draftSkills: toSkills,
        );
        _isComparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isComparing = false;
      });
    }
  }

  Future<void> _confirmRestore(CurriculumRevisionSummary target) async {
    final snapshot = await widget.draftRepository.fetchRevisionSnapshot(
      target.id,
    );
    if (!mounted) return;
    if (snapshot == null) {
      setState(() => _error = 'Could not load snapshot for ${target.id}.');
      return;
    }

    final previewDiff = CurriculumDraftDiff.compute(
      publishedFamilies: widget.currentFamilies,
      publishedSkills: widget.currentSkills,
      draftFamilies: snapshot.families,
      draftSkills: snapshot.skills,
    );
    var notesInput = '';
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        title: Text('Restore Revision #${target.revisionNumber}?'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceMd,
              children: [
                Text(
                  'Restoring creates a new forward revision so history is '
                  'never erased. Existing rider and horse progress and '
                  'instructor verifications remain preserved.',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                _CurriculumDiffSummaryCard(diff: previewDiff),
                TextField(
                  key: const Key('restoreNotesField'),
                  onChanged: (value) => notesInput = value,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Restoration Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            key: const Key('confirmRestoreRevisionButton'),
            onPressed: previewDiff.removedSkills.isNotEmpty
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.restore_outlined, size: 18),
            label: const Text('Restore as New Revision'),
          ),
        ],
      ),
    );
    final notes = notesInput.trim();
    if (!(confirmed ?? false) || !mounted) return;

    setState(() {
      _isRestoring = true;
      _error = null;
    });
    try {
      final restored = await widget.draftRepository.rollbackToRevision(
        targetRevisionId: target.id,
        notes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return;
      widget.onRestored?.call(restored);
      await _loadRevisions();
      if (!mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restored as Revision #${restored.revisionNumber}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassDialog(
      title: const Text('Curriculum Revision History'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceMd,
            children: [
              if (!widget.publishingEnabled)
                Container(
                  key: const Key('revisionRestoreDisabledNotice'),
                  padding: const EdgeInsets.all(AppTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Text(
                    'Publishing and restoring revisions are currently disabled '
                    'in this environment. You can browse and compare history.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_revisions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No published curriculum revisions have been recorded yet.',
                  ),
                )
              else ...[
                _buildCompareSection(context),
                const Divider(),
                for (final rev in _revisions)
                  _buildRevisionCard(context, rev),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRestoring ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildCompareSection(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'current', child: Text('Current Live')),
      for (final rev in _revisions)
        DropdownMenuItem(
          value: rev.id,
          child: Text('Revision #${rev.revisionNumber}'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceSm,
      children: [
        Text(
          'Compare Revisions',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Wrap(
          spacing: AppTokens.spaceSm,
          runSpacing: AppTokens.spaceSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                key: const Key('compareFromDropdown'),
                isExpanded: true,
                initialValue: _compareFromId,
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: items,
                onChanged: (v) => setState(() => _compareFromId = v),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                key: const Key('compareToDropdown'),
                isExpanded: true,
                initialValue: _compareToId,
                decoration: const InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: items,
                onChanged: (v) => setState(() => _compareToId = v),
              ),
            ),
            FilledButton.tonalIcon(
              key: const Key('compareRevisionsButton'),
              onPressed: _isComparing ? null : _runComparison,
              icon: const Icon(Icons.compare_arrows_outlined, size: 18),
              label: const Text('Compare'),
            ),
          ],
        ),
        if (_compareDiff != null)
          _CurriculumDiffSummaryCard(diff: _compareDiff!),
      ],
    );
  }

  Widget _buildRevisionCard(
    BuildContext context,
    CurriculumRevisionSummary rev,
  ) {
    final theme = Theme.of(context);
    return AppSurfaceCard(
      key: Key('revisionCard_${rev.id}'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceXs,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Revision #${rev.revisionNumber}'
                  '${rev.isRollback ? ' · Restored' : ''}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatRevisionDate(rev.publishedAt ?? rev.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
            ],
          ),
          Text(
            'Published by ${rev.publishedByName} · '
            '${rev.familyCount} families · ${rev.skillCount} skills',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          if (rev.notes != null && rev.notes!.trim().isNotEmpty)
            Text(rev.notes!, style: theme.textTheme.bodyMedium),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (rev.addedSkillIds.isNotEmpty)
                Chip(label: Text('+${rev.addedSkillIds.length} skills')),
              if (rev.modifiedSkillIds.isNotEmpty)
                Chip(label: Text('${rev.modifiedSkillIds.length} updated')),
              if (rev.retiredSkillIds.isNotEmpty)
                Chip(label: Text('${rev.retiredSkillIds.length} retired')),
              if (rev.revisedStandards.isNotEmpty)
                Chip(
                  label: Text(
                    '${rev.revisedStandards.length} revised standards',
                  ),
                ),
            ],
          ),
          if (rev.isCompleted)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: Key('restoreRevisionButton_${rev.id}'),
                onPressed: widget.publishingEnabled && !_isRestoring
                    ? () => _confirmRestore(rev)
                    : null,
                icon: const Icon(Icons.restore_outlined, size: 16),
                label: const Text('Restore Previous Revision'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurriculumDiffSummaryCard extends StatelessWidget {
  const _CurriculumDiffSummaryCard({required this.diff});

  final CurriculumDraftDiff diff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!diff.hasChanges) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(AppTokens.spaceSm),
        child: Text(
          'No curriculum differences detected.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (diff.addedFamilies.isNotEmpty)
            Text(
              'Added Families (${diff.addedFamilies.length}): '
              '${diff.addedFamilies.map((f) => f.name).join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          if (diff.modifiedFamilies.isNotEmpty)
            Text(
              'Updated Families (${diff.modifiedFamilies.length}): '
              '${diff.modifiedFamilies.map((f) => f.family.name).join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          if (diff.addedSkills.isNotEmpty)
            Text(
              'Added Skills (${diff.addedSkills.length}): '
              '${diff.addedSkills.map((s) => s.name).join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          if (diff.modifiedSkills.isNotEmpty)
            for (final item in diff.modifiedSkills)
              Text(
                '• Updated ${item.skill.name}: '
                '${item.changedFields.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
          if (diff.retiredSkills.isNotEmpty)
            Text(
              'Retired Skills (${diff.retiredSkills.length}): '
              '${diff.retiredSkills.map((s) => s.name).join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          if (diff.removedSkills.isNotEmpty)
            Text(
              'Blocked: ${diff.removedSkills.length} published skill(s) '
              'cannot be removed (retire them instead).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
