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
    required String? name,
    required bool isForRider,
    //required List<SubCategory?>? allSubCategories,
    required SkillTreeRepository skillsRepository,
  })  : _name = name,
        _skill = skill,
        _isForRider = isForRider,
       // _allSubCategories = allSubCategories,
        _skillsRepository = skillsRepository,
        super(const CreateSkillDialogState()) {
   // emit(state.copyWith(allSubCategories: _allSubCategories));
    //_setTheSubCategoryList();
  }

// this is the skill that is being edited
// null if new skill
  final Skill? _skill;
  final bool _isForRider;
  //
  final String? _name;
  final SkillTreeRepository _skillsRepository;
 // final List<SubCategory?>? _allSubCategories;

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
    // emit(
    //   state.copyWith(
    //     updateSubCategoryList: UpdateSubCategoryList.inProgress,
    //   ),
    // );
    // final subCategories = <SubCategory?>[
    //   ...state.subCategoryList ?? [],
    // ];
    // debugPrint('SubCategoryList: ${subCategories.length}');
    // subCategories.contains(subCategory)
    //     ? subCategories.remove(subCategory)
    //     : subCategories.add(subCategory);

    // try {
    //   await _skillsRepository.createOrEditSubCategory(
    //     subCategory: subCategory,
    //   );
    //   emit(
    //     state.copyWith(
    //       updateSubCategoryList: UpdateSubCategoryList.success,
    //       subCategoryList: subCategories,
    //     ),
    //   );
    // } catch (e) {
    //   debugPrint('Error updateing subcategory: $e');
    //   emit(state.copyWith(updateSubCategoryList: UpdateSubCategoryList.error));
    // }
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
      lastEditBy: _name,
      rider: _isForRider,
      difficulty: state.difficulty,
      skillName: state.name.value,
      lastEditDate: DateTime.now(),
      description: state.description.value,
      learningDescription: state.learningDescription.value,
      proficientDescription: state.proficientDescription.value,
    );

    // //update the subcategories in the SubCategory list with the new skill
    // for (final subCategory in subCategories) {
    //   try {
    //     //if the skill is not in the subcategory add it
    //     if (!subCategory!.skills.contains(skill.id)) {
    //       debugPrint(
    //         'adding ${skill.skillName} to subcategory: ${subCategory.name}',
    //       );
    //       subCategory.skills.add(skill.id);
    //       await _skillsRepository.createOrEditSubCategory(
    //         subCategory: subCategory,
    //       );
    //     } else {
    //       debugPrint(
    //         'Skill ${skill.skillName} is already in subcategory: ${subCategory.name}',
    //       );
    //     }
    //   } catch (e) {
    //     debugPrint(e.toString());
    //     emit(
    //       state.copyWith(status: FormzStatus.submissionFailure),
    //     );
    //   }

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

    // final subCategories = state.subCategoryList ?? [];
    // the skillid should be in the subcategoryids
    // if not it has to be added and updated
    //update the subcategories in the SubCategory list with the new skill

    final skill = Skill(
      lastEditBy: _name,
      lastEditDate: DateTime.now(),
      difficulty: state.difficulty,
      id: editedSkill?.id as String,
      rider: editedSkill?.rider ?? true,
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

    // for (final subCategory in subCategories) {
    //   try {
    //     //if the skill is not in the subcategory add it
    //     if (!subCategory!.skills.contains(skill.id)) {
    //       debugPrint(
    //         'adding ${skill.skillName} to subcategory: ${subCategory.name}',
    //       );
    //       subCategory.skills.add(skill.id);
    //       await _skillsRepository.createOrEditSubCategory(
    //         subCategory: subCategory,
    //       );
    //     } else {
    //       debugPrint(
    //         'Skill ${skill.skillName} is already in subcategory: ${subCategory.name}',
    //       );
    //     }
    //   } catch (e) {
    //     debugPrint(e.toString());
    //     emit(
    //       state.copyWith(status: FormzStatus.submissionFailure),
    //     );
    //   }

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
    // final subCategories = state.allSubCategories;
    // //remove the skill from the subcategory
    // for (final subCategory in subCategories!) {
    //   try {
    //     //if the skill is in the subcategory remove it
    //     if (subCategory!.skills.contains(skill.id)) {
    //       debugPrint(
    //         'removing ${skill.skillName} from subcategory: ${subCategory.name}',
    //       );
    //       subCategory.skills.remove(skill.id);
    //       _skillsRepository.createOrEditSubCategory(
    //         subCategory: subCategory,
    //       );
    //     } else {
    //       debugPrint(
    //         'Skill ${skill.skillName} is not in subcategory: ${subCategory.name}',
    //       );
    //     }
    //   } catch (e) {
    //     debugPrint(e.toString());
    //     emit(
    //       state.copyWith(status: FormzStatus.submissionFailure),
    //     );
    //   }
    // }

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
