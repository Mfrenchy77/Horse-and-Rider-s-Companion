import 'dart:collection';
import 'dart:math' as math;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class SkillCategoryGraphSection extends StatefulWidget {
  const SkillCategoryGraphSection({
    required this.category,
    required this.skills,
    required this.onSkillSelected,
    super.key,
  });

  final SkillCategory category;
  final List<Skill> skills;
  final ValueChanged<Skill> onSkillSelected;

  @override
  State<SkillCategoryGraphSection> createState() =>
      _SkillCategoryGraphSectionState();
}

class _SkillCategoryGraphSectionState extends State<SkillCategoryGraphSection> {
  late final TransformationController _controller;

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
    final data = SkillCategoryGraphBuilder(skills: widget.skills).build();
    final categoryLabel = _categoryLabel(widget.category);
    final icon = _categoryIcon(widget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Intro • Intermediate • Advanced',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!data.hasDiagram)
          _EmptyCategoryPlaceholder(label: categoryLabel)
        else
          _SkillGraphCard(
            data: data,
            controller: _controller,
            onSkillSelected: widget.onSkillSelected,
          ),
      ],
    );
  }
}

class _SkillGraphCard extends StatelessWidget {
  const _SkillGraphCard({
    required this.data,
    required this.controller,
    required this.onSkillSelected,
  });

  final SkillGraphData data;
  final TransformationController controller;
  final ValueChanged<Skill> onSkillSelected;

  @override
  Widget build(BuildContext context) {
    final graph = Graph()..isTree = false;
    final nodes = <String, Node>{};

    data.skillById.forEach((id, value) {
      final node = Node.Id(id);
      nodes[id] = node;
      graph.addNode(node);
    });

    for (final edge in data.edges) {
      final parent = nodes[edge.parentId];
      final child = nodes[edge.childId];
      if (parent != null && child != null) {
        graph.addEdge(parent, child);
      }
    }

    final config = SugiyamaConfiguration()
      ..nodeSeparation = 60
      ..levelSeparation = 170
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    final estimatedHeight = data.estimatedHeight;
    final estimatedWidth = data.estimatedWidth;

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(constraints.maxWidth, estimatedWidth);
          return SizedBox(
            height: estimatedHeight,
            child: InteractiveViewer(
              transformationController: controller,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(120),
              minScale: 0.5,
              maxScale: 2.2,
              child: SizedBox(
                width: width,
                height: estimatedHeight,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: _DifficultyLaneOverlay(),
                    ),
                    GraphView(
                      graph: graph,
                      algorithm: SugiyamaAlgorithm(config),
                      paint: Paint()
                        ..color = Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4)
                        ..strokeWidth = 1.4
                        ..style = PaintingStyle.stroke,
                      builder: (node) {
                        final skillId = node.key?.value as String;
                        final skill = data.skillById[skillId]!;
                        final isBase = data.baseSkillIds.contains(skillId);
                        final depth = data.depthBySkillId[skillId] ?? 0;
                        return _SkillGraphNode(
                          skill: skill,
                          isBase: isBase,
                          depth: depth,
                          onTap: () => onSkillSelected(skill),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SkillGraphLegend extends StatelessWidget {
  const SkillGraphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final legendItems = DifficultyState.values
        .where((difficulty) => difficulty != DifficultyState.All)
        .map(
          (difficulty) => _LegendChip(
            color: _difficultyColor(difficulty, Theme.of(context).colorScheme)
                .withValues(alpha: 0.18),
            label: _difficultyLabel(difficulty),
            borderColor: _difficultyColor(
              difficulty,
              Theme.of(context).colorScheme,
            ),
          ),
        )
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: legendItems,
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.borderColor,
  });

  final Color color;
  final String label;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: borderColor,
            ),
      ),
    );
  }
}

class _SkillGraphNode extends StatelessWidget {
  const _SkillGraphNode({
    required this.skill,
    required this.isBase,
    required this.depth,
    required this.onTap,
  });

