import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

String _wireSubject(SkillSubject subject) =>
    subject == SkillSubject.horse ? 'horse' : 'rider';

String _wireRealm(SkillCategory realm) {
  switch (realm) {
    case SkillCategory.Husbandry:
      return 'Husbandry';
    case SkillCategory.In_Hand:
      return 'In_Hand';
    case SkillCategory.Mounted:
      return 'Mounted';
    case SkillCategory.Other:
      return 'Other';
  }
}

String? _wireLevel(DifficultyState? level) {
  switch (level) {
    case DifficultyState.Introductory:
      return 'introductory';
    case DifficultyState.Intermediate:
      return 'intermediate';
    case DifficultyState.Advanced:
      return 'advanced';
    case DifficultyState.All:
    case null:
      return null;
  }
}

SkillTreeSuggestionsRepository _resolveSuggestionsRepo(
  BuildContext context,
  SkillTreeSuggestionsRepository? override,
) {
  if (override != null) return override;
  try {
    return context.read<SkillTreeSuggestionsRepository>();
  } catch (_) {
    return SkillTreeSuggestionsRepository();
  }
}

/// Opens the community Skill Tree suggestion dialog, automatically attaching
/// the current [subject], [realm], and optional [targetSkill]/[targetLevel].
Future<SkillTreeSuggestion?> showSuggestImprovementDialog(
  BuildContext context, {
  required SkillSubject subject,
  required SkillCategory realm,
  String? familyId,
  CurriculumSkill? targetSkill,
  DifficultyState? targetLevel,
  SkillTreeSuggestionsRepository? repository,
}) async {
  final appState = context.read<AppCubit>().state;
  if (appState.isGuest || appState.user.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'Please sign in with a verified account to submit a Skill Tree '
          'curriculum suggestion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return null;
  }
  if (!appState.user.emailVerified) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'Please verify your email address before submitting a curriculum '
          'suggestion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return null;
  }

  final resolvedRepo = _resolveSuggestionsRepo(context, repository);
  return showDialog<SkillTreeSuggestion>(
    context: context,
    builder: (ctx) => _SuggestImprovementDialog(
      repository: resolvedRepo,
      subject: subject,
      realm: targetSkill?.realm ?? realm,
      familyId: targetSkill?.familyId ?? familyId,
      targetSkill: targetSkill,
      targetLevel: targetLevel,
    ),
  );
}

/// Opens a dialog listing the current user's submitted Skill Tree suggestions
/// and any public resolution notes from moderators or administrators.
Future<void> showMySuggestionsDialog(
  BuildContext context, {
  SkillTreeSuggestionsRepository? repository,
}) async {
  final appState = context.read<AppCubit>().state;
  if (appState.isGuest ||
      appState.user.isEmpty ||
      !appState.user.emailVerified) {
    await showSuggestImprovementDialog(
      context,
      subject: SkillSubject.rider,
      realm: SkillCategory.Other,
      repository: repository,
    );
    return;
  }

  final resolvedRepo = _resolveSuggestionsRepo(context, repository);
  await showDialog<void>(
    context: context,
    builder: (ctx) => _MySuggestionsDialog(
      repository: resolvedRepo,
      submitterUid: appState.user.id,
    ),
  );
}

class _SuggestImprovementDialog extends StatefulWidget {
  const _SuggestImprovementDialog({
    required this.repository,
    required this.subject,
    required this.realm,
    required this.familyId,
    required this.targetSkill,
    required this.targetLevel,
  });

  final SkillTreeSuggestionsRepository repository;
  final SkillSubject subject;
  final SkillCategory realm;
  final String? familyId;
  final CurriculumSkill? targetSkill;
  final DifficultyState? targetLevel;

  @override
  State<_SuggestImprovementDialog> createState() =>
      _SuggestImprovementDialogState();
}

