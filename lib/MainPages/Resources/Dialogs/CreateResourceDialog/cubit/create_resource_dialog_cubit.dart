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
    required KeysRepository keysRepository,
    required ResourcesRepository resourcesRepository,
  })  : _keysRepository = keysRepository,
        _resourcesRepository = resourcesRepository,
        super(const CreateResourceDialogState()) {
    _keysRepository.getJsonLinkApiKey().then((value) => _jsonKey = value);

    emit(
      state.copyWith(
        imageUrl: resource?.thumbnail ?? '',
        url: Url.dirty(resource?.url ?? ''),
        title: SingleWord.dirty(resource?.name ?? ''),
        description: SingleWord.dirty(resource?.description ?? ''),
        skills: skills,
        isEdit: isEdit,
        resource: resource,
        usersProfile: usersProfile,
      ),
    );
  }
  String? _jsonKey;
  final KeysRepository _keysRepository;
  final ResourcesRepository _resourcesRepository;

  ///   Called when user is inputting the Url to be parsed
  ///   and turned into a Resource
  void urlChanged(String value) {
    final url = Url.dirty(value);
    emit(
      state.copyWith(
        urlFetchedStatus: UrlFetchedStatus.initial,
        url: url,
      ),
    );
    if (state.url.isValid) {
      fetchUrl();
    } else {
      debugPrint('$value is not validated');
    }
  }

  ///   Called when Editing a Resource and the
  ///   Title is changed
  void titleChanged(String value) {
    final title = SingleWord.dirty(value);
    emit(
      state.copyWith(
        title: title,
        urlFetchedStatus: state.url.value.isNotEmpty
            ? UrlFetchedStatus.fetched
            : UrlFetchedStatus.initial,
      ),
    );
  }

  ///   Called when Editing a Resource and the
  ///  ImageUrl is changed
  void imageUrlChanged(String value) {
    final imageUrl = value;
    emit(
      state.copyWith(
        imageUrl: imageUrl,
      ),
    );
  }

  ///   Called when Editing a Resource and the
  ///   Description is changed
  void descriptionChanged(String value) {
    final description = SingleWord.dirty(value);
    emit(
      state.copyWith(description: description),
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
    final updatedSkills = List<String>.from(resource.skillTreeIds ?? []);
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
        resourceSkills: updatedResourceSkills,
        resource: updatedResource,
      ),
    );
  }

  /// the skills that in the resourceSkills list
  List<Skill?>? getSkillsForResource({
    required List<String?>? ids,
  }) {
    final skills = <Skill?>[];
    if (ids != null) {
      if (state.skills == null || state.skills!.isEmpty) {
        debugPrint('No skills found');
        return null;
      } else {
        for (final skill in state.skills!) {
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

  // if the url does not have a scheme, add https
  String _checkAndModifyUrl(String value) {
    var uri = Uri.parse(value);

    // Check if the scheme is missing
    if (uri.scheme.isEmpty) {
      // Add 'https://' as default scheme
      uri = Uri.parse('https://$value');
    }

    return uri.toString();
  }

  // read the url String and extract the metadata
  // update the state with the metadata

  Future<void> fetchUrl() async {
    final url = _checkAndModifyUrl(state.url.value.trim());
    debugPrint('fetchUrl: $url');
    emit(state.copyWith(urlFetchedStatus: UrlFetchedStatus.fetching));
    final metadataRepository = UrlMetadataRepository(apiKey: _jsonKey ?? '');

    try {
      debugPrint('Fetching the metadata');
      // First attempt: Using the API
      final metadata = await metadataRepository.extractUrlMetadata(url: url);
      if (metadata.title.isNotEmpty && metadata.description.isNotEmpty) {
        updateUrlMetadata(data: metadata);
      } else {
        debugPrint('Scraping the webpage');
        // If title or description is empty, attempt to scrape the webpage
        final scrapedMetadata =
            await metadataRepository.extractMetadataFromUrl(url);
        updateUrlMetadata(data: scrapedMetadata);
      }
    } catch (e) {
      // Handle errors from both attempts
      debugPrint('Error Fetching Url: $e');
      emit(
        state.copyWith(
          isError: true,
          error: e.toString(),
          urlFetchedStatus: UrlFetchedStatus.error,
          status: FormStatus.initial,
        ),
      );
    }
  }

  ///   Called when the url is inputted and validated
  ///  and the metadata is fetched
  void updateUrlMetadata({required UrlMetadata data}) {
    final title = SingleWord.dirty(data.title);
    final description = SingleWord.dirty(data.description);
    final imageUrl = data.imageUrls.first ?? '';
    debugPrint('imageUrl: $imageUrl');
    debugPrint('title: $title');
    debugPrint('description: $description');
    emit(
      state.copyWith(
        urlFetchedStatus: UrlFetchedStatus.fetched,
        url: Url.dirty(state.url.value),
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
    );
  }

  ///   Called when the url is inputted and validated
  Future<void> createResource() async {
    emit(
      state.copyWith(status: FormStatus.submitting),
    );
    final url = state.url.value;
    if (state.url.isValid) {
      final user = BaseListItem(
        isSelected: false,
        isCollapsed: false,
        id: state.usersProfile?.email ?? '',
      );
      final raters = <BaseListItem>[user];
      final skillIds = state.resourceSkills?.map((e) => e?.id).toList();
      final resource = Resource(
        url: url,
        rating: 0,
        numberOfRates: 0,
        usersWhoRated: raters,
        skillTreeIds: skillIds,
        name: state.title.value,
        id: ViewUtils.createId(),
        thumbnail: state.imageUrl,
        lastEditDate: DateTime.now(),
        description: state.description.value,
        lastEditBy: state.usersProfile?.name ?? '',
      );

      try {
        await _resourcesRepository.createOrUpdateResource(resource: resource);
        emit(state.copyWith(status: FormStatus.success));
      } on FirebaseException catch (e) {
        debugPrint('Error: ${e.message}');
        emit(
          state.copyWith(
            isError: true,
            error: e.message ?? 'Error',
            status: FormStatus.failure,
          ),
        );
      }
    } else {
      debugPrint('Url is not valid');
    }
  }

  Future<void> editResource() async {
    emit(state.copyWith(status: FormStatus.submitting));
    debugPrint(
      'Editting Resource ${state.resource?.name ?? state.title.value}',
    );

    if (state.url.isValid) {
      final editedResource = Resource(
        lastEditDate: DateTime.now(),
        name: state.title.value.isEmpty
            ? state.resource?.name
            : state.title.value,
        rating: state.resource?.rating ?? 1,
        lastEditBy: state.usersProfile?.name,
        description: state.description.value.isEmpty
            ? state.resource?.description
            : state.description.value,
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
        skillTreeIds: state.resourceSkills?.map((e) => e?.id).toList() ?? [],
        thumbnail:
            state.imageUrl.isEmpty ? state.resource?.thumbnail : state.imageUrl,
      );

      try {
        await _resourcesRepository.createOrUpdateResource(
          resource: editedResource,
        );
        emit(state.copyWith(status: FormStatus.success));
      } catch (e) {
        debugPrint('Error: $e');
        final errorMessage =
            (e is FirebaseException) ? e.message ?? 'Firebase Error' : 'Error';
        emit(
          state.copyWith(
            isError: true,
            error: errorMessage,
            status: FormStatus.failure,
          ),
        );
      }
    } else {
      debugPrint('Url is not valid');
    }
  }

  void clearMetaDataError() {
    emit(
      state.copyWith(
        urlFetchedStatus: UrlFetchedStatus.initial,
      ),
    );
  }

  //  Clears the error message
  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }
}
