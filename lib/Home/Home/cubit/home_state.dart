// ignore_for_file: use_late_for_private_fields_and_variables, constant_identifier_names, lines_longer_than_80_chars

part of 'home_cubit.dart';

enum SkillSearchState { skill, level }

enum SearchState { initial, searching, success }

enum LevelSubmitionStatus { submitting, ititial }

enum LevelSubmissionStatus { submitting, initial }

enum ResourcesSortStatus {
  recent,
  saved,
  oldest,
  mostRecommended,
}

enum SkillTreeNavigation {
  SkillList,
  SkillLevel,
  TrainingPath,
  TrainingPathList
}

enum HomeStatus {
  loading,
  profile,
  resource,
  horseLog,
  skillTree,
  ridersLog,
  profileSetup,
}

@immutable
class HomeState extends Equatable {
  const HomeState({
    this.user,
    this.skill,
    this.skills,
    this.levels,
    this.horseId,
    this.bannerAd,
    this.category,
    this.resource,
    this.index = 0,
    this.allSkills,
    this.categories,
    this.error = '',
    this.searchList,
    this.introSkills,
    this.subCategory,
    this.trainingPath,
    this.sortedSkills,
    this.horseProfile,
    this.usersProfile,
    this.message = '',
    this.allResources,
    this.resourcesList,
    this.ownersProfile,
    this.subCategories,
    this.advancedSkills,
    this.viewingProfile,
    this.savedResources,
    this.isGuest = false,
    this.isOwner = false,
    this.isSearch = false,
    this.snackBar = false,
    this.isViewing = false,
    this.searchQuery = '',
    this.isForRider = true,
    this.unreadMessages = 0,
    this.trainingPathSkills,
    this.intermediateSkills,
    this.isSnackbar = false,
    this.isEditState = false,
    this.isSearching = false,
    this.isFromProfile = false,
    this.errorSnackBar = false,
    this.searchResult = const [],
    this.isBannerAdReady = false,
    this.messageSnackBar = false,
    this.trainingPaths = const [],
    this.name = const Name.pure(),
    this.isDescriptionHidden = true,
    this.email = const Email.pure(),
    this.isFromTrainingPath = false,
    this.showingProfileSetup = false,
    this.horseSearchResult = const [],
    this.isFromTrainingPathList = false,
    this.formzStatus = FormzStatus.pure,
    this.homeStatus = HomeStatus.loading,
    this.searchState = SearchState.initial,
    this.isSendingMessageToSupport = false,
    this.difficultyState = DifficultyState.all,
    this.skillSearchState = SkillSearchState.skill,
    this.resourcesSortStatus = ResourcesSortStatus.recent,
    this.levelSubmitionStatus = LevelSubmitionStatus.ititial,
    this.levelSubmissionStatus = LevelSubmissionStatus.initial,
    this.skillTreeNavigation = SkillTreeNavigation.TrainingPathList,
  });
  final int index;
  final Name name;
  final User? user;
  final Email email;
  final Skill? skill;
  final String error;
  final bool isOwner;
  final bool isGuest;
  final bool snackBar;
  final bool isSearch;
  final bool isViewing;
  final String message;
  final String? horseId;
  final bool isSnackbar;
  final bool isForRider;
  final bool isEditState;
  final bool isSearching;
  final bool isFromProfile;
  final Resource? resource;
  final String searchQuery;
  final int unreadMessages;
  final bool errorSnackBar;
  final BannerAd? bannerAd;
  final Catagorry? category;
  final bool messageSnackBar;
  final List<Level?>? levels;
  final bool isBannerAdReady;
  final List<Skill?>? skills;
  final HomeStatus homeStatus;
  final bool isFromTrainingPath;
  final List<Skill?>? allSkills;
  final FormzStatus formzStatus;
  final SearchState searchState;
  final bool showingProfileSetup;
  final SubCategory? subCategory;
  final bool isDescriptionHidden;
  final List<String?>? searchList;
  final List<Skill?>? introSkills;
  final List<Skill?>? sortedSkills;
  final TrainingPath? trainingPath;
  final HorseProfile? horseProfile;
  final RiderProfile? usersProfile;
  final bool isFromTrainingPathList;
  final RiderProfile? ownersProfile;
  final List<Skill?>? advancedSkills;
  final RiderProfile? viewingProfile;
  final List<Catagorry?>? categories;
  final List<Resource?>? allResources;
  final List<Resource?>? resourcesList;
  final bool isSendingMessageToSupport;
  final List<Resource?>? savedResources;
  final DifficultyState difficultyState;
  final List<Skill?>? trainingPathSkills;
  final List<RiderProfile?> searchResult;
  final List<Skill?>? intermediateSkills;
  final List<TrainingPath?> trainingPaths;
  final List<SubCategory?>? subCategories;
  final SkillSearchState skillSearchState;
  final List<HorseProfile?> horseSearchResult;
  final SkillTreeNavigation skillTreeNavigation;
  final ResourcesSortStatus resourcesSortStatus;
  final LevelSubmitionStatus levelSubmitionStatus;
  final LevelSubmissionStatus levelSubmissionStatus;

