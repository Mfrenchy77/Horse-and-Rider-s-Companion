part of 'edit_rider_profile_cubit.dart';

enum SubmissionStatus { inProgress, success, failure, initial }

enum AutoCompleteStatus { loading, success, initial, error }

class EditRiderProfileState extends Equatable {
  const EditRiderProfileState({
    this.bio = '',
    this.error = '',
    this.homeUrl = '',
    this.riderName = '',
    this.locationName = '',
    this.prediction = const [],
    this.location = const GeoPoint(0, 0),
    this.status = SubmissionStatus.initial,
    this.autoCompleteStatus = AutoCompleteStatus.initial,
  });
  final String bio;
  final String error;
  final String homeUrl;
  final String riderName;
  final GeoPoint location;
  final String locationName;
  final SubmissionStatus status;
  final List<Prediction> prediction;
  final AutoCompleteStatus autoCompleteStatus;

  EditRiderProfileState copyWith({
    String? bio,
    String? error,
    String? homeUrl,
    String? riderName,
    GeoPoint? location,
    String? locationName,
    SubmissionStatus? status,
    List<Prediction>? prediction,
    AutoCompleteStatus? autoCompleteStatus,
  }) {
    return EditRiderProfileState(
      bio: bio ?? this.bio,
      error: error ?? this.error,
      status: status ?? this.status,
      homeUrl: homeUrl ?? this.homeUrl,
      location: location ?? this.location,
      riderName: riderName ?? this.riderName,
      prediction: prediction ?? this.prediction,
      locationName: locationName ?? this.locationName,
      autoCompleteStatus: autoCompleteStatus ?? this.autoCompleteStatus,
    );
  }

  @override
  List<Object> get props => [
        riderName,
        bio,
        location,
        homeUrl,
        status,
        locationName,
        prediction,
        autoCompleteStatus,
        error,
      ];
}
