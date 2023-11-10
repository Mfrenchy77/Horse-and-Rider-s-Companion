// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'skilltree_state.dart';

class SkilltreeCubit extends Cubit<SkilltreeState> {
  SkilltreeCubit({
    HorseProfile? horseProfile,
    RiderProfile? viewingProfile,
    required RiderProfile? usersProfile,
    required SkillTreeRepository skillTreeRepository,
  })  : _horseProfile = horseProfile,
        _viewingProfile = viewingProfile,
        _usersProfile = usersProfile,
        _skillTreeRepository = skillTreeRepository,
        super(const SkilltreeState()) {
    emit(
      state.copyWith(
        isForRider: _horseProfile == null,
        horseProfile: _horseProfile,
        usersProfile: _usersProfile,
        viewingProfile: _viewingProfile,
      ),
    );

    _categoryStream =
        _skillTreeRepository.getCatagoriesForRiderSkillTree().listen((event) {
      _categories = event.docs.map((e) => e.data() as Catagorry?).toList();
      emit(state.copyWith(categories: _categories));
      _subCategoryStream = _skillTreeRepository
          .getSubCategoriesForRiderSkillTree()
          .listen((event) {
        _subCategories =
            event.docs.map((e) => e.data() as SubCategory?).toList();
        emit(state.copyWith(subCategories: _subCategories));
        _skillsStream =
            _skillTreeRepository.getSkillsForRiderSkillTree().listen((event) {
          _skills = event.docs.map((e) => e.data() as Skill?).toList();
          emit(state.copyWith(skills: _skills));
          _levelsStream =
              _skillTreeRepository.getLevelsForRiderSkillTree().listen((event) {
            _levels = event.docs.map((e) => e.data() as Level?).toList();
            emit(state.copyWith(levels: _levels));
          });
        });
      });
    });
  }

  // viewingProfile is the rider that the user is viewing
  // if not null we use the skill tree for that rider
  // if null we use the skill tree for the riderProfile user
  final RiderProfile? _viewingProfile;

  // if usersProfile is null we need to restrict access to the skill tree
  //  and treat it as a guest user
  final RiderProfile? _usersProfile;

  // horseProfile is the horse that the user is viewing
  // if not null we use the skill tree for that horse
  // and we set isForRider to false
  final HorseProfile? _horseProfile;

  final SkillTreeRepository _skillTreeRepository;
  late final StreamSubscription<QuerySnapshot<Object?>> _categoryStream;
  List<Catagorry?>? _categories;
  late final StreamSubscription<QuerySnapshot<Object?>> _subCategoryStream;
  List<SubCategory?>? _subCategories;
  late final StreamSubscription<QuerySnapshot<Object?>> _skillsStream;
  List<Skill?>? _skills;
  late final StreamSubscription<QuerySnapshot<Object?>> _levelsStream;
  List<Level?>? _levels;

/* ********************************************************
                          Search
 ***********************************************************/
  void cancelSearch() {
    emit(state.copyWith(isSearch: false));
  }

  void search() {
    emit(state.copyWith(isSearch: true));
  }

  void getSkillByName(String skillName) {
    final skill =
        state.skills!.firstWhere((element) => element!.skillName == skillName);

    emit(
      state.copyWith(
        skill: skill,
      ),
    );
  }

  void clearSearchQuery() {
    emit(state.copyWith(searchQuery: ''));
  }

  void searchQueryChanged({required String searchQuery}) {
    emit(state.copyWith(searchQuery: searchQuery));
  }

/* ********************************************************
                          Filter
  ***********************************************************/

  /// This method will be called when the user clicks the back button
  /// when in subcategories
  void backToCategory() {
    emit(
      state.copyWith(
        filterState: FilterState.Category,
        category: null,
        subCategory: null,
        skill: null,
        level: null,
        subCategories: _subCategories,
        skills: _skills,
        levels: _levels,
      ),
    );
  }

  List<Skill?>? getAllSkills() {
    return _skills;
  }

  Color getBackgroundColorForDifficulty(DifficultyState difficulty) {
    switch (difficulty) {
      case DifficultyState.introductory:
        return Colors.lightBlue.shade100;
      case DifficultyState.intermediate:
        return Colors.blue;
      case DifficultyState.advanced:
        return Colors.blue.shade900;
      case DifficultyState.all:
        return Colors.transparent; // Default color for undefined difficulty
    }
  }

  List<Skill?> sortedByDifficulty({required List<Skill?>? skills}) {
    // Assign each difficulty level a numerical value for sorting
    const difficultyOrder = {
      DifficultyState.introductory: 1,
      DifficultyState.intermediate: 2,
      DifficultyState.advanced: 3,
    };
    // Sort the filtered list of skills by the
    // numerical value of their difficulty
    final filteredSkills = skills!
        .where((skill) => skill!.difficulty != DifficultyState.all)
        .toList()
      ..sort((a, b) {
        final aDifficulty = difficultyOrder[a?.difficulty] ?? 0;
        final bDifficulty = difficultyOrder[b?.difficulty] ?? 0;
        return aDifficulty.compareTo(bDifficulty);
      });

    return filteredSkills;
  }

