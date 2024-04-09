part of 'create_resource_dialog_cubit.dart';

enum UrlFetchedStatus { initial, fetching, fetched, error }

class CreateResourceDialogState extends Equatable {
  const CreateResourceDialogState({
    this.skills,
    this.resource,
    this.error = '',
    this.usersProfile,
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

  /// The url of the resource
  final Url url;

  /// Whether the resource is being edited
  final bool isEdit;

  /// The error message of the form
  final String error;

  /// Whether there is an error in the form
  final bool isError;

  /// The image url of the resource
  final String imageUrl;

  /// The title of the resource
  final SingleWord title;

  /// The resource that is being created/edited
  final Resource? resource;

  /// The status of the form
  final FormzStatus status;

  /// The skills that are associated with the resource
  final List<Skill?>? skills;

  /// The description of the resource
  final SingleWord description;

  /// The profile of the user who is creating the resource
  final RiderProfile? usersProfile;

  /// The skills that are associated with the resource
  final List<Skill?>? resourceSkills;

  /// The status of the url fetching
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
    RiderProfile? usersProfile,
    List<Skill?>? resourceSkills,
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
      usersProfile: usersProfile ?? this.usersProfile,
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
        usersProfile,
        resourceSkills,
        urlFetchedStatus,
      ];
}
