part of 'edit_rider_profile_cubit.dart';

enum SubmissionStatus { inProgress, success, failure, initial }

enum AutoCompleteStatus { loading, success, initial, error }

class EditRiderProfileState extends Equatable {
  const EditRiderProfileState({
    this.user,
    this.picUrl,
    this.stateId,
    this.id = '',
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
    this.isTrainer = false,
    this.isSubmitting = false,
    this.isLocationSearch = false,
    this.zipCode = const ZipCode.pure(),
    this.status = SubmissionStatus.initial,
    this.locationStatus = FormzStatus.pure,
    this.autoCompleteStatus = AutoCompleteStatus.initial,
  });

  /// Id of the rider/user
  final String id;

  /// Nullable User to determine if the user is
  /// registered or not
  final User? user;

  /// The bio of the rider
  final String bio;

  /// Boolean to determine if there is an error
  final bool isError;

  /// The error message
  final String error;

  /// The picture url of the rider
  final String? picUrl;

  /// Whether the user is a trainer/instructor or not
  final bool isTrainer;

  /// The home url of the rider
  final String homeUrl;

  /// The state id of the rider
  final String? stateId;

  /// The zip code of the rider
  final ZipCode zipCode;

  /// The name of the rider
  final String riderName;

  /// Boolean to determine if the form is submitting
  final bool isSubmitting;

  /// The country iso of the rider
  final String? countryIso;

  /// The location name of the rider
  final String locationName;

  /// The selected city of the rider
  final String? selectedCity;

  /// The selected state of the rider
  final String? selectedState;

  /// Boolean to determine if the location is being searched
  final bool isLocationSearch;

  /// The selected country of the rider
  final String? selectedCountry;

  /// The status of the submission
  final SubmissionStatus status;

  /// The rider profile
  final RiderProfile? riderProfile;

  /// The status of the location
  final FormzStatus locationStatus;

  /// The prediction of the postal code
  final PostalCodeResults? prediction;

  /// The status of the auto complete
  final AutoCompleteStatus autoCompleteStatus;

  /// The copyWith method is used to create a new instance of
  ///  the [EditRiderProfileState]
  EditRiderProfileState copyWith({
    String? id,
    User? user,
    String? bio,
    bool? isError,
    String? error,
    String? picUrl,
    String? stateId,
    bool? isTrainer,
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
      id: id ?? this.id,
      bio: bio ?? this.bio,
      user: user ?? this.user,
      error: error ?? this.error,
      picUrl: picUrl ?? this.picUrl,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      homeUrl: homeUrl ?? this.homeUrl,
      zipCode: zipCode ?? this.zipCode,
      stateId: stateId ?? this.stateId,
      isTrainer: isTrainer ?? this.isTrainer,
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

  /// The props for the [Equatable] package
  @override
  List<Object?> get props => [
        id,
        bio,
        user,
        error,
        picUrl,
        status,
        homeUrl,
        isError,
        zipCode,
        stateId,
        isTrainer,
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
