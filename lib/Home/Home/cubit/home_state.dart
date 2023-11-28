// ignore_for_file: use_late_for_private_fields_and_variables

part of 'home_cubit.dart';

enum SkillSearchState { skill, level }

enum SearchType { ititial, rider, horse }

enum LevelSubmitionStatus { submitting, ititial }

enum LevelSubmissionStatus { submitting, initial }

enum SearchState { email, name, horse, horseNickName }

enum SkillTreeStatus { categories, subCategories, skill, level }

enum ResourcesSortStatus { recent, saved, oldest, mostRecommended }

// ignore: constant_identifier_names
enum SkillTreeNavigation { Category, SubCategory, Skill, SkillLevel }

enum HomeStatus { loading, profile, resource, skillTree, ridersLog, horseLog }

@immutable
class HomeState extends Equatable {
  const HomeState({
    this.skill,
    this.skills,
    this.levels,
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
    this.isGuest = false,
    this.isOwner = false,
    this.isError = false,
    this.isSearch = false,
    this.snackBar = false,
    this.isViewing = false,
    this.searchQuery = '',
    this.isForRider = true,
    this.unreadMessages = 0,
    this.intermediateSkills,
    this.isSnackbar = false,
    this.isEditState = false,
    this.isSearching = false,
    this.errorSnackBar = false,
    this.searchResult = const [],
    this.isBannerAdReady = false,
    this.messageSnackBar = false,
    this.name = const Name.pure(),
    this.isDescriptionHidden = true,
    this.email = const Email.pure(),
    this.horseSearchResult = const [],
    this.searchState = SearchState.name,
    this.formzStatus = FormzStatus.pure,
    this.searchType = SearchType.ititial,
    this.homeStatus = HomeStatus.loading,
    this.isSendingMessageToSupport = false,
    this.difficultyState = DifficultyState.all,
    this.skillSearchState = SkillSearchState.skill,
    this.skillTreeStatus = SkillTreeStatus.categories,
    this.skillTreeNavigation = SkillTreeNavigation.Skill,
    this.resourcesSortStatus = ResourcesSortStatus.recent,
    this.levelSubmitionStatus = LevelSubmitionStatus.ititial,
    this.levelSubmissionStatus = LevelSubmissionStatus.initial,
  });
  final int index;
  final Name name;
  final Email email;
  final Skill? skill;
  final String error;
  final bool isError;
  final bool isOwner;
  final bool isGuest;
  final bool snackBar;
  final bool isSearch;
  final bool isViewing;
  final String message;
  final bool isSnackbar;
  final bool isForRider;
  final bool isEditState;
  final bool isSearching;
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
  final SearchType searchType;
  final List<Skill?>? allSkills;
  final FormzStatus formzStatus;
  final SearchState searchState;
  final SubCategory? subCategory;
  final bool isDescriptionHidden;
  final List<String?>? searchList;
  final List<Skill?>? introSkills;
  final List<Skill?>? sortedSkills;
  final HorseProfile? horseProfile;
  final RiderProfile? usersProfile;
  final RiderProfile? ownersProfile;
  final List<Skill?>? advancedSkills;
  final RiderProfile? viewingProfile;
  final List<Catagorry?>? categories;
  final List<Resource?>? allResources;
  final List<Resource?>? resourcesList;
  final bool isSendingMessageToSupport;
  final SkillTreeStatus skillTreeStatus;
  final DifficultyState difficultyState;
  final List<RiderProfile?> searchResult;
  final List<Skill?>? intermediateSkills;
  final List<SubCategory?>? subCategories;
  final SkillSearchState skillSearchState;
  final List<HorseProfile?> horseSearchResult;
  final SkillTreeNavigation skillTreeNavigation;
  final ResourcesSortStatus resourcesSortStatus;
  final LevelSubmitionStatus levelSubmitionStatus;
  final LevelSubmissionStatus levelSubmissionStatus;

