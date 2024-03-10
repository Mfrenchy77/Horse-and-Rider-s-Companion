// ignore_for_file: constant_identifier_names

part of 'app_cubit.dart';

/// The current status of the app.
enum AppStatus {
  authenticated,
  unauthenticated,
}

/// The Sort State of the Resources
enum ResourcesSortStatus {
  saved,
  recent,
  oldest,
  mostRecommended,
}

/// The Navigation within the SkillTree Section
enum SkillTreeNavigation {
  SkillList,
  SkillLevel,
  TrainingPath,
  TrainingPathList
}

/// The Page Status of the App
enum AppPageStatus {
  auth,
  error,
  profile,
  loading,
  settings,
  messages,
  resource,
  skillTree,
  resourceList,
  profileSetup,
  awitingEmailVerification,
}

class AppState extends Equatable {
  const AppState._({
    this.skill,
    this.resource,
    this.bannerAd,
    this.index = 0,
    this.horseId = '',
    this.usersProfile,
    this.trainingPath,
    this.horseProfile,
    this.ownersProfile,
    this.viewingProfile,
    this.isEdit = false,
    required this.status,
    this.isGuest = false,
    this.isError = false,
    this.isSearch = false,
    this.isMessage = false,
    this.errorMessage = '',
    this.isViewing = false,
    this.isForRider = true,
    this.user = User.empty,
    this.allSkills = const [],
    this.resources = const [],
    this.isFromProfile = false,
    this.searchList = const [],
    this.sortedSkills = const [],
    this.isBannerAdReady = false,
    this.trainingPaths = const [],
    this.savedResources = const [],
    this.isFromTrainingPath = false,
    this.isFromTrainingPathList = false,
    this.pageStatus = AppPageStatus.loading,
    this.difficultyState = DifficultyState.all,
    this.resourcesSortStatus = ResourcesSortStatus.recent,
    this.skillTreeNavigation = SkillTreeNavigation.SkillList,
  });

  const AppState.authenticated(User user)
      : this._(status: AppStatus.authenticated, user: user);

  const AppState.unauthenticated() : this._(status: AppStatus.unauthenticated);

  /// The index of the current page in the app.
  final int index;

  /// The current user of the app.
  final User user;

  /// Whether the user has selcted to edit.
  final bool isEdit;

  /// The current skill being viewed.
  final Skill? skill;

  /// Whether the user is a guest or not.
  final bool isGuest;

  /// Set when an Error snackbar needs to be shown
  final bool isError;

  /// Whether the state for the app bar is set to search.
  final bool isSearch;

  /// Set when a message snackbar needs to be shown
  final bool isMessage;

  /// The Id of the horse being viewed.
  final String horseId;

  /// Whether the use is viewing a profile or not.
  final bool isViewing;

  /// Whether we are viewing a rider or a horse profile.
  final bool isForRider;

  /// The current status of the app(whether the user is authenticated or not).
  final AppStatus status;

  /// The Resource being viewed.
  final Resource? resource;

  /// Whether Navigation is coming from Profile.
  final bool isFromProfile;

  /// The BannerAd to be shown in the app.
  final BannerAd? bannerAd;

  /// The error message to be shown in the snackbar
  final String errorMessage;

  /// Whether the BannerAd is ready to be shown.
  final bool isBannerAdReady;

  /// The Unsorted list of Skills from the database
  final List<Skill?> allSkills;

  /// Whether Navigation is coming from the TrainingPath section.
  final bool isFromTrainingPath;

  /// The current page status of the app.
  final AppPageStatus pageStatus;

  /// The List to populate the search field.
  final List<String?> searchList;

  /// The database resources
  final List<Resource?> resources;

  /// The List of Skills that are sorted by difficulty and isForRider
  final List<Skill?> sortedSkills;

  /// The current Training Path being viewed.
  final TrainingPath? trainingPath;

  /// Whether Navigation is coming from the TrainingPathList section.
  final bool isFromTrainingPathList;

  /// The current user's RiderProfile.
  final RiderProfile? usersProfile;

  /// The Profile of the owner of the horse being viewed
  /// if not the current user.
  final RiderProfile? ownersProfile;

