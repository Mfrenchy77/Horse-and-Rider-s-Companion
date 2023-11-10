part of 'skill_create_dialog_cubit.dart';

enum UpdateSubCategoryList { inProgress, error, success, inital }

class CreateSkillDialogState extends Equatable {
  const CreateSkillDialogState({
    this.subCategoryList,
    this.allSubCategories,
    this.status = FormzStatus.pure,
    this.name = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
    this.difficulty = DifficultyState.introductory,
    this.updateSubCategoryList = UpdateSubCategoryList.inital,
  });

  final SingleWord name;
  final FormzStatus status;
  final SingleWord description;
  final DifficultyState difficulty;
  final List<SubCategory?>? subCategoryList;
  final List<SubCategory?>? allSubCategories;
  final UpdateSubCategoryList updateSubCategoryList;

  CreateSkillDialogState copyWith({
    SingleWord? name,
    FormzStatus? status,
    SingleWord? description,
    DifficultyState? difficulty,
    List<SubCategory?>? subCategoryList,
    List<SubCategory?>? allSubCategories,
    UpdateSubCategoryList? updateSubCategoryList,
  }) {
    return CreateSkillDialogState(
      name: name ?? this.name,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      subCategoryList: subCategoryList ?? this.subCategoryList,
      allSubCategories: allSubCategories ?? this.allSubCategories,
      updateSubCategoryList:
          updateSubCategoryList ?? this.updateSubCategoryList,
    );
  }

  @override
  List<Object?> get props => [
        name,
        status,
        difficulty,
        description,
        subCategoryList,
        allSubCategories,
        updateSubCategoryList,
      ];
}
