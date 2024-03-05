// ignore_for_file: constant_identifier_names

part of 'app_cubit.dart';

/// The current status of the app.
enum AppStatus {
  authenticated,
  unauthenticated,
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
  loading,
  profile,
  resource,
  skillTree,
  profileSetup,
  awitingEmailVerification,
}

class AppState extends Equatable {
  const AppState._({
    this.bannerAd,
    this.index = 0,
    this.horseId = '',
    this.usersProfile,
    this.horseProfile,
    this.ownersProfile,
    this.viewingProfile,
    this.isGuest = false,
    this.isError = false,
    required this.status,
    this.isMessage = false,
    this.errorMessage = '',
    this.isViewing = false,
    this.isForRider = true,
    this.skills = const [],
    this.user = User.empty,
    this.resources = const [],
    this.isFromProfile = false,
    this.isBannerAdReady = false,
    this.trainingPaths = const [],
    this.isFromTrainingPath = false,
    this.isFromTrainingPathList = false,
    this.pageStatus = AppPageStatus.loading,
    this.skillTreeNavigation = SkillTreeNavigation.SkillList,
  });

  const AppState.authenticated(User user)
      : this._(status: AppStatus.authenticated, user: user);

  const AppState.unauthenticated() : this._(status: AppStatus.unauthenticated);

  /// The index of the current page in the app.
  final int index;

  /// The current user of the app.
  final User user;

  /// Whether the user is a guest or not.
  final bool isGuest;

  /// Set when an Error snackbar needs to be shown
  final bool isError;

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

  /// Whether Navigation is coming from Profile.
  final bool isFromProfile;

  /// The database skills
  final List<Skill> skills;

  /// The BannerAd to be shown in the app.
  final BannerAd? bannerAd;

  /// The error message to be shown in the snackbar
  final String errorMessage;

  /// Whether the BannerAd is ready to be shown.
  final bool isBannerAdReady;

  /// Whether Navigation is coming from the TrainingPath section.
  final bool isFromTrainingPath;

  /// The database resources
  final List<Resource> resources;

  /// The current page status of the app.
  final AppPageStatus pageStatus;

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

  /// The database training paths
  final List<TrainingPath> trainingPaths;

  /// The current navigation within the SkillTree section.
  final SkillTreeNavigation skillTreeNavigation;

  AppState copyWith({
    int? index,
    User? user,
    bool? isGuest,
    bool? isError,
    bool? isMessage,
    String? horseId,
    bool? isViewing,
    bool? isForRider,
    AppStatus? status,
    BannerAd? bannerAd,
    List<Skill>? skills,
    bool? isFromProfile,
    String? errorMessage,
    bool? isBannerAdReady,
    bool? isFromTrainingPath,
    AppPageStatus? pageStatus,
    List<Resource>? resources,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    RiderProfile? ownersProfile,
    bool? isFromTrainingPathList,
    RiderProfile? viewingProfile,
    List<TrainingPath>? trainingPaths,
    SkillTreeNavigation? skillTreeNavigation,
  }) {
    return AppState._(
      user: user ?? this.user,
      index: index ?? this.index,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      horseId: horseId ?? this.horseId,
      isGuest: isGuest ?? this.isGuest,
      bannerAd: bannerAd ?? this.bannerAd,
      isMessage: isMessage ?? this.isMessage,
      isViewing: isViewing ?? this.isViewing,
      resources: resources ?? this.resources,
      pageStatus: pageStatus ?? this.pageStatus,
      isForRider: isForRider ?? this.isForRider,
      errorMessage: errorMessage ?? this.errorMessage,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      ownersProfile: ownersProfile ?? this.ownersProfile,
      isFromProfile: isFromProfile ?? this.isFromProfile,
      trainingPaths: trainingPaths ?? this.trainingPaths,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      isFromTrainingPath: isFromTrainingPath ?? this.isFromTrainingPath,
      skillTreeNavigation: skillTreeNavigation ?? this.skillTreeNavigation,
      isFromTrainingPathList:
          isFromTrainingPathList ?? this.isFromTrainingPathList,
    );
  }

  @override
  List<Object?> get props => [
        user,
        index,
        status,
        skills,
        isGuest,
        horseId,
        isError,
        bannerAd,
        isMessage,
        isViewing,
        resources,
        isForRider,
        pageStatus,
        errorMessage,
        horseProfile,
        usersProfile,
        ownersProfile,
        isFromProfile,
        trainingPaths,
        viewingProfile,
        isBannerAdReady,
        isFromTrainingPath,
        skillTreeNavigation,
        isFromTrainingPathList,
      ];
}
