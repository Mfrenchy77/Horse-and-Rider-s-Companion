part of 'skilltree_cubit.dart';

// ignore: constant_identifier_names
enum FilterState { Category, SubCategory, Skill, Level }

/// State of skilltree screen.
class SkilltreeState extends Equatable {
  /// Create [SkilltreeState].
  ///
  /// [isSearch] is whether search mode is enabled or not.
  /// [filterState] is current filter state.
  const SkilltreeState({
    this.skill,
    this.level,
    this.skills,
    this.levels,
    this.category,
    this.categories,
    this.error = '',
    this.subCategory,
    this.horseProfile,
    this.usersProfile,
    this.subCategories,
    this.viewingProfile,
    this.isError = false,
    this.isSearch = false,
    this.searchQuery = '',
    this.isForRider = true,
    this.isSearching = false,
    this.isSkillTreeEdit = false,
    this.filterState = FilterState.Skill,
    this.difficultyState = DifficultyState.all,
  });
  final Skill? skill;
  final Level? level;
  final String error;
  final bool isError;
  final bool isSearch;
  final bool isForRider;
  final bool isSearching;
  final String searchQuery;
  final Catagorry? category;
  final List<Skill?>? skills;
  final List<Level?>? levels;
  final bool isSkillTreeEdit;
  final FilterState filterState;
  final SubCategory? subCategory;
  final HorseProfile? horseProfile;
  final RiderProfile? usersProfile;
  final RiderProfile? viewingProfile;
  final List<Catagorry?>? categories;
  final DifficultyState difficultyState;
  final List<SubCategory?>? subCategories;

  /// Create [SkilltreeState] with new value.
  ///
  /// [isSearch] is whether search mode is enabled or not.
  /// [filterState] is current filter state.
  SkilltreeState copyWith({
    Skill? skill,
    Level? level,
    String? error,
    bool? isError,
    bool? isSearch,
    bool? isForRider,
    bool? isSearching,
    String? searchQuery,
    Catagorry? category,
    List<Skill?>? skills,
    List<Level?>? levels,
    bool? isSkillTreeEdit,
    SubCategory? subCategory,
    FilterState? filterState,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    RiderProfile? viewingProfile,
    List<Catagorry?>? categories,
    List<SubCategory?>? subCategories,
    DifficultyState? difficultyState,
  }) {
    return SkilltreeState(
      error: error ?? this.error,
      skill: skill ?? this.skill,
      level: level ?? this.level,
      skills: skills ?? this.skills,
      levels: levels ?? this.levels,
      isError: isError ?? this.isError,
      category: category ?? this.category,
      isSearch: isSearch ?? this.isSearch,
      isForRider: isForRider ?? this.isForRider,
      categories: categories ?? this.categories,
      subCategory: subCategory ?? this.subCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      filterState: filterState ?? this.filterState,
      isSearching: isSearching ?? this.isSearching,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      subCategories: subCategories ?? this.subCategories,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      isSkillTreeEdit: isSkillTreeEdit ?? this.isSkillTreeEdit,
      difficultyState: difficultyState ?? this.difficultyState,
    );
  }

  @override
  List<Object?> get props => [
        skill,
        level,
        error,
        skills,
        levels,
        category,
        isError,
        isSearch,
        isForRider,
        categories,
        subCategory,
        filterState,
        isSearching,
        searchQuery,
        horseProfile,
        usersProfile,
        subCategories,
        viewingProfile,
        isSkillTreeEdit,
        difficultyState,
      ];
}
