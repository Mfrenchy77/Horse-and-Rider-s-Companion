part of 'add_horse_dialog_cubit.dart';

enum DateStatus { nodate, picking, dateSet }

enum PictureGetterStatus { nothing, picking, got }

enum IsPurchacedStatus { notPurchased, isPurchased }

class AddHorseDialogState extends Equatable {
  const AddHorseDialogState({
    this.id = '',
    this.stateId,
    this.height = 0,
    this.countryIso,
    this.error = '',
    this.prediction,
    this.picUrl = '',
    this.dateOfBirth,
    this.selectedCity,
    this.horseProfile,
    this.usersProfile,
    this.selectedState,
    this.selectedCountry,
    this.dateOfPurchase,
    this.inchesValue = 0,
    this.handsValue = 14,
    this.locationName = '',
    this.picFlilePath = '',
    this.isLocationSearch = false,
    this.status = FormzStatus.pure,
    this.dateStatus = DateStatus.nodate,
    this.zipCode = const ZipCode.pure(),
    this.breed = const SingleWord.pure(),
    this.color = const SingleWord.pure(),
    this.gender = const SingleWord.pure(),
    this.locationStatus = FormzStatus.pure,
    this.horseName = const SingleWord.pure(),
    this.purchasePrice = const Numberz.pure(),
    this.picStatus = PictureGetterStatus.nothing,
    this.horseNickname = const SingleWord.pure(),
    this.autoCompleteStatus = AutoCompleteStatus.initial,
    this.isPurchacedStatus = IsPurchacedStatus.notPurchased,
  });

  final String id;
  final int height;
  final String error;
  final String picUrl;
  final int handsValue;
  final String? stateId;
  final ZipCode zipCode;
  final int inchesValue;
  final SingleWord color;
  final SingleWord breed;
  final SingleWord gender;
  final FormzStatus status;
  final String? countryIso;
  final int? dateOfPurchase;
  final String picFlilePath;
  final String locationName;
  final String? selectedCity;
  final SingleWord horseName;
  final DateTime? dateOfBirth;
  final String? selectedState;
  final bool isLocationSearch;
  final Numberz purchasePrice;
  final DateStatus dateStatus;
  final String? selectedCountry;
  final SingleWord horseNickname;
  final RiderProfile? usersProfile;
  final HorseProfile? horseProfile;
  final FormzStatus? locationStatus;
  final PostalCodeResults? prediction;
  final PictureGetterStatus picStatus;
  final IsPurchacedStatus isPurchacedStatus;
  final AutoCompleteStatus autoCompleteStatus;

  AddHorseDialogState copyWith({
    String? id,
    int? height,
    String? error,
    String? picUrl,
    String? stateId,
    int? handsValue,
    ZipCode? zipCode,
    int? inchesValue,
    SingleWord? breed,
    SingleWord? color,
    SingleWord? gender,
    String? countryIso,
    int? dateOfPurchase,
    FormzStatus? status,
    String? locationName,
    String? picFlilePath,
    String? selectedCity,
    String? selectedState,
    DateTime? dateOfBirth,
    SingleWord? horseName,
    Numberz? purchasePrice,
    DateStatus? dateStatus,
    bool? isLocationSearch,
    String? selectedCountry,
    SingleWord? horseNickname,
    RiderProfile? usersProfile,
    HorseProfile? horseProfile,
    FormzStatus? locationStatus,
    PostalCodeResults? prediction,
    PictureGetterStatus? picStatus,
    IsPurchacedStatus? isPurchacedStatus,
    AutoCompleteStatus? autoCompleteStatus,
  }) {
    return AddHorseDialogState(
      id: id ?? this.id,
      color: color ?? this.color,
      error: error ?? this.error,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      picUrl: picUrl ?? this.picUrl,
      height: height ?? this.height,
      status: status ?? this.status,
      stateId: stateId ?? this.stateId,
      zipCode: zipCode ?? this.zipCode,
      picStatus: picStatus ?? this.picStatus,
      horseName: horseName ?? this.horseName,
      countryIso: countryIso ?? this.countryIso,
      dateStatus: dateStatus ?? this.dateStatus,
      prediction: prediction ?? this.prediction,
      handsValue: handsValue ?? this.handsValue,
      inchesValue: inchesValue ?? this.inchesValue,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      usersProfile: usersProfile ?? this.usersProfile,
      horseProfile: horseProfile ?? this.horseProfile,
      locationName: locationName ?? this.locationName,
      picFlilePath: picFlilePath ?? this.picFlilePath,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedState: selectedState ?? this.selectedState,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      horseNickname: horseNickname ?? this.horseNickname,
      dateOfPurchase: dateOfPurchase ?? this.dateOfPurchase,
      locationStatus: locationStatus ?? this.locationStatus,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      isLocationSearch: isLocationSearch ?? this.isLocationSearch,
      isPurchacedStatus: isPurchacedStatus ?? this.isPurchacedStatus,
      autoCompleteStatus: autoCompleteStatus ?? this.autoCompleteStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        error,
        color,
        breed,
        gender,
        picUrl,
        height,
        status,
        stateId,
        zipCode,
        horseName,
        picStatus,
        countryIso,
        handsValue,
        prediction,
        dateStatus,
        inchesValue,
        dateOfBirth,
        usersProfile,
        horseProfile,
        locationName,
        picFlilePath,
        selectedCity,
        selectedState,
        horseNickname,
        purchasePrice,
        locationStatus,
        dateOfPurchase,
        selectedCountry,
        isLocationSearch,
        isPurchacedStatus,
        autoCompleteStatus,
      ];
}
