import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';

class UpdateResourceSkills extends StatefulWidget {
  const UpdateResourceSkills({super.key, required this.resource});

  final Resource resource;

  @override
  State<UpdateResourceSkills> createState() => _UpdateResourceSkillsState();
}

class _UpdateResourceSkillsState extends State<UpdateResourceSkills> {
  late final _original = widget.resource.skillTreeIds.toSet();
  late final _selected = {..._original};
  String _query = '';
  String? _error;
  bool _saving = false;
  SkillCategory? _category;
  DifficultyState? _difficulty;

  bool _canEdit(AppCubit cubit) =>
      !cubit.state.isGuest &&
      ((cubit.state.usersProfile?.editor ?? false) ||
          cubit.canEditResource(widget.resource));

  String _skillDetails(Skill skill) =>
      '${skill.rider ? 'Rider' : 'Horse'} · '
      '${skill.category.name.replaceAll('_', ' ')} · ${skill.difficulty.name}';

  Future<void> _save() async {
    final id = widget.resource.id;
    if (_saving || id == null || !_canEdit(context.read<AppCubit>())) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ResourcesRepository>().updateSkillLinks(
        id: id,
        added: _selected.difference(_original),
        removed: _original.difference(_selected),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the skill links. Try again.';
      });
    }
  }

  void _openSkill(Skill skill) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.goNamed(
      SkillTreeView.skillLevelName,
      pathParameters: {SkillTreeView.skillPathParam: skill.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppCubit>();
    final canEdit = _canEdit(app) && (widget.resource.id?.isNotEmpty ?? false);
    final skills = app.state.allSkills.whereType<Skill>().toList()
      ..sort((a, b) => a.skillName.compareTo(b.skillName));
    final matches = skills.where(
      (skill) =>
          skill.skillName.toLowerCase().contains(_query) &&
          (_category == null || skill.category == _category) &&
          (_difficulty == null || skill.difficulty == _difficulty),
    );
    final changed =
        _selected.length != _original.length ||
        !_selected.containsAll(_original);

    return PopScope(
      canPop: !_saving,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: Material(
            // Deliberately square and flat: this route avoids anti-aliased
            // corners and elevation shaders on fragile WebGL renderers.
            color:
                Theme.of(context).dialogTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Associated skills',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: 480,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            Text(widget.resource.name ?? 'Resource'),
                            if (canEdit) ...[
                              TextField(
                                onChanged: (value) => setState(
                                  () => _query = value.trim().toLowerCase(),
                                ),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  labelText: 'Search skills',
                                ),
                              ),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  DropdownButton<SkillCategory>(
                                    value: _category,
                                    hint: const Text('All categories'),
                                    items: [
                                      const DropdownMenuItem(
                                        child: Text('All categories'),
                                      ),
                                      for (final value in SkillCategory.values)
                                        DropdownMenuItem(
                                          value: value,
                                          child: Text(
                                            value.name.replaceAll('_', ' '),
                                          ),
                                        ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _category = value),
                                  ),
                                  DropdownButton<DifficultyState>(
                                    value: _difficulty,
                                    hint: const Text('All difficulties'),
                                    items: [
                                      const DropdownMenuItem(
                                        child: Text('All difficulties'),
                                      ),
                                      for (final value
                                          in DifficultyState.values)
                                        if (value != DifficultyState.All)
                                          DropdownMenuItem(
                                            value: value,
                                            child: Text(value.name),
                                          ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _difficulty = value),
                                  ),
                                ],
                              ),
                              if (skills.isEmpty)
                                const Text(
                                  'The skill catalogue is unavailable.',
                                )
                              else if (matches.isEmpty)
                                const Text('No skills match these filters.'),
                              for (final skill in matches)
                                CheckboxListTile(
                                  key: ValueKey('resource-skill-${skill.id}'),
                                  contentPadding: EdgeInsets.zero,
                                  value: _selected.contains(skill.id),
                                  title: Text(skill.skillName),
                                  secondary: _original.contains(skill.id)
                                      ? IconButton(
                                          onPressed: _saving
                                              ? null
                                              : () => _openSkill(skill),
                                          icon: const Icon(Icons.open_in_new),
                                          tooltip: 'Open ${skill.skillName}',
                                        )
                                      : null,
                                  subtitle: Text(_skillDetails(skill)),
                                  onChanged: _saving
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected ?? false) {
                                              _selected.add(skill.id);
                                            } else {
                                              _selected.remove(skill.id);
                                            }
                                          });
                                        },
                                ),
                            ] else ...[
                              if (_original.isEmpty)
                                const Text('No associated skills yet.'),
                              for (final skill in skills)
                                if (_original.contains(skill.id))
                                  TextButton(
                                    onPressed: () => _openSkill(skill),
                                    child: Text(skill.skillName),
                                  ),
                              const Text(
                                'Resource owners and editors can change '
                                'skill links.',
                              ),
                            ],
                            if (_error != null)
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      if (canEdit) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: changed && !_saving ? _save : null,
                          child: Text(_saving ? 'Saving…' : 'Update'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
