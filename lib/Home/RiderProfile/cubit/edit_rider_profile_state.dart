part of 'edit_rider_profile_cubit.dart';

enum SubmissionStatus { inProgress, success, failure, initial }

enum AutoCompleteStatus { loading, success, initial, error }

class EditRiderProfileState extends Equatable {
  const EditRiderProfileState({
    this.picUrl,
    this.bio = '',
    this.prediction,
    this.error = '',
    this.riderProfile,
    this.homeUrl = '',
    this.riderName = '',
    this.isError = false,
    this.locationName = '',
    this.isSubmitting = false,
    this.isLocationSearch = false,
    this.zipCode = const ZipCode.pure(),
    this.status = SubmissionStatus.initial,
    this.locationStatus = FormzStatus.pure,
    this.autoCompleteStatus = AutoCompleteStatus.initial,
  });
  final String bio;
  final bool isError;
  final String error;
  final String? picUrl;
  final String homeUrl;
  final ZipCode zipCode;
  final String riderName;
  final bool isSubmitting;
  final String locationName;
  final bool isLocationSearch;
  final SubmissionStatus status;
  final RiderProfile? riderProfile;
  final FormzStatus locationStatus;
  final PostalCodeResults? prediction;
  final AutoCompleteStatus autoCompleteStatus;

  EditRiderProfileState copyWith({
    String? bio,
    bool? isError,
    String? error,
    String? picUrl,
    String? homeUrl,
    ZipCode? zipCode,
    String? riderName,
    bool? isSubmitting,
    String? locationName,
    bool? isLocationSearch,
    SubmissionStatus? status,
    RiderProfile? riderProfile,
    FormzStatus? locationStatus,
    PostalCodeResults? prediction,
    AutoCompleteStatus? autoCompleteStatus,
  }) {
    return EditRiderProfileState(
      bio: bio ?? this.bio,
      error: error ?? this.error,
      picUrl: picUrl ?? this.picUrl,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      homeUrl: homeUrl ?? this.homeUrl,
      zipCode: zipCode ?? this.zipCode,
      riderName: riderName ?? this.riderName,
      prediction: prediction ?? this.prediction,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      riderProfile: riderProfile ?? this.riderProfile,
      locationName: locationName ?? this.locationName,
      locationStatus: locationStatus ?? this.locationStatus,
      isLocationSearch: isLocationSearch ?? this.isLocationSearch,
      autoCompleteStatus: autoCompleteStatus ?? this.autoCompleteStatus,
    );
  }

  @override
  List<Object?> get props => [
        bio,
        error,
        picUrl,
        status,
        homeUrl,
        isError,
        zipCode,
        riderName,
        prediction,
        riderProfile,
        isSubmitting,
        locationName,
        locationStatus,
        isLocationSearch,
        autoCompleteStatus,
      ];
}
