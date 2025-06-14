// create_training_path_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'create_training_path_state.dart';

class CreateTrainingPathCubit extends Cubit<CreateTrainingPathState> {
  CreateTrainingPathCubit({
    required SkillTreeRepository trainingPathRepository,
    required List<Skill> allSkills,
    TrainingPath? editing,
    required bool isForRider,
    required RiderProfile user,
  })  : _repo = trainingPathRepository,
        super(
          _buildInitialState(
            allSkills: allSkills,
            editing: editing,
            isForRider: isForRider,
            user: user,
          ),
        );

  final SkillTreeRepository _repo;

  /// Turn your existing skillNodes list + allSkills into the four pieces
  static CreateTrainingPathState _buildInitialState({
    required List<Skill> allSkills,
    TrainingPath? editing,
    required bool isForRider,
    required RiderProfile user,
  }) {
    final nodes = editing?.skillNodes ?? <SkillNode>[];

    // roots = those with null or empty parentId
    final roots = nodes
        .where((n) => (n?.parentId ?? '').isEmpty)
        .cast<SkillNode>()
        .toList();

    // childrenMap: parentId → list of its children
    final childrenMap = <String, List<SkillNode>>{};
    for (final n in nodes.where((n) => (n?.parentId ?? '').isNotEmpty)) {
      childrenMap[n!.parentId!] = (childrenMap[n.parentId!] ?? [])..add(n);
    }

    // available = allSkills minus those skillIds in nodes
    final usedIds = nodes.map((n) => n?.skillId).toSet();
    final avail = allSkills.where((s) => !usedIds.contains(s.id)).toList();

    return CreateTrainingPathState(
      initialAllSkills: List.unmodifiable(allSkills),
      availableSkills: avail,
      rootNodes: roots,
      childNodes: childrenMap,
      isForRider: isForRider,
      name: SingleWord.dirty(editing?.name ?? ''),
      description: SingleWord.dirty(editing?.description ?? ''),
      trainingPath: editing,
      usersProfile: user,
    );
  }

  /// Existing UI calls
  void isSearch() => emit(state.copyWith(isSearch: !state.isSearch));
  void searchQueryChanged({required String query}) =>
      emit(state.copyWith(searchQuery: query));
  void isForHorse() => emit(state.copyWith(isForRider: !state.isForRider));
  void trainingPathNameChanged({required String name}) =>
      emit(state.copyWith(name: SingleWord.dirty(name)));
  void trainingPathDescriptionChanged({required String description}) =>
      emit(state.copyWith(description: SingleWord.dirty(description)));

  /// Called when you drop or tap a skill to make it a ROOT node
  void skillNodeSelected({required String skillName}) {
    // find the Skill
    final skill =
        state.availableSkills.firstWhere((s) => s.skillName == skillName);

    // create a new root‐level SkillNode
    final node = SkillNode(
      id: ViewUtils.createId(),
      name: skillName,
      skillId: skill.id,
      position: state.rootNodes.length,
      parentId: null, // root
    );

    emit(
      state.copyWith(
        availableSkills: List.from(state.availableSkills)..remove(skill),
        rootNodes: List.from(state.rootNodes)..add(node),
      ),
    );
  }

  /// Called when you drop a skill onto a parent chip
  void createOrDeleteChildSkillNode({
    required SkillNode parentNode,
    required String skillName,
  }) {
    final existing = state.childNodes[parentNode.id] ?? [];

    // if it already existed, remove it:
    final matched =
        existing.where((n) => n.name == skillName).toList(growable: false);
    if (matched.isNotEmpty) {
      // just remove that node
      removeNode(matched.first);
      return;
    }

    // otherwise, add it as a new child
    final skill =
        state.availableSkills.firstWhere((s) => s.skillName == skillName);

    final newChild = SkillNode(
      id: ViewUtils.createId(),
      name: skillName,
      skillId: skill.id,
      parentId: parentNode.id,
      position: existing.length,
    );

    final newChildrenMap = Map<String, List<SkillNode>>.from(state.childNodes);
    newChildrenMap[parentNode.id] = [
      ...existing,
      newChild,
    ];

    emit(
      state.copyWith(
        availableSkills: List.from(state.availableSkills)..remove(skill),
        childNodes: newChildrenMap,
      ),
    );
  }

  /// Remove any node (root or child) and return its Skill to the pool
  void removeNode(SkillNode node) {
    // restore the Skill
    final skill =
        state.initialAllSkills.firstWhere((s) => s.id == node.skillId);

    // remove from roots if present
    final newRoots = List.of(state.rootNodes)
      ..removeWhere((n) => n.id == node.id);

    // adjust children map
    final newChildren = Map<String, List<SkillNode>>.from(state.childNodes);
    final pid = node.parentId ?? '';
    if (pid.isEmpty) {
      // removed a root: also drop its subtree if you like
      newChildren.remove(node.id);
    } else {
      final sibs = List.of(newChildren[pid]!)
        ..removeWhere((n) => n.id == node.id);
      newChildren[pid] = sibs;
    }

    emit(
      state.copyWith(
        availableSkills: List.from(state.availableSkills)..add(skill),
        rootNodes: newRoots,
        childNodes: newChildren,
      ),
    );
  }

  ///Error handling
  void resetError() =>
      emit(state.copyWith(error: '', status: FormStatus.initial));
  void setError(String error) =>
      emit(state.copyWith(error: error, status: FormStatus.failure));

  /// Final create/edit call
  Future<void> createOrEditTrainingPath() async {
    if (!state.name.isValid || !state.description.isValid) {
      emit(state.copyWith(status: FormStatus.failure));
      return;
    }
    emit(state.copyWith(status: FormStatus.submitting));

    // flatten roots + all children
    final allNodes = <SkillNode>[
      ...state.rootNodes,
      for (final list in state.childNodes.values) ...list,
    ];

    final tp = TrainingPath(
      id: state.trainingPath?.id ?? ViewUtils.createId(),
      name: state.name.value,
      description: state.description.value,
      isForRider: state.isForRider,
      skillNodes: allNodes,
      skills: allNodes.map((n) => n.id).toList(),
      createdAt: state.trainingPath?.createdAt ?? DateTime.now(),
      createdBy: state.usersProfile!.name,
      createdById: state.usersProfile!.email,
      lastEditBy: state.usersProfile!.name,
      lastEditDate: DateTime.now(),
    );

    try {
      await _repo.createOrEditTrainingPath(trainingPath: tp);
      emit(state.copyWith(status: FormStatus.success));
    } on Exception {
      emit(state.copyWith(status: FormStatus.failure));
    }
  }

  /// Delete the training path only if userProfile name matched the createdBy
  /// field of the training path.
  void deleteTrainingPath() {
    if (state.trainingPath?.createdBy == state.usersProfile?.name) {
      _repo.deleteTrainingPath(
        trainingPath: state.trainingPath,
      );
    } else {
      debugPrint('User does not have permission to delete this training path');
    }
  }
}
