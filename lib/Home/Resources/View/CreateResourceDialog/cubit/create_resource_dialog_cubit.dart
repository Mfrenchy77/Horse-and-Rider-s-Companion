import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

part 'create_resource_dialog_state.dart';

class CreateResourceDialogCubit extends Cubit<CreateResourceDialogState> {
  CreateResourceDialogCubit({
    required this.usersProfile,
    required bool isEdit,
    required Resource? resource,
    required List<Skill?>? skills,
    required ResourcesRepository resourcesRepository,
  })  : _skills = skills,
        _isEdit = isEdit,
        _resource = resource,
        _resourcesRepository = resourcesRepository,
        super(const CreateResourceDialogState()) {
    if (resource != null) {
      urlChanged(resource.url.toString());
      // list of skills that are in the resourceids
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
    fetchUrl();
  }

  ///   Called when Editing a Resource and the
  ///   Title is changed
  void titleChanged(String value) {
    final title = SingleWord.dirty(value);
    emit(
      state.copyWith(
        title: title,
        status: Formz.validate([title]),
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
    final resource = state.resource;
    final updatedSkills = List<String>.from(resource?.skillTreeIds ?? []);

    if (updatedSkills.contains(skillId)) {
      debugPrint('removing skill');
      updatedSkills.remove(skillId);
    } else {
      debugPrint('adding skill');
      updatedSkills.add(skillId);
    }

    final updatedResourceSkills = getSkillsForResource(ids: updatedSkills);
    final updatedResource = resource?.copyWith(skillTreeIds: updatedSkills);

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

    try {
      final metadata = await MetadataFetch.extract(url);
      if (metadata != null) {
        final title = SingleWord.dirty(metadata.title ?? '');
        final description = SingleWord.dirty(metadata.description ?? '');
        final imageUrl = _checkAndModifyUrl(metadata.image ?? '');
        debugPrint('imageUrl: $imageUrl');
        emit(
          state.copyWith(
            urlFetchedStatus: UrlFetchedStatus.fetched,
            url: Url.dirty(url),
            title: title,
            description: description,
            imageUrl: imageUrl,
            status: Formz.validate([state.url, title, description]),
          ),
        );
      } else {
        throw Exception('Metadata not found for URL');
      }
    } catch (e) {
      debugPrint('Error Fetching Url: $e');
      // emit(
      //   state.copyWith(
      //     isError: true,
      //     error: e.toString(),
      //     urlFetchedStatus: UrlFetchedStatus.error,
      //     status: FormzStatus.invalid,
      //   ),
      // );
    }
  }

  ///   Called when the url is inputted and validated
  Future<void> createResource() async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );
    final url = state.url.value;
    if (state.status.isValidated) {
      await MetadataFetch.extract(url).then((value) {
        if (value != null) {
          final user = BaseListItem(
            id: usersProfile?.email ?? '',
            isCollapsed: false,
            isSelected: false,
          );
          final raters = <BaseListItem>[user];
          final skillIds = state.resourceSkills?.map((e) => e?.id).toList();
          final resource = Resource(
            id: ViewUtils.createId(),
            name: value.title,
            thumbnail: value.image,
            description: value.description,
            url: url,
            numberOfRates: 0,
            rating: 0,
            skillTreeIds: skillIds,
            usersWhoRated: raters,
            lastEditBy: usersProfile?.name ?? '',
            lastEditDate: DateTime.now(),
          );

          try {
            _resourcesRepository.createOrUpdateResource(resource: resource);
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
        }
      });
    }
  }

  Future<void> editResource() async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    if (state.resource == null) {
      debugPrint('Resource is null');
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          isError: true,
          error: 'Error',
        ),
      );
      return;
    }

    final url =
        state.url.value.isNotEmpty ? state.url.value : state.resource!.url;
    final editedResource = Resource(
      id: state.resource!.id,
      name: state.title.value,
      thumbnail: state.imageUrl.isNotEmpty
          ? state.imageUrl
          : state.resource!.thumbnail,
      description: state.description.value.isNotEmpty
          ? state.description.value
          : state.resource!.description,
      url: url,
      numberOfRates: state.resource!.numberOfRates,
      rating: state.resource!.rating,
      skillTreeIds: state.resourceSkills?.map((e) => e?.id).toList() ?? [],
      usersWhoRated: state.resource!.usersWhoRated,
      lastEditBy: usersProfile?.name ?? '',
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

  //  Clears the error message
  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }
}