  final Skill skill;
  final bool isBase;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final difficultyColor = _difficultyColor(skill.difficulty, colorScheme);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                difficultyColor.withValues(alpha: 0.12),
                difficultyColor.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: difficultyColor.withValues(alpha: 0.6),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 6),
                color: difficultyColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DifficultyPill(
                    difficulty: skill.difficulty,
                    color: difficultyColor,
                  ),
                  Text(
                    'Tier ${depth + 1}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                skill.skillName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (skill.description != null &&
                  skill.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  skill.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              if (isBase)
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: difficultyColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Foundation Skill',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: difficultyColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({required this.difficulty, required this.color});
  final DifficultyState difficulty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _difficultyLabel(difficulty),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DifficultyLaneOverlay extends StatelessWidget {
  const _DifficultyLaneOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lanes = DifficultyState.values
        .where((difficulty) => difficulty != DifficultyState.All)
        .toList();

    return Column(
      children: [
        for (final difficulty in lanes)
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _difficultyColor(difficulty, colorScheme)
                    .withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _difficultyLabel(difficulty),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCategoryPlaceholder extends StatelessWidget {
  const _EmptyCategoryPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        'No $label skills yet. Add a new skill to begin this track.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class SkillGraphData {
  SkillGraphData({
    required this.skillById,
    required this.edges,
    required this.baseSkillIds,
    required this.depthBySkillId,
    required this.nodesPerDepth,
  });

  final Map<String, Skill> skillById;
  final List<SkillGraphEdge> edges;
  final Set<String> baseSkillIds;
  final Map<String, int> depthBySkillId;
  final Map<int, int> nodesPerDepth;

  bool get hasDiagram => skillById.isNotEmpty;

  double get estimatedHeight {
    if (skillById.isEmpty) return 220;
    final maxDepth = depthBySkillId.values.fold<int>(0, math.max);
    return math.max(320, (maxDepth + 1) * 180).toDouble();
  }

  double get estimatedWidth {
    if (skillById.isEmpty) return 320;
    final widestLayer = nodesPerDepth.values.fold<int>(1, math.max);
    return (widestLayer * 240).toDouble();
  }
}

class SkillGraphEdge {
  SkillGraphEdge({required this.parentId, required this.childId});

  final String parentId;
  final String childId;
}

class SkillCategoryGraphBuilder {
  SkillCategoryGraphBuilder({required this.skills});

  final List<Skill> skills;

  SkillGraphData build() {
    final nonNullSkills = skills;
    final skillById = <String, Skill>{
      for (final skill in nonNullSkills) skill.id: skill,
    };

    if (skillById.isEmpty) {
      return SkillGraphData(
        skillById: skillById,
        edges: const <SkillGraphEdge>[],
        baseSkillIds: const <String>{},
        depthBySkillId: const <String, int>{},
        nodesPerDepth: const <int, int>{},
      );
    }

    final edges = <SkillGraphEdge>[];
    final incomingCounts = <String, int>{
      for (final skill in nonNullSkills) skill.id: 0,
    };
    final childrenByParent = <String, List<String>>{};

    for (final skill in nonNullSkills) {
      final localPrereqs = skill.prerequisites
          .where(skillById.containsKey)
          .toList(growable: false);

      for (final prereq in localPrereqs) {
        edges.add(SkillGraphEdge(parentId: prereq, childId: skill.id));
        incomingCounts[skill.id] = (incomingCounts[skill.id] ?? 0) + 1;
        childrenByParent.putIfAbsent(prereq, _newChildList).add(skill.id);
      }
    }

    final baseSkills = incomingCounts.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toSet();

    final depthBySkillId = _calculateDepths(
      baseSkills: baseSkills,
      childrenByParent: childrenByParent,
      skillById: skillById,
    );

    final nodesPerDepth = <int, int>{};
    depthBySkillId.forEach((_, depth) {
      nodesPerDepth[depth] = (nodesPerDepth[depth] ?? 0) + 1;
    });

    return SkillGraphData(
      skillById: skillById,
      edges: edges,
      baseSkillIds: baseSkills,
      depthBySkillId: depthBySkillId,
      nodesPerDepth: nodesPerDepth,
    );
  }

  Map<String, int> _calculateDepths({
    required Set<String> baseSkills,
    required Map<String, List<String>> childrenByParent,
    required Map<String, Skill> skillById,
  }) {
    final depthBySkillId = <String, int>{};
    final queue = Queue<String>();
    final difficultyFloor = {
      DifficultyState.Introductory: 0,
      DifficultyState.Intermediate: 1,
      DifficultyState.Advanced: 2,
      DifficultyState.All: 0,
    };

    if (baseSkills.isEmpty) {
      baseSkills.addAll(skillById.keys);
    }

    for (final id in baseSkills) {
      final difficulty =
          skillById[id]?.difficulty ?? DifficultyState.Introductory;
      depthBySkillId[id] = difficultyFloor[difficulty] ?? 0;
      queue.add(id);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentDepth = depthBySkillId[current] ?? 0;
      for (final child in childrenByParent[current] ?? const <String>[]) {
        final proposedDepth = currentDepth + 1;
        final difficultyDepth =
            difficultyFloor[skillById[child]?.difficulty] ?? proposedDepth;
        final targetDepth = math.max(proposedDepth, difficultyDepth);
        if (targetDepth > (depthBySkillId[child] ?? -1)) {
          depthBySkillId[child] = targetDepth;
          queue.add(child);
        }
      }
    }

    return depthBySkillId;
  }
}

List<String> _newChildList() => <String>[];

IconData _categoryIcon(SkillCategory category) {
  switch (category) {
    case SkillCategory.Mounted:
      return Icons.directions_run;
    case SkillCategory.In_Hand:
      return Icons.pan_tool;
    case SkillCategory.Husbandry:
      return Icons.eco;
    case SkillCategory.Other:
      return Icons.auto_fix_high;
  }
}

String _categoryLabel(SkillCategory category) {
  switch (category) {
    case SkillCategory.Mounted:
      return 'Mounted skills';
    case SkillCategory.In_Hand:
      return 'In-hand skills';
    case SkillCategory.Husbandry:
      return 'Husbandry skills';
    case SkillCategory.Other:
      return 'Additional skills';
  }
}

String _difficultyLabel(DifficultyState difficulty) {
  switch (difficulty) {
    case DifficultyState.Introductory:
      return 'Intro';
    case DifficultyState.Intermediate:
      return 'Intermediate';
    case DifficultyState.Advanced:
      return 'Advanced';
    case DifficultyState.All:
      return 'All levels';
  }
}

Color _difficultyColor(DifficultyState difficulty, ColorScheme scheme) {
  switch (difficulty) {
    case DifficultyState.Introductory:
      return scheme.primary;
    case DifficultyState.Intermediate:
      return scheme.tertiary;
    case DifficultyState.Advanced:
      return scheme.error;
    case DifficultyState.All:
      return scheme.primary;
  }
}
