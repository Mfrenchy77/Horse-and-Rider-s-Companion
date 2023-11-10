part of 'home_cubit.dart';

enum LevelSubmitionStatus { submitting, ititial }

enum SkillTreeStatus { categories, subCategories, skill, level }

enum ResourcesSortStatus { recent, saved, oldest, mostRecommended }

enum SearchState { email, name, horse, horseNickName }

enum SearchType { ititial, rider, horse }

enum HomeStatus { loading, profile, resource, skillTree, ridersLog }

@immutable
class HomeState extends Equatable {
  const HomeState({
    this.skill,
    this.skills,
    this.levels,
    this.bannerAd,
    this.category,
    this.resources,
    this.index = 0,
    this.categories,
    this.error = '',
    this.subCategory,
    this.message = '',
    this.usersProfile,
    this.subCategories,
    this.viewingProfile,
    this.snackBar = false,
    this.isViewing = false,
    this.unreadMessages = 0,
    this.isSearching = false,
    this.errorSnackBar = false,
    this.searchResult = const [],
    this.isSkillTreeEdit = false,
    this.isResourcesEdit = false,
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
    this.skillTreeStatus = SkillTreeStatus.categories,
    this.resourcesSortStatus = ResourcesSortStatus.recent,
    this.levelSubmitionStatus = LevelSubmitionStatus.ititial,
  });

  final int index;
  final Name name;
  final Email email;
  final Skill? skill;
  final String error;
  final bool snackBar;
  final String message;
  final bool isViewing;
  final bool isSearching;
  final int unreadMessages;
  final bool errorSnackBar;
  final BannerAd? bannerAd;
  final Catagorry? category;
  final bool messageSnackBar;
  final List<Level?>? levels;
  final bool isResourcesEdit;
  final bool isBannerAdReady;
  final bool isSkillTreeEdit;
  final List<Skill?>? skills;
  final HomeStatus homeStatus;
  final SearchType searchType;
  final SubCategory? subCategory;
  final FormzStatus formzStatus;
  final SearchState searchState;
  final bool isDescriptionHidden;
  final RiderProfile? usersProfile;
  final List<Resource?>? resources;
  final List<Catagorry?>? categories;
  final RiderProfile? viewingProfile;
  final bool isSendingMessageToSupport;
  final SkillTreeStatus skillTreeStatus;
  final List<RiderProfile?> searchResult;
  final List<SubCategory?>? subCategories;
  final List<HorseProfile?> horseSearchResult;
  final ResourcesSortStatus resourcesSortStatus;
  final LevelSubmitionStatus levelSubmitionStatus;

  HomeState copyWith({
    Name? name,
    int? index,
    Email? email,
    Skill? skill,
    String? error,
    bool? snackBar,
    String? message,
    bool? isViewing,
    bool? isSearching,
    BannerAd? bannerAd,
    int? unreadMessages,
    bool? errorSnackBar,
    Catagorry? category,
    List<Skill?>? skills,
    List<Level?>? levels,
    bool? messageSnackBar,
    bool? isBannerAdReady,
    bool? isResourcesEdit,
    bool? isSkillTreeEdit,
    SearchType? searchType,
    HomeStatus? homeStatus,
    SubCategory? subCategory,
    SearchState? searchState,
    FormzStatus? formzStatus,
    bool? isDescriptionHidden,
    RiderProfile? usersProfile,
    List<Resource?>? resources,
    List<Catagorry?>? categories,
    RiderProfile? viewingProfile,
    bool? isSendingMessageToSupport,
    SkillTreeStatus? skillTreeStatus,
    List<SubCategory?>? subCategories,
    List<RiderProfile?>? searchResult,
    List<HorseProfile?>? horseSearchResult,
    ResourcesSortStatus? resourcesSortStatus,
    LevelSubmitionStatus? levelSubmitionStatus,
  }) {
    return HomeState(
      name: name ?? this.name,
      email: email ?? this.email,
      skill: skill ?? this.skill,
      index: index ?? this.index,
      error: error ?? this.error,
      skills: skills ?? this.skills,
      levels: levels ?? this.levels,
      message: message ?? this.message,
      snackBar: snackBar ?? this.snackBar,
      category: category ?? this.category,
      bannerAd: bannerAd ?? this.bannerAd,
      isViewing: isViewing ?? this.isViewing,
      resources: resources ?? this.resources,
      searchType: searchType ?? this.searchType,
      homeStatus: homeStatus ?? this.homeStatus,
      categories: categories ?? this.categories,
      subCategory: subCategory ?? this.subCategory,
      isSearching: isSearching ?? this.isSearching,
      formzStatus: formzStatus ?? this.formzStatus,
      searchState: searchState ?? this.searchState,
      searchResult: searchResult ?? this.searchResult,
      usersProfile: usersProfile ?? this.usersProfile,
      subCategories: subCategories ?? this.subCategories,
      errorSnackBar: errorSnackBar ?? this.errorSnackBar,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      messageSnackBar: messageSnackBar ?? this.messageSnackBar,
      isSkillTreeEdit: isSkillTreeEdit ?? this.isSkillTreeEdit,
      isResourcesEdit: isResourcesEdit ?? this.isResourcesEdit,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      skillTreeStatus: skillTreeStatus ?? this.skillTreeStatus,
      isSendingMessageToSupport:
          isSendingMessageToSupport ?? this.isSendingMessageToSupport,
      horseSearchResult: horseSearchResult ?? this.horseSearchResult,
      isDescriptionHidden: isDescriptionHidden ?? this.isDescriptionHidden,
      resourcesSortStatus: resourcesSortStatus ?? this.resourcesSortStatus,
      levelSubmitionStatus: levelSubmitionStatus ?? this.levelSubmitionStatus,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        error,
        skill,
        index,
        skills,
        levels,
        message,
        snackBar,
        category,
        bannerAd,
        resources,
        isViewing,
        categories,
        searchType,
        homeStatus,
        isSearching,
        subCategory,
        formzStatus,
        searchState,
        searchResult,
        usersProfile,
        errorSnackBar,
        subCategories,
        viewingProfile,
        unreadMessages,
        messageSnackBar,
        skillTreeStatus,
        isSkillTreeEdit,
        isResourcesEdit,
        isBannerAdReady,
        horseSearchResult,
        resourcesSortStatus,
        isDescriptionHidden,
        levelSubmitionStatus,
        isSendingMessageToSupport,
      ];
}
