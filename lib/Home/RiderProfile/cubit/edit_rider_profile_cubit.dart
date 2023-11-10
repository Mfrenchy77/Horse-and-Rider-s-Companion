// ignore_for_file: cast_nullable_to_non_nullable

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:image_picker/image_picker.dart';

part 'edit_rider_profile_state.dart';

class EditRiderProfileCubit extends Cubit<EditRiderProfileState> {
  EditRiderProfileCubit({
    required KeysRepository keysRepository,
    required RiderProfile riderProfile,
    required CloudRepository cloudRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _riderProfile = riderProfile,
        _keysRepository = keysRepository,
        _cloudRepository = cloudRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const EditRiderProfileState()) {
    _keysRepository
        .getMapsApiKey()
        .then((value) => _places = GoogleMapsPlaces(apiKey: value));
  }

  final RiderProfile _riderProfile;
  final RiderProfileRepository _riderProfileRepository;
  final CloudRepository _cloudRepository;
  final KeysRepository _keysRepository;
  late final GoogleMapsPlaces _places;

  void riderNameChanged({required String value}) {
    emit(state.copyWith(riderName: value));
  }

  void riderBioChanged({required String value}) {
    emit(state.copyWith(bio: value));
  }

  void riderLocationChanged({required GeoPoint value}) {
    emit(state.copyWith(location: value));
  }

  void riderHomeUrlChanged({required String value}) {
    emit(state.copyWith(homeUrl: value));
  }

  Future<void> riderProfilePicClicked() async {
    final picker = ImagePicker();
    XFile? pickedFile;

    pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );
    if (pickedFile != null) {
      final picUrl = await _cloudRepository.addRiderPhoto(
        path: pickedFile.path,
        riderId: _riderProfile.id as String,
      );
      if (picUrl != null) {
        _riderProfile
          ..picUrl = picUrl
          ..lastEditBy = _riderProfile.name
          ..lastEditDate = DateTime.now();
        await _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: _riderProfile,
        );
      }
    }
  }

//method that opens a dialog to let user choose
// their city based on ther geo location
  Future<void> autoCompleteLocation({required String value}) async {
    if (value.length >= 3) {
      try {
        final response = await _places.autocomplete(value);
        if (response.status == 'OK') {
          emit(
            state.copyWith(
              autoCompleteStatus: AutoCompleteStatus.success,
              prediction: response.predictions,
            ),
          );
        } else {
          emit(
            state.copyWith(
              autoCompleteStatus: AutoCompleteStatus.error,
              error: response.errorMessage,
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

  Future<void> getGeoPoint(Prediction prediction) async {
    await _places.getDetailsByPlaceId(prediction.placeId ?? '').then((value) {
      debugPrint('Location Name: ${value.result?.formattedAddress}');
      emit(
        state.copyWith(
          location: GeoPoint(
            value.result?.geometry?.location.lat as double,
            value.result?.geometry?.location.lng as double,
          ),
          locationName: prediction.description,
          autoCompleteStatus: AutoCompleteStatus.initial,
        ),
      );

      debugPrint('State Location Name: ${state.locationName}');
    });
  }

  Future<void> updateRiderProfile() async {
    emit(state.copyWith(status: SubmissionStatus.inProgress));

    _riderProfile
      ..name = state.riderName == '' ? _riderProfile.name : state.riderName
      ..location = state.location == const GeoPoint(0, 0)
          ? _riderProfile.location
          : state.location
      ..bio = state.bio == '' ? _riderProfile.bio : state.bio
      ..homeUrl = state.homeUrl == '' ? _riderProfile.homeUrl : state.homeUrl
      ..locationName = state.locationName == ''
          ? _riderProfile.locationName
          : state.locationName
      ..location = state.location == const GeoPoint(0, 0)
          ? _riderProfile.location
          : state.location
      ..lastEditBy = _riderProfile.name
      ..lastEditDate = DateTime.now();

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: _riderProfile,
      );
      emit(state.copyWith(status: SubmissionStatus.success));
    } catch (e) {
      debugPrint('Sometin went wong');
      emit(state.copyWith(status: SubmissionStatus.failure));
    }
  }

  @override
  Future<void> close() {
    _places.dispose();
    return super.close();
  }
}
