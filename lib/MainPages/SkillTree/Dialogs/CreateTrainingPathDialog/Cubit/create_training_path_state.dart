part of 'create_training_path_cubit.dart';

class CreateTrainingPathState extends Equatable {
  const CreateTrainingPathState({
    this.error,
    this.trainingPath,
    this.usersProfile,
    this.isSearch = false,
    this.searchQuery = '',
    this.isForRider = false,
    this.rootNodes = const [],
    this.childNodes = const {},
    this.availableSkills = const [],
    this.initialAllSkills = const [],
    this.status = FormStatus.initial,
    this.name = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
  });

  /// Error message
  final String? error;

  /// Are we showing the search input?
  final bool isSearch;

  /// Is this path for a rider (vs horse)?
  final bool isForRider;

  /// Name & description validation
  final SingleWord name;

  /// Form submission status
  final FormStatus status;

  /// Current search text (for filtering availableSkills)
  final String searchQuery;

  final SingleWord description;

  /// For edit mode: the original TrainingPath
  final TrainingPath? trainingPath;

  /// Who’s creating/editing
  final RiderProfile? usersProfile;

  /// Skills not yet placed into the path
  final List<Skill> availableSkills;

  /// Top‐level nodes in the training path
  final List<SkillNode> rootNodes;

  /// The master list of all skills (never mutated)
  final List<Skill> initialAllSkills;

  /// Children keyed by parentNode.id
  final Map<String, List<SkillNode>> childNodes;

  CreateTrainingPathState copyWith({
    String? error,
    bool? isSearch,
    bool? isForRider,
    SingleWord? name,
    FormStatus? status,
    String? searchQuery,
    SingleWord? description,
    List<SkillNode>? rootNodes,
    TrainingPath? trainingPath,
    RiderProfile? usersProfile,
    List<Skill>? availableSkills,
    List<Skill>? initialAllSkills,
    Map<String, List<SkillNode>>? childNodes,
  }) {
    return CreateTrainingPathState(
      name: name ?? this.name,
      error: error ?? this.error,
      status: status ?? this.status,
      isSearch: isSearch ?? this.isSearch,
      rootNodes: rootNodes ?? this.rootNodes,
      childNodes: childNodes ?? this.childNodes,
      isForRider: isForRider ?? this.isForRider,
      searchQuery: searchQuery ?? this.searchQuery,
      description: description ?? this.description,
      trainingPath: trainingPath ?? this.trainingPath,
      usersProfile: usersProfile ?? this.usersProfile,
      availableSkills: availableSkills ?? this.availableSkills,
      initialAllSkills: initialAllSkills ?? this.initialAllSkills,
    );
  }

  @override
  List<Object?> get props => [
        name,
        error,
        status,
        isSearch,
        rootNodes,
        childNodes,
        isForRider,
        description,
        searchQuery,
        trainingPath,
        usersProfile,
        availableSkills,
        initialAllSkills,
      ];
}
