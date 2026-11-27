import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/skill_tree_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/featured_category_navigation.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/classic_blue_gray.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class SkillTreeV2Header extends StatefulWidget {
  const SkillTreeV2Header({
    super.key,
    required this.state,
    required this.hasHorseProfile,
    required this.profileLabel,
    required this.onSelectRealm,
    required this.onSelectViewMode,
    required this.onSearchChanged,
    this.showCategoryNavigation = true,
  });

  final SkillTreeV2State state;
  final bool hasHorseProfile;
  final String? profileLabel;
  final ValueChanged<SkillCategory> onSelectRealm;
  final ValueChanged<SkillTreeV2ViewMode> onSelectViewMode;
  final ValueChanged<String> onSearchChanged;
  final bool showCategoryNavigation;

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
    final isHorse = state.subject == SkillSubject.horse;
    final hasProfileLabel =
        widget.profileLabel != null && widget.profileLabel!.trim().isNotEmpty;
    final contextTitle = isHorse
        ? (hasProfileLabel
              ? 'Horse Skills · ${widget.profileLabel}'
              : 'Horse Skills')
        : (hasProfileLabel
              ? 'Rider Skills · ${widget.profileLabel}'
              : 'Rider Skills');

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
            ValueListenableBuilder<bool>(
              valueListenable: SkillTreeSpotlightTour.isTourActive,
              builder: (context, tourActive, child) => KeyedSubtree(
                key: tourActive ? SkillTreeSpotlightTour.subjectKey : null,
                child: child!,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHorse
                        ? HorseAndRiderIcons.horseIcon
                        : Icons.person_outline,
                    size: 20,
                    color: AppTokens.accentColor(context),
                  ),
                  const SizedBox(width: AppTokens.spaceXs),
                  Flexible(
                    child: Text(
                      contextTitle,
                      key: const Key('skillTreeV2ContextTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Equestrian Dictionary',
              onPressed: () => context.push('/Dictionary'),
              icon: const Icon(Icons.menu_book_outlined),
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
        if (isHorse && !widget.hasHorseProfile)
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
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: AppTokens.spaceSm),
                Expanded(
                  child: Text(
                    'No horse profile selected. Select a horse profile to '
                    'record Horse progress.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        if (state.viewMode == SkillTreeV2ViewMode.browse &&
            widget.showCategoryNavigation) ...[
          ValueListenableBuilder<bool>(
            valueListenable: SkillTreeSpotlightTour.isTourActive,
            builder: (context, tourActive, child) => KeyedSubtree(
              key: tourActive ? SkillTreeSpotlightTour.categoriesKey : null,
              child: child!,
            ),
            child: FeaturedCategoryNavigation(
              subject: state.subject,
              availableRealms: state.availableRealms,
              selectedRealm: state.realm,
              familyCountsByRealm: {
                for (final realm in state.availableRealms)
                  realm: state.families
                      .where(
                        (f) => f.subject == state.subject && f.realm == realm,
                      )
                      .length,
              },
              isSearching: state.searchQuery.trim().isNotEmpty,
              onSelectRealm: widget.onSelectRealm,
            ),
          ),
          TextField(
            key: const Key('skillTreeV2SearchField'),
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? AppTokens.midnightInputFill
                  : ClassicBlueGray.surface.withValues(alpha: 0.82),
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
