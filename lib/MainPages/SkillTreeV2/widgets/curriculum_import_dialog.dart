// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

enum _ImportDiffBaseline { published, currentDraft }

/// Callback signature for picking a local JSON file containing a canonical
/// Skill Tree 2.0 export bundle.
typedef CurriculumImportFilePicker =
    Future<({String name, String content})?> Function();

/// Frosted-glass administrator dialog to upload or paste canonical Skill Tree
/// 2.0 JSON, validate schema and constraints, preview diffs against the
/// published curriculum and current draft, and apply the validated result to
/// the working draft without auto-publishing.
class CurriculumImportDialog extends StatefulWidget {
  const CurriculumImportDialog({
    super.key,
    required this.publishedFamilies,
    required this.publishedSkills,
    required this.currentDraftFamilies,
    required this.currentDraftSkills,
    this.onPickFile,
  });

  final List<SkillFamily> publishedFamilies;
  final List<CurriculumSkill> publishedSkills;
  final List<SkillFamily> currentDraftFamilies;
  final List<CurriculumSkill> currentDraftSkills;
  final CurriculumImportFilePicker? onPickFile;

  @override
  State<CurriculumImportDialog> createState() => _CurriculumImportDialogState();
}

class _CurriculumImportDialogState extends State<CurriculumImportDialog> {
  final TextEditingController _jsonController = TextEditingController();
  CurriculumImportResult? _validationResult;
  String? _selectedFileName;
  String? _fileReadError;
  bool _pickingFile = false;
  _ImportDiffBaseline _diffBaseline = _ImportDiffBaseline.published;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<({String name, String content})?> _defaultPickJsonFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return (name: picked.name, content: utf8.decode(bytes));
  }

  Future<void> _handlePickFile() async {
    setState(() {
      _pickingFile = true;
      _fileReadError = null;
    });
    try {
      final picker = widget.onPickFile ?? _defaultPickJsonFile;
      final selected = await picker();
      if (!mounted) return;
      if (selected == null) {
        setState(() => _pickingFile = false);
        return;
      }
      _jsonController.text = selected.content;
      setState(() {
        _pickingFile = false;
        _selectedFileName = selected.name;
      });
      _validateCurrentInput();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickingFile = false;
        _fileReadError = 'Could not read JSON file: $e';
      });
    }
  }

  void _validateCurrentInput() {
    final result = parseAndValidateCurriculumImportJson(
      _jsonController.text,
      publishedFamilies: widget.publishedFamilies,
      publishedSkills: widget.publishedSkills,
    );
    setState(() {
      _fileReadError = null;
      _validationResult = result;
    });
  }

  void _clearInput() {
    _jsonController.clear();
    setState(() {
      _selectedFileName = null;
      _fileReadError = null;
      _validationResult = null;
    });
  }

  void _applyImport() {
    final result = _validationResult;
    if (result == null || !result.isValid) return;
    Navigator.of(context).pop(
      SkillTreeCurriculumDraft(
        families: result.families!,
        skills: result.skills!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _validationResult;
    final canApply = !_pickingFile && (result?.isValid ?? false);

    return AppGlassDialog(
      key: const Key('curriculumImportDialog'),
      maxWidth: 640,
      title: const Text('Import Curriculum JSON'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 540),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceMd,
            children: [
              Text(
                'Upload or paste canonical Skill Tree JSON '
                '({"schemaVersion": 2, "families": [...], "skills": [...]}). '
                'Validation and change preview run before modifying your draft.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              Wrap(
                spacing: AppTokens.spaceSm,
                runSpacing: AppTokens.spaceXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('importCurriculumUploadFileButton'),
                    onPressed: _pickingFile ? null : _handlePickFile,
                    icon: _pickingFile
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Upload JSON File'),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('importCurriculumValidateButton'),
                    onPressed: _pickingFile ? null : _validateCurrentInput,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Validate & Preview Changes'),
                  ),
                  if (_jsonController.text.isNotEmpty ||
                      _validationResult != null)
                    TextButton(
                      key: const Key('importCurriculumClearButton'),
                      onPressed: _pickingFile ? null : _clearInput,
                      child: const Text('Clear'),
                    ),
                ],
              ),
              if (_selectedFileName != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    key: const Key('importSelectedFileChip'),
                    avatar: const Icon(Icons.description_outlined, size: 16),
                    label: Text(_selectedFileName!),
                  ),
                ),
              TextField(
                key: const Key('importCurriculumJsonField'),
                controller: _jsonController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Canonical Curriculum JSON',
                  hintText:
                      'Paste JSON from build/curriculum/skill_tree_v2_import.json '
                      'or Download Curriculum',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  if (_validationResult != null || _fileReadError != null) {
                    setState(() {
                      _validationResult = null;
                      _fileReadError = null;
                    });
                  }
                },
              ),
              if (_fileReadError != null)
                _ImportErrorsCard(errors: [_fileReadError!]),
              if (result != null && !result.isValid)
                _ImportErrorsCard(errors: result.errors),
              if (result != null && result.isValid)
                _buildValidPreviewSection(context, result),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('importCurriculumCancelButton'),
          onPressed: _pickingFile ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('importCurriculumApplyButton'),
          onPressed: canApply ? _applyImport : null,
          icon: const Icon(Icons.download_done_outlined, size: 18),
          label: const Text('Import into Draft'),
        ),
      ],
    );
  }

  Widget _buildValidPreviewSection(
    BuildContext context,
    CurriculumImportResult result,
  ) {
    final theme = Theme.of(context);
    final importedFamilies = result.families!;
    final importedSkills = result.skills!;
    final sizeKb = (result.sizeBytes / 1024).toStringAsFixed(1);

    final diff = switch (_diffBaseline) {
      _ImportDiffBaseline.published => CurriculumDraftDiff.compute(
        publishedFamilies: widget.publishedFamilies,
        publishedSkills: widget.publishedSkills,
        draftFamilies: importedFamilies,
        draftSkills: importedSkills,
      ),
      _ImportDiffBaseline.currentDraft => CurriculumDraftDiff.compute(
        publishedFamilies: widget.currentDraftFamilies,
        publishedSkills: widget.currentDraftSkills,
        draftFamilies: importedFamilies,
        draftSkills: importedSkills,
      ),
    };

    return Column(
      key: const Key('importCurriculumDiffPreview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceSm,
      children: [
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppTokens.spaceSm),
          child: Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const AppStatusBadge(
                label: 'Valid Schema v2',
                tone: AppStatusTone.success,
              ),
              Chip(label: Text('${importedFamilies.length} families')),
              Chip(label: Text('${importedSkills.length} skills')),
              Chip(label: Text('${result.totalLevels} levels')),
              Chip(label: Text('$sizeKb KB')),
            ],
          ),
        ),
        if (result.warnings.isNotEmpty)
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppTokens.spaceSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                for (final warning in result.warnings)
                  Text(
                    'Warning: $warning',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
        SegmentedButton<_ImportDiffBaseline>(
          key: const Key('importDiffCompareToggle'),
          segments: const [
            ButtonSegment<_ImportDiffBaseline>(
              value: _ImportDiffBaseline.published,
              label: Text('vs. Published Curriculum'),
            ),
            ButtonSegment<_ImportDiffBaseline>(
              value: _ImportDiffBaseline.currentDraft,
              label: Text('vs. Current Draft'),
            ),
          ],
          selected: {_diffBaseline},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            setState(() => _diffBaseline = selection.first);
          },
        ),
        _ImportDiffDetailsCard(diff: diff),
        Text(
          'Importing updates your working draft only. Changes are not published '
          'until you Save Draft and Publish Curriculum.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTokens.secondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}

class _ImportErrorsCard extends StatelessWidget {
  const _ImportErrorsCard({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxVisible = 25;
    final visible = errors.take(maxVisible).toList();
    final remaining = errors.length - visible.length;

    return AppSurfaceCard(
      key: const Key('importCurriculumErrorsCard'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppTokens.spaceXs),
              Expanded(
                child: Text(
                  'Validation failed (${errors.length} '
                  '${errors.length == 1 ? 'issue' : 'issues'})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          for (final err in visible)
            Text(
              '• $err',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (remaining > 0)
            Text(
              '• …and $remaining additional issue(s).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportDiffDetailsCard extends StatelessWidget {
  const _ImportDiffDetailsCard({required this.diff});

  final CurriculumDraftDiff diff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!diff.hasChanges) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Text(
          'No differences found compared to this baseline.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final familyChangeCount =
        diff.addedFamilies.length +
        diff.modifiedFamilies.length +
        diff.removedFamilies.length;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceXs,
            children: [
              Chip(label: Text('Added: ${diff.addedSkills.length}')),
              Chip(label: Text('Modified: ${diff.modifiedSkills.length}')),
              Chip(label: Text('Retired: ${diff.retiredSkills.length}')),
              Chip(label: Text('Removed: ${diff.removedSkills.length}')),
              Chip(label: Text('Family changes: $familyChangeCount')),
            ],
          ),
          if (diff.addedFamilies.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Added Families (${diff.addedFamilies.length})',
            ),
            for (final f in diff.addedFamilies)
              Text('• ${f.name} (${f.id})', style: theme.textTheme.bodySmall),
          ],
          if (diff.modifiedFamilies.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Modified Families (${diff.modifiedFamilies.length})',
            ),
            for (final item in diff.modifiedFamilies)
              Text(
                '• ${item.family.name} (${item.family.id}) — '
                '${item.changedFields.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
          ],
          if (diff.removedFamilies.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Removed Families (${diff.removedFamilies.length})',
            ),
            for (final f in diff.removedFamilies)
              Text('• ${f.name} (${f.id})', style: theme.textTheme.bodySmall),
          ],
          if (diff.addedSkills.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Added Skills (${diff.addedSkills.length})',
            ),
            for (final s in diff.addedSkills)
              Text('• ${s.name} (${s.id})', style: theme.textTheme.bodySmall),
          ],
          if (diff.modifiedSkills.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Modified Skills (${diff.modifiedSkills.length})',
            ),
            for (final item in diff.modifiedSkills)
              Text(
                '• ${item.skill.name} (${item.skill.id}) — '
                '${item.changedFields.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
          ],
          if (diff.retiredSkills.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Retired Skills (${diff.retiredSkills.length})',
            ),
            for (final s in diff.retiredSkills)
              Text(
                '• ${s.name} (${s.id})'
                '${s.replacedBy == null ? '' : ' → ${s.replacedBy}'}',
                style: theme.textTheme.bodySmall,
              ),
          ],
          if (diff.removedSkills.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Removed Skills (${diff.removedSkills.length})',
            ),
            for (final s in diff.removedSkills)
              Text(
                '• ${s.name} (${s.id})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
