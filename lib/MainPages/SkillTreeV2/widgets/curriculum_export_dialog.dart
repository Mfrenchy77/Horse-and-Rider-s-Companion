// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_file_downloader.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Generates a clean `.json` filename for downloaded curriculum exports.
String buildCurriculumExportFileName([DateTime? now]) {
  final dt = (now ?? DateTime.now()).toUtc();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return 'skill_tree_curriculum_$y-$m-$d.json';
}

/// Builds a deterministic, canonical JSON string of the full published
/// curriculum matching the backend publishing format.
String buildCanonicalCurriculumExportJson({
  required List<SkillFamily> families,
  required List<CurriculumSkill> skills,
}) {
  final sortedFamilies = List<SkillFamily>.from(families)
    ..sort((a, b) {
      final orderDiff = a.sortOrder.compareTo(b.sortOrder);
      return orderDiff != 0 ? orderDiff : a.id.compareTo(b.id);
    });
  final sortedSkills = List<CurriculumSkill>.from(skills)
    ..sort((a, b) {
      final orderDiff = a.sortOrder.compareTo(b.sortOrder);
      return orderDiff != 0 ? orderDiff : a.id.compareTo(b.id);
    });

  final payload = <String, Object?>{
    'schemaVersion': 2,
    'families': sortedFamilies.map((f) => f.toMap()).toList(),
    'skills': sortedSkills.map((s) => s.toMap()).toList(),
  };
  return '${const JsonEncoder.withIndent('  ').convert(payload)}\n';
}

/// Frosted-glass dialog allowing administrators to download or copy the full
/// published Skill Tree curriculum.
class CurriculumExportDialog extends StatefulWidget {
  const CurriculumExportDialog({
    super.key,
    required this.families,
    required this.skills,
    this.onDownloadFile,
  });

  final List<SkillFamily> families;
  final List<CurriculumSkill> skills;

  /// Optional callback for tests or platform file savers.
  final Future<void> Function(String fileName, String content)? onDownloadFile;

  @override
  State<CurriculumExportDialog> createState() => _CurriculumExportDialogState();
}

class _CurriculumExportDialogState extends State<CurriculumExportDialog> {
  bool _busy = false;
  String? _statusMessage;

  Future<void> _handleCopy(String exportJson) async {
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      await Clipboard.setData(ClipboardData(text: exportJson));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = 'Full curriculum copied to clipboard.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = 'Could not copy curriculum export.';
      });
    }
  }

  Future<void> _handleDownload(String exportJson) async {
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    final fileName = buildCurriculumExportFileName();
    try {
      final downloader = widget.onDownloadFile ?? downloadCurriculumFile;
      await downloader(fileName, exportJson);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = 'Downloaded $fileName.';
      });
    } on CurriculumDownloadUnsupportedException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage =
            'Direct file download is available on web. Use Copy Export instead.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage =
            'Could not download curriculum file. Try again or use Copy Export.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = widget.skills
        .where((s) => s.status == CurriculumSkillStatus.active)
        .length;
    final retiredCount = widget.skills
        .where((s) => s.status == CurriculumSkillStatus.retired)
        .length;
    final levelCount = widget.skills.fold<int>(
      0,
      (total, s) => total + s.availableLevels.length,
    );
    final exportJson = buildCanonicalCurriculumExportJson(
      families: widget.families,
      skills: widget.skills,
    );

    return AppGlassDialog(
      key: const Key('curriculumExportDialog'),
      title: const Text('Download Curriculum'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceMd,
            children: [
              Text(
                'Export the complete published Skill Tree curriculum, '
                'including families, active and retired skills, difficulty '
                'standards, educational components, and skill links.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              AppSurfaceCard(
                padding: const EdgeInsets.all(AppTokens.spaceMd),
                child: Wrap(
                  spacing: AppTokens.spaceSm,
                  runSpacing: AppTokens.spaceXs,
                  children: [
                    Chip(label: Text('${widget.families.length} families')),
                    Chip(label: Text('$activeCount active skills')),
                    if (retiredCount > 0)
                      Chip(label: Text('$retiredCount retired skills')),
                    Chip(label: Text('$levelCount difficulty standards')),
                  ],
                ),
              ),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  key: const Key('curriculumExportStatusText'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          key: const Key('copyCurriculumExportButton'),
          onPressed: _busy ? null : () => _handleCopy(exportJson),
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('Copy Export'),
        ),
        FilledButton.icon(
          key: const Key('downloadCurriculumExportButton'),
          onPressed: _busy ? null : () => _handleDownload(exportJson),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Download Curriculum'),
        ),
      ],
    );
  }
}