class _SuggestImprovementDialogState extends State<_SuggestImprovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rationaleController = TextEditingController();
  final _aliasController = TextEditingController();
  late SuggestionCategory _category = widget.targetSkill == null
      ? SuggestionCategory.newSkillProposal
      : SuggestionCategory.componentOrExample;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rationaleController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await widget.repository.submitSuggestion(
        SkillTreeSuggestionDraft(
          contributionCategory: _category,
          subject: _wireSubject(widget.subject),
          realm: _wireRealm(widget.realm),
          familyId: widget.familyId,
          targetSkillId: widget.targetSkill?.id,
          targetSkillName: widget.targetSkill?.name,
          targetLevel: _wireLevel(widget.targetLevel),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          rationale: _rationaleController.text.trim().isEmpty
              ? null
              : _rationaleController.text.trim(),
          proposedAlias: _aliasController.text.trim().isEmpty
              ? null
              : _aliasController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on SkillTreeSuggestionException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not submit suggestion. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skill = widget.targetSkill;
    final level = widget.targetLevel;
    final contextParts = [
      subjectDisplayLabel(widget.subject),
      realmDisplayLabel(widget.realm),
      if (skill != null) skill.name,
      if (level != null && level != DifficultyState.All) level.name,
    ];

    return AlertDialog(
      key: const Key('suggestImprovementDialog'),
      title: Text(
        skill == null
            ? 'Suggest a Skill Tree Improvement'
            : 'Suggest Improvement: ${skill.name}',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceSm,
              children: [
                Wrap(
                  spacing: AppTokens.spaceXs,
                  runSpacing: AppTokens.spaceXs,
                  children: [
                    for (final part in contextParts)
                      Chip(
                        label: Text(part),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                DropdownButtonFormField<SuggestionCategory>(
                  key: const Key('suggestionCategoryField'),
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Suggestion Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in SuggestionCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _category = value);
                        },
                ),
                TextFormField(
                  key: const Key('suggestionTitleField'),
                  controller: _titleController,
                  enabled: !_submitting,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Short Title',
                    hintText: 'e.g., Add safety cue for hind hoof picking',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.length < 5) {
                      return 'Please enter at least 5 characters.';
                    }
                    return null;
                  },
                ),
                if (_category == SuggestionCategory.missingTermOrAlias)
                  TextFormField(
                    key: const Key('suggestionAliasField'),
                    controller: _aliasController,
                    enabled: !_submitting,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Proposed Term or Alias (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                TextFormField(
                  key: const Key('suggestionDescriptionField'),
                  controller: _descriptionController,
                  enabled: !_submitting,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    hintText:
                        'Describe the skill, component, terminology, or '
                        'difficulty standard improvement.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.length < 10) {
                      return 'Please provide at least 10 characters of detail.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: const Key('suggestionRationaleField'),
                  controller: _rationaleController,
                  enabled: !_submitting,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Why this helps riders or horses (optional)',
                    border: OutlineInputBorder(),
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
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('suggestionSubmitButton'),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Submit Suggestion'),
        ),
      ],
    );
  }
}

class _MySuggestionsDialog extends StatefulWidget {
  const _MySuggestionsDialog({
    required this.repository,
    required this.submitterUid,
  });

  final SkillTreeSuggestionsRepository repository;
  final String submitterUid;

  @override
  State<_MySuggestionsDialog> createState() => _MySuggestionsDialogState();
}

class _MySuggestionsDialogState extends State<_MySuggestionsDialog> {
  late Future<List<SkillTreeSuggestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchMySuggestions(
      submitterUid: widget.submitterUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('mySuggestionsDialog'),
      title: const Text('My Submitted Suggestions'),
      content: SizedBox(
        width: 540,
        height: 400,
        child: FutureBuilder<List<SkillTreeSuggestion>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load your suggestions.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'You have not submitted any Skill Tree suggestions yet.',
                ),
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppTokens.spaceXs,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(item.status.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.publicResolutionNote != null &&
                        item.publicResolutionNote!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTokens.spaceSm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                        ),
                        child: Text(
                          'Resolution note: ${item.publicResolutionNote}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
            );
          },
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
}
