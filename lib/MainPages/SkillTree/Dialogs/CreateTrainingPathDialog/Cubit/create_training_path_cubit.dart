import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'create_training_path_state.dart';

class CreateTrainingPathCubit extends Cubit<CreateTrainingPathState> {
  CreateTrainingPathCubit({
    required bool isForRider,
    required List<Skill?> allSkills,
    required RiderProfile usersProfile,
    required TrainingPath? trainingPath,
    required SkillTreeRepository trainingPathRepository,
  })  : _trainingPathRepository = trainingPathRepository,
        super(const CreateTrainingPathState()) {
    emit(
      state.copyWith(
        skillNodes: trainingPath?.skillNodes,
        allSkills: allSkills,
        isForRider: isForRider,
        usersProfile: usersProfile,
        trainingPath: trainingPath,
      ),
    );
  }

  ///   The TrainingPath that is being edited

  final SkillTreeRepository _trainingPathRepository;

  void trainingPathNameChanged({required String name}) {
    final trainingPathName = SingleWord.dirty(name);

    emit(
      state.copyWith(name: trainingPathName),
    );
  }

  void trainingPathDescriptionChanged({required String description}) {
    final trainingPathDescription = SingleWord.dirty(description);

    emit(
      state.copyWith(description: trainingPathDescription),
    );
  }

  ///   Toggles whether the training path is for a horse or a rider
  void isForHorse() {
    emit(state.copyWith(isForRider: !state.isForRider));
  }

  /// Returns only the skills for horse or rider
  List<Skill?> skillsForHorseOrRider() {
    return state.allSkills
        .where((element) => element?.rider == state.isForRider)
        .toList();
  }

  void isSearch() {
    debugPrint('All Skills: ${state.allSkills.length}');
    final searchList = skillsForHorseOrRider()
        .map((e) => e?.skillName)
        .toList()
        .where(
          (element) => element?.toLowerCase().contains('') ?? false,
        )
        .toList();

    debugPrint('searchList: $searchList');
    debugPrint('searchList: ${searchList.length}');
    emit(state.copyWith(isSearch: !state.isSearch, searchList: searchList));
  }

  void searchQueryChanged({required String query}) {
    final searchList = state.allSkills
        .map((e) => e?.skillName)
        .toList()
        .where(
          (element) =>
              element?.toLowerCase().contains(query.toLowerCase()) ?? false,
        )
        .toList();
    emit(state.copyWith(searchList: searchList, searchQuery: query));
  }

  void trainingPathSkillsChanged({required String? skillId}) {
    final allSkills = state.allSkills;
    if (skillId != null) {
      if (state.skills.contains(skillId)) {
        final skills = state.skills..remove(skillId);

        emit(state.copyWith(skills: skills));
        return;
      } else {
        final skills = state.skills..add(skillId);
        allSkills.removeWhere((element) => element?.id == skillId);
        emit(state.copyWith(skills: skills));
        return;
      }
    } else {
      debugPrint('Skill id is Null');
    }
  }

  void trainingPathSkillNodesChanged({required SkillNode? skillNode}) {
    final selectedSkills = state.selectedSkills;
    if (skillNode != null) {
      if (state.skillNodes.contains(skillNode)) {
        final skillNodes = state.skillNodes
          ..removeWhere(
            (element) => element?.id == skillNode.id,
          );

        emit(state.copyWith(skillNodes: skillNodes));
        return;
      } else {
        final skillNodes = state.skillNodes
          ..add(
            skillNode,
          );
        selectedSkills
            .removeWhere((element) => element?.skillName == skillNode.name);
        emit(
          state.copyWith(
            skillNodes: skillNodes,
            selectedSkills: selectedSkills,
          ),
        );
        return;
      }
    } else {
      debugPrint('Skill id is Null');
    }
  }

  ///   Called when the user has selected a skill name to add to the
  /// Selected Skills. We want to remove the skill from the list of skills
  /// if the skill is already in the list and add the skill to the list if it
  /// is not in the list
  void skillSelected({required String? skillName}) {
    debugPrint('Skill Selected: $skillName');
    final allSkills = state.allSkills;
    final searchList = state.searchList;
    if (skillName != null) {
      // Create a modifiable copy of the list
      final selectedSkills = List<Skill?>.from(state.selectedSkills);
      final removedSkills = List<Skill?>.from(state.removedSkills);

      if (selectedSkills.any((element) => element?.skillName == skillName)) {
        allSkills.add(
          removedSkills
              .firstWhere((element) => element?.skillName == skillName),
        );
        searchList?.add(skillName);
        removedSkills.removeWhere((element) => element?.skillName == skillName);
        selectedSkills
            .removeWhere((element) => element?.skillName == skillName);
      } else {
        selectedSkills.add(
          allSkills.firstWhere((element) => element?.skillName == skillName),
        );
        removedSkills.add(
          allSkills.firstWhere((element) => element?.skillName == skillName),
        );
        allSkills.removeWhere((element) => element?.skillName == skillName);
        searchList?.remove(skillName);
      }

      emit(
        state.copyWith(
          allSkills: allSkills,
          searchList: searchList,
          removedSkills: removedSkills,
          selectedSkills: selectedSkills,
        ),
      );
    } else {
      debugPrint('Skill id is Null');
    }
  }

