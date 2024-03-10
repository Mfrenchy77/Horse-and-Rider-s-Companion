import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'create_resource_dialog_state.dart';

class CreateResourceDialogCubit extends Cubit<CreateResourceDialogState> {
  CreateResourceDialogCubit({
    required this.usersProfile,
    required bool isEdit,
    required Resource? resource,
    required KeysRepository keysRepository,
    required List<Skill?>? skills,
    required ResourcesRepository resourcesRepository,
  })  : _skills = skills,
        _isEdit = isEdit,
        _resource = resource,
        _keysRepository = keysRepository,
        _resourcesRepository = resourcesRepository,
        super(const CreateResourceDialogState()) {
    _keysRepository.getJsonLinkApiKey().then((value) => _jsonKey = value);
    if (resource != null) {
      emit(
        state.copyWith(
          title: SingleWord.dirty(resource.name ?? ''),
          description: SingleWord.dirty(resource.description ?? ''),
          imageUrl: resource.thumbnail,
          url: Url.dirty(resource.url ?? ''),
          status: Formz.validate([
            SingleWord.dirty(resource.name ?? ''),
            SingleWord.dirty(resource.description ?? ''),
            Url.dirty(resource.url ?? ''),
          ]),
        ),
      );
    }
    emit(
      state.copyWith(
        skills: _skills,
        resource: _resource,
        isEdit: _isEdit,
        resourceSkills: getSkillsForResource(ids: _resource?.skillTreeIds),
      ),
    );
  }
  final bool _isEdit;
  final Resource? _resource;
  final List<Skill?>? _skills;
  final RiderProfile? usersProfile;
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
        status: Formz.validate([url]),
      ),
    );
    if (!state.url.invalid) {
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
        status: Formz.validate([title]),
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
      state.copyWith(
        description: description,
        status: Formz.validate([description]),
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
  List<Skill?>? getSkillsForResource({required List<String?>? ids}) {
    final skills = <Skill?>[];
    if (ids != null) {
      if (_skills != null) {
        for (final skill in _skills!) {
          if (ids.contains(skill?.id)) {
            skills.add(skill);
          }
        }
      } else {
        debugPrint('skills is null');
      }
    } else {
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
          status: FormzStatus.invalid,
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
        status: Formz.validate([state.url, title, description]),
      ),
    );
  }
  //   });
  //   try {

  //     final title = SingleWord.dirty(data.title ?? '');
  //     final description = SingleWord.dirty(data.description ?? '');
  //     final imageUrl = _checkAndModifyUrl(data.imageUrl ?? '');
  //     debugPrint('imageUrl: $imageUrl');
  //     debugPrint('title: $title');
  //     debugPrint('description: $description');
  //     emit(
  //       state.copyWith(
  //         urlFetchedStatus: UrlFetchedStatus.fetched,
  //         url: Url.dirty(url),
  //         title: title,
  //         description: description,
  //         imageUrl: imageUrl,
  //         status: Formz.validate([state.url, title, description]),
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint('Error Fetching Url: $e');
  //     // emit(
  //     //   state.copyWith(
  //     //     isError: true,
  //     //     error: e.toString(),
  //     //     urlFetchedStatus: UrlFetchedStatus.error,
  //     //     status: FormzStatus.invalid,
  //     //   ),
  //     // );
  //   }
  // }

  ///   Called when the url is inputted and validated
  Future<void> createResource() async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );
    final url = state.url.value;
    if (state.status.isValidated) {
      final user = BaseListItem(
        id: usersProfile?.email ?? '',
        isCollapsed: false,
        isSelected: false,
      );
      final raters = <BaseListItem>[user];
      final skillIds = state.resourceSkills?.map((e) => e?.id).toList();
      final resource = Resource(
        id: ViewUtils.createId(),
        name: state.title.value,
        thumbnail: state.imageUrl,
        description: state.description.value,
        url: url,
        numberOfRates: 0,
        rating: 0,
        skillTreeIds: skillIds,
        usersWhoRated: raters,
        lastEditBy: usersProfile?.name ?? '',
        lastEditDate: DateTime.now(),
      );

      try {
        await _resourcesRepository.createOrUpdateResource(resource: resource);
        emit(state.copyWith(status: FormzStatus.submissionSuccess));
      } on FirebaseException catch (e) {
        debugPrint('Error: ${e.message}');
        emit(
          state.copyWith(
            status: FormzStatus.submissionFailure,
            error: e.message ?? 'Error',
            isError: true,
          ),
        );
      }
    } else {
      debugPrint('Form is not valid');
    }
  }

  Future<void> editResource() async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    debugPrint(
      'Editting Resource ${state.resource?.name ?? state.title.value}',
    );

    if (state.status.isValidated) {
      final editedResource = Resource(
        id: state.resource?.id ?? ViewUtils.createId(),
        name: state.title.value.isEmpty
            ? state.resource?.name
            : state.title.value,
        thumbnail:
            state.imageUrl.isEmpty ? state.resource?.thumbnail : state.imageUrl,
        description: state.description.value.isEmpty
            ? state.resource?.description
            : state.description.value,
        url: state.url.value.isEmpty ? state.resource?.url : state.url.value,
        numberOfRates: state.resource?.numberOfRates ?? 0,
        rating: state.resource?.rating ?? 1,
        skillTreeIds: state.resourceSkills?.map((e) => e?.id).toList() ?? [],
        usersWhoRated: state.resource?.usersWhoRated ??
            [
              BaseListItem(
                id: usersProfile?.email,
                isSelected: true,
                isCollapsed: false,
              ),
            ],
        lastEditBy: usersProfile?.name,
        lastEditDate: DateTime.now(),
      );

      try {
        await _resourcesRepository.createOrUpdateResource(
          resource: editedResource,
        );
        emit(state.copyWith(status: FormzStatus.submissionSuccess));
      } catch (e) {
        debugPrint('Error: $e');
        final errorMessage =
            (e is FirebaseException) ? e.message ?? 'Firebase Error' : 'Error';
        emit(
          state.copyWith(
            status: FormzStatus.submissionFailure,
            error: errorMessage,
            isError: true,
          ),
        );
      }
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
