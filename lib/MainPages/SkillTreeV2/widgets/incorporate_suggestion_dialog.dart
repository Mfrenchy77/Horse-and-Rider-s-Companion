// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_draft_dialogs.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Result returned when an administrator incorporates a community suggestion
/// into the curriculum draft (never auto-publishing).
class IncorporateSuggestionResult {
  const IncorporateSuggestionResult({
    required this.draftSaved,
    required this.markIncorporated,
    required this.grantPublicCredit,
  });

  final bool draftSaved;
  final bool markIncorporated;
  final bool grantPublicCredit;
}

/// Frosted-glass workflow dialog connecting a community [SkillTreeSuggestion]
/// directly into the administrator's curriculum draft editor.
class IncorporateSuggestionDialog extends StatefulWidget {
  const IncorporateSuggestionDialog({
    super.key,
    required this.suggestion,
    required this.draftRepository,
    required this.publishedFamilies,
    required this.publishedSkills,
  });

  final SkillTreeSuggestion suggestion;
  final SkillTreeDraftRepository draftRepository;
  final List<SkillFamily> publishedFamilies;
  final List<CurriculumSkill> publishedSkills;

  @override
  State<IncorporateSuggestionDialog> createState() =>
      _IncorporateSuggestionDialogState();
}

class _IncorporateSuggestionDialogState
    extends State<IncorporateSuggestionDialog> {
  bool _loading = true;
  bool _saving = false;
  bool _draftChanged = false;
  bool _draftSaved = false;
  bool _markIncorporated = true;
  bool _grantPublicCredit = false;
  String? _error;

  List<SkillFamily> _families = const [];
  List<CurriculumSkill> _skills = const [];
  String? _selectedFamilyId;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final existingDraft = await widget.draftRepository.fetchDraft();
      if (!mounted) return;
      final families = existingDraft != null && existingDraft.families.isNotEmpty
          ? List<SkillFamily>.from(existingDraft.families)
          : List<SkillFamily>.from(widget.publishedFamilies);
      final skills = existingDraft != null && existingDraft.skills.isNotEmpty
          ? List<CurriculumSkill>.from(existingDraft.skills)
          : List<CurriculumSkill>.from(widget.publishedSkills);

      final targetSkill = _findTargetSkill(skills);
      final preferredFamilyId =
          targetSkill?.familyId ??
          widget.suggestion.familyId ??
          families
              .where(
                (f) =>
                    f.subject.name == widget.suggestion.subject &&
                    f.realm.name == widget.suggestion.realm,
              )
              .map((f) => f.id)
              .firstOrNull ??
          families.firstOrNull?.id;

      setState(() {
        _families = families;
        _skills = skills;
        _selectedFamilyId = preferredFamilyId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _families = List<SkillFamily>.from(widget.publishedFamilies);
        _skills = List<CurriculumSkill>.from(widget.publishedSkills);
        _selectedFamilyId = _families.firstOrNull?.id;
        _error = 'Loaded current curriculum baseline: $e';
        _loading = false;
      });
    }
  }

  CurriculumSkill? _findTargetSkill(List<CurriculumSkill> skills) {
    final targetId = widget.suggestion.targetSkillId;
    if (targetId == null || targetId.isEmpty) return null;
    for (final s in skills) {
      if (s.id == targetId) return s;
    }
    return null;
  }

  DifficultyState? _parseTargetLevel(String? raw) {
    return switch (raw?.toLowerCase()) {
      'introductory' => DifficultyState.Introductory,
      'intermediate' => DifficultyState.Intermediate,
      'advanced' => DifficultyState.Advanced,
      _ => null,
    };
  }

  SkillSubject _parseSubject(String raw) =>
      raw == 'horse' ? SkillSubject.horse : SkillSubject.rider;

  SkillCategory _parseRealm(String raw) {
    return switch (raw) {
      'Husbandry' => SkillCategory.Husbandry,
      'In_Hand' => SkillCategory.In_Hand,
      'Mounted' => SkillCategory.Mounted,
      _ => SkillCategory.Other,
    };
  }

  Future<void> _editTargetSkill() async {
    final target = _findTargetSkill(_skills);
    if (target == null) return;
    final family = _families.where((f) => f.id == target.familyId).firstOrNull;
    if (family == null) return;
    final publishedSkill = widget.publishedSkills
        .where((s) => s.id == target.id)
        .firstOrNull;

    final updated = await showAppGlassDialog<CurriculumSkill>(
      context: context,
      builder: (_) => EditCurriculumSkillDialog(
        initialSkill: target,
        publishedSkill: publishedSkill,
        family: family,
        allSkills: _skills,
        existingSkillIds: _skills.map((s) => s.id).toSet(),
        defaultSortOrder: target.sortOrder,
        initialExpandedLevel: _parseTargetLevel(widget.suggestion.targetLevel),
      ),
    );
    if (updated == null || !mounted) return;

    final nextSkills = List<CurriculumSkill>.from(_skills);
    final idx = nextSkills.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      nextSkills[idx] = updated;
    } else {
      nextSkills.add(updated);
    }
    setState(() {
      _skills = nextSkills;
      _draftChanged = true;
      _draftSaved = false;
      _error = null;
    });
  }

  Future<void> _createNewSkill() async {
    final family =
        _families.where((f) => f.id == _selectedFamilyId).firstOrNull ??
        _families.firstOrNull;
    if (family == null) {
      setState(
        () => _error = 'Add or select a skill family before creating a skill.',
      );
      return;
    }
    final familyCount = _skills.where((s) => s.familyId == family.id).length;
    final created = await showAppGlassDialog<CurriculumSkill>(
      context: context,
      builder: (_) => EditCurriculumSkillDialog(
        family: family,
        allSkills: _skills,
        existingSkillIds: _skills.map((s) => s.id).toSet(),
        defaultSortOrder: familyCount + 1,
        initialExpandedLevel: _parseTargetLevel(widget.suggestion.targetLevel),
      ),
    );
    if (created == null || !mounted) return;

    setState(() {
      _skills = [..._skills, created];
      _draftChanged = true;
      _draftSaved = false;
      _error = null;
    });
  }

  Future<void> _addNewFamily() async {
    final created = await showAppGlassDialog<SkillFamily>(
      context: context,
      builder: (_) => EditSkillFamilyDialog(
        defaultSubject: _parseSubject(widget.suggestion.subject),
        defaultRealm: _parseRealm(widget.suggestion.realm),
        existingFamilyIds: _families.map((f) => f.id).toSet(),
        defaultSortOrder: _families.length + 1,
      ),
    );
    if (created == null || !mounted) return;

    setState(() {
      _families = [..._families, created];
      _selectedFamilyId = created.id;
      _draftChanged = true;
      _draftSaved = false;
      _error = null;
    });
  }

  Future<void> _saveDraftAndFinish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_draftChanged && !_draftSaved) {
        await widget.draftRepository.saveDraft(
          SkillTreeCurriculumDraft(families: _families, skills: _skills),
          note: 'Incorporated suggestion: ${widget.suggestion.title}',
        );
      }
      if (!mounted) return;
      setState(() {
        _draftSaved = true;
        _saving = false;
      });
      Navigator.of(context).pop(
        IncorporateSuggestionResult(
          draftSaved: _draftChanged || _draftSaved,
          markIncorporated: _markIncorporated,
          grantPublicCredit:
              widget.suggestion.creditConsent && _grantPublicCredit,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.suggestion;
    final targetSkill = _findTargetSkill(_skills);
    final alreadyIncorporated =
        s.status == SuggestionStatus.incorporated ||
        s.status == SuggestionStatus.published;

    return AppGlassDialog(
      key: const Key('incorporateSuggestionDialog'),
      title: const Text('Incorporate into Draft'),
      content: SizedBox(
        width: 580,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppTokens.spaceMd,
                  children: [
                    if (alreadyIncorporated)
                      Container(
                        key: const Key('alreadyIncorporatedNotice'),
                        padding: const EdgeInsets.all(AppTokens.spaceSm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                        ),
                        child: Text(
                          'This suggestion was already marked as '
                          '${s.status.label}. Review existing draft changes '
                          'carefully to avoid duplicating edits.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(AppTokens.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Text(
                            s.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Chip(
                                label: Text(s.contributionCategory.label),
                                visualDensity: VisualDensity.compact,
                              ),
                              if (s.targetSkillName != null)
                                Chip(
                                  label: Text('Skill: ${s.targetSkillName}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (s.targetLevel != null)
                                Chip(
                                  label: Text('Level: ${s.targetLevel}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          Text(s.description, style: theme.textTheme.bodySmall),
                          if (s.proposedAlias != null &&
                              s.proposedAlias!.isNotEmpty)
                            Text(
                              'Proposed term: ${s.proposedAlias}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (s.rationale != null && s.rationale!.isNotEmpty)
                            Text(
                              'Rationale: ${s.rationale}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTokens.secondaryTextColor(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'Changes are saved only to your curriculum draft and '
                      'never published automatically.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                    if (_families.isNotEmpty)
                      DropdownButtonFormField<String>(
                        key: const Key('incorporateFamilyDropdown'),
                        isExpanded: true,
                        initialValue: _selectedFamilyId,
                        decoration: const InputDecoration(
                          labelText: 'Skill Family (for new skills)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final f in _families)
                            DropdownMenuItem(value: f.id, child: Text(f.name)),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _selectedFamilyId = v),
                      ),
                    Wrap(
                      spacing: AppTokens.spaceSm,
                      runSpacing: AppTokens.spaceSm,
                      children: [
                        if (targetSkill != null)
                          FilledButton.tonalIcon(
                            key: const Key('incorporateEditTargetSkillButton'),
                            onPressed: _saving ? null : _editTargetSkill,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text('Edit ${targetSkill.name}'),
                          ),
                        OutlinedButton.icon(
                          key: const Key('incorporateCreateSkillButton'),
                          onPressed: _saving ? null : _createNewSkill,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Add New Skill'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('incorporateAddFamilyButton'),
                          onPressed: _saving ? null : _addNewFamily,
                          icon: const Icon(
                            Icons.create_new_folder_outlined,
                            size: 18,
                          ),
                          label: const Text('Add Skill Family'),
                        ),
                      ],
                    ),
                    if (_draftChanged)
                      Text(
                        'Draft edits staged and ready to save.',
                        key: const Key('incorporateDraftStagedText'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Divider(),
                    CheckboxListTile(
                      key: const Key('incorporateMarkStatusCheckbox'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _markIncorporated,
                      onChanged: _saving
                          ? null
                          : (v) => setState(
                              () => _markIncorporated = v ?? false,
                            ),
                      title: const Text('Mark suggestion as Incorporated'),
                    ),
                    if (s.creditConsent)
                      CheckboxListTile(
                        key: const Key('incorporateGrantCreditCheckbox'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _grantPublicCredit,
                        onChanged: _saving
                            ? null
                            : (v) => setState(
                                () => _grantPublicCredit = v ?? false,
                              ),
                        title: const Text(
                          'Acknowledge contributor in Community Contributors',
                        ),
                        subtitle: const Text(
                          'Contributor opted in. Only their display name is '
                          'shown publicly (never email or suggestion text).',
                        ),
                      )
                    else
                      Text(
                        'Contributor did not opt into public recognition.',
                        key: const Key('incorporateNoConsentText'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTokens.secondaryTextColor(context),
                        ),
                      ),
                    if (_error != null)
                      Text(
                        _error!,
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('incorporateSaveDraftButton'),
          onPressed: _saving || (!_draftChanged && !_markIncorporated)
              ? null
              : _saveDraftAndFinish,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_draftChanged ? 'Save Draft' : 'Save Status'),
        ),
      ],
    );
  }
}
