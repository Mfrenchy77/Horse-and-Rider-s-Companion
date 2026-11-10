import 'dart:async';
import 'dart:collection';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

Future<void> showSkillPrerequisiteDiagramDialog({
  required BuildContext context,
  required Skill skill,
  required List<Skill?> allSkills,
  required ValueChanged<Skill> onSkillSelected,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Prerequisite Map • ${skill.skillName}'),
            actions: [
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).maybePop(),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SkillPrerequisiteDiagram(
                skill: skill,
                allSkills: allSkills,
                onSkillSelected: (selected) {
                  Navigator.of(ctx).maybePop();
                  onSkillSelected(selected);
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Draws an interactive diagram showing how a [skill] is connected to
/// its prerequisite skills. Tapping any node will trigger [onSkillSelected].
class SkillPrerequisiteDiagram extends StatefulWidget {
  const SkillPrerequisiteDiagram({
    super.key,
    required this.skill,
    required this.allSkills,
    required this.onSkillSelected,
    this.skillLevelsById = const {},
    this.showDescription = true,
    this.showLegend = true,
  });

  /// Skill currently being viewed.
  final Skill skill;

  /// All skills available in the skill tree.
  final List<Skill?> allSkills;

  /// Callback fired when the user taps any skill node.
  final ValueChanged<Skill> onSkillSelected;

  /// Map of skill id to the viewer's progress for that skill.
  final Map<String, SkillLevel> skillLevelsById;

  /// Whether to show helper text above the diagram.
  final bool showDescription;

  /// Whether to show the legend below the diagram.
  final bool showLegend;

  @override
  State<SkillPrerequisiteDiagram> createState() =>
      _SkillPrerequisiteDiagramState();
}

class _SkillPrerequisiteDiagramState extends State<SkillPrerequisiteDiagram> {
  late final TransformationController _controller;
  double _currentScale = 1;
  Offset _currentPan = Offset.zero;
  bool _hasAutoCentered = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diagramData = SkillPrerequisiteGraphBuilder(
      skill: widget.skill,
      allSkills: widget.allSkills,
      includeDependents: true,
    ).build();
    final skillLevelsById = widget.skillLevelsById;

    if (!diagramData.hasDiagram) {
      return const _DiagramPlaceholder();
    }

    final graph = Graph()..isTree = false;
    final nodes = <String, Node>{};

    diagramData.skillById.forEach((id, value) {
      final node = Node.Id(id);
      nodes[id] = node;
      graph.addNode(node);
    });

    for (final edge in diagramData.edges) {
      final parent = nodes[edge.parentId];
      final child = nodes[edge.childId];
      if (parent != null && child != null) {
        graph.addEdge(parent, child);
      }
    }

    final config = SugiyamaConfiguration()
      ..nodeSeparation = 48
      ..levelSeparation = 140
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDescription) ...[
          Text(
            'Explore how this skill connects back to foundational skills '
            'and forward to future unlocks.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Card(
            clipBehavior: Clip.hardEdge,
            elevation: 3,
            child: Stack(
              children: [
                Listener(
                  onPointerSignal: (event) =>
                      _handlePointerSignal(context, event),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (!_hasAutoCentered) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _centerGraph(constraints.biggest);
                        });
                      }
                      return InteractiveViewer(
                        transformationController: _controller,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(160),
                        minScale: 0.5,
                        maxScale: 2.4,
                        scaleEnabled: false,
                        onInteractionEnd: (_) => _captureCurrentTransform(),
                        child: GraphView(
                          graph: graph,
                          algorithm: SugiyamaAlgorithm(config),
                          paint: Paint()
                            ..color = Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.6)
                            ..strokeWidth = 1.2
                            ..style = PaintingStyle.stroke,
                          builder: (node) {
                            final skillId = node.key!.value as String;
                            final nodeSkill = diagramData.skillById[skillId]!;
                            final isBase =
                                diagramData.baseSkillIds.contains(skillId);
                            final isSelected = skillId == widget.skill.id;
                            final isDirectPrerequisite = diagramData
                                .directPrerequisiteIds
                                .contains(skillId);
                            final isDescendant = diagramData.descendantSkillIds
                                .contains(skillId);
                            final descendantDepth =
                                diagramData.downstreamDepthBySkillId[skillId];
                            final depth =
                                diagramData.depthBySkillId[skillId] ?? 0;
                            final skillLevel = skillLevelsById[skillId];
                            return _SkillDiagramNode(
                              skill: nodeSkill,
                              depth: depth,
                              isBase: isBase,
                              isSelected: isSelected,
                              isDirectPrerequisite: isDirectPrerequisite,
                              isDescendant: isDescendant,
                              descendantDepth: descendantDepth,
                              skillLevel: skillLevel,
                              onTap: () => widget.onSkillSelected(nodeSkill),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _DiagramControls(
                    onZoomIn: () => _zoom(0.15),
                    onZoomOut: () => _zoom(-0.15),
                    onReset: _resetView,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 12),
          const _DiagramLegend(),
        ],
      ],
    );
  }

  void _zoom(double delta) {
    setState(() {
      _currentScale = (_currentScale + delta).clamp(0.5, 2.4);
      _controller.value = _composeMatrix();
    });
  }

  void _resetView() {
    setState(() {
      _currentScale = 1;
      _currentPan = Offset.zero;
      _controller.value = _composeMatrix();
    });
  }

  void _captureCurrentTransform() {
    final matrix = _controller.value;
    _currentScale = matrix.getMaxScaleOnAxis();
    _currentPan = Offset(matrix.row0[3], matrix.row1[3]);
  }

  Matrix4 _composeMatrix() {
    return Matrix4.identity()
      ..setEntry(0, 0, _currentScale)
      ..setEntry(1, 1, _currentScale)
      ..setEntry(2, 2, _currentScale)
      ..setEntry(0, 3, _currentPan.dx)
      ..setEntry(1, 3, _currentPan.dy);
  }

  void _handlePointerSignal(BuildContext context, PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver
        .register(event, (PointerSignalEvent _) {});
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position.hasPixels) {
      final target = (scrollable.position.pixels + event.scrollDelta.dy).clamp(
        scrollable.position.minScrollExtent,
        scrollable.position.maxScrollExtent,
      );
      scrollable.position.jumpTo(target);
      return;
    }
  }

  void _centerGraph(Size viewport) {
    if (!mounted || viewport.isEmpty) return;
    final matrix = Matrix4.identity()
      ..setEntry(0, 3, viewport.width * 0.15)
      ..setEntry(1, 3, viewport.height * 0.05);
    _controller.value = matrix;
    _currentPan = Offset(matrix.row0[3], matrix.row1[3]);
    _currentScale = 1;
    _hasAutoCentered = true;
  }
}

/// Lightweight placeholder rendered when there are no prerequisites to show.
class _DiagramPlaceholder extends StatelessWidget {
  const _DiagramPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prerequisite Map',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'There are no prerequisites to visualize for this skill yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SkillDiagramNode extends StatelessWidget {
  const _SkillDiagramNode({
    required this.skill,
    required this.depth,
    required this.isBase,
    required this.isSelected,
    required this.isDirectPrerequisite,
    required this.isDescendant,
    this.descendantDepth,
    this.skillLevel,
    required this.onTap,
  });

  final Skill skill;
  final int depth;
  final bool isBase;
  final bool isSelected;
  final bool isDirectPrerequisite;
  final bool isDescendant;
  final int? descendantDepth;
  final SkillLevel? skillLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightDescendant = isDescendant && !isSelected;
    final levelState = skillLevel?.levelState ?? LevelState.NO_PROGRESS;
    final hasProgress =
        skillLevel != null && levelState != LevelState.NO_PROGRESS;
    final statusColor = _statusColor(colorScheme, skillLevel);
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : isBase
            ? colorScheme.secondaryContainer
            : highlightDescendant
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest;
    final gradient = _learningGradient(skillLevel, colorScheme);
    final borderColor = isSelected
        ? colorScheme.primary
        : isDirectPrerequisite
            ? colorScheme.tertiary
            : hasProgress
                ? statusColor
                : highlightDescendant
                    ? colorScheme.primary
                    : isBase
                        ? colorScheme.secondary
                        : colorScheme.outlineVariant;
    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : highlightDescendant
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;
    final levelLabel = isSelected
        ? 'Current Skill'
        : highlightDescendant
            ? 'Future Level ${(descendantDepth ?? 0) + 1}'
            : 'Level ${depth + 1}';
    final statusPill = hasProgress && skillLevel != null
        ? _SkillStatusPill(skillLevel: skillLevel!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 4 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  levelLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (statusPill != null) statusPill,
              ],
            ),
            const SizedBox(height: 4),
            Text(
              skill.skillName,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            _DifficultyPill(difficulty: skill.difficulty, textColor: textColor),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(ColorScheme colorScheme, SkillLevel? skillLevel) {
  if (skillLevel == null) {
    return colorScheme.outlineVariant;
  }
  switch (skillLevel.levelState) {
    case LevelState.LEARNING:
      return skillLevel.verified ? Colors.amber : colorScheme.primary;
    case LevelState.PROFICIENT:
      return colorScheme.tertiary;
    case LevelState.VERIFIED:
      return Colors.amber;
    case LevelState.NO_PROGRESS:
      return colorScheme.outlineVariant;
  }
}

Gradient? _learningGradient(
  SkillLevel? skillLevel,
  ColorScheme colorScheme,
) {
  if (skillLevel == null || skillLevel.levelState != LevelState.LEARNING) {
    return null;
  }
  final fillColor =
      skillLevel.verified ? Colors.amber : colorScheme.primaryContainer;
  return LinearGradient(
    stops: const [0.35, 0.65],
    colors: [fillColor.withValues(alpha: 0.85), Colors.transparent],
  );
}

String? _statusLabel(SkillLevel skillLevel) {
  switch (skillLevel.levelState) {
    case LevelState.NO_PROGRESS:
      return null;
    case LevelState.LEARNING:
      return 'Learning';
    case LevelState.PROFICIENT:
      return 'Proficient';
    case LevelState.VERIFIED:
      return 'Verified';
  }
}

class _SkillStatusPill extends StatelessWidget {
  const _SkillStatusPill({required this.skillLevel});

  final SkillLevel skillLevel;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(skillLevel);
    if (label == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final color = _statusColor(colors, skillLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DiagramControls extends StatelessWidget {
  const _DiagramControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in),
            onPressed: onZoomIn,
          ),
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.zoom_out),
            onPressed: onZoomOut,
          ),
          IconButton(
            tooltip: 'Reset view',
            icon: const Icon(Icons.refresh),
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({
    required this.difficulty,
    required this.textColor,
  });

  final DifficultyState difficulty;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = colors.surface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Text(
        difficulty.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DiagramLegend extends StatelessWidget {
  const _DiagramLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(label: 'Base skill', colorType: _LegendColorType.base),
        _LegendItem(
          label: 'Direct prerequisite',
          colorType: _LegendColorType.directPrereq,
        ),
        _LegendItem(
          label: 'Unlockable skill',
          colorType: _LegendColorType.dependent,
        ),
        _LegendItem(
          label: 'Selected skill',
          colorType: _LegendColorType.selected,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.colorType,
  });

  final String label;
  final _LegendColorType colorType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (colorType) {
      _LegendColorType.base => colorScheme.secondary,
      _LegendColorType.directPrereq => colorScheme.tertiary,
      _LegendColorType.dependent => colorScheme.primary,
      _LegendColorType.selected => colorScheme.primaryContainer,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

enum _LegendColorType { base, directPrereq, dependent, selected }

/// Immutable graph representation returned by [SkillPrerequisiteGraphBuilder].
class SkillPrerequisiteGraphData {
  SkillPrerequisiteGraphData({
    required Map<String, Skill> skillById,
    required Set<SkillPrerequisiteEdge> edges,
    required Set<String> baseSkillIds,
    required Set<String> directPrerequisiteIds,
    required Map<String, int> depthBySkillId,
    required Set<String> descendantSkillIds,
    required Map<String, int> downstreamDepthBySkillId,
  })  : skillById = UnmodifiableMapView(skillById),
        edges = UnmodifiableSetView(edges),
        baseSkillIds = UnmodifiableSetView(baseSkillIds),
        directPrerequisiteIds = UnmodifiableSetView(directPrerequisiteIds),
        depthBySkillId = UnmodifiableMapView(depthBySkillId),
        descendantSkillIds = UnmodifiableSetView(descendantSkillIds),
        downstreamDepthBySkillId =
            UnmodifiableMapView(downstreamDepthBySkillId);

  /// Skills participating in the graph keyed by id.
  final Map<String, Skill> skillById;

  /// Directed edges from prerequisite -> dependent skill.
  final Set<SkillPrerequisiteEdge> edges;

  /// Skills that do not have prerequisites within the current graph.
  final Set<String> baseSkillIds;

  /// Direct prerequisites for the selected skill.
  final Set<String> directPrerequisiteIds;

  /// Depth of each skill within the ancestor tree (0 = base skill).
  final Map<String, int> depthBySkillId;

  /// Skills that unlock after the selected skill.
  final Set<String> descendantSkillIds;

  /// Steps away from the selected skill within the dependent tree.
  final Map<String, int> downstreamDepthBySkillId;

  /// Whether there is anything to visualize beyond the selected skill itself.
  bool get hasDiagram => skillById.length > 1 && edges.isNotEmpty;
}

/// Builder that extracts prerequisite relationships for the provided [skill].
class SkillPrerequisiteGraphBuilder {
  SkillPrerequisiteGraphBuilder({
    required this.skill,
    required this.allSkills,
    this.includeDependents = false,
  });

  final Skill skill;
  final List<Skill?> allSkills;
  final bool includeDependents;

  SkillPrerequisiteGraphData build() {
    final skillMap = {
      for (final entry in allSkills.whereType<Skill>()) entry.id: entry,
    };

    final dependentsBySkillId = <String, List<String>>{};
    for (final entry in skillMap.entries) {
      for (final prereq in entry.value.prerequisites) {
        dependentsBySkillId.putIfAbsent(prereq, () => []).add(entry.key);
      }
    }

    final ancestorIds = <String>{};
    _collectAncestors(skill.id, skillMap, ancestorIds);

    final descendantIds = <String>{};
    if (includeDependents) {
      _collectDescendants(skill.id, dependentsBySkillId, descendantIds);
    }

    final relevantIds = <String>{...ancestorIds, ...descendantIds};
    final relevantSkills = {
      for (final id in relevantIds)
        if (skillMap[id] != null) id: skillMap[id]!,
    };

    final edges = <SkillPrerequisiteEdge>{};
    final baseIds = <String>{};
    final directPrereqIds = <String>{};

    final adjacency = <String, List<String>>{};

    for (final entry in relevantSkills.entries) {
      final current = entry.value;
      final filteredPrereqs =
          current.prerequisites.where(relevantSkills.containsKey).toList();

      if (current.prerequisites.isEmpty) {
        baseIds.add(entry.key);
      } else {
        for (final prereqId in filteredPrereqs) {
          edges.add(SkillPrerequisiteEdge(prereqId, entry.key));
          adjacency.putIfAbsent(prereqId, () => []).add(entry.key);
          if (entry.key == skill.id) {
            directPrereqIds.add(prereqId);
          }
        }
      }
    }

    final depthBySkillId = _calculateDepthMap(
      baseIds: baseIds,
      adjacency: adjacency,
    );

    final downstreamDepthBySkillId = includeDependents
        ? _calculateDownstreamDepths(
            rootId: skill.id,
            dependents: dependentsBySkillId,
            allowedIds: relevantIds,
          )
        : <String, int>{};

    return SkillPrerequisiteGraphData(
      skillById: relevantSkills,
      edges: edges,
      baseSkillIds: baseIds,
      directPrerequisiteIds: directPrereqIds,
      depthBySkillId: depthBySkillId,
      descendantSkillIds: descendantIds,
      downstreamDepthBySkillId: downstreamDepthBySkillId,
    );
  }

  Map<String, int> _calculateDepthMap({
    required Set<String> baseIds,
    required Map<String, List<String>> adjacency,
  }) {
    final depth = <String, int>{};
    final queue = Queue<MapEntry<String, int>>();
    for (final base in baseIds) {
      queue.add(MapEntry(base, 0));
    }
    while (queue.isNotEmpty) {
      final entry = queue.removeFirst();
      final existing = depth[entry.key];
      if (existing != null && existing <= entry.value) continue;
      depth[entry.key] = entry.value;
      for (final child in adjacency[entry.key] ?? const <String>[]) {
        queue.add(MapEntry(child, entry.value + 1));
      }
    }
    return depth;
  }

  void _collectAncestors(
    String? skillId,
    Map<String, Skill> skillMap,
    Set<String> accumulator,
  ) {
    if (skillId == null) return;
    if (accumulator.contains(skillId)) return;
    final current = skillMap[skillId];
    if (current == null) {
      accumulator.add(skillId); // Track to avoid reprocessing.
      return;
    }
    accumulator.add(skillId);
    for (final prereqId in current.prerequisites) {
      _collectAncestors(prereqId, skillMap, accumulator);
    }
  }

  void _collectDescendants(
    String skillId,
    Map<String, List<String>> dependentsBySkillId,
    Set<String> accumulator,
  ) {
    for (final dependentId
        in dependentsBySkillId[skillId] ?? const <String>[]) {
      if (accumulator.add(dependentId)) {
        _collectDescendants(dependentId, dependentsBySkillId, accumulator);
      }
    }
  }

  Map<String, int> _calculateDownstreamDepths({
    required String rootId,
    required Map<String, List<String>> dependents,
    required Set<String> allowedIds,
  }) {
    final depths = <String, int>{rootId: 0};
    final queue = Queue<String>()..add(rootId);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentDepth = depths[current] ?? 0;
      for (final child in dependents[current] ?? const <String>[]) {
        if (!allowedIds.contains(child)) continue;
        final nextDepth = currentDepth + 1;
        final existing = depths[child];
        if (existing == null || existing > nextDepth) {
          depths[child] = nextDepth;
          queue.add(child);
        }
      }
    }

    return depths;
  }
}

/// Directed relationship between a prerequisite (parent) skill and the skill
/// that depends on it.
@immutable
class SkillPrerequisiteEdge {
  const SkillPrerequisiteEdge(this.parentId, this.childId);

  final String parentId;
  final String childId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillPrerequisiteEdge &&
        other.parentId == parentId &&
        other.childId == childId;
  }

  @override
  int get hashCode => Object.hash(parentId, childId);
}
