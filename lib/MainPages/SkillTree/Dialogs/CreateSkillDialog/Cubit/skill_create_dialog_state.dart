part of 'skill_create_dialog_cubit.dart';

enum UpdateSubCategoryList { inProgress, error, success, inital }

class CreateSkillDialogState extends Equatable {
  const CreateSkillDialogState({
    this.skill,
    this.allSkills,
    this.usersProfile,
    this.subCategoryList,
    this.allSubCategories,
    this.isForRider = true,
    this.prerequisites = const [],
    this.status = FormStatus.initial,
    this.name = const SingleWord.pure(),
    this.category = SkillCategory.Mounted,
    this.description = const SingleWord.pure(),
    this.difficulty = DifficultyState.Introductory,
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
  final FormStatus status;

  /// The category of the skill
  final SkillCategory category;

  /// The description of the skill
  final SingleWord description;

  /// List of all the possible skills for prerequisites
  final List<Skill?>? allSkills;

  /// The difficulty of the skill
  final DifficultyState difficulty;

  /// The users Profile
  final RiderProfile? usersProfile;

  /// List of prerequisite skills for the skill
  final List<String> prerequisites;

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
    FormStatus? status,
    List<Skill?>? allSkills,
    SingleWord? description,
    SkillCategory? category,
    RiderProfile? usersProfile,
    List<String>? prerequisites,
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
      category: category ?? this.category,
      allSkills: allSkills ?? this.allSkills,
      isForRider: isForRider ?? this.isForRider,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      usersProfile: usersProfile ?? this.usersProfile,
      prerequisites: prerequisites ?? this.prerequisites,
      proficientDescription:
          proficientDescription ?? this.proficientDescription,
      updateSubCategoryList:
          updateSubCategoryList ?? this.updateSubCategoryList,
      subCategoryList: subCategoryList ?? this.subCategoryList,
      allSubCategories: allSubCategories ?? this.allSubCategories,
      learningDescription: learningDescription ?? this.learningDescription,
    );
  }

  @override
  List<Object?> get props => [
        name,
        skill,
        status,
        category,
        allSkills,
        isForRider,
        difficulty,
        description,
        usersProfile,
        prerequisites,
        subCategoryList,
        allSubCategories,
        learningDescription,
        proficientDescription,
        updateSubCategoryList,
      ];
}
