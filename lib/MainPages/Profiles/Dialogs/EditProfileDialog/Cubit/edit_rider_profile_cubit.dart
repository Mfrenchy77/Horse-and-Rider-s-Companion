// ignore_for_file: cast_nullable_to_non_nullable

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/location_lookup_service.dart';
import 'package:image_picker/image_picker.dart';

part 'edit_rider_profile_state.dart';

class EditRiderProfileCubit extends Cubit<EditRiderProfileState> {
  EditRiderProfileCubit({
    required User? user,
    required this._riderProfile,
    required ApiKeyProvider keysRepository,
    required this._cloudRepository,
    required this._riderProfileRepository,
    LocationLookupService? locationLookupService,
  }) : _user = user,
       _locationLookupService =
           locationLookupService ??
           LocationLookupService(keysRepository: keysRepository),
       super(const EditRiderProfileState()) {
    _locationLookupService.warmUp();
    emit(
      state.copyWith(
        user: _user,
        bio: _riderProfile?.bio,
        riderProfile: _riderProfile,
        picUrl: _riderProfile?.picUrl,
        homeUrl: _riderProfile?.homeUrl,
        selectedCity: _riderProfile?.cityName,
        selectedState: _riderProfile?.stateName,
        locationName: _riderProfile?.locationName,
        selectedCountry: _riderProfile?.countryName,
        isTrainer: _riderProfile?.isTrainer ?? false,
        riderName: _user?.name ?? _riderProfile?.name,
        id: _user != null ? user?.id : _riderProfile?.id,
        zipCode: ZipCode.dirty(_riderProfile?.zipCode ?? ''),
      ),
    );
  }

  final User? _user;
  final RiderProfile? _riderProfile;
  final MediaStorageRepository _cloudRepository;
  final RiderProfileStore _riderProfileRepository;
  final LocationLookupService _locationLookupService;

  void riderNameChanged({required String value}) {
    emit(state.copyWith(riderName: value));
  }

  void riderBioChanged({required String value}) {
    emit(state.copyWith(bio: value));
  }

  void riderLocationChanged({required String value}) {
    final zipCode = ZipCode.dirty(value);
    emit(state.copyWith(locationName: '', zipCode: zipCode));
  }

  /// Toggle the trainer status
  void toggleTrainerStatus() {
    emit(state.copyWith(isTrainer: !state.isTrainer));
  }

  void riderHomeUrlChanged({required String value}) {
    emit(state.copyWith(homeUrl: value));
  }

