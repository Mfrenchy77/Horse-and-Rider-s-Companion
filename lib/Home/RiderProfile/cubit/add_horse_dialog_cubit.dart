// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:google_maps_webservice_ex/places.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';
import 'package:image_picker/image_picker.dart';

part 'add_horse_dialog_state.dart';

class AddHorseDialogCubit extends Cubit<AddHorseDialogState> {
  AddHorseDialogCubit({
    required KeysRepository keysRepository,
    required RiderProfile? riderProfile,
    required this.cloudRepository,
    required HorseProfileRepository horseProfileRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _riderProfile = riderProfile,
        _keysRepository = keysRepository,
        _horseProfileRepository = horseProfileRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const AddHorseDialogState()) {
    _keysRepository
        .getMapsApiKey()
        .then((value) => _places = GoogleMapsPlaces(apiKey: value));
  }
  final RiderProfile? _riderProfile;
  late final GoogleMapsPlaces _places;

  final HorseProfileRepository _horseProfileRepository;
  final RiderProfileRepository _riderProfileRepository;
  final KeysRepository _keysRepository;
  final CloudRepository cloudRepository;
  List<String> horseBreeds = [
    'Akhal-Teke',
    'American Cream Draft',
    'American Paint Horse',
    'American Quarter Horse',
    'American Saddlebred',
    'Andalusian',
    'Appaloosa',
    'Arabian',
    'Ardennes',
    'Australian Stock Horse',
    'Azteca',
    'Barb',
    'Bashkir Curly',
    'Belgian Draft',
    'Budyonny',
    'Camargue',
    'Canadian Horse',
    'Caspian',
    'Cleveland Bay',
    'Clydesdale',
    'Connemara Pony',
    'Criollo',
    'Danish Warmblood',
    'Dartmoor Pony',
    'Donkey',
    'Dutch Warmblood',
    'Exmoor Pony',
    'Falabella',
    'Fell Pony',
    'Fjord',
    'Franches-Montagnes',
    'Frederiksborg',
    'Freiberger',
    'Friesian',
    'Gypsy Vanner',
    'Hackney',
    'Haflinger',
    'Hanoverian',
    'Highland Pony',
    'Holsteiner',
    'Icelandic Horse',
    'Irish Draught',
    'Jutland',
    'Knabstrupper',
    'Lipizzan',
    'Lusitano',
    'Marwari',
    'Miniature Horse',
    'Missouri Fox Trotter',
    'Morab',
    'Morgan',
    'Mountain Pleasure Horse',
    'Mustang',
    'National Show Horse',
    'New Forest Pony',
    'Noriker',
    'Oldenburg',
    'Orlov Trotter',
    'Paint Horse',
    'Palomino',
    'Paso Fino',
    'Percheron',
    'Peruvian Paso',
    'Pinto',
    'Poitou',
    'Pony of the Americas',
    'Pottok',
    'Quarter Horse',
    'Racking Horse',
    'Rocky Mountain Horse',
    'Selle Francais',
    'Shetland Pony',
    'Shire',
    'Standardbred',
    'Suffolk Punch',
    'Swedish Warmblood',
    'Tennessee Walking Horse',
    'Thoroughbred',
    'Trakehner',
    'Warmblood',
    'Welsh Cob',
    'Welsh Pony',
    'Westphalian',
    'Wielkopolski',
    'Zangersheide',
  ];

  void horseNameChanged(String value) {
    final horseName = SingleWord.dirty(value);
    emit(
      state.copyWith(
        horseName: horseName,
        status: Formz.validate([horseName]),
      ),
    );
  }

  void horseNicknameChanged(String value) {
    final horseNickname = SingleWord.dirty(value);
    emit(
      state.copyWith(
        horseNickname: horseNickname,
        status: Formz.validate([horseNickname]),
      ),
    );
  }

  void horseBreedChanged(String value) {
    final breed = SingleWord.dirty(value);
    emit(
      state.copyWith(
        breed: breed,
        status: Formz.validate([breed]),
      ),
    );
  }

  List<String> getAutocompleteBreedSuggestions(String query) {
    final matches = <String>[];

    for (final breed in horseBreeds) {
      if (breed.toLowerCase().contains(query.toLowerCase())) {
        matches.add(breed);
      }
    }
    return matches;
  }

  List<String> autocompleteColorSuggestions(String query) {
    final matches = <String>[];

    for (final breed in horseBreeds) {
      if (breed.toLowerCase().contains(query.toLowerCase())) {
        matches.add(breed);
      }
    }
    return matches;
  }

  void horseGenderChanged(String value) {
    final gender = SingleWord.dirty(value);
    emit(
      state.copyWith(
        gender: gender,
        status: Formz.validate([gender]),
      ),
    );
  }

  Future<void> horsePicButtonClicked() async {
    emit(state.copyWith(picStatus: PictureGetterStatus.picking));
    final picker = ImagePicker();
    String horseId;
    if (state.id.isEmpty) {
      horseId = ViewUtils.createId();
    } else {
      horseId = state.id;
    }
    XFile? pickedFile;

    pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 10,
    );

    if (pickedFile != null) {
      final picUrl = await cloudRepository.addHorsePhoto(
        path: pickedFile.path,
        horseId: horseId,
      );
      emit(
        state.copyWith(
          id: horseId,
          picUrl: picUrl,
          picStatus: PictureGetterStatus.got,
          picFlilePath: pickedFile.path,
        ),
      );
    } else {
      debugPrint('No Image Selected');
    }
  }

