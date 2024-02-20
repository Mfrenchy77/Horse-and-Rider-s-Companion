part of 'edit_rider_profile_cubit.dart';

enum SubmissionStatus { inProgress, success, failure, initial }

enum AutoCompleteStatus { loading, success, initial, error }

class EditRiderProfileState extends Equatable {
  const EditRiderProfileState({
    this.picUrl,
    this.stateId,
    this.bio = '',
    this.countryIso,
    this.prediction,
    this.error = '',
    this.riderProfile,
    this.selectedCity,
    this.homeUrl = '',
    this.selectedState,
    this.selectedCountry,
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
  final String? stateId;
  final ZipCode zipCode;
  final String riderName;
  final bool isSubmitting;
  final String? countryIso;
  final String locationName;
  final String? selectedCity;
  final String? selectedState;
  final bool isLocationSearch;
  final String? selectedCountry;
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
    String? stateId,
    String? homeUrl,
    ZipCode? zipCode,
    String? riderName,
    String? countryIso,
    bool? isSubmitting,
    String? locationName,
    String? selectedCity,
    String? selectedState,
    bool? isLocationSearch,
    String? selectedCountry,
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
      stateId: stateId ?? this.stateId,
      riderName: riderName ?? this.riderName,
      prediction: prediction ?? this.prediction,
      countryIso: countryIso ?? this.countryIso,
      selectedCity: selectedCity ?? this.selectedCity,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      riderProfile: riderProfile ?? this.riderProfile,
      locationName: locationName ?? this.locationName,
      selectedState: selectedState ?? this.selectedState,
      locationStatus: locationStatus ?? this.locationStatus,
      selectedCountry: selectedCountry ?? this.selectedCountry,
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
        stateId,
        riderName,
        countryIso,
        prediction,
        riderProfile,
        isSubmitting,
        locationName,
        selectedCity,
        selectedState,
        locationStatus,
        selectedCountry,
        isLocationSearch,
        autoCompleteStatus,
      ];
}