  HomeState copyWith({
    Name? name,
    User? user,
    int? index,
    Skill? skill,
    Level? level,
    Email? email,
    String? error,
    bool? isGuest,
    bool? isOwner,
    bool? isSearch,
    bool? snackBar,
    String? horseId,
    bool? isViewing,
    String? message,
    ZipCode? zipCode,
    bool? isSnackbar,
    bool? isForRider,
    bool? isEditState,
    bool? isSearching,
    Resource? resource,
    BannerAd? bannerAd,
    int? unreadMessages,
    bool? isFromProfile,
    String? searchQuery,
    Catagorry? category,
    bool? errorSnackBar,
    List<Skill?>? skills,
    List<Level?>? levels,
    bool? messageSnackBar,
    bool? isBannerAdReady,
    HomeStatus? homeStatus,
    List<Skill?>? allSkills,
    bool? isFromTrainingPath,
    SubCategory? subCategory,
    SearchState? searchState,
    FormzStatus? formzStatus,
    bool? showingProfileSetup,
    List<String?>? searchList,
    bool? isDescriptionHidden,
    List<Skill?>? introSkills,
    TrainingPath? trainingPath,
    List<Skill?>? sortedSkills,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    RiderProfile? ownersProfile,
    bool? isFromTrainingPathList,
    List<Skill?>? advancedSkills,
    RiderProfile? viewingProfile,
    List<Catagorry?>? categories,
    List<Resource?>? allResources,
    List<Resource?>? resourcesList,
    List<Resource?>? savedResources,
    bool? isSendingMessageToSupport,
    List<Skill?>? trainingPathSkills,
    List<Skill?>? intermediateSkills,
    DifficultyState? difficultyState,
    List<RiderProfile?>? searchResult,
    List<SubCategory?>? subCategories,
    SkillSearchState? skillSearchState,
    List<TrainingPath?>? trainingPaths,
    List<HorseProfile?>? horseSearchResult,
    SkillTreeNavigation? skillTreeNavigation,
    ResourcesSortStatus? resourcesSortStatus,
    LevelSubmitionStatus? levelSubmitionStatus,
    LevelSubmissionStatus? levelSubmissionStatus,
  }) {
    return HomeState(
      user: user ?? this.user,
      name: name ?? this.name,
      skill: skill ?? this.skill,
      email: email ?? this.email,
      index: index ?? this.index,
      error: error ?? this.error,
      skills: skills ?? this.skills,
      levels: levels ?? this.levels,
      horseId: horseId ?? this.horseId,
      isGuest: isGuest ?? this.isGuest,
      isOwner: isOwner ?? this.isOwner,
      message: message ?? this.message,
      resource: resource ?? this.resource,
      snackBar: snackBar ?? this.snackBar,
      bannerAd: bannerAd ?? this.bannerAd,
      category: category ?? this.category,
      isSearch: isSearch ?? this.isSearch,
      isViewing: isViewing ?? this.isViewing,
      allSkills: allSkills ?? this.allSkills,
      searchList: searchList ?? this.searchList,
      homeStatus: homeStatus ?? this.homeStatus,
      isSnackbar: isSnackbar ?? this.isSnackbar,
      isForRider: isForRider ?? this.isForRider,
      categories: categories ?? this.categories,
      isEditState: isEditState ?? this.isEditState,
      isSearching: isSearching ?? this.isSearching,
      formzStatus: formzStatus ?? this.formzStatus,
      searchState: searchState ?? this.searchState,
      introSkills: introSkills ?? this.introSkills,
      subCategory: subCategory ?? this.subCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      trainingPath: trainingPath ?? this.trainingPath,
      allResources: allResources ?? this.allResources,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      searchResult: searchResult ?? this.searchResult,
      sortedSkills: sortedSkills ?? this.sortedSkills,
      isFromProfile: isFromProfile ?? this.isFromProfile,
      trainingPaths: trainingPaths ?? this.trainingPaths,
      resourcesList: resourcesList ?? this.resourcesList,
      ownersProfile: ownersProfile ?? this.ownersProfile,
      errorSnackBar: errorSnackBar ?? this.errorSnackBar,
      subCategories: subCategories ?? this.subCategories,
      savedResources: savedResources ?? this.savedResources,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      advancedSkills: advancedSkills ?? this.advancedSkills,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      messageSnackBar: messageSnackBar ?? this.messageSnackBar,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      difficultyState: difficultyState ?? this.difficultyState,
      skillSearchState: skillSearchState ?? this.skillSearchState,
      horseSearchResult: horseSearchResult ?? this.horseSearchResult,
      isFromTrainingPath: isFromTrainingPath ?? this.isFromTrainingPath,
      intermediateSkills: intermediateSkills ?? this.intermediateSkills,
      trainingPathSkills: trainingPathSkills ?? this.trainingPathSkills,
      showingProfileSetup: showingProfileSetup ?? this.showingProfileSetup,
      skillTreeNavigation: skillTreeNavigation ?? this.skillTreeNavigation,
      isDescriptionHidden: isDescriptionHidden ?? this.isDescriptionHidden,
      resourcesSortStatus: resourcesSortStatus ?? this.resourcesSortStatus,
      levelSubmitionStatus: levelSubmitionStatus ?? this.levelSubmitionStatus,
      levelSubmissionStatus:
          levelSubmissionStatus ?? this.levelSubmissionStatus,
      isFromTrainingPathList:
          isFromTrainingPathList ?? this.isFromTrainingPathList,
      isSendingMessageToSupport:
          isSendingMessageToSupport ?? this.isSendingMessageToSupport,
    );
  }