  Future<void> horseDateOfBirthChanged(DateTime? date) async {
    final dob = date?.millisecondsSinceEpoch;

    emit(
      state.copyWith(
        dateStatus: DateStatus.dateSet,
        dateOfBirth: dob,
      ),
    );
  }

  void horseColorChanged(String value) {
    final color = SingleWord.dirty(value);
    emit(
      state.copyWith(
        color: color,
        status: Formz.validate([color]),
      ),
    );
  }

  Future<void> horseLocationChanged(String value) async {
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

  void horseHeightChanged(String height) {
    final height0 = SingleWord.dirty(height);
    emit(
      state.copyWith(
        height: height0,
        status: Formz.validate([height0]),
      ),
    );
  }

  void handsChanged(int value) {
    emit(state.copyWith(handsValue: value));
  }

  void inchesChanged(int value) {
    emit(state.copyWith(inchesValue: value));
  }

  Future<void> horseDateOfPurchaseChanged(DateTime? date) async {
    final dop = date?.millisecondsSinceEpoch;
    emit(
      state.copyWith(
        dateOfPurchase: dop,
      ),
    );
  }

  void horsePurchasePriceChanged(int value) {
    final purchasePrice = Numberz.dirty(value);
    emit(
      state.copyWith(
        purchasePrice: purchasePrice,
        status: Formz.validate([purchasePrice]),
      ),
    );
  }

  void toogleIsPurchased({required bool isPurchaced}) {
    if (isPurchaced) {
      emit(state.copyWith(isPurchacedStatus: IsPurchacedStatus.isPurchased));
    } else {
      emit(state.copyWith(isPurchacedStatus: IsPurchacedStatus.notPurchased));
    }
  }

  Future<void> createHorseProfile() async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );

    final initialNoteEntry = BaseListItem(
      id: DateTime.now().toString(),
      name:
          "${_riderProfile?.name} registered ${state.horseName} with Horse & Rider's Companion",
      message: _riderProfile?.name,
      parentId: _riderProfile?.email,
      date: DateTime.now(),
    );
    final notes = [initialNoteEntry];
// ignore: omit_local_variable_types
    final HorseProfile horseProfile = HorseProfile(
      id: ViewUtils.createId(),
      name: state.horseName.value.trim(),
      nickname: state.horseNickname.value.trim(),
      breed: state.breed.value.trim(),
      picUrl: state.picUrl.trim(),
      dateOfBirth: state.dateOfBirth != null
          ? DateTime.fromMillisecondsSinceEpoch(state.dateOfBirth as int)
          : null,
      color: state.color.value.trim(),
      location: state.location,
      locationName: state.locationName.trim(),
      height: state.height.value.trim(),
      gender: state.gender.value.trim(),
      currentOwnerId: _riderProfile?.email?.trim() as String,
      currentOwnerName: _riderProfile?.name?.trim() as String,
      dateOfPurchase: state.dateOfPurchase != null
          ? DateTime.fromMillisecondsSinceEpoch(
              state.dateOfPurchase as int,
            )
          : null,
      purchasePrice: state.purchasePrice.value,
      lastEditDate: DateTime.now(),
      lastEditBy: _riderProfile?.name?.trim(),
      notes: notes,
    );
    if (horseProfile.dateOfBirth != null) {
      final dobNote = BaseListItem(
        id: DateTime.now().toString(),
        date: horseProfile.dateOfBirth,
        parentId: _riderProfile?.email?.trim(),
        message: _riderProfile?.name?.trim(),
        name: '${horseProfile.name} was Born',
      );
      horseProfile.notes?.add(dobNote);
    }
    if (horseProfile.dateOfPurchase != null) {
      final purchaseDate = BaseListItem(
        id: DateTime.now().toString(),
        date: horseProfile.dateOfPurchase,
        parentId: _riderProfile?.email,
        message: _riderProfile?.name,
        name:
            '${horseProfile.name} was Purchased by ${_riderProfile?.name} for ${horseProfile.purchasePrice}',
      );
      horseProfile.notes?.add(purchaseDate);
    }
    final ownedHorse = BaseListItem(
      id: horseProfile.id,
      name: horseProfile.name,
      imageUrl: horseProfile.picUrl,
      isCollapsed: false,
    );
    if (_riderProfile?.ownedHorses != null) {
      _riderProfile?.ownedHorses?.add(ownedHorse);
    } else {
      final ownedHorseList = <BaseListItem>[ownedHorse];
      _riderProfile?.ownedHorses = ownedHorseList;
    }
    _riderProfile?.notes?.add(initialNoteEntry);
    try {
      debugPrint("Submitting ${horseProfile.name}'s Profile");
      await _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: _riderProfile as RiderProfile,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      debugPrint('Something went Wrong: $e');
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> editHorseProfile({
    required HorseProfile? editedHorseProfile,
  }) async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );

// ignore: omit_local_variable_types
    final HorseProfile horseProfile = HorseProfile(
      id: editedHorseProfile?.id as String,
      name: state.horseName.value.isNotEmpty
          ? state.horseName.value.trim()
          : editedHorseProfile?.name as String,
      nickname: state.horseNickname.value.isNotEmpty
          ? state.horseNickname.value.trim()
          : editedHorseProfile?.nickname,
      breed: state.breed.value.isNotEmpty
          ? state.breed.value.trim()
          : editedHorseProfile?.breed,
      location: state.locationName.isNotEmpty
          ? state.location
          : editedHorseProfile?.location,
      locationName: state.locationName.isNotEmpty
          ? state.locationName.trim()
          : editedHorseProfile?.locationName,
      gender: state.gender.value.isNotEmpty
          ? state.gender.value.trim()
          : editedHorseProfile?.gender,
      picUrl: state.picUrl.isNotEmpty
          ? state.picUrl.trim()
          : editedHorseProfile?.picUrl,
      dateOfBirth: state.dateOfBirth != null
          ? DateTime.fromMillisecondsSinceEpoch(state.dateOfBirth as int)
          : editedHorseProfile?.dateOfBirth,
      color: state.color.value.isNotEmpty
          ? state.color.value.trim()
          : editedHorseProfile?.color,
      height: state.height.value.isNotEmpty
          ? state.height.value.trim()
          : editedHorseProfile?.height,
      currentOwnerId: editedHorseProfile?.currentOwnerId as String,
      currentOwnerName: editedHorseProfile?.currentOwnerName as String,
      dateOfPurchase: state.dateOfPurchase != null
          ? DateTime.fromMillisecondsSinceEpoch(state.dateOfPurchase as int)
          : editedHorseProfile?.dateOfPurchase,
      purchasePrice: state.purchasePrice.value != 0
          ? state.purchasePrice.value
          : editedHorseProfile?.purchasePrice,
      notes: editedHorseProfile?.notes,
      lastEditDate: DateTime.now(),
      lastEditBy: _riderProfile?.name,
    );
    final editNote = BaseListItem(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      parentId: _riderProfile?.email,
      message: _riderProfile?.name,
      name:
          "${horseProfile.name}'s profile was edited by ${_riderProfile?.name}",
    );
    horseProfile.notes?.add(editNote);
    _riderProfile?.notes?.add(editNote);
// update the users profile with the edited horses detail in owned horses
    final ownedHorse = BaseListItem(
      id: horseProfile.id,
      name: horseProfile.name,
      imageUrl: horseProfile.picUrl,
      isCollapsed: false,
    );
    if (_riderProfile?.ownedHorses != null) {
      _riderProfile?.ownedHorses?.removeWhere(
        (horse) => horse.id == horseProfile.id,
      );
      _riderProfile?.ownedHorses?.add(ownedHorse);
    } else {
      final ownedHorseList = <BaseListItem>[ownedHorse];
      _riderProfile?.ownedHorses = ownedHorseList;
    }

    try {
      debugPrint("Submitting ${horseProfile.name}'s Updated Profile");
      await _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: _riderProfile as RiderProfile,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } on FirebaseException catch (e) {
      debugPrint('Something went Wrong: $e');
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteHorseProfile({
    required HorseProfile? horseProfile,
  }) async {
    emit(
      state.copyWith(status: FormzStatus.submissionInProgress),
    );
    final deleteNote = BaseListItem(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      parentId: _riderProfile?.email,
      name: _riderProfile?.name,
      message: '${horseProfile?.name} was deleted by ${_riderProfile?.name}',
    );
    horseProfile?.notes?.add(deleteNote);
    final userDeleteNote = BaseListItem(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      parentId: _riderProfile?.email,
      name: _riderProfile?.name,
      message: 'Deleted {horseProfile?.name} from profile',
    );
    _riderProfile?.notes?.add(userDeleteNote);
    _riderProfile?.ownedHorses?.removeWhere(
      (horse) => horse.id == horseProfile?.id,
    );

    try {
      debugPrint("Deleting ${horseProfile?.name}'s Profile");
      _horseProfileRepository.deleteHorseProfile(
        id: horseProfile?.id as String,
      );
      await _riderProfileRepository
          .createOrUpdateRiderProfile(
            riderProfile: _riderProfile as RiderProfile,
          )
          .then(
            (value) =>
                emit(state.copyWith(status: FormzStatus.submissionSuccess)),
          );
    } on FirebaseException catch (e) {
      debugPrint('Something went Wrong: $e');
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          error: e.toString(),
        ),
      );
    }
  }
}
