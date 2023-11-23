part of 'create_resource_dialog_cubit.dart';

enum UrlFetchedStatus { initial, fetching, fetched, error }

class CreateResourceDialogState extends Equatable {
  const CreateResourceDialogState({
    this.skills,
    this.resource,
    this.error = '',
    this.imageUrl = '',
    this.resourceSkills,
    this.isEdit = false,
    this.isError = false,
    this.url = const Url.pure(),
    this.status = FormzStatus.pure,
    this.title = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
    this.urlFetchedStatus = UrlFetchedStatus.initial,
  });

  final Url url;
  final bool isEdit;
  final String error;
  final bool isError;
  final String imageUrl;
  final SingleWord title;
  final Resource? resource;
  final FormzStatus status;
  final List<Skill?>? skills;
  final SingleWord description;
  final List<String?>? resourceSkills;
  final UrlFetchedStatus urlFetchedStatus;

  CreateResourceDialogState copyWith({
    Url? url,
    bool? isEdit,
    String? error,
    bool? isError,
    String? imageUrl,
    SingleWord? title,
    Resource? resource,
    FormzStatus? status,
    List<Skill?>? skills,
    SingleWord? description,
    List<String?>? resourceSkills,
    UrlFetchedStatus? urlFetchedStatus,
  }) {
    return CreateResourceDialogState(
      url: url ?? this.url,
      error: error ?? this.error,
      title: title ?? this.title,
      isEdit: isEdit ?? this.isEdit,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      resource: resource ?? this.resource,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      resourceSkills: resourceSkills ?? this.resourceSkills,
      urlFetchedStatus: urlFetchedStatus ?? this.urlFetchedStatus,
    );
  }

  @override
  List<Object?> get props => [
        url,
        title,
        error,
        isEdit,
        skills,
        status,
        isError,
        resource,
        imageUrl,
        description,
        resourceSkills,
        urlFetchedStatus,
      ];
}
