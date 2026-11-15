import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

final RegExp _draftDocIdRegex = RegExp(r'^[A-Za-z0-9._-]{1,120}$');

String _slugify(String input) {
  final lower = input.trim().toLowerCase();
  final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final collapsed = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
  return collapsed.isEmpty ? 'item' : collapsed;
}

String _realmSlug(SkillCategory realm) {
  return switch (realm) {
    SkillCategory.Husbandry => 'husbandry',
    SkillCategory.In_Hand => 'in_hand',
    SkillCategory.Mounted => 'mounted',
    SkillCategory.Other => 'other',
  };
}

String _difficultyLabel(DifficultyState level) {
  return switch (level) {
    DifficultyState.Introductory => 'Introductory',
    DifficultyState.Intermediate => 'Intermediate',
    DifficultyState.Advanced => 'Advanced',
    DifficultyState.All => 'All',
  };
}

String _relationLabel(SkillRelationType relation) {
  return switch (relation) {
    SkillRelationType.counterpart => 'Counterpart',
    SkillRelationType.foundation => 'Foundation',
    SkillRelationType.next => 'Next',
    SkillRelationType.theory => 'Theory',
  };
}

/// Admin dialog to create or edit a [SkillFamily] inside the curriculum draft.
class EditSkillFamilyDialog extends StatefulWidget {
  const EditSkillFamilyDialog({
    super.key,
    this.initialFamily,
    required this.defaultSubject,
    required this.defaultRealm,
    required this.existingFamilyIds,
    this.defaultSortOrder = 0,
  });

  final SkillFamily? initialFamily;
  final SkillSubject defaultSubject;
  final SkillCategory defaultRealm;
  final Set<String> existingFamilyIds;
  final int defaultSortOrder;

  @override
  State<EditSkillFamilyDialog> createState() => _EditSkillFamilyDialogState();
}

class _EditSkillFamilyDialogState extends State<EditSkillFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;
  bool _idManuallyEdited = false;

  bool get _isEditing => widget.initialFamily != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFamily;
    _idController = TextEditingController(text: initial?.id ?? '');
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _sortOrderController = TextEditingController(
      text: (initial?.sortOrder ?? widget.defaultSortOrder).toString(),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_isEditing || _idManuallyEdited) return;
    final prefix =
        '${widget.defaultSubject.toWireString()}.${_realmSlug(widget.defaultRealm)}';
    _idController.text = '$prefix.${_slugify(value)}';
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final initial = widget.initialFamily;
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final family = SkillFamily(
      id: initial?.id ?? _idController.text.trim(),
      subject: initial?.subject ?? widget.defaultSubject,
      realm: initial?.realm ?? widget.defaultRealm,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sortOrder: sortOrder,
      schemaVersion: initial?.schemaVersion ?? 2,
    );
    Navigator.of(context).pop(family);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Skill Family' : 'Add Skill Family'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Family Name *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onNameChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Family name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Family ID *',
                    helperText: _isEditing
                        ? 'Existing family IDs are preserved to protect references.'
                        : 'Unique slug (e.g. rider.mounted.balance)',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _idManuallyEdited = true,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (!_draftDocIdRegex.hasMatch(trimmed)) {
                      return 'ID must match ^[A-Za-z0-9._-]{1,120}\$.';
                    }
                    if (!_isEditing &&
                        widget.existingFamilyIds.contains(trimmed)) {
                      return 'A family with this ID already exists.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a whole number.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Apply to Draft' : 'Add Family'),
        ),
      ],
    );
  }
}

