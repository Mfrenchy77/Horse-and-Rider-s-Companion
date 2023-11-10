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
    required ResourcesRepository resourcesRepository,
  })  : _resourcesRepository = resourcesRepository,
        super(const CreateResourceDialogState());

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
        description: const SingleWord.pure(),
        title: const SingleWord.pure(),
        imageUrl: '',
        status: Formz.validate([url]),
      ),
    );
  }

  ///   Called when Editing a Resourse and the
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

  ///   Called when Editing a Resourse and the
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

  // if the url does not have a scheme, add https
  String _checkAndModifyUrl(String value) {
    var url = value;
    // Check if the URL starts with "http://" or "https://"
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // If not, add "https://"
      url = 'http://$url';
    }

    // Check if the URL contains "www."
    if (!url.contains('www.')) {
      // If not, add "www."
      url = url.replaceAll('https://', 'https://www.');
      url = url.replaceAll('http://', 'http://www.');
    }

    return url;
  }

  // read the url String and extract the metadata
  // update the state with the metadata
  Future<void> fetchUrl() async {
    final url = _checkAndModifyUrl(state.url.value.trim());
    debugPrint('fetchUrl: $url');
    emit(
      state.copyWith(
        urlFetchedStatus: UrlFetchedStatus.fetching,
      ),
    );
    try {
      await MetadataFetch.extract(url).then((value) {
        if (value != null) {
          final title = SingleWord.dirty(value.title ?? '');
          final description = SingleWord.dirty(value.description ?? '');
          final imageUrl = value.image ?? '';
          final url = Url.dirty(value.url ?? '');
          emit(
            state.copyWith(
              urlFetchedStatus: UrlFetchedStatus.fetched,
              url: url,
              title: title,
              description: description,
              imageUrl: imageUrl,
              status: Formz.validate([title, description]),
            ),
          );
        } else {
          debugPrint('Error Fetching Url');
          emit(
            state.copyWith(
              isError: true,
              error: 'Error Fetching Url',
              urlFetchedStatus: UrlFetchedStatus.error,
              status: FormzStatus.invalid,
            ),
          );
        }
      });
    } on Exception catch (e) {
      debugPrint('Error Fetching Url: $e.');
      emit(
        state.copyWith(
          isError: true,
          urlFetchedStatus: UrlFetchedStatus.error,
          error: e.toString(),
          status: FormzStatus.invalid,
        ),
      );
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
          final skillId = BaseListItem();
          final skillIds = <BaseListItem>[skillId];
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

  ///   Called when the user wants to update the [resource]
  Future<void> editResource(Resource? resource) async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );
    final url = state.url.value.isNotEmpty ? state.url.value : resource?.url;

    debugPrint('url empty?: ${state.url.value.isEmpty}');
    await MetadataFetch.extract(url.toString()).then((value) {
      if (value != null && resource != null) {
        final editedResource = Resource(
          id: resource.id,
          name: state.title.value,
          thumbnail: resource.thumbnail,
          description: state.description.value,
          url: url,
          numberOfRates: resource.numberOfRates,
          rating: resource.rating,
          skillTreeIds: resource.skillTreeIds,
          usersWhoRated: resource.usersWhoRated,
          lastEditBy: usersProfile?.name ?? '',
          lastEditDate: DateTime.now(),
        );

        try {
          _resourcesRepository.createOrUpdateResource(resource: editedResource);
          emit(state.copyWith(status: FormzStatus.submissionSuccess));
        } on FirebaseException catch (e) {
          debugPrint('Error: ${e.message}');
          emit(state.copyWith(status: FormzStatus.submissionFailure));
        }
      }
    });
  }

  //  Clears the error message
  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }
}
