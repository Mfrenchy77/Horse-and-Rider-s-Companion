part of 'create_resource_dialog_cubit.dart';

enum UrlFetchedStatus { initial, fetching, fetched, error }

// ignore: constant_identifier_names
enum DifficultyFilter { All, Introductory, Intermediate, Advanced }

// ignore: constant_identifier_names
enum CategoryFilter { All, In_Hand, Husbandry, Mounted,Other }

class CreateResourceDialogState extends Equatable {
  const CreateResourceDialogState({
    this.resource,
    this.title = '',
    this.error = '',
    this.usersProfile,
    this.imageUrl = '',
    this.resourceSkills,
    this.isEdit = false,
    this.filteredSkills,
    this.isError = false,
    this.description = '',
    this.skills = const [],
    this.url = const Url.pure(),
    this.status = FormStatus.initial,
    this.categoryFilter = CategoryFilter.All,
    this.difficultyFilter = DifficultyFilter.All,
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

  /// The title of the resource
  final String title;

  /// The image url of the resource
  final String imageUrl;

  /// The resource that is being created/edited
  final Resource? resource;

  /// The status of the form
  final FormStatus status;

  /// The description of the resource
  final String description;

  /// The skills that are associated with the resource
  final List<Skill?> skills;

  /// The profile of the user who is creating the resource
  final RiderProfile? usersProfile;

  /// All the skills that are filtered
  final List<Skill?>? filteredSkills;

  /// The category filter
  final CategoryFilter categoryFilter;

  /// The skills that are associated with the resource
  final List<Skill?>? resourceSkills;

  /// The status of the url fetching
  final UrlFetchedStatus urlFetchedStatus;

  /// The difficulty filter
  final DifficultyFilter difficultyFilter;

  CreateResourceDialogState copyWith({
    Url? url,
    bool? isEdit,
    String? title,
    String? error,
    bool? isError,
    String? imageUrl,
    Resource? resource,
    FormStatus? status,
    String? description,
    List<Skill?>? skills,
    RiderProfile? usersProfile,
    List<Skill?>? filteredSkills,
    List<Skill?>? resourceSkills,
    CategoryFilter? categoryFilter,
    DifficultyFilter? difficultyFilter,
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
      filteredSkills: filteredSkills ?? this.filteredSkills,
      resourceSkills: resourceSkills ?? this.resourceSkills,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
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
        categoryFilter,
        filteredSkills,
        resourceSkills,
        difficultyFilter,
        urlFetchedStatus,
      ];
}
