// // ignore_for_file: cast_nullable_to_non_nullable

// import 'package:bloc/bloc.dart';
// import 'package:database_repository/database_repository.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart';
// import 'package:form_inputs/form_inputs.dart';
// import 'package:formz/formz.dart';
// import 'package:horseandriderscompanion/utils/view_utils.dart';

// part 'sub_category_create_dialog_state.dart';

// class SubCategoryCreateDialogCubit extends Cubit<SubCategoryCreateDialogState> {
//   SubCategoryCreateDialogCubit({
//     SubCategory? editingSubCategory,
//     required Catagorry category,
//     required this.isRider,
//     required String? name,
//     required SkillTreeRepository subCategoryRepository,
//   })  : _name = name,
//         _editingSubCategory = editingSubCategory,
//         _category = category,
//         _subCategoryRepository = subCategoryRepository,
//         super(const SubCategoryCreateDialogState()) {
//     emit(state.copyWith(subCategory: _editingSubCategory));
//   }

//   final SubCategory? _editingSubCategory;
//   final bool isRider;
//   final String? _name;
//   final SkillTreeRepository _subCategoryRepository;
//   final Catagorry _category;

//   ///   Called when the user is inputting the new SubCategory name
//   void subCategoryNameChanged(String value) {
//     final name = SingleWord.dirty(value);

//     emit(state.copyWith(name: name, status: Formz.validate([name])));
//   }

//   ///   Called when the user is inputting the New SubCategory description
//   void subCategoryDescriptionChanged(String value) {
//     final description = SingleWord.dirty(value);

//     emit(
//       state.copyWith(
//         description: description,
//         status: Formz.validate([description]),
//       ),
//     );
//   }

//   ///   Called when the user has selected a skill
//   /// we want to remove the skill from the list of skills
//   /// if the skill is already in the list
//   /// and add the skill to the list if it is not in the list
//   void subCategorySkillsChanged(String? skillId) {
//     if (skillId != null) {
//       if (state.skills.contains(skillId)) {
//         final skills = state.skills..remove(skillId);

//         emit(state.copyWith(skills: skills));
//         return;
//       } else {
//         final skills = state.skills..add(skillId);

//         emit(state.copyWith(skills: skills));
//         return;
//       }
//     } else {
//       debugPrint('Skill id is Null');
//     }
//   }

//   ///   Called when creating new SubCategory
//   Future<void> createSubCategory(int position) async {
//     emit(
//       state.copyWith(status: FormzStatus.submissionInProgress),
//     );

//     final subCategory = SubCategory(
//       parentId: _category.id,
//       id: ViewUtils.createId(),
//       name: state.name.value,
//       description: state.description.value,
//       isRider: isRider,
//       position: position,
//       skills: state.skills,
//       lastEditBy: _name!,
//       lastEditDate: DateTime.now(),
//     );

//     try {
//       await _subCategoryRepository.createOrEditSubCategory(
//         subCategory: subCategory,
//       );

//       emit(
//         state.copyWith(status: FormzStatus.submissionSuccess),
//       );
//     } catch (e) {
//       debugPrint(e.toString());
//       emit(
//         state.copyWith(status: FormzStatus.submissionFailure),
//       );
//     }
//   }

//   /// Called when editing a SubCategory
//   Future<void> editSubCategory() async {
//     emit(state.copyWith(status: FormzStatus.submissionInProgress));

//     final subCategory = SubCategory(
//       parentId: state.subCategory?.parentId,
//       id: state.subCategory?.id as String,
//       name: state.name.value.isNotEmpty
//           ? state.name.value
//           : state.subCategory?.name as String,
//       description: state.description.value.isNotEmpty
//           ? state.description.value
//           : state.subCategory?.description as String,
//       isRider: state.subCategory?.isRider as bool,
//       position: state.subCategory?.position as int,
//       skills: state.skills.isNotEmpty
//           ? state.skills
//           : state.subCategory?.skills as List<String>,
//       lastEditBy: _name!,
//       lastEditDate: DateTime.now(),
//     );

//     try {
//       await _subCategoryRepository.createOrEditSubCategory(
//         subCategory: subCategory,
//       );
//       emit(state.copyWith(status: FormzStatus.submissionSuccess));
//     } catch (e) {
//       debugPrint(e.toString());
//       emit(state.copyWith(status: FormzStatus.submissionFailure));
//     }
//   }

//   /// Called when deleting a SubCategory
//   void deleteSubCategory({required SubCategory subCategory}) {
//     emit(state.copyWith(status: FormzStatus.submissionInProgress));

//     try {
//       _subCategoryRepository.deleteSubCategory(
//         subCategory: subCategory,
//       );
//       emit(state.copyWith(status: FormzStatus.submissionSuccess));
//     } catch (e) {
//       debugPrint(e.toString());
//       emit(state.copyWith(status: FormzStatus.submissionFailure));
//     }
//   }
// }