class _EditableComponent {
  _EditableComponent({String title = '', String description = ''})
      : titleController = TextEditingController(text: title),
        descriptionController = TextEditingController(text: description);

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _EditableLevelFields {
  _EditableLevelFields({SkillLevelDefinition? initial})
      : overviewController =
            TextEditingController(text: initial?.overview ?? ''),
        learningController =
            TextEditingController(text: initial?.learning ?? ''),
        proficientController =
            TextEditingController(text: initial?.proficient ?? ''),
        standardVersion = initial?.standardVersion ?? 1,
        standardUpdatedAt = initial?.standardUpdatedAt,
        components = (initial?.components ?? const [])
            .map(
              (c) => _EditableComponent(
                title: c.title,
                description: c.description,
              ),
            )
            .toList();

  final TextEditingController overviewController;
  final TextEditingController learningController;
  final TextEditingController proficientController;
  final int standardVersion;
  final DateTime? standardUpdatedAt;
  final List<_EditableComponent> components;

  void dispose() {
    overviewController.dispose();
    learningController.dispose();
    proficientController.dispose();
    for (final component in components) {
      component.dispose();
    }
  }
}

class _EditableRelatedSkill {
  _EditableRelatedSkill({
    required this.skillId,
    required this.relation,
    this.level,
  });

  String skillId;
  SkillRelationType relation;
  DifficultyState? level;
}

/// Admin dialog to create or edit a [CurriculumSkill] inside the curriculum
/// draft while preserving its canonical ID, legacy mappings, and progress.
class EditCurriculumSkillDialog extends StatefulWidget {
  const EditCurriculumSkillDialog({
    super.key,
    this.initialSkill,
    required this.family,
    required this.allSkills,
    required this.existingSkillIds,
    this.defaultSortOrder = 0,
    this.initialExpandedLevel,
  });

  final CurriculumSkill? initialSkill;
  final SkillFamily family;
  final List<CurriculumSkill> allSkills;
  final Set<String> existingSkillIds;
  final int defaultSortOrder;
  final DifficultyState? initialExpandedLevel;

