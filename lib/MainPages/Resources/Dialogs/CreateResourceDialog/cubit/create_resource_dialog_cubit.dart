import 'dart:async';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'create_resource_dialog_state.dart';

class CreateResourceDialogCubit extends Cubit<CreateResourceDialogState> {
  CreateResourceDialogCubit({
    required bool isEdit,
    required Resource? resource,
    required List<Skill?>? skills,
    required RiderProfile? usersProfile,
    required ResourcesRepository resourcesRepository,
  })  : _debounce = null,
        _resourcesRepository = resourcesRepository,
        super(const CreateResourceDialogState()) {
    emit(
      state.copyWith(
        skills: skills,
        isEdit: isEdit,
        resource: resource,
        filteredSkills: skills,
        usersProfile: usersProfile,
        title: resource?.name ?? '',
        imageUrl: resource?.thumbnail ?? '',
        url: Url.dirty(resource?.url ?? ''),
        description: resource?.description ?? '',
      ),
    );
  }
  Timer? _debounce;
  final ResourcesRepository _resourcesRepository;

  ///   Called when user is inputting the Url to be parsed
  ///   and turned into a Resource
  void urlChanged(String value) {
    final url = Url.dirty(value);

    // Emit the new URL state
    emit(
      state.copyWith(
        url: url,
        // Resetting status and other related state properties
        urlFetchedStatus: UrlFetchedStatus.initial,
        title: '',
        description: '',
        imageUrl: '',
        isError: false,
        error: '',
      ),
    );

    // Cancel any existing debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new debounce timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (url.isValid) {
        getMetadata(url.value);
      } else {
        debugPrint('Invalid URL');
        // Optionally handle invalid URL case
      }
    });
  }

  ///   Called when Editing a Resource and the
  ///   Title is changed
  void titleChanged(String value) {
    emit(
      state.copyWith(
        title: value,
      ),
    );

    _checkMetadataCompleteness();
  }

  ///   Called when Editing a Resource and the
  ///  ImageUrl is changed
  void imageUrlChanged(String value) {
    //final imageUrl = value;
    emit(
      state.copyWith(
        imageUrl: value,
      ),
    );

    _checkMetadataCompleteness();
  }

  ///   Called when Editing a Resource and the
  ///   Description is changed
  void descriptionChanged(String value) {
    //final description = SingleWord.dirty(value);
    emit(
      state.copyWith(description: value),
    );
    _checkMetadataCompleteness();
  }

  /// Checks if the title, description and url are not empty
  void _checkMetadataCompleteness() {
    final isComplete = state.title.isNotEmpty &&
        state.description.isNotEmpty &&
        state.url.value.isNotEmpty;
    emit(
      state.copyWith(
        urlFetchedStatus:
            isComplete ? UrlFetchedStatus.fetched : UrlFetchedStatus.manual,
      ),
    );
  }

  ///   Called when the user has selected a skill
  /// we want to remove the skill from the list of skills
  /// if the skill is already in the list
  /// and add the skill to the list if it is not in the list
  void resourceSkillsChanged(String skillId) {
    debugPrint('resourceSkillsChanged: $skillId');
    final resource = state.resource ?? Resource();

    // Clone the current list of skill IDs to avoid directly modifying the state
    final updatedSkills = List<String>.from(resource.skillTreeIds);
    debugPrint('updatedSkills: $updatedSkills');

    if (updatedSkills.contains(skillId)) {
      debugPrint('removing skill');
      updatedSkills.remove(skillId);
    } else {
      debugPrint('adding skill');
      updatedSkills.add(skillId);
    }
    // Fetch the skills for the updated list of IDs
    final updatedResourceSkills = getSkillsForResource(ids: updatedSkills);

    // Create a new copy of the resource with the updated skill IDs
    final updatedResource = resource.copyWith(skillTreeIds: updatedSkills);

    // Emit the new state with updated values
    emit(
      state.copyWith(
        resource: updatedResource,
        resourceSkills: updatedResourceSkills,
      ),
    );
  }

  /// User entered in the search bar to filter the skills
  void searchSkills(String value) {
    final filteredSkills = <Skill?>[];
    if (value.isNotEmpty) {
      final skills = state.skills;
      for (final skill in skills) {
        if (skill?.skillName.toLowerCase().contains(value.toLowerCase()) ??
            false) {
          filteredSkills.add(skill);
        }
      }
    } else {
      filteredSkills.addAll(state.skills);
    }
    emit(
      state.copyWith(
        filteredSkills: filteredSkills,
      ),
    );
  }

  void difficultyFilterChanged(DifficultyFilter? difficultyFilter) {
    emit(
      state.copyWith(
        difficultyFilter: difficultyFilter,
      ),
    );
    _sortSkills(
      state.categoryFilter,
      difficultyFilter,
    );
  }

  void categoryFilterChanged(CategoryFilter? categoryFilter) {
    emit(
      state.copyWith(
        categoryFilter: categoryFilter,
      ),
    );
    _sortSkills(
      categoryFilter,
      state.difficultyFilter,
    );
  }

  ///Sorts the Skills based on the SkillTreeSortState
  void _sortSkills(
    CategoryFilter? categorySort,
    DifficultyFilter? difficultySort,
  ) {
    final allSkills = state.skills;
    var sortedSkills = <Skill?>[];

    // First, sort by category
    sortedSkills = _sortSkillsByCategory(categorySort, allSkills);

    // Then, sort by difficulty within the filtered category
    sortedSkills = _sortSkillsByDifficulty(difficultySort, sortedSkills);

    // Emit the sorted skills
    emit(state.copyWith(filteredSkills: sortedSkills));
  }

  List<Skill?> _sortSkillsByCategory(
    CategoryFilter? categorySort,
    List<Skill?> skills,
  ) {
    switch (categorySort) {
      case CategoryFilter.All:
        return skills;
      case CategoryFilter.Husbandry:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategoryFilter.Husbandry.name,
            )
            .toList();
      case CategoryFilter.Mounted:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategoryFilter.Mounted.name,
            )
            .toList();
      case CategoryFilter.In_Hand:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategoryFilter.In_Hand.name,
            )
            .toList();
      case CategoryFilter.Other:
        return skills
            .where(
              (element) => element?.category.name == CategoryFilter.Other.name,
            )
            .toList();
      case null:
        return skills;
    }
  }

  List<Skill?> _sortSkillsByDifficulty(
    DifficultyFilter? difficultySort,
    List<Skill?> skills,
  ) {
    switch (difficultySort) {
      case DifficultyFilter.All:
        return skills;
      case DifficultyFilter.Introductory:
        return skills
            .where(
              (element) =>
                  element?.difficulty.name ==
                  DifficultyFilter.Introductory.name,
            )
            .toList();
      case DifficultyFilter.Intermediate:
        return skills
            .where(
              (element) =>
                  element?.difficulty.name ==
                  DifficultyFilter.Intermediate.name,
            )
            .toList();
      case DifficultyFilter.Advanced:
        return skills
            .where(
              (element) =>
                  element?.difficulty.name == DifficultyFilter.Advanced.name,
            )
            .toList();
      case null:
        return skills;
    }
  }

  /// Checks if the url is valid
  bool _checkUrlValid(String url) {
    final isUrlValid = AnyLinkPreview.isValidLink(
      url,
      protocols: ['http', 'https'],
      hostWhitelist: ['https://youtube.com/'],
      // hostBlacklist: ['https://facebook.com/'],
    );
    return isUrlValid;
  }

  /// Fetches the metadata of the URL
  Future<void> getMetadata(String url) async {
    emit(state.copyWith(urlFetchedStatus: UrlFetchedStatus.fetching));

    final isValid = _checkUrlValid(url);
    if (isValid) {
      final metadata = await AnyLinkPreview.getMetadata(
        link: url,
        cache: const Duration(days: 7),
        proxyUrl: 'https://corsproxy.io/?',
      );

      if (metadata == null || (metadata.title?.isEmpty ?? true)) {
        // No metadata fetched, switch to manual entry
        debugPrint('No metadata fetched: $metadata');
        emit(
          state.copyWith(
            urlFetchedStatus: UrlFetchedStatus.manual,
            isError: false,
            error: '',
          ),
        );
      } else {
        // Metadata fetched successfully
        debugPrint('Metadata fetched: $metadata');
        emit(
          state.copyWith(
            url: Url.dirty(url),
            title: metadata.title ?? '',
            imageUrl: metadata.image ?? '',
            description: metadata.desc ?? '',
            urlFetchedStatus: UrlFetchedStatus.fetched,
          ),
        );
      }
    } else {
      // Invalid URL
      debugPrint('Invalid URL');
      emit(
        state.copyWith(
          urlFetchedStatus: UrlFetchedStatus.error,
          isError: true,
          error: 'Invalid URL',
        ),
      );
    }
  }

  /// the skills that in the resourceSkills list
  List<Skill?>? getSkillsForResource({
    required List<String?>? ids,
  }) {
    final skills = <Skill?>[];
    if (ids != null) {
      if (state.skills.isEmpty) {
        debugPrint('No skills found');
        return null;
      } else {
        for (final skill in state.skills) {
          if (ids.contains(skill?.id)) {
            skills.add(skill);
          }
        }
      }
    } else {
      debugPrint('No skills found');
      return null;
    }
    return skills;
  }

  Future<void> editResource() async {
    emit(state.copyWith(submitStatus: ResourceSubmitStatus.submitting));
    debugPrint(
      'Editting Resource ${state.resource?.name ?? state.title}',
    );

    if (state.url.isValid) {
      final editedResource = Resource(
        comments: state.resource?.comments ?? [],
        lastEditDate: DateTime.now(),
        name: state.title.isEmpty ? state.resource?.name : state.title,
        rating: state.resource?.rating ?? 1,
        lastEditBy: state.usersProfile?.name,
        description: state.description.isEmpty
            ? state.resource?.description
            : state.description,
        usersWhoRated: state.resource?.usersWhoRated ??
            [
              BaseListItem(
                isSelected: true,
                isCollapsed: false,
                id: state.usersProfile?.email,
              ),
            ],
        id: state.resource?.id ?? ViewUtils.createId(),
        numberOfRates: state.resource?.numberOfRates ?? 0,
        url: state.url.value.isEmpty ? state.resource?.url : state.url.value,
        skillTreeIds: state.resourceSkills
                ?.map((e) => e?.id)
                .whereType<String>()
                .toList() ??
            [],
        thumbnail:
            state.imageUrl.isEmpty ? state.resource?.thumbnail : state.imageUrl,
      );

      try {
        await _resourcesRepository.createOrUpdateResource(
          resource: editedResource,
        );
        debugPrint('Resource Edited');
        emit(state.copyWith(submitStatus: ResourceSubmitStatus.success));
      } catch (e) {
        debugPrint('Error: $e');
        final errorMessage =
            (e is FirebaseException) ? e.message ?? 'Firebase Error' : 'Error';
        emit(
          state.copyWith(
            isError: true,
            error: errorMessage,
            submitStatus: ResourceSubmitStatus.error,
          ),
        );
      }
    } else {
      debugPrint('Url is not valid');
    }
  }

  ///  Called when the user has finished creating the resource
  /// if all the fields are filled
  bool isFormValid() {
    return state.title.isNotEmpty &&
        state.description.isNotEmpty &&
        state.url.value.isNotEmpty;
  }

  void clearMetaDataError() {
    emit(
      state.copyWith(
        urlFetchedStatus: UrlFetchedStatus.manual,
      ),
    );
  }

  //  Clears the error message
  void clearError() {
    emit(
      state.copyWith(
        error: '',
        isError: false,
        submitStatus: ResourceSubmitStatus.initial,
        //urlFetchedStatus: UrlFetchedStatus.initial,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
