// ignore_for_file: constant_identifier_names

part of 'create_resource_dialog_cubit.dart';

enum UrlFetchedStatus { initial, fetching, manual, fetched, error }

enum ResourceSubmitStatus { initial, submitting, success, error }

enum DifficultyFilter { All, Introductory, Intermediate, Advanced }

enum CategoryFilter { All, In_Hand, Husbandry, Mounted, Other }

enum ResourceInputType { link, pdf }

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
    this.submitStatus = ResourceSubmitStatus.initial,
    this.inputType = ResourceInputType.link,
    // PDF fields
    this.pdfName,
    this.pdfBytes,
    this.pdfPicking = false,
    this.pdfUploading = false,
    this.pdfUploadProgress = 0.0,
  });

  final Url url;
  final bool isEdit;
  final String error;
  final bool isError;
  final String title;
  final String imageUrl;
  final Resource? resource;
  final FormStatus status;
  final String description;

  final List<Skill?> skills;
  final RiderProfile? usersProfile;

  final List<Skill?>? filteredSkills;
  final CategoryFilter categoryFilter;
  final List<Skill?>? resourceSkills;
  final ResourceSubmitStatus submitStatus;
  final UrlFetchedStatus urlFetchedStatus;
  final DifficultyFilter difficultyFilter;

  // Input type
  final ResourceInputType inputType;

  // PDF
  final String? pdfName;
  final Uint8List? pdfBytes;
  final bool pdfPicking;
  final bool pdfUploading;
  final double pdfUploadProgress;

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
    ResourceSubmitStatus? submitStatus,
    ResourceInputType? inputType,
    // PDF
    String? pdfName,
    Uint8List? pdfBytes,
    bool? pdfPicking,
    bool? pdfUploading,
    double? pdfUploadProgress,
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
      submitStatus: submitStatus ?? this.submitStatus,
      filteredSkills: filteredSkills ?? this.filteredSkills,
      resourceSkills: resourceSkills ?? this.resourceSkills,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
      urlFetchedStatus: urlFetchedStatus ?? this.urlFetchedStatus,
      inputType: inputType ?? this.inputType,
      // PDF
      pdfName: pdfName ?? this.pdfName,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      pdfPicking: pdfPicking ?? this.pdfPicking,
      pdfUploading: pdfUploading ?? this.pdfUploading,
      pdfUploadProgress: pdfUploadProgress ?? this.pdfUploadProgress,
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
        submitStatus,
        categoryFilter,
        filteredSkills,
        resourceSkills,
        difficultyFilter,
        urlFetchedStatus,
        inputType,
        pdfName,
        pdfBytes,
        pdfPicking,
        pdfUploading,
        pdfUploadProgress,
      ];
}