  @override
  State<EditCurriculumSkillDialog> createState() =>
      _EditCurriculumSkillDialogState();
}

class _EditCurriculumSkillDialogState extends State<EditCurriculumSkillDialog> {
  static const List<DifficultyState> _editableLevels = [
    DifficultyState.Introductory,
    DifficultyState.Intermediate,
    DifficultyState.Advanced,
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _summaryController;
  late final TextEditingController _purposeController;
  late final TextEditingController _aliasesController;
  late final TextEditingController _safetyController;
  late final TextEditingController _sortOrderController;
  late final Set<DifficultyState> _selectedLevels;
  late final Set<DifficultyState> _expandedLevels;
  late final Map<DifficultyState, _EditableLevelFields> _levelFields;
  late final List<_EditableRelatedSkill> _relatedSkills;

  bool _idManuallyEdited = false;
  bool _hasAttemptedSubmit = false;
  String? _levelsError;

  bool get _isEditing => widget.initialSkill != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSkill;
    _idController = TextEditingController(text: initial?.id ?? '');
    _nameController = TextEditingController(text: initial?.name ?? '');
    _summaryController = TextEditingController(text: initial?.summary ?? '');
    _purposeController = TextEditingController(text: initial?.purpose ?? '');
    _aliasesController = TextEditingController(
      text: (initial?.aliases ?? const []).join(', '),
    );
    _safetyController = TextEditingController(
      text: (initial?.safety ?? const []).join('\n'),
    );
    _sortOrderController = TextEditingController(
      text: (initial?.sortOrder ?? widget.defaultSortOrder).toString(),
    );

    _selectedLevels = initial != null && initial.availableLevels.isNotEmpty
        ? Set<DifficultyState>.from(initial.availableLevels)
        : <DifficultyState>{DifficultyState.Introductory};

    final initialExpanded = widget.initialExpandedLevel;
    if (initialExpanded != null && _selectedLevels.contains(initialExpanded)) {
      _expandedLevels = {initialExpanded};
    } else {
      final firstSelected = _editableLevels
          .where(_selectedLevels.contains)
          .firstOrNull;
      _expandedLevels = firstSelected != null ? {firstSelected} : {};
    }

    _levelFields = {
      for (final level in _editableLevels)
        level: _EditableLevelFields(initial: initial?.levels[level]),
    };

    _relatedSkills = (initial?.relatedSkills ?? const [])
        .map(
          (r) => _EditableRelatedSkill(
            skillId: r.skillId,
            relation: r.relation,
            level: r.level,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _summaryController.dispose();
    _purposeController.dispose();
    _aliasesController.dispose();
    _safetyController.dispose();
    _sortOrderController.dispose();
    for (final fields in _levelFields.values) {
      fields.dispose();
    }
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_isEditing || _idManuallyEdited) return;
    final prefix =
        '${widget.family.subject.toWireString()}.${_realmSlug(widget.family.realm)}';
    _idController.text = '$prefix.${_slugify(value)}';
  }

  List<String> _parseAliases() {
    return _aliasesController.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> _parseSafety() {
    return _safetyController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _levelHasValidationError(DifficultyState level) {
    if (!_hasAttemptedSubmit || !_selectedLevels.contains(level)) return false;
    final fields = _levelFields[level]!;
    if (fields.overviewController.text.trim().isEmpty ||
        fields.learningController.text.trim().isEmpty ||
        fields.proficientController.text.trim().isEmpty) {
      return true;
    }
    return fields.components.any(
      (c) =>
          c.titleController.text.trim().isEmpty ||
          c.descriptionController.text.trim().isEmpty,
    );
  }

  void _submit() {
    setState(() {
      _hasAttemptedSubmit = true;
      _levelsError = _selectedLevels.isEmpty
          ? 'Select at least one difficulty level.'
          : null;
    });
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedLevels.isEmpty) {
      setState(() {});
      return;
    }

    final initial = widget.initialSkill;
    final orderedLevels =
        _editableLevels.where(_selectedLevels.contains).toList();
    final levelsMap = <DifficultyState, SkillLevelDefinition>{};
    for (final level in orderedLevels) {
      final fields = _levelFields[level]!;
      final components = fields.components
          .map(
            (c) => SkillComponent(
              title: c.titleController.text.trim(),
              description: c.descriptionController.text.trim(),
            ),
          )
          .where((c) => c.title.isNotEmpty || c.description.isNotEmpty)
          .toList();
      levelsMap[level] = SkillLevelDefinition(
        overview: fields.overviewController.text.trim(),
        components: components,
        learning: fields.learningController.text.trim(),
        proficient: fields.proficientController.text.trim(),
        standardVersion: fields.standardVersion,
        standardUpdatedAt: fields.standardUpdatedAt,
      );
    }

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final skill = CurriculumSkill(
      id: initial?.id ?? _idController.text.trim(),
      schemaVersion: initial?.schemaVersion ?? 2,
      status: initial?.status ?? CurriculumSkillStatus.active,
      subject: initial?.subject ?? widget.family.subject,
      realm: initial?.realm ?? widget.family.realm,
      familyId: initial?.familyId ?? widget.family.id,
      name: _nameController.text.trim(),
      aliases: _parseAliases(),
      summary: _summaryController.text.trim(),
      purpose: _purposeController.text.trim(),
      safety: _parseSafety(),
      availableLevels: orderedLevels,
      levels: levelsMap,
      relatedSkills: _relatedSkills
          .where((r) => r.skillId.isNotEmpty)
          .map(
            (r) => RelatedSkill(
              skillId: r.skillId,
              relation: r.relation,
              level: r.level,
            ),
          )
          .toList(),
      legacyIds: initial?.legacyIds ?? const [],
      sortOrder: sortOrder,
      replacedBy: initial?.replacedBy,
      updatedAt: initial?.updatedAt,
      updatedBy: initial?.updatedBy,
    );

    Navigator.of(context).pop(skill);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentId = widget.initialSkill?.id ?? _idController.text.trim();
    final selectableRelated = widget.allSkills
        .where((s) => s.id != currentId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEditing ? 'Edit Skill (Draft)' : 'Add Skill (Draft)'),
      content: SizedBox(
        width: 660,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Family: ${widget.family.name}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onNameChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Skill name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Skill ID *',
                    helperText: _isEditing
                        ? 'Skill ID and legacy mappings are preserved so user progress stays intact.'
                        : 'Unique canonical ID (e.g. rider.mounted.half_halt)',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _idManuallyEdited = true,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (!_draftDocIdRegex.hasMatch(trimmed)) {
                      return 'ID must match ^[A-Za-z0-9._-]{1,120}\$.';
                    }
                    if (!_isEditing &&
                        widget.existingSkillIds.contains(trimmed)) {
                      return 'A skill with this ID already exists.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _summaryController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Summary / Description *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Summary is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purposeController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Purpose / Why It Matters *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Purpose is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aliasesController,
                  decoration: const InputDecoration(
                    labelText: 'Aliases (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _safetyController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Safety Guidance (one note per line)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a whole number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Difficulty Standards',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _editableLevels.map((level) {
                    final selected = _selectedLevels.contains(level);
                    return FilterChip(
                      label: Text(_difficultyLabel(level)),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedLevels.add(level);
                          } else {
                            _selectedLevels.remove(level);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_levelsError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _levelsError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                for (final level in _editableLevels)
                  if (_selectedLevels.contains(level)) ...[
                    const SizedBox(height: 12),
                    _buildLevelEditor(context, level, _levelFields[level]!),
                  ],
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      'Related Skills',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selectableRelated.isNotEmpty)
                      TextButton.icon(
                        key: const Key('addRelatedSkillButton'),
                        onPressed: () {
                          setState(() {
                            _relatedSkills.add(
                              _EditableRelatedSkill(
                                skillId: selectableRelated.first.id,
                                relation: SkillRelationType.foundation,
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Related Skill'),
                      ),
                  ],
                ),
                for (var i = 0; i < _relatedSkills.length; i++) ...[
                  const SizedBox(height: 8),
                  _buildRelatedSkillRow(i, selectableRelated),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Apply to Draft' : 'Add Skill'),
        ),
      ],
    );
  }

  Widget _buildLevelEditor(
    BuildContext context,
    DifficultyState level,
    _EditableLevelFields fields,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedLevels.contains(level);
    final hasError = _levelHasValidationError(level);
    return Card(
      key: Key('levelEditorCard_${level.name}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: Key('levelEditorHeader_${level.name}'),
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedLevels.remove(level);
                  } else {
                    _expandedLevels.add(level);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_difficultyLabel(level)} Standard',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasError && !isExpanded) ...[
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Needs attention',
                        key: Key('levelEditorErrorBadge_${level.name}'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: isExpanded,
              maintainState: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
              controller: fields.overviewController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Level Overview *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Overview is required for ${_difficultyLabel(level)}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: fields.learningController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Learning Standard *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Learning standard is required for ${_difficultyLabel(level)}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: fields.proficientController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Proficient Standard *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Proficient standard is required for ${_difficultyLabel(level)}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  'Educational Components',
                  style: theme.textTheme.labelLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      fields.components.add(_EditableComponent());
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Component'),
                ),
              ],
            ),
            for (var i = 0; i < fields.components.length; i++) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: fields.components[i].titleController,
                          decoration: const InputDecoration(
                            labelText: 'Component Title *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Component title is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: fields.components[i].descriptionController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Component Description *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Component description is required.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove component',
                    onPressed: () {
                      setState(() {
                        final removed = fields.components.removeAt(i);
                        removed.dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSkillRow(
    int index,
    List<CurriculumSkill> selectableRelated,
  ) {
    final item = _relatedSkills[index];
    final hasCurrent = selectableRelated.any((s) => s.id == item.skillId);
    final options = hasCurrent
        ? selectableRelated
        : [
            ...selectableRelated,
          ];

    Widget buildSkillDropdown() => DropdownButtonFormField<String>(
      key: Key('relatedSkillDropdown_$index'),
      isExpanded: true,
      initialValue: hasCurrent ? item.skillId : null,
      decoration: const InputDecoration(
        labelText: 'Skill',
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (s) => DropdownMenuItem<String>(
              value: s.id,
              child: Text(
                s.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          item.skillId = value;
        });
      },
    );

    Widget buildRelationDropdown() => DropdownButtonFormField<SkillRelationType>(
      key: Key('relatedRelationDropdown_$index'),
      isExpanded: true,
      initialValue: item.relation,
      decoration: const InputDecoration(
        labelText: 'Relation',
        border: OutlineInputBorder(),
      ),
      items: SkillRelationType.values
          .map(
            (r) => DropdownMenuItem<SkillRelationType>(
              value: r,
              child: Text(
                _relationLabel(r),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          item.relation = value;
        });
      },
    );

    Widget buildRemoveButton() => IconButton(
      key: Key('removeRelatedSkillButton_$index'),
      tooltip: 'Remove related skill',
      onPressed: () {
        setState(() {
          _relatedSkills.removeAt(index);
        });
      },
      icon: const Icon(Icons.delete_outline),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildSkillDropdown(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buildRelationDropdown()),
                  const SizedBox(width: 4),
                  buildRemoveButton(),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: buildSkillDropdown()),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: buildRelationDropdown()),
            buildRemoveButton(),
          ],
        );
      },
    );
  }
}

/// Dialog summarizing differences between published curriculum and the admin
/// draft, with a toggle to preview draft vs published in Skill Tree 2.0.
class DraftPreviewDialog extends StatelessWidget {
  const DraftPreviewDialog({
    super.key,
    required this.publishedFamilies,
    required this.publishedSkills,
    required this.draftFamilies,
    required this.draftSkills,
    required this.isPreviewingDraft,
    required this.onTogglePreview,
  });

  final List<SkillFamily> publishedFamilies;
  final List<CurriculumSkill> publishedSkills;
  final List<SkillFamily> draftFamilies;
  final List<CurriculumSkill> draftSkills;
  final bool isPreviewingDraft;
  final ValueChanged<bool> onTogglePreview;

  @override
  Widget build(BuildContext context) {
    final pubFamilyMap = {for (final f in publishedFamilies) f.id: f};
    final pubSkillMap = {for (final s in publishedSkills) s.id: s};

    final addedFamilies =
        draftFamilies.where((f) => !pubFamilyMap.containsKey(f.id)).toList();
    final modifiedFamilies = draftFamilies.where((f) {
      final pub = pubFamilyMap[f.id];
      if (pub == null) return false;
      return pub.name != f.name ||
          pub.description != f.description ||
          pub.sortOrder != f.sortOrder;
    }).toList();

    final addedSkills =
        draftSkills.where((s) => !pubSkillMap.containsKey(s.id)).toList();
    final modifiedSkills = draftSkills.where((s) {
      final pub = pubSkillMap[s.id];
      if (pub == null) return false;
      return pub.toMap().toString() != s.toMap().toString();
    }).toList();

    final hasChanges = addedFamilies.isNotEmpty ||
        modifiedFamilies.isNotEmpty ||
        addedSkills.isNotEmpty ||
        modifiedSkills.isNotEmpty;

    return AlertDialog(
      title: const Text('Curriculum Draft Preview'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Preview Draft in Skill Tree 2.0'),
                subtitle: const Text(
                  'Toggle off to compare with the published curriculum.',
                ),
                value: isPreviewingDraft,
                onChanged: (value) {
                  onTogglePreview(value);
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              if (!hasChanges)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No differences between the draft and published curriculum.',
                  ),
                )
              else ...[
                if (addedFamilies.isNotEmpty) ...[
                  _sectionTitle(context, 'Added Families (${addedFamilies.length})'),
                  for (final f in addedFamilies) Text('• ${f.name} (${f.id})'),
                  const SizedBox(height: 10),
                ],
                if (modifiedFamilies.isNotEmpty) ...[
                  _sectionTitle(
                    context,
                    'Modified Families (${modifiedFamilies.length})',
                  ),
                  for (final f in modifiedFamilies)
                    Text('• ${f.name} (${f.id})'),
                  const SizedBox(height: 10),
                ],
                if (addedSkills.isNotEmpty) ...[
                  _sectionTitle(context, 'Added Skills (${addedSkills.length})'),
                  for (final s in addedSkills) Text('• ${s.name} (${s.id})'),
                  const SizedBox(height: 10),
                ],
                if (modifiedSkills.isNotEmpty) ...[
                  _sectionTitle(
                    context,
                    'Modified Skills (${modifiedSkills.length})',
                  ),
                  for (final s in modifiedSkills) Text('• ${s.name} (${s.id})'),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