  HomeState copyWith({
    Name? name,
    int? index,
    Skill? skill,
    Level? level,
    Email? email,
    String? error,
    bool? isGuest,
    bool? isError,
    bool? isOwner,
    bool? isSearch,
    bool? snackBar,
    bool? isViewing,
    String? message,
    bool? isSnackbar,
    bool? isForRider,
    bool? isEditState,
    bool? isSearching,
    Resource? resource,
    BannerAd? bannerAd,
    int? unreadMessages,
    String? searchQuery,
    Catagorry? category,
    bool? errorSnackBar,
    List<Skill?>? skills,
    List<Level?>? levels,
    bool? messageSnackBar,
    bool? isBannerAdReady,
    SearchType? searchType,
    HomeStatus? homeStatus,
    List<Skill?>? allSkills,
    SubCategory? subCategory,
    SearchState? searchState,
    FormzStatus? formzStatus,
    List<String?>? searchList,
    bool? isDescriptionHidden,
    List<Skill?>? introSkills,
    List<Skill?>? sortedSkills,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    RiderProfile? ownersProfile,
    List<Skill?>? advancedSkills,
    RiderProfile? viewingProfile,
    List<Catagorry?>? categories,
    List<Resource?>? allResources,
    List<Resource?>? resourcesList,
    bool? isSendingMessageToSupport,
    SkillTreeStatus? skillTreeStatus,
    List<Skill?>? intermediateSkills,
    DifficultyState? difficultyState,
    List<RiderProfile?>? searchResult,
    List<SubCategory?>? subCategories,
    SkillSearchState? skillSearchState,
    List<HorseProfile?>? horseSearchResult,
    SkillTreeNavigation? skillTreeNavigation,
    ResourcesSortStatus? resourcesSortStatus,
    LevelSubmitionStatus? levelSubmitionStatus,
    LevelSubmissionStatus? levelSubmissionStatus,
  }) {
    return HomeState(
      name: name ?? this.name,
      skill: skill ?? this.skill,
      email: email ?? this.email,
      index: index ?? this.index,
      error: error ?? this.error,
      skills: skills ?? this.skills,
      levels: levels ?? this.levels,
      isGuest: isGuest ?? this.isGuest,
      isOwner: isOwner ?? this.isOwner,
      isError: isError ?? this.isError,
      message: message ?? this.message,
      resource: resource ?? this.resource,
      snackBar: snackBar ?? this.snackBar,
      bannerAd: bannerAd ?? this.bannerAd,
      category: category ?? this.category,
      isSearch: isSearch ?? this.isSearch,
      isViewing: isViewing ?? this.isViewing,
      allSkills: allSkills ?? this.allSkills,
      searchList: searchList ?? this.searchList,
      searchType: searchType ?? this.searchType,
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
      allResources: allResources ?? this.allResources,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      searchResult: searchResult ?? this.searchResult,
      sortedSkills: sortedSkills ?? this.sortedSkills,
      resourcesList: resourcesList ?? this.resourcesList,
      ownersProfile: ownersProfile ?? this.ownersProfile,
      errorSnackBar: errorSnackBar ?? this.errorSnackBar,
      subCategories: subCategories ?? this.subCategories,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      advancedSkills: advancedSkills ?? this.advancedSkills,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      messageSnackBar: messageSnackBar ?? this.messageSnackBar,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      skillTreeStatus: skillTreeStatus ?? this.skillTreeStatus,
      difficultyState: difficultyState ?? this.difficultyState,
      skillSearchState: skillSearchState ?? this.skillSearchState,
      horseSearchResult: horseSearchResult ?? this.horseSearchResult,
      skillTreeNavigation: skillTreeNavigation ?? this.skillTreeNavigation,
      isDescriptionHidden: isDescriptionHidden ?? this.isDescriptionHidden,
      resourcesSortStatus: resourcesSortStatus ?? this.resourcesSortStatus,
      levelSubmitionStatus: levelSubmitionStatus ?? this.levelSubmitionStatus,
      intermediateSkills: intermediateSkills ?? this.intermediateSkills,
      levelSubmissionStatus:
          levelSubmissionStatus ?? this.levelSubmissionStatus,
      isSendingMessageToSupport:
          isSendingMessageToSupport ?? this.isSendingMessageToSupport,
    );
  }

  @override
  List<Object?> get props => [
        name,
        skill,
        email,
        index,
        error,
        skills,
        levels,
        isOwner,
        isGuest,
        isError,
        message,
        bannerAd,
        category,
        snackBar,
        isSearch,
        resource,
        isViewing,
        isSnackbar,
        isForRider,
        searchType,
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
        allResources,
        sortedSkills,
        horseProfile,
        usersProfile,
        searchResult,
        errorSnackBar,
        resourcesList,
        subCategories,
        ownersProfile,
        unreadMessages,
        advancedSkills,
        viewingProfile,
        isBannerAdReady,
        messageSnackBar,
        skillTreeStatus,
        difficultyState,
        skillSearchState,
        horseSearchResult,
        intermediateSkills,
        isDescriptionHidden,
        resourcesSortStatus,
        skillTreeNavigation,
        levelSubmitionStatus,
        levelSubmissionStatus,
        isSendingMessageToSupport,
      ];
}