  Future<void> riderProfilePicClicked() async {
    String? picUrl;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      emit(state.copyWith(isSubmitting: true));
      picUrl = await _cloudRepository.addRiderPhoto(
        file: pickedFile,
        riderId: state.id,
      );
      if (picUrl != null) {
        emit(state.copyWith(picUrl: picUrl, isSubmitting: false));
      } else {
        emit(
          state.copyWith(
            isSubmitting: false,
            error: 'Error uploading image',
            status: SubmissionStatus.failure,
          ),
        );
        clearError();
      }
    }
  }

  /// Toggle the location search
  void toggleLocationSearch() {
    emit(state.copyWith(isLocationSearch: !state.isLocationSearch));
  }

  void riderZipCodeChanged({required String value}) {
    final zipCode = ZipCode.dirty(value);
    emit(state.copyWith(zipCode: zipCode));
  }

  /// Get the list of countries from the location api
  Future<List<Country>> getCountries() {
    return _locationLookupService.getCountries();
  }

  /// Get the list of states from the location api
  /// [countryIso] is the iso code for the country
  Future<List<StateLocation>> getStates({required String countryIso}) {
    return _locationLookupService.getStates(countryIso: countryIso);
  }

  /// Get the list of cities from the location api
  /// [stateIso] is the id of the state
  /// [countryIso] is the iso code for the country
  Future<List<City>> getCities({
    required String stateIso,
    required String countryIso,
  }) {
    return _locationLookupService.getCities(
      stateIso: stateIso,
      countryIso: countryIso,
    );
  }

  void countryChanged({
    required String countryIso,
    required String countryName,
  }) {
    emit(state.copyWith(countryIso: countryIso, selectedCountry: countryName));
  }

  void stateChanged({required String stateId, required String stateName}) {
    emit(state.copyWith(stateId: stateId, selectedState: stateName));
  }

  void cityChanged({required String city}) {
    emit(state.copyWith(selectedCity: city));
  }

  void locationSelected({
    required String locationName,
    required String selectedZipCode,
  }) {
    final zipCode = ZipCode.dirty(selectedZipCode);
    emit(state.copyWith(locationName: locationName, zipCode: zipCode));
  }

  Future<void> _searchForZip() async {
    emit(state.copyWith(autoCompleteStatus: AutoCompleteStatus.loading));

    if (state.countryIso != null &&
        state.selectedCity != null &&
        state.selectedState != null) {
      try {
        final zipResponse = await _locationLookupService.queryZipcode(
          city: state.selectedCity!,
          country: state.countryIso!,
          state: state.selectedState!,
        );
        if (zipResponse != null && zipResponse.results.results.isNotEmpty) {
          if (zipResponse.results.results.length > 1) {
            emit(
              state.copyWith(
                prediction: zipResponse.results,
                autoCompleteStatus: AutoCompleteStatus.success,
              ),
            );
          } else {
            final zipCode = ZipCode.dirty(
              zipResponse.results.results.keys.elementAt(0),
            );
            emit(
              state.copyWith(
                zipCode: zipCode,
                prediction: zipResponse.results,
                autoCompleteStatus: AutoCompleteStatus.success,
              ),
            );
          }
        }
      } catch (e) {
        emit(
          state.copyWith(
            autoCompleteStatus: AutoCompleteStatus.error,
            error: e.toString(),
          ),
        );
      }
    }
  }

  void countrySelected({required String country, required String countryIso}) {
    emit(state.copyWith(selectedCountry: country, countryIso: countryIso));
  }

  void stateSelected(String selectedState) {
    emit(state.copyWith(selectedState: selectedState));
  }

  void citySelected(String city) {
    emit(state.copyWith(selectedCity: city));
    _searchForZip();
  }

  Future<void> updateRiderProfile() async {
    emit(state.copyWith(status: SubmissionStatus.inProgress));
    final riderProfile = state.riderProfile;

    // Create a new instance of riderProfile with updated values
    final updatedRiderProfile = riderProfile?.copyWith(
      id: state.id,
      bio: state.bio,
      picUrl: state.picUrl,
      name: state.riderName,
      homeUrl: state.homeUrl,
      stateIso: state.stateId,
      isTrainer: state.isTrainer,
      lastEditBy: state.riderName,
      cityName: state.selectedCity,
      lastEditDate: DateTime.now(),
      zipCode: state.zipCode.value,
      countryIso: state.countryIso,
      stateName: state.selectedState,
      locationName: state.locationName,
      countryName: state.selectedCountry,
    );

    if (updatedRiderProfile != null) {
      try {
        await _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: updatedRiderProfile,
        );
        emit(state.copyWith(status: SubmissionStatus.success));
      } catch (e, stackTrace) {
        AppLogger.error(
          LogCategory.profile,
          'Failed to update rider profile',
          error: e,
          stackTrace: stackTrace,
        );
        emit(
          state.copyWith(
            status: SubmissionStatus.failure,
            error: e.toString(),
            isError: true,
          ),
        );
        clearError();
      }
    } else {
      AppLogger.warning(
        LogCategory.profile,
        'Cannot update profile: riderProfile is null',
      );
    }
  }

  ///   Called when a new user creates and account,
  ///   but a Horse and Rider Profile   is not set up for them
  Future<void> createRiderProfile() async {
    if (state.user?.name != null) {
      final String finalName;
      if (state.riderName != state.user?.name) {
        finalName = state.riderName;
      } else {
        finalName = state.user?.name ?? '';
      }

      final note = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: "$finalName joined Horse & Rider's Companion!",
        date: DateTime.now(),
        message: state.user?.name,
        parentId: state.user?.email,
      );

      final riderProfile = RiderProfile(
        id: state.id,
        notes: [note],
        bio: state.bio,
        name: finalName,
        picUrl: state.picUrl,
        lastEditBy: finalName,
        homeUrl: state.homeUrl,
        stateIso: state.stateId,
        lastEditDate: DateTime.now(),
        zipCode: state.zipCode.value,
        cityName: state.selectedCity,
        countryIso: state.countryIso,
        email: state.user?.email ?? '',
        stateName: state.selectedState,
        locationName: state.locationName,
        countryName: state.selectedCountry,
      );
      try {
        emit(state.copyWith(status: SubmissionStatus.inProgress));
        await _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: riderProfile,
        );
        emit(state.copyWith(status: SubmissionStatus.success));
      } on RepositoryException catch (e, stackTrace) {
        AppLogger.error(
          LogCategory.profile,
          'Failed to create rider profile: ${e.message}',
          error: e,
          stackTrace: stackTrace,
        );
        emit(
          state.copyWith(
            status: SubmissionStatus.failure,
            error: e.toString(),
            isError: true,
          ),
        );
        clearError();
      }
    } else {
      AppLogger.warning(
        LogCategory.profile,
        'Cannot create rider profile: user is null',
      );
      emit(state.copyWith(error: 'User is null', isError: true));
      clearError();
    }
  }

  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }
}
