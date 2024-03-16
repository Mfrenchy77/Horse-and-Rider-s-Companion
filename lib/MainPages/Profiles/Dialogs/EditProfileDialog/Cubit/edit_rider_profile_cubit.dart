// ignore_for_file: cast_nullable_to_non_nullable

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:image_picker/image_picker.dart';

part 'edit_rider_profile_state.dart';

class EditRiderProfileCubit extends Cubit<EditRiderProfileState> {
  EditRiderProfileCubit({
    required User? user,
    required RiderProfile? riderProfile,
    required KeysRepository keysRepository,
    required CloudRepository cloudRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _user = user,
        _riderProfile = riderProfile,
        _keysRepository = keysRepository,
        _cloudRepository = cloudRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const EditRiderProfileState()) {
    _keysRepository.getZipCodeApiKey().then((value) => _zipApi = value);
    _keysRepository
        .getLocationApiKey()
        .then((value) => _locationApiKey = value);
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
        riderName: _user?.name ?? _riderProfile?.name,
        id: _user != null ? user?.id : _riderProfile?.id,
        zipCode: ZipCode.dirty(_riderProfile?.zipCode ?? ''),
      ),
    );
  }

  final User? _user;
  late String _zipApi = '';
  String _locationApiKey = '';
  final RiderProfile? _riderProfile;
  final KeysRepository _keysRepository;
  final CloudRepository _cloudRepository;
  final RiderProfileRepository _riderProfileRepository;

  void riderNameChanged({required String value}) {
    emit(state.copyWith(riderName: value));
  }

  void riderBioChanged({required String value}) {
    emit(state.copyWith(bio: value));
  }

  void riderLocationChanged({required String value}) {
    final zipCode = ZipCode.dirty(value);
    emit(
      state.copyWith(
        locationName: '',
        zipCode: zipCode,
        locationStatus: Formz.validate([zipCode]),
      ),
    );
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
      imageQuality: 20,
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
      }
    }
  }

  /// Toggle the location search
  void toggleLocationSearch() {
    emit(state.copyWith(isLocationSearch: !state.isLocationSearch));
  }

  void riderZipCodeChanged({required String value}) {
    final zipCode = ZipCode.dirty(value);
    emit(
      state.copyWith(
        zipCode: zipCode,
        locationStatus: Formz.validate([zipCode]),
      ),
    );
  }

  /// Get the list of countries from the location api
  Future<List<Country>> getCountries() async {
    final locationRepository = LocationRepository(apiKey: _locationApiKey);
    return locationRepository.getCountries();
  }

  /// Get the list of states from the location api
  /// [countryIso] is the iso code for the country
  Future<List<StateLocation>> getStates({required String countryIso}) async {
    final locationRepository = LocationRepository(apiKey: _locationApiKey);
    return locationRepository.getStates(countryIso: countryIso);
  }

  /// Get the list of cities from the location api
  /// [stateIso] is the id of the state
  /// [countryIso] is the iso code for the country
  Future<List<City>> getCities({
    required String stateIso,
    required String countryIso,
  }) async {
    debugPrint('Getting Cities for $stateIso, $countryIso');
    final locationRepository = LocationRepository(apiKey: _locationApiKey);
    return locationRepository.getCities(
      stateIso: stateIso,
      countryCode: countryIso,
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
    debugPrint('Location Name: $locationName');
    debugPrint('Zip Code: $selectedZipCode');
    final zipCode = ZipCode.dirty(selectedZipCode);
    if (zipCode.valid) {
      emit(
        state.copyWith(
          locationName: locationName,
          zipCode: zipCode,
          locationStatus: Formz.validate([zipCode]),
        ),
      );
    } else {
      debugPrint('Zip Code is not valid');
      emit(
        state.copyWith(
          locationName: locationName,
          zipCode: zipCode,
          locationStatus: Formz.validate([zipCode]),
        ),
      );
    }
  }

  Future<void> _searchForZip() async {
    debugPrint('Searching by Zip Code');
    final zipcodeRepo = ZipcodeRepository(apiKey: _zipApi);

    emit(state.copyWith(autoCompleteStatus: AutoCompleteStatus.loading));

    if (state.countryIso != null &&
        state.selectedCity != null &&
        state.selectedState != null) {
      try {
        final zipResponse = await zipcodeRepo.queryZipcode(
          city: state.selectedCity!,
          country: state.countryIso!,
          state: state.selectedState!,
        );
        if (zipResponse != null && zipResponse.results.results.isNotEmpty) {
          if (zipResponse.results.results.length > 1) {
            debugPrint('More than one result');
            emit(
              state.copyWith(
                autoCompleteStatus: AutoCompleteStatus.success,
                prediction: zipResponse.results,
              ),
            );
          } else {
            debugPrint('One result');
            final zipCode =
                ZipCode.dirty(zipResponse.results.results.keys.elementAt(0));
            emit(
              state.copyWith(
                zipCode: zipCode,
                locationStatus: Formz.validate([zipCode]),
                autoCompleteStatus: AutoCompleteStatus.success,
                prediction: zipResponse.results,
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
    } else {
      debugPrint('No Country, State or City Selected');
    }
  }

  void countrySelected({required String country, required String countryIso}) {
    debugPrint('Country Selected: $country');
    emit(state.copyWith(selectedCountry: country, countryIso: countryIso));
  }

  void stateSelected(String selectedState) {
    debugPrint('State Selected: $selectedState');
    emit(state.copyWith(selectedState: selectedState));
  }

  void citySelected(String city) {
    debugPrint('City Selected: $city');
    emit(state.copyWith(selectedCity: city));
    _searchForZip();
  }

  Future<void> updateRiderProfile() async {
    emit(state.copyWith(status: SubmissionStatus.inProgress));
    final riderProfile = state.riderProfile;
    debugPrint('zipCode: ${state.zipCode.value}');
    debugPrint('locationName: ${state.locationName}');

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
      debugPrint('Editing Rider Profile ${updatedRiderProfile.name}');
      try {
        await _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: updatedRiderProfile,
        );
        emit(state.copyWith(status: SubmissionStatus.success));
      } catch (e) {
        debugPrint('Something went wrong: $e');
        emit(state.copyWith(status: SubmissionStatus.failure));
      }
    } else {
      debugPrint('Rider Profile is null');
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
      debugPrint(
        '111   111   Creating a New Profile for $finalName   !!!   !!!',
      );

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
        await _riderProfileRepository
            .createOrUpdateRiderProfile(
              riderProfile: riderProfile,
            )
            .then(
              (value) => emit(state.copyWith(status: SubmissionStatus.success)),
            );
      } on FirebaseException catch (e) {
        debugPrint('Error: ${e.message}');
        emit(state.copyWith(error: e.toString(), isError: true));
      }
    } else {
      debugPrint('User is null');
      emit(state.copyWith(error: 'User is null', isError: true));
    }
  }

  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }
}