  void _sortSkillsByDifficulty({
    required DifficultyState difficultyState,
    required SubCategory subCategory,
  }) {
    //if the user clicks a difficulty we are going to change the filter to
    //skills for that difficulty.
    // and select only the skills for that difficulty
    // if difficulty is all we are going to show all the skills

    var skills = <Skill?>[];
    emit(
      state.copyWith(
        skills: _getSkillsForSubCategory(subCategory: subCategory),
      ),
    );
    debugPrint('DifficultyState: $difficultyState');

    if (state.skills != null) {
      for (final skill in state.skills!) {
        debugPrint('Skill Difficulty: ${skill?.difficulty}');
      }

      if (difficultyState != DifficultyState.all) {
        skills = state.skills!
            .where((element) => element?.difficulty == difficultyState)
            .toList();

        emit(
          state.copyWith(
            skills: skills,
            difficultyState: difficultyState,
            filterState: FilterState.Skill,
          ),
        );
      } else {
        emit(
          state.copyWith(
            skills: _getSkillsForSubCategory(subCategory: subCategory),
            difficultyState: difficultyState,
            filterState: FilterState.Skill,
          ),
        );
      }
    } else {
      debugPrint('skills is null');
    }
    emit(state.copyWith(difficultyState: difficultyState));
  }
// Open the difficulty select dialog
// this will allow the user to select a difficulty to filter by
// the user can select all, introductory, intermediate, or advanced

  void openDifficultySelectDialog({
    required BuildContext context,
    required SubCategory subCategory,
  }) {
    showDialog<AlertDialog>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  subCategory: subCategory,
                  difficultyState: DifficultyState.introductory,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Introductory'),
            ),
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  subCategory: subCategory,
                  difficultyState: DifficultyState.intermediate,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Intermediate'),
            ),
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  subCategory: subCategory,
                  difficultyState: DifficultyState.advanced,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Advanced'),
            ),
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  difficultyState: DifficultyState.all,
                  subCategory: subCategory,
                );
                Navigator.of(context).pop();
              },
              child: const Text('All'),
            ),
          ],
        ),
      ),
    );
  }

  List<Skill> _getSkillsForSubCategory({required SubCategory subCategory}) {
    final skills = <Skill>[];
    if (_skills != null) {
      for (final skill in _skills!) {
        if (subCategory.skills.contains(skill?.id)) {
          skills.add(skill!);
        }
      }
      emit(
        state.copyWith(skills: skills),
      );
    } else {
      debugPrint('skills is null');
    }
    return skills;
  }

  /// This method will be called when the user clicks a category
  /// it will change the filter to subcategories for that category.
  void categorySelected({required Catagorry category}) {
    //if the user clicks a category we are going to change the filter
    //to subcategories for that category.
    // and select only the subcategories for that category
    var subCategories = <SubCategory?>[];
    if (state.subCategories != null) {
      subCategories = _subCategories!
          .where((element) => element?.parentId == category.id)
          .toList();

      emit(
        state.copyWith(
          categories: _categories,
          category: category,
          subCategories: subCategories,
          filterState: FilterState.SubCategory,
        ),
      );
    } else {
      debugPrint('subCategories is null');
    }
  }

  void skillTreeHome() {
    debugPrint('skillTreeHome');
    emit(
      state.copyWith(
        filterState: FilterState.Skill,
        category: null,
        subCategory: null,
        skill: null,
        level: null,
        subCategories: _subCategories,
        skills: _skills,
        levels: _levels,
      ),
    );
  }

  /// This method will be called when the user clicks a subcategory
  /// it will change the filter to skills for that subcategory.
  /// and select only the skills for that subcategory
  void subCategorySelected({required SubCategory subCategory}) {
    emit(
      state.copyWith(
        subCategory: subCategory,
        skills: _getSkillsForSubCategory(subCategory: subCategory),
        filterState: FilterState.Skill,
      ),
    );
  }

  /// This method will be called when the user clicks a skill
  /// it will change the filter to levels for that skill.
  /// and select only the levels for that skill
  void skillSelected({required Skill skill}) {
    //If a user clicks a skill we are going to change
    // the filter to levels for that skill.
    // and select only the levels for that skill
    var levels = <Level?>[];
    if (state.levels != null) {
      levels = state.levels!
          .where(
            (element) => element!.skillId == skill.id,
          )
          .toList();

      emit(
        state.copyWith(
          skill: skill,
          levels: levels,
          filterState: FilterState.Level,
        ),
      );
    } else {
      debugPrint('levels is null');
    }
  }

  /// This method will be called when the user clicks a level
  /// it will change the filter to levels for that level.
  void levelSelected({required Level level}) {
    emit(state.copyWith(level: level));
  }

  /// This is to toggle the edit mode for the skill tree
  void toggleSkillTreeEdit() {
    emit(state.copyWith(isSkillTreeEdit: !state.isSkillTreeEdit));
  }

  @override
  Future<void> close() {
    _skillsStream.cancel();
    _levelsStream.cancel();
    _categoryStream.cancel();
    _subCategoryStream.cancel();
    return super.close();
  }
}
