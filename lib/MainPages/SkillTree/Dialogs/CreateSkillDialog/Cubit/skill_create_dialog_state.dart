part of 'skill_create_dialog_cubit.dart';

enum UpdateSubCategoryList { inProgress, error, success, inital }

class CreateSkillDialogState extends Equatable {
  const CreateSkillDialogState({
    this.skill,
    this.usersProfile,
    this.subCategoryList,
    this.allSubCategories,
    this.isForRider = true,
    this.status = FormzStatus.pure,
    this.name = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
    this.difficulty = DifficultyState.introductory,
    this.learningDescription = const SingleWord.pure(),
    this.proficientDescription = const SingleWord.pure(),
    this.updateSubCategoryList = UpdateSubCategoryList.inital,
  });

  /// If not null, this is the skill that is being edited
  final Skill? skill;

  /// Wheter the skill is for a rider or a horse
  final bool isForRider;

  /// The name of the skill
  final SingleWord name;

  /// The status of the form
  final FormzStatus status;

  /// The description of the skill
  final SingleWord description;

  /// The difficulty of the skill
  final DifficultyState difficulty;

  /// The users Profile 
  final RiderProfile? usersProfile;

  /// The description of the skill when the user is learning it
  final SingleWord learningDescription;

  /// The description of the skill when the user is proficient at it
  final SingleWord proficientDescription;

  /// The list of subcategories that the skill belongs to
  final List<SubCategory?>? subCategoryList;

  /// The list of all subcategories
  final List<SubCategory?>? allSubCategories;

  /// An updated list of subcategories
  final UpdateSubCategoryList updateSubCategoryList;

  CreateSkillDialogState copyWith({
    Skill? skill,
    bool? isForRider,
    SingleWord? name,
    FormzStatus? status,
    SingleWord? description,
    RiderProfile? usersProfile,
    DifficultyState? difficulty,
    SingleWord? learningDescription,
    SingleWord? proficientDescription,
    List<SubCategory?>? subCategoryList,
    List<SubCategory?>? allSubCategories,
    UpdateSubCategoryList? updateSubCategoryList,
  }) {
    return CreateSkillDialogState(
      name: name ?? this.name,
      skill: skill ?? this.skill,
      status: status ?? this.status,
      isForRider: isForRider ?? this.isForRider,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      usersProfile: usersProfile ?? this.usersProfile,
      proficientDescription:
          proficientDescription ?? this.proficientDescription,
      subCategoryList: subCategoryList ?? this.subCategoryList,
      updateSubCategoryList:
          updateSubCategoryList ?? this.updateSubCategoryList,
      allSubCategories: allSubCategories ?? this.allSubCategories,
      learningDescription: learningDescription ?? this.learningDescription,
    );
  }

  @override
  List<Object?> get props => [
        name,
        skill,
        status,
        isForRider,
        difficulty,
        description,
        usersProfile,
        subCategoryList,
        allSubCategories,
        learningDescription,
        proficientDescription,
        updateSubCategoryList,
      ];
}