  @override
  List<Object?> get props => [
        user,
        name,
        skill,
        email,
        index,
        error,
        skills,
        levels,
        horseId,
        isOwner,
        isGuest,
        message,
        bannerAd,
        category,
        snackBar,
        isSearch,
        resource,
        allSkills,
        isViewing,
        isSnackbar,
        isForRider,
        homeStatus,
        categories,
        searchList,
        isEditState,
        searchState,
        formzStatus,
        isSearching,
        subCategory,
        introSkills,
        searchQuery,
        trainingPath,
        allResources,
        sortedSkills,
        horseProfile,
        usersProfile,
        searchResult,
        isFromProfile,
        trainingPaths,
        errorSnackBar,
        resourcesList,
        subCategories,
        ownersProfile,
        savedResources,
        unreadMessages,
        advancedSkills,
        viewingProfile,
        isBannerAdReady,
        messageSnackBar,
        difficultyState,
        skillSearchState,
        horseSearchResult,
        isFromTrainingPath,
        trainingPathSkills,
        intermediateSkills,
        isDescriptionHidden,
        showingProfileSetup,
        resourcesSortStatus,
        skillTreeNavigation,
        levelSubmitionStatus,
        levelSubmissionStatus,
        isFromTrainingPathList,
        isSendingMessageToSupport,
      ];
}
