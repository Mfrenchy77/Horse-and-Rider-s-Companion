// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/CommonWidgets/horse_details.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:image_picker/image_picker.dart';

part 'add_horse_dialog_state.dart';

class AddHorseDialogCubit extends Cubit<AddHorseDialogState> {
  AddHorseDialogCubit({
    required RiderProfile usersProfile,
    required HorseProfile? horseProfile,
    required KeysRepository keysRepository,
    required HorseProfileRepository horseProfileRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _keysRepository = keysRepository,
        _horseProfileRepository = horseProfileRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const AddHorseDialogState()) {
    _keysRepository.getZipCodeApiKey().then((value) => _zipApi = value);
    _keysRepository
        .getLocationApiKey()
        .then((value) => _locationApiKey = value);
    emit(
      state.copyWith(
        id: horseProfile?.id ?? DateTime.now().toString(),
        horseProfile: horseProfile,
        usersProfile: usersProfile,
        height: horseProfile?.height,
        picUrl: horseProfile?.picUrl,
        selectedCity: horseProfile?.cityName,
        selectedState: horseProfile?.stateName,
        dateOfBirth: horseProfile?.dateOfBirth,
        locationName: horseProfile?.locationName,
        selectedCountry: horseProfile?.countryName,
        breed: SingleWord.dirty(horseProfile?.breed ?? ''),
        color: SingleWord.dirty(horseProfile?.color ?? ''),
        zipCode: ZipCode.dirty(horseProfile?.zipCode ?? ''),
        gender: SingleWord.dirty(horseProfile?.gender ?? ''),
        horseName: SingleWord.dirty(horseProfile?.name ?? ''),
        horseNickname: SingleWord.dirty(horseProfile?.nickname ?? ''),
        purchasePrice: Numberz.dirty(horseProfile?.purchasePrice ?? 0),
        dateOfPurchase: horseProfile?.dateOfPurchase?.millisecondsSinceEpoch,
      ),
    );
  }
  String _zipApi = '';
  String _locationApiKey = '';

  final KeysRepository _keysRepository;
  final HorseProfileRepository _horseProfileRepository;
  final RiderProfileRepository _riderProfileRepository;

  void horseNameChanged(String value) {
    final horseName = SingleWord.dirty(value);
    emit(
      state.copyWith(horseName: horseName),
    );
  }

  void horseNicknameChanged(String value) {
    final horseNickname = SingleWord.dirty(value);
    emit(
      state.copyWith(horseNickname: horseNickname),
    );
  }

  void horseBreedChanged(String value) {
    final breed = SingleWord.dirty(value);
    emit(
      state.copyWith(
        breed: breed,
      ),
    );
  }

  List<String> getAutocompleteBreedSuggestions(String query) {
    final matches = <String>[];

    for (final breed in HorseDetails.breeds) {
      if (breed.toLowerCase().contains(query.toLowerCase())) {
        matches.add(breed);
      }
    }
    return matches;
  }

  List<String> autocompleteColorSuggestions(String query) {
    final matches = <String>[];

    for (final color in HorseDetails.colors) {
      if (color.toLowerCase().contains(query.toLowerCase())) {
        matches.add(color);
      }
    }
    return matches;
  }

  void horseGenderChanged(String value) {
    final gender = SingleWord.dirty(value);
    emit(
      state.copyWith(gender: gender),
    );
  }

  Future<void> horsePicButtonClicked() async {
    String? picUrl;
    final cloudRepository = CloudRepository();

    emit(state.copyWith(picStatus: PictureGetterStatus.picking));

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );

    if (pickedFile != null) {
      picUrl = await cloudRepository.addHorsePhoto(
        file: pickedFile,
        horseId: state.horseProfile?.id ?? state.id,
      );
      if (picUrl != null) {
        emit(
          state.copyWith(
            horseProfile: state.horseProfile?.copyWith(id: picUrl),
            picUrl: picUrl,
            picStatus: PictureGetterStatus.nothing,
          ),
        );
      } else {
        emit(
          state.copyWith(
            picStatus: PictureGetterStatus.nothing,
            status: FormStatus.failure,
            error: 'Error uploading image',
          ),
        );
        debugPrint('Pic Url is null');
      }
    }
  }

