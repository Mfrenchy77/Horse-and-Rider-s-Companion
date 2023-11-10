part of 'horse_profile_cubit.dart';

enum LevelSubmitionStatus { submitting, ititial }

enum HorseHomePageStatus { profile, skillTree }

enum SkillTreeStatus { categories, subCategories, skill, level }

class HorseHomeState extends Equatable {
  const HorseHomeState({
    this.skill,
    this.skills,
    this.levels,
    this.category,
    this.bannerAd,
    this.index = 0,
    this.error = '',
    this.categories,
    this.subCategory,
    this.message = '',
    this.horseProfile,
    this.usersProfile,
    this.ownersProfile,
    this.subCategories,
    this.isSnackbar = false,
    this.isEditState = false,
    this.isErrorSnackBar = false,
    this.isBannerAdReady = false,
    this.status = SkillTreeStatus.categories,
    this.horseHomePageStatus = HorseHomePageStatus.profile,
    this.levelSubmitionStatus = LevelSubmitionStatus.ititial,
  });
  final int index;
  final Skill? skill;
  final String error;
  final String message;
  final bool isSnackbar;
  final bool isEditState;
  final BannerAd? bannerAd;
  final Catagorry? category;
  final bool isErrorSnackBar;
  final bool isBannerAdReady;
  final List<Skill?>? skills;
  final List<Level?>? levels;
  final SkillTreeStatus status;
  final SubCategory? subCategory;
  final HorseProfile? horseProfile;
  final RiderProfile? usersProfile;
  final RiderProfile? ownersProfile;
  final List<Catagorry?>? categories;
  final List<SubCategory?>? subCategories;
  final HorseHomePageStatus horseHomePageStatus;
  final LevelSubmitionStatus levelSubmitionStatus;

  HorseHomeState copyWith({
    int? index,
    Skill? skill,
    String? error,
    String? message,
    bool? isSnackbar,
    bool? isEditState,
    BannerAd? bannerAd,
    Catagorry? category,
    List<Skill?>? skills,
    List<Level?>? levels,
    bool? isBannerAdReady,
    bool? isErrorSnackBar,
    SkillTreeStatus? status,
    SubCategory? subCategory,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    RiderProfile? ownersProfile,
    List<Catagorry?>? categories,
    List<SubCategory?>? subCategories,
    HorseHomePageStatus? horseHomePageStatus,
    LevelSubmitionStatus? levelSubmitionStatus,
  }) {
    return HorseHomeState(
      index: index ?? this.index,
      skill: skill ?? this.skill,
      error: error ?? this.error,
      skills: skills ?? this.skills,
      levels: levels ?? this.levels,
      status: status ?? this.status,
      message: message ?? this.message,
      category: category ?? this.category,
      bannerAd: bannerAd ?? this.bannerAd,
      isSnackbar: isSnackbar ?? this.isSnackbar,
      categories: categories ?? this.categories,
      subCategory: subCategory ?? this.subCategory,
      isEditState: isEditState ?? this.isEditState,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      ownersProfile: ownersProfile ?? this.ownersProfile,
      subCategories: subCategories ?? this.subCategories,
      isErrorSnackBar: isErrorSnackBar ?? this.isErrorSnackBar,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      horseHomePageStatus: horseHomePageStatus ?? this.horseHomePageStatus,
      levelSubmitionStatus: levelSubmitionStatus ?? this.levelSubmitionStatus,
    );
  }

  @override
  List<Object?> get props => [
        index,
        skill,
        error,
        skills,
        levels,
        status,
        message,
        category,
        bannerAd,
        isSnackbar,
        categories,
        subCategory,
        isEditState,
        horseProfile,
        usersProfile,
        ownersProfile,
        subCategories,
        isErrorSnackBar,
        isBannerAdReady,
        horseHomePageStatus,
        levelSubmitionStatus,
      ];
}
