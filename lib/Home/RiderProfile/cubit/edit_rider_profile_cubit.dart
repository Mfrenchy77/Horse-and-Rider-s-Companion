// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';

part 'edit_rider_profile_state.dart';

class EditRiderProfileCubit extends Cubit<EditRiderProfileState> {
  EditRiderProfileCubit({
    required RiderProfile riderProfile,
    required KeysRepository keysRepository,
    required CloudRepository cloudRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _riderProfile = riderProfile,
        _keysRepository = keysRepository,
        _cloudRepository = cloudRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const EditRiderProfileState()) {
    _keysRepository.getZipCodeApiKey().then((value) => _zipApi = value);
    emit(
      state.copyWith(
        riderProfile: _riderProfile,
        bio: _riderProfile.bio,
        picUrl: _riderProfile.picUrl,
        riderName: _riderProfile.name,
        homeUrl: _riderProfile.homeUrl,
        locationName: _riderProfile.locationName,
        zipCode: ZipCode.dirty(_riderProfile.zipCode ?? ''),
      ),
    );
  }

  late String _zipApi;
  final RiderProfile _riderProfile;
  final KeysRepository _keysRepository;
  // late final GoogleMapsPlaces _places;
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

  void riderHomeUrlChanged({required String value}) {
    emit(state.copyWith(homeUrl: value));
  }

  Future<void> riderProfilePicClicked() async {
    String? picUrl;

    if (kIsWeb) {
      // Web-specific logic
      final webImageData = await ImagePickerWeb.getImageAsBytes();
      if (webImageData != null) {
        emit(state.copyWith(isSubmitting: true));
        picUrl = await _cloudRepository.addRiderPhoto(
          data: webImageData,
          riderId: _riderProfile.id as String,
        );
      }
    } else {
      // Mobile-specific logic
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 20,
      );
      if (pickedFile != null) {
        emit(state.copyWith(isSubmitting: true));
        final file = File(pickedFile.path);
        picUrl = await _cloudRepository.addRiderPhoto(
          path: file.path,
          riderId: _riderProfile.id as String,
        );
      }
    }
    if (picUrl != null) {
      emit(state.copyWith(picUrl: picUrl, isSubmitting: false));
    } else {
      emit(
        state.copyWith(
          isSubmitting: false,
          status: SubmissionStatus.failure,
          error: 'Error uploading image',
        ),
      );
      debugPrint('Pic Url is null');
    }
  }

  /// Toggle the location search
  void toggleLocationSearch() {
    emit(state.copyWith(isLocationSearch: !state.isLocationSearch));
  }

//method that opens a dialog to let user choose
// their city based on ther geo location
  Future<void> searchForLocation() async {
    final value = state.zipCode.value;
    final zipcodeRepo = ZipcodeRepository(apiKey: _zipApi);
    if (value.length >= 5) {
      emit(state.copyWith(autoCompleteStatus: AutoCompleteStatus.loading));
      try {
        final response = await zipcodeRepo.queryZipcode(value, country: 'us');
        if (response != null) {
          debugPrint('Response: ${response.results.results.length}');
          emit(
            state.copyWith(
              autoCompleteStatus: AutoCompleteStatus.success,
              prediction: response.results,
            ),
          );
        } else {
          emit(
            state.copyWith(
              autoCompleteStatus: AutoCompleteStatus.error,
              error: 'Error ',
            ),
          );
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

  // Future<void> getGeoPoint(Prediction prediction) async {
  //   await _places.getDetailsByPlaceId(prediction.placeId ?? '')
  //.then((value) {
  //     debugPrint('Location Name: ${value.result?.formattedAddress}');
  //     emit(
  //       state.copyWith(
  //         location: GeoPoint(
  //           value.result?.geometry?.location.lat as double,
  //           value.result?.geometry?.location.lng as double,
  //         ),
  //         locationName: prediction.description,
  //         autoCompleteStatus: AutoCompleteStatus.initial,
  //       ),
  //     );

  //     debugPrint('State Location Name: ${state.locationName}');
  //   });
  // }
  Future<void> updateRiderProfile() async {
    emit(state.copyWith(status: SubmissionStatus.inProgress));
    final riderProfile = state.riderProfile;
    debugPrint('zipCode: ${state.zipCode.value}');
    debugPrint('locationName: ${state.locationName}');

    // Create a new instance of riderProfile with updated values
    final updatedRiderProfile = riderProfile?.copyWith(
      bio: state.bio,
      picUrl: state.picUrl,
      name: state.riderName,
      homeUrl: state.homeUrl,
      lastEditDate: DateTime.now(),
      zipCode: state.zipCode.value,
      lastEditBy: _riderProfile
          .name, // Ensure _riderProfile.name is the correct reference
      locationName: state.locationName,
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

  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }
}
