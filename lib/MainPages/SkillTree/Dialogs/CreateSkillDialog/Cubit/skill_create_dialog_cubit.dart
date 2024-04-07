// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'skill_create_dialog_state.dart';

// TODO():This needs to be reworked
class CreateSkillDialogCubit extends Cubit<CreateSkillDialogState> {
  CreateSkillDialogCubit({
    required Skill? skill,
    required bool isForRider,
    required RiderProfile usersProfile,
    required SkillTreeRepository skillsRepository,
  })  : _skillsRepository = skillsRepository,
        super(const CreateSkillDialogState()) {
    emit(
      state.copyWith(
        skill: skill,
        isForRider: isForRider,
        usersProfile: usersProfile,
      ),
    );
  }

  final SkillTreeRepository _skillsRepository;

  /// Called when the new Skill Name changes
  void skillNameChanged(String value) {
    final name = SingleWord.dirty(value);
    emit(state.copyWith(name: name, status: Formz.validate([name])));
  }

  /// Called when the new Skill Description changes
  void skillDescriptionChanged(String value) {
    final description = SingleWord.dirty(value);
    emit(
      state.copyWith(
        description: description,
        status: Formz.validate([description]),
      ),
    );
  }

  /// Called when the new Skill Learning Description changes
  void skillLearningDescriptionChanged(String value) {
    final learningDescription = SingleWord.dirty(value);
    emit(
      state.copyWith(
        learningDescription: learningDescription,
        status: Formz.validate([learningDescription]),
      ),
    );
  }

  /// Called when the new Skill Proficient Description changes
  void skillProficientDescriptionChanged(String value) {
    final proficientDescription = SingleWord.dirty(value);
    emit(
      state.copyWith(
        proficientDescription: proficientDescription,
        status: Formz.validate([proficientDescription]),
      ),
    );
  }

  /// Called when the new Skill Difficulty changes
  void skillDifficultyChanged(DifficultyState value) {
    emit(
      state.copyWith(
        difficulty: value,
      ),
    );
  }
// create a list of subcategories and a list of
// subcategories that the skill is in

  // void _setTheSubCategoryList() {
  //   if (_skill != null) {
  //     //  get the subcategories that the skill is in
  //     if (state.allSubCategories != null) {
  //       final subCategories = _allSubCategories!
  //           .where((element) => element!.skills.contains(_skill!.id))
  //           .toList();

  //       emit(
  //         state.copyWith(
  //           difficulty: _skill?.difficulty ?? DifficultyState.introductory,
  //           subCategoryList: subCategories,
  //         ),
  //       );
  //     } else {
  //       debugPrint('No SubCategories');
  //       emit(
  //         state.copyWith(
  //           subCategoryList: [],
  //         ),
  //       );
  //     }
  //   } else {
  //     debugPrint('No Skill');
  //   }
  // }

// user selects a subcategory to add to the skillid to its skills list
  Future<void> updateSubCategoryList({required SubCategory subCategory}) async {
    debugPrint('No more SubCategories');
  }

  ///   Called when creating new Skill
  Future<void> createSkill(int position) async {
    // final subCategories = state.subCategoryList ?? [];
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );

    final skill = Skill(
      id: ViewUtils.createId(),
      position: position,
      rider: state.isForRider,
      difficulty: state.difficulty,
      skillName: state.name.value,
      lastEditDate: DateTime.now(),
      description: state.description.value,
      lastEditBy: state.usersProfile?.email,
      learningDescription: state.learningDescription.value,
      proficientDescription: state.proficientDescription.value,
    );

    try {
      await _skillsRepository.createOrEditSkill(
        skill: skill,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(status: FormzStatus.submissionFailure),
      );
    }
  }

  Future<void> editSkill({Skill? editedSkill}) async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );

    final skill = Skill(
      lastEditDate: DateTime.now(),
      difficulty: state.difficulty,
      id: editedSkill?.id as String,
      rider: editedSkill?.rider ?? true,
      lastEditBy: state.usersProfile?.email,
      position: editedSkill?.position as int,
      skillName: state.name.value.isNotEmpty
          ? state.name.value
          : editedSkill?.skillName as String,
      description: state.description.value.isNotEmpty
          ? state.description.value
          : editedSkill?.description as String,
      learningDescription: state.learningDescription.value.isNotEmpty
          ? state.learningDescription.value
          : editedSkill?.learningDescription as String,
      proficientDescription: state.proficientDescription.value.isNotEmpty
          ? state.proficientDescription.value
          : editedSkill?.proficientDescription as String,
    );

    try {
      await _skillsRepository.createOrEditSkill(
        skill: skill,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
        ),
      );
    }
  }

  void deleteSkill({required Skill skill}) {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );

    try {
      _skillsRepository.deleteSkill(
        skill: skill,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(status: FormzStatus.submissionFailure),
      );
    }
  }

  void resetError() {
    emit(state.copyWith(updateSubCategoryList: UpdateSubCategoryList.inital));
  }
}