  /// add or remove skill node from the list of skill nodes
  /// by name
  void skillNodeSelected({required String skillName}) {
    final skillList = List<String>.from(state.skills);
    debugPrint('Creating Root Skill Node: $skillName');
    final allSkills = List<Skill>.from(state.allSkills);
    final skillNodes = List<SkillNode?>.from(state.skillNodes);
    final removedSkills = List<Skill>.from(state.removedSkills);
    final selectedSkills = List<Skill>.from(state.selectedSkills);

    final newSkillNode = SkillNode(
      position: 0,
      parentId: '',
      name: skillName,
      id: ViewUtils.createId(),
      skillId:
          allSkills.firstWhere((element) => element.skillName == skillName).id,
    );
    // Create a modifiable copy of the list

    if (skillNodes.any((element) => element?.name == skillName)) {
      debugPrint('Removing Skill Node: $skillName');
      skillList.add(skillName);
      allSkills.add(
        removedSkills.firstWhere((element) => element.skillName == skillName),
      );
      removedSkills.removeWhere((element) => element.skillName == skillName);
      skillNodes.removeWhere((element) => element?.name == skillName);
    } else {
      debugPrint('Adding Skill Node: $skillName');
      removedSkills.add(
        selectedSkills.firstWhere((element) => element.skillName == skillName),
      );
      allSkills.removeWhere((element) => element.skillName == skillName);
      skillNodes.add(newSkillNode);
      selectedSkills.removeWhere((element) => element.skillName == skillName);
    }

    emit(
      state.copyWith(
        skills: skillList,
        allSkills: allSkills,
        skillNodes: skillNodes,
        removedSkills: removedSkills,
        selectedSkills: selectedSkills,
      ),
    );
  }

  /// Children of the [skillNode] sorted by position
  List<SkillNode?> childrenOfSkillNode({required SkillNode? skillNode}) {
    final children = <SkillNode?>[];

    for (final node in state.skillNodes) {
      if (node?.parentId == skillNode?.id) {
        children.add(node);
      }
    }

    children.sort((a, b) => a!.position.compareTo(b!.position));
    return children;
  }

  /// Return a list of Strings of the all the skill names for the
  /// Search suggestions
  List<String> skillNames() {
    final skillNames = <String>[];

    for (final skill in state.skills) {
      skillNames.add(skill);
    }

    return skillNames;
  }

  Future<void> createOrEditTrainingPath() async {
    if (state.name.isValid && state.description.isValid) {
      emit(state.copyWith(status: FormStatus.submitting));

      try {
        final trainingPath = TrainingPath(
          name: state.name.value,
          lastEditDate: DateTime.now(),
          skillNodes: state.skillNodes,
          isForRider: state.isForRider,
          lastEditBy: state.usersProfile!.name,
          description: state.description.value,
          id: state.trainingPath?.id ?? ViewUtils.createId(),
          skills: state.skillNodes.map((e) => e?.id).toList(),
          createdAt: state.trainingPath?.createdAt ?? DateTime.now(),
          createdById:
              state.trainingPath?.createdById ?? state.usersProfile!.email,
          createdBy: state.trainingPath?.createdBy ?? state.usersProfile!.name,
        );

        await _trainingPathRepository.createOrEditTrainingPath(
          trainingPath: trainingPath,
        );

        emit(state.copyWith(status: FormStatus.success));
      } on Exception catch (e) {
        emit(state.copyWith(status: FormStatus.failure));
        debugPrint('Exception: $e');
      }
    } else {
      debugPrint('Name or Description is not valid');
    }
  }

  /// Method that handles the creation of a child skill node
  /// and the deletion of a child skill node
  void createOrDeleteChildSkillNode({
    required SkillNode? parentNode,
    required String? skillName,
  }) {
    if (parentNode != null && skillName != null) {
      final newSkillList = List<String>.from(state.skills);
      final newAllSkills = List<Skill>.from(state.allSkills);
      final newSkillNodes = List<SkillNode>.from(state.skillNodes);
      final newRemovedSkills = List<Skill>.from(state.removedSkills);
      final newSelectedSkills = List<Skill>.from(state.selectedSkills);

      if (parentNode.name == skillName) {
        // Remove the node and update the selected skills list
        newSkillNodes.removeWhere((element) => element.name == skillName);
        newSkillList.add(skillName);
        newSelectedSkills.add(
          newAllSkills.firstWhere((element) => element.skillName == skillName),
        );
        newAllSkills.add(
          newRemovedSkills
              .firstWhere((element) => element.skillName == skillName),
        );
        newRemovedSkills
            .removeWhere((element) => element.skillName == skillName);
      } else {
        // Create a new node and update the selected skills list
        newRemovedSkills.add(
          newSelectedSkills
              .firstWhere((element) => element.skillName == skillName),
        );
        newSkillNodes.add(
          SkillNode(
            id: ViewUtils.createId(),
            skillId: newAllSkills
                .firstWhere((element) => element.skillName == skillName)
                .id,
            name: skillName,
            position: newSkillNodes
                .where((element) => element.parentId == parentNode.id)
                .length,
            parentId: parentNode.id,
          ),
        );
        newSelectedSkills
            .removeWhere((element) => element.skillName == skillName);
        newAllSkills.removeWhere((element) => element.skillName == skillName);
      }

      emit(
        state.copyWith(
          skills: newSkillList,
          allSkills: newAllSkills,
          skillNodes: newSkillNodes,
          removedSkills: newRemovedSkills,
          selectedSkills: newSelectedSkills,
        ),
      );
    } else {
      debugPrint('Parent Node or Skill Name is Null');
    }
  }

  /// Delete the training path only if userProfile name matched the createdBy
  /// field of the training path.
  void deleteTrainingPath() {
    if (state.trainingPath?.createdBy == state.usersProfile?.name) {
      _trainingPathRepository.deleteTrainingPath(
        trainingPath: state.trainingPath,
      );
    } else {
      debugPrint('User does not have permission to delete this training path');
    }
  }
}
