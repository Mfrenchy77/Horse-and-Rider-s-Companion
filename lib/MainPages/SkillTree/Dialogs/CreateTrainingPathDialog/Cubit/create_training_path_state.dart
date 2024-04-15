part of 'create_training_path_cubit.dart';

class CreateTrainingPathState extends Equatable {
  const CreateTrainingPathState({
    this.trainingPath,
    this.usersProfile,
    this.isSearch = false,
    this.searchQuery = '',
    this.skills = const [],
    this.isForRider = false,
    this.allSkills = const [],
    this.skillNodes = const [],
    this.searchList = const [],
    this.removedSkills = const [],
    this.selectedSkills = const [],
    this.status = FormStatus.initial,
    this.name = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
  });

  final bool isSearch;
  final bool isForRider;
  final SingleWord name;
  final String searchQuery;
  final FormStatus status;
  final List<String> skills;
  final List<Skill?> allSkills;
  final SingleWord description;
  final List<String?>? searchList;
  final RiderProfile? usersProfile;
  final List<Skill?> removedSkills;
  final TrainingPath? trainingPath;
  final List<Skill?> selectedSkills;
  final List<SkillNode?> skillNodes;

  CreateTrainingPathState copyWith({
    bool? isSearch,
    SingleWord? name,
    bool? isForRider,
    String? searchQuery,
    FormStatus? status,
    List<String>? skills,
    List<Skill?>? allSkills,
    SingleWord? description,
    List<String?>? searchList,
    RiderProfile? usersProfile,
    TrainingPath? trainingPath,
    List<Skill?>? removedSkills,
    List<Skill?>? selectedSkills,
    List<SkillNode?>? skillNodes,
  }) {
    return CreateTrainingPathState(
      name: name ?? this.name,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      isSearch: isSearch ?? this.isSearch,
      allSkills: allSkills ?? this.allSkills,
      isForRider: isForRider ?? this.isForRider,
      searchList: searchList ?? this.searchList,
      skillNodes: skillNodes ?? this.skillNodes,
      searchQuery: searchQuery ?? this.searchQuery,
      description: description ?? this.description,
      usersProfile: usersProfile ?? this.usersProfile,
      trainingPath: trainingPath ?? this.trainingPath,
      removedSkills: removedSkills ?? this.removedSkills,
      selectedSkills: selectedSkills ?? this.selectedSkills,
    );
  }

  @override
  List<Object?> get props => [
        name,
        status,
        skills,
        isSearch,
        allSkills,
        searchList,
        skillNodes,
        isForRider,
        searchQuery,
        description,
        usersProfile,
        trainingPath,
        removedSkills,
        selectedSkills,
      ];
}
