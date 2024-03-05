part of 'profile_search_cubit.dart';


enum SearchType {
  email,
  name,
  horse,
  horseId,
  horseNickName,
  horseLocation,
  riderLocation,
}

class ProfileSearchState extends Equatable {
  const ProfileSearchState({
    this.error = '',
    this.isError = false,
    this.searchValue = '',
    this.isSearchRider = true,
    this.riderProfiles = const [],
    this.horseProfiles = const [],
    this.status = FormzStatus.pure,
    this.email = const Email.pure(),
    this.searchType = SearchType.name,
    this.zipCode = const ZipCode.pure(),
    this.locationRange = const LocationRange.pure(),
  });

  /// This is used when the user is searching for a rider by email
  final Email email;

  /// This is the error message if the search fails
  final String error;

  /// This marks the search as an error
  final bool isError;

  /// This is used when the user is searching for a rider or horse by zip code
  final ZipCode zipCode;

  /// This is the status of the search
  final FormzStatus status;

  /// This determines if the Search is for a rider or a horse
  final bool isSearchRider;

  /// This is used when the user is searching for a rider or horse by name
  final String searchValue;

  /// This is the Type of search the user is performing
  final SearchType searchType;

  /// This is the location range when searching for a profile
  /// by area
  final LocationRange locationRange;

  /// This is the search result list of Rider Profiles
  final List<RiderProfile> riderProfiles;

  /// This is the search result list of Horse Profiles
  final List<HorseProfile> horseProfiles;

  ProfileSearchState copyWith({
    Email? email,
    String? error,
    bool? isError,
    ZipCode? zipCode,
    bool? isSearchRider,
    FormzStatus? status,
    String? searchValue,
    SearchType? searchType,
    LocationRange? locationRange,
    List<RiderProfile>? riderProfiles,
    List<HorseProfile>? horseProfiles,
  }) {
    return ProfileSearchState(
      email: email ?? this.email,
      error: error ?? this.error,
      status: status ?? this.status,
      zipCode: zipCode ?? this.zipCode,
      isError: isError ?? this.isError,
      searchType: searchType ?? this.searchType,
      searchValue: searchValue ?? this.searchValue,
      locationRange: locationRange ?? this.locationRange,
      riderProfiles: riderProfiles ?? this.riderProfiles,
      horseProfiles: horseProfiles ?? this.horseProfiles,
      isSearchRider: isSearchRider ?? this.isSearchRider,
    );
  }

  @override
  List<Object> get props => [
        email,
        error,
        status,
        isError,
        zipCode,
        searchType,
        searchValue,
        locationRange,
        riderProfiles,
        horseProfiles,
        isSearchRider,
      ];
}