  /// The HorseProfile being viewed.
  final HorseProfile? horseProfile;

  /// The RiderProfile being viewed.
  final RiderProfile? viewingProfile;

  /// List of Saved Resources
  final List<Resource?> savedResources;

  /// The Difficulty of the skills for sorting
  final DifficultyState difficultyState;

  /// The database training paths
  final List<TrainingPath?> trainingPaths;

  /// The sort state of the resources
  final ResourcesSortStatus resourcesSortStatus;

  /// The current navigation within the SkillTree section.
  final SkillTreeNavigation skillTreeNavigation;

  AppState copyWith({
    int? index,
    User? user,
    Skill? skill,
    bool? isEdit,
    bool? isGuest,
    bool? isError,
    bool? isSearch,
    bool? isMessage,
    String? horseId,
    bool? isViewing,
    bool? isForRider,
    AppStatus? status,
    Resource? resource,
    BannerAd? bannerAd,
    bool? isFromProfile,
    String? errorMessage,
    bool? isBannerAdReady,
    List<Skill?>? allSkills,
    bool? isFromTrainingPath,
    List<String?>? searchList,
    AppPageStatus? pageStatus,
    List<Skill?>? sortedSkills,
    TrainingPath? trainingPath,
    List<Resource?>? resources,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    RiderProfile? ownersProfile,
    bool? isFromTrainingPathList,
    RiderProfile? viewingProfile,
    List<Resource?>? savedResources,
    DifficultyState? difficultyState,
    List<TrainingPath?>? trainingPaths,
    ResourcesSortStatus? resourcesSortStatus,
    SkillTreeNavigation? skillTreeNavigation,
  }) {
    return AppState._(
      user: user ?? this.user,
      skill: skill ?? this.skill,
      index: index ?? this.index,
      isEdit: isEdit ?? this.isEdit,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      horseId: horseId ?? this.horseId,
      isGuest: isGuest ?? this.isGuest,
      resource: resource ?? this.resource,
      isSearch: isSearch ?? this.isSearch,
      bannerAd: bannerAd ?? this.bannerAd,
      isMessage: isMessage ?? this.isMessage,
      isViewing: isViewing ?? this.isViewing,
      resources: resources ?? this.resources,
      allSkills: allSkills ?? this.allSkills,
      pageStatus: pageStatus ?? this.pageStatus,
      isForRider: isForRider ?? this.isForRider,
      searchList: searchList ?? this.searchList,
      sortedSkills: sortedSkills ?? this.sortedSkills,
      trainingPath: trainingPath ?? this.trainingPath,
      errorMessage: errorMessage ?? this.errorMessage,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      ownersProfile: ownersProfile ?? this.ownersProfile,
      isFromProfile: isFromProfile ?? this.isFromProfile,
      trainingPaths: trainingPaths ?? this.trainingPaths,
      savedResources: savedResources ?? this.savedResources,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      difficultyState: difficultyState ?? this.difficultyState,
      isFromTrainingPath: isFromTrainingPath ?? this.isFromTrainingPath,
      skillTreeNavigation: skillTreeNavigation ?? this.skillTreeNavigation,
      resourcesSortStatus: resourcesSortStatus ?? this.resourcesSortStatus,
      isFromTrainingPathList:
          isFromTrainingPathList ?? this.isFromTrainingPathList,
    );
  }

  @override
  List<Object?> get props => [
        user,
        skill,
        index,
        status,
        isEdit,
        isGuest,
        horseId,
        isError,
        resource,
        bannerAd,
        isSearch,
        isMessage,
        isViewing,
        resources,
        allSkills,
        isForRider,
        pageStatus,
        searchList,
        sortedSkills,
        trainingPath,
        errorMessage,
        horseProfile,
        usersProfile,
        ownersProfile,
        isFromProfile,
        trainingPaths,
        savedResources,
        viewingProfile,
        isBannerAdReady,
        difficultyState,
        isFromTrainingPath,
        skillTreeNavigation,
        resourcesSortStatus,
        isFromTrainingPathList,
      ];
}
