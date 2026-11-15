import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class SkillTreeV2Header extends StatefulWidget {
  const SkillTreeV2Header({
    super.key,
    required this.state,
    required this.hasHorseProfile,
    required this.horseName,
    required this.onSelectSubject,
    required this.onSelectRealm,
    required this.onSelectViewMode,
    required this.onSearchChanged,
  });

  final SkillTreeV2State state;
  final bool hasHorseProfile;
  final String? horseName;
  final ValueChanged<SkillSubject> onSelectSubject;
  final ValueChanged<SkillCategory> onSelectRealm;
  final ValueChanged<SkillTreeV2ViewMode> onSelectViewMode;
  final ValueChanged<String> onSearchChanged;

  @override
  State<SkillTreeV2Header> createState() => _SkillTreeV2HeaderState();
}

class _SkillTreeV2HeaderState extends State<SkillTreeV2Header> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.state.searchQuery,
  );

  @override
  void didUpdateWidget(covariant SkillTreeV2Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceSm,
      children: [
        Wrap(
          spacing: AppTokens.spaceSm,
          runSpacing: AppTokens.spaceSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            SegmentedButton<SkillSubject>(
              key: const Key('skillTreeV2SubjectSelector'),
              segments: const [
                ButtonSegment(
                  value: SkillSubject.rider,
                  icon: Icon(Icons.person_outline),
                  label: Text('Rider'),
                ),
                ButtonSegment(
                  value: SkillSubject.horse,
                  icon: Icon(HorseAndRiderIcons.horseIcon),
                  label: Text('Horse'),
                ),
              ],
              selected: {state.subject},
              onSelectionChanged: (selection) =>
                  widget.onSelectSubject(selection.first),
            ),
            SegmentedButton<SkillTreeV2ViewMode>(
              key: const Key('skillTreeV2ViewModeSelector'),
              segments: const [
                ButtonSegment(
                  value: SkillTreeV2ViewMode.browse,
                  icon: Icon(Icons.account_tree_outlined),
                  label: Text('Explore Skills'),
                ),
                ButtonSegment(
                  value: SkillTreeV2ViewMode.summary,
                  icon: Icon(Icons.insights_outlined),
                  label: Text('My Skills'),
                ),
              ],
              selected: {
                if (state.viewMode == SkillTreeV2ViewMode.browse)
                  SkillTreeV2ViewMode.browse
                else
                  SkillTreeV2ViewMode.summary,
              },
              onSelectionChanged: (selection) =>
                  widget.onSelectViewMode(selection.first),
            ),
          ],
        ),
        if (state.subject == SkillSubject.horse)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMd,
              vertical: AppTokens.spaceSm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  widget.hasHorseProfile
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 18,
                ),
                const SizedBox(width: AppTokens.spaceSm),
                Expanded(
                  child: Text(
                    widget.hasHorseProfile
                        ? 'Tracking Horse abilities for '
                              '${widget.horseName ?? 'selected horse'}.'
                        : 'Browsing Horse curriculum freely. Select or add a '
                              'horse profile when you want to record progress.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        if (state.viewMode == SkillTreeV2ViewMode.browse) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: AppTokens.spaceXs,
              children: [
                for (final realm in state.availableRealms)
                  ChoiceChip(
                    key: Key('skillTreeV2Realm_${realm.name}'),
                    label: Text(realmDisplayLabel(realm)),
                    selected:
                        state.searchQuery.trim().isEmpty &&
                        state.realm == realm,
                    onSelected: (_) => widget.onSelectRealm(realm),
                  ),
              ],
            ),
          ),
          TextField(
            key: const Key('skillTreeV2SearchField'),
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search skills, aliases, or components...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
