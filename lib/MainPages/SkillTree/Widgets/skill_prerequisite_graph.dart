part of 'skill_prerequisite_diagram.dart';

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
