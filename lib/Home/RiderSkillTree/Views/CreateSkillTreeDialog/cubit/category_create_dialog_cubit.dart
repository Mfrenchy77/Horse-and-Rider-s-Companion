// ignore_for_file: cast_nullable_to_non_nullable

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';

part 'category_create_dialog_state.dart';

class CreateCategoryDialogCubit extends Cubit<CreateCategoryDialogState> {
  CreateCategoryDialogCubit({
    required this.isRider,
    required String? name,
    required SkillTreeRepository catagorryRepository,
    required int position,
  })  : _name = name,
        _categoryRepository = catagorryRepository,
        _position = position,
        super(const CreateCategoryDialogState());

  final bool isRider;
  final int _position;
  final String? _name;
  final SkillTreeRepository _categoryRepository;

  ///   Called when the user is inputting the new Category name
  void categoryNameChanged(String value) {
    final name = SingleWord.dirty(value);

    emit(state.copyWith(name: name, status: Formz.validate([name])));
  }

  ///   Called when the user is inputting the New Category description
  void categoryDescriptionChanged(String value) {
    final description = SingleWord.dirty(value);

    emit(
      state.copyWith(
        description: description,
        status: Formz.validate([description]),
      ),
    );
  }

  ///   Called when creating new Category
  Future<void> createCategory(int position) async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );

    final category = Catagorry(
      id: ViewUtils.createId(),
      name: state.name.value,
      description: state.description.value,
      position: _position,
      rider: isRider,
      lastEditBy: _name as String,
      lastEditDate: DateTime.now(),
    );

    try {
      await _categoryRepository.createOrEditCategory(
        catagory: category,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint('something went wrong$e');
      emit(
        state.copyWith(status: FormzStatus.submissionFailure),
      );
    }
  }

  Future<void> editCategory({Catagorry? editedCategory}) async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );
    final category = Catagorry(
      id: editedCategory?.id as String,
      name: state.name.value.isNotEmpty
          ? state.name.value
          : editedCategory?.name as String,
      description: state.description.value.isNotEmpty
          ? state.description.value
          : editedCategory?.description as String,
      position: editedCategory?.position as int,
      rider: editedCategory?.rider as bool,
      lastEditBy: _name as String,
      lastEditDate: DateTime.now(),
    );
    try {
      await _categoryRepository.createOrEditCategory(
        catagory: category,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(status: FormzStatus.submissionFailure),
      );
    }
  }

  void deleteCategory({required Catagorry category}) {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );
    try {
      _categoryRepository.deleteCategory(
        catagorry: category,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(status: FormzStatus.submissionFailure),
      );
    }
  }
}