  Future<void> horseDateOfBirthChanged(DateTime? date) async {
    emit(
      state.copyWith(
        dateStatus: DateStatus.dateSet,
        dateOfBirth: date,
      ),
    );
  }

  void horseColorChanged(String value) {
    final color = SingleWord.dirty(value);
    emit(
      state.copyWith(color: color),
    );
  }

  /// Toggle the location search
  void toggleLocationSearch() {
    emit(state.copyWith(isLocationSearch: !state.isLocationSearch));
  }

  void horseZipChanged(String value) {
    final zipCode = ZipCode.dirty(value);
    emit(
      state.copyWith(
        locationName: '',
        zipCode: zipCode,
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

  void zipCodeChanged(String value) {
    final zipCode = ZipCode.dirty(value);
    emit(
      state.copyWith(zipCode: zipCode),
    );
  }

  Future<void> _searchForZip() async {
    final zipcodeRepo = ZipcodeRepository(apiKey: _zipApi);

    emit(state.copyWith(autoCompleteStatus: AutoCompleteStatus.loading));

    if (state.countryIso != null &&
        state.selectedCity != null &&
        state.selectedState != null) {
      try {
        debugPrint('Searching by Zip Code');
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

  void locationSelected({
    required String locationName,
    required String selectedZipCode,
  }) {
    debugPrint('Location Name: $locationName');
    debugPrint('Zip Code: $selectedZipCode');
    final zipCode = ZipCode.dirty(selectedZipCode);
    if (zipCode.isValid) {
      emit(
        state.copyWith(
          locationName: locationName,
          zipCode: zipCode,
        ),
      );
    } else {
      debugPrint('Zip Code is not valid');
      emit(
        state.copyWith(
          locationName: locationName,
          zipCode: zipCode,
        ),
      );
    }
  }

  void horseHeightChanged(int height) {
    emit(
      state.copyWith(
        height: height,
      ),
    );
  }

  /// Update the height from the Hands Number Picker
  void updateHeightInHands(int hands) {
    final previousHandHeight = cmToHandsAndInches(state.height).toInt();
    final difference = hands - previousHandHeight;
    final newHeight = previousHandHeight + difference;
    emit(state.copyWith(height: handsToCm(newHeight)));
  }

  void updateHeightInInches(int inches) {
    final previousInches = cmToHandsRemainder(state.height);
    final difference = inches - previousInches;
    final differenceInCm = difference * 2.54;
    final newHeight = state.height + differenceInCm.round();
    emit(state.copyWith(height: newHeight));
  }

  /// increment the height value by 1 centimeter
  void incrementHeightByCentimeter() {
    debugPrint('Incrementing Height from: ${state.height}');
    final height = state.height + 1;
    debugPrint('New Height: $height');
    emit(
      state.copyWith(
        height: height,
      ),
    );
  }

  /// decrement the height value by 1 centimeter
  void decrementHeightByCentimeter() {
    debugPrint('Decrementing Height');
    final height = state.height - 1;
    emit(
      state.copyWith(
        height: height,
      ),
    );
  }

  void incrementHeightByInch() {
    final newHeight = state.height + 2.54.round();
    emit(state.copyWith(height: newHeight));
  }

  void decrementHeightByInch() {
    final newHeight = state.height - 2.54.round();
    emit(state.copyWith(height: newHeight));
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
      state.copyWith(status: FormStatus.submitting),
    );

    final initialNoteEntry = BaseListItem(
      id: state.horseProfile?.id ?? state.id,
      name:
          "${state.usersProfile?.name} registered ${state.horseName.value} with Horse & Rider's Companion",
      message: state.usersProfile?.name,
      parentId: state.usersProfile?.email,
      date: DateTime.now(),
    );
    final notes = [initialNoteEntry];
// ignore: omit_local_variable_types
    final HorseProfile horseProfile = HorseProfile(
      notes: notes,
      height: state.height,
      id: ViewUtils.createId(),
      picUrl: state.picUrl.trim(),
      lastEditDate: DateTime.now(),
      breed: state.breed.value.trim(),
      gender: state.gender.value.trim(),
      name: state.horseName.value.trim(),
      zipCode: state.zipCode.value.trim(),
      locationName: state.locationName.trim(),
      purchasePrice: state.purchasePrice.value,
      nickname: state.horseNickname.value.trim(),
      lastEditBy: state.usersProfile?.name.trim(),
      currentOwnerId: state.usersProfile?.email.trim() as String,
      currentOwnerName: state.usersProfile?.name.trim() as String,
      dateOfPurchase: state.dateOfPurchase != null
          ? DateTime.fromMillisecondsSinceEpoch(
              state.dateOfPurchase as int,
            )
          : null,
      dateOfBirth: state.dateOfBirth != null
          ? DateTime.fromMillisecondsSinceEpoch(state.dateOfBirth as int)
          : null,
      color: state.color.value.trim(),
    );
    if (horseProfile.dateOfBirth != null) {
      /// Add a note to the horses profile that it was born
      /// and who the owner was at the time
      final dobNote = BaseListItem(
        date: state.dateOfBirth,
        id: state.dateOfBirth.toString(),
        message: state.usersProfile?.name.trim(),
        parentId: state.usersProfile?.email.trim(),
        name: '${state.horseProfile?.name} was Born',
      );
      horseProfile.notes?.add(dobNote);
    }
    if (horseProfile.dateOfPurchase != null) {
      final purchaseDate = BaseListItem(
        id: DateTime.now().toString(),
        date: horseProfile.dateOfPurchase,
        parentId: state.usersProfile?.email,
        message: state.usersProfile?.name,
        name:
            '${horseProfile.name} was Purchased by ${state.usersProfile?.name} for ${horseProfile.purchasePrice}',
      );
      horseProfile.notes?.add(purchaseDate);
    }
    final ownedHorse = BaseListItem(
      id: horseProfile.id,
      name: horseProfile.name,
      imageUrl: horseProfile.picUrl,
      isCollapsed: false,
    );
    final updatedUserProfile = state.usersProfile?.copyWith(
      ownedHorses: [...?state.usersProfile?.ownedHorses, ownedHorse],
      notes: [...?state.usersProfile?.notes, initialNoteEntry],
    );
    try {
      debugPrint("Submitting ${horseProfile.name}'s Profile");
      await _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedUserProfile!,
      );
      emit(
        state.copyWith(
          usersProfile: updatedUserProfile,
          status: FormStatus.success,
        ),
      );
    } catch (e) {
      debugPrint('Something went Wrong: $e');
      emit(
        state.copyWith(
          status: FormStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> editHorseProfile() async {
    emit(
      state.copyWith(status: FormStatus.submitting),
    );

// ignore: omit_local_variable_types
    final HorseProfile horseProfile = HorseProfile(
      lastEditDate: DateTime.now(),
      dateOfBirth: state.dateOfBirth,
      picUrl: state.picUrl.isNotEmpty
          ? state.picUrl.trim()
          : state.horseProfile?.picUrl,
      notes: state.horseProfile?.notes,
      breed: state.breed.value.isNotEmpty
          ? state.breed.value.trim()
          : state.horseProfile?.breed,
      color: state.color.value.isNotEmpty
          ? state.color.value.trim()
          : state.horseProfile?.color,
      id: state.horseProfile?.id as String,
      lastEditBy: state.usersProfile?.name,
      gender: state.gender.value.isNotEmpty
          ? state.gender.value.trim()
          : state.horseProfile?.gender,
      zipCode: state.zipCode.value.isNotEmpty
          ? state.zipCode.value
          : state.horseProfile?.zipCode,
      name: state.horseName.value.isNotEmpty
          ? state.horseName.value.trim()
          : state.horseProfile?.name as String,
      locationName: state.locationName.isNotEmpty
          ? state.locationName.trim()
          : state.horseProfile?.locationName,
      nickname: state.horseNickname.value.isNotEmpty
          ? state.horseNickname.value.trim()
          : state.horseProfile?.nickname,
      purchasePrice: state.purchasePrice.value != 0
          ? state.purchasePrice.value
          : state.horseProfile?.purchasePrice,
      height: state.height != 0 ? state.height : state.horseProfile?.height,
      currentOwnerId: state.horseProfile?.currentOwnerId as String,
      currentOwnerName: state.horseProfile?.currentOwnerName as String,
      dateOfPurchase: state.dateOfPurchase != null
          ? DateTime.fromMillisecondsSinceEpoch(state.dateOfPurchase as int)
          : state.horseProfile?.dateOfPurchase,
    );
    final editNote = BaseListItem(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      parentId: state.usersProfile?.email,
      message: state.usersProfile?.name,
      name:
          "${horseProfile.name}'s profile was edited by ${state.usersProfile?.name}",
    );
    horseProfile.notes?.add(editNote);
    state.usersProfile?.notes?.add(editNote);
// update the users profile with the edited horses detail in owned horses
    final ownedHorse = BaseListItem(
      id: horseProfile.id,
      name: horseProfile.name,
      imageUrl: horseProfile.picUrl,
      isCollapsed: false,
    );
    final updatedOwnedHorses = state.usersProfile?.ownedHorses
        ?.where((horse) => horse.id != horseProfile.id)
        .toList();
    updatedOwnedHorses?.add(ownedHorse);

    final updatedUserProfile = state.usersProfile?.copyWith(
      ownedHorses: updatedOwnedHorses,
      notes: [...?state.usersProfile?.notes, editNote],
    );

    try {
      debugPrint("Submitting ${horseProfile.name}'s Updated Profile");
      await _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedUserProfile!,
      );
      emit(
        state.copyWith(
          usersProfile: updatedUserProfile,
          status: FormStatus.success,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('Something went Wrong: $e');
      emit(
        state.copyWith(
          status: FormStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteHorseProfile({
    required HorseProfile? horseProfile,
  }) async {
    emit(
      state.copyWith(status: FormStatus.submitting),
    );
    final deleteNote = BaseListItem(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      parentId: state.usersProfile?.email,
      name: state.usersProfile?.name,
      message:
          '${horseProfile?.name} was deleted by ${state.usersProfile?.name}',
    );
    horseProfile?.notes?.add(deleteNote);
    final userDeleteNote = BaseListItem(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      parentId: state.usersProfile?.email,
      name: state.usersProfile?.name,
      message: 'Deleted {horseProfile?.name} from profile',
    );
    final updatedOwnedHorses = state.usersProfile?.ownedHorses
        ?.where((horse) => horse.id != horseProfile?.id)
        .toList();

    final updatedUserProfile = state.usersProfile?.copyWith(
      ownedHorses: updatedOwnedHorses,
      notes: [...?state.usersProfile?.notes, userDeleteNote],
    );

    try {
      debugPrint("Deleting ${horseProfile?.name}'s Profile");
      _horseProfileRepository.deleteHorseProfile(
        id: horseProfile?.id as String,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedUserProfile!,
      );
      emit(
        state.copyWith(
          usersProfile: updatedUserProfile,
          status: FormStatus.success,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('Something went Wrong: $e');
      emit(
        state.copyWith(
          status: FormStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
