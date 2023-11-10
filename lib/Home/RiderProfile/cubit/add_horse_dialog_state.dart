part of 'add_horse_dialog_cubit.dart';

enum DateStatus { nodate, picking, dateSet }

enum PictureGetterStatus { nothing, picking, got }

enum IsPurchacedStatus { notPurchased, isPurchased }

class AddHorseDialogState extends Equatable {
  const AddHorseDialogState({
    this.id = '',
    this.error = '',
    this.picUrl = '',
    this.dateOfBirth,
    this.dateOfPurchase,
    this.inchesValue = 0,
    this.handsValue = 14,
    this.locationName = '',
    this.picFlilePath = '',
    this.prediction = const [],
    this.status = FormzStatus.pure,
    this.dateStatus = DateStatus.nodate,
    this.location = const GeoPoint(0, 0),
    this.breed = const SingleWord.pure(),
    this.color = const SingleWord.pure(),
    this.gender = const SingleWord.pure(),
    this.height = const SingleWord.pure(),
    this.horseName = const SingleWord.pure(),
    this.purchasePrice = const Numberz.pure(),
    this.picStatus = PictureGetterStatus.nothing,
    this.horseNickname = const SingleWord.pure(),
    this.autoCompleteStatus = AutoCompleteStatus.initial,
    this.isPurchacedStatus = IsPurchacedStatus.notPurchased,
  });

  final String id;
  final String error;
  final String picUrl;
  final int handsValue;
  final int inchesValue;
  final int? dateOfBirth;
  final SingleWord color;
  final SingleWord breed;
  final SingleWord gender;
  final SingleWord height;
  final GeoPoint? location;
  final FormzStatus status;
  final int? dateOfPurchase;
  final String picFlilePath;
  final SingleWord horseName;
  final String locationName;
  final Numberz purchasePrice;
  final DateStatus dateStatus;
  final SingleWord horseNickname;
  final List<Prediction> prediction;
  final PictureGetterStatus picStatus;
  final IsPurchacedStatus isPurchacedStatus;
  final AutoCompleteStatus autoCompleteStatus;

  AddHorseDialogState copyWith({
    String? id,
    String? error,
    String? picUrl,
    int? handsValue,
    int? inchesValue,
    int? dateOfBirth,
    SingleWord? breed,
    SingleWord? color,
    SingleWord? gender,
    SingleWord? height,
    GeoPoint? location,
    int? dateOfPurchase,
    FormzStatus? status,
    String? locationName,
    String? picFlilePath,
    SingleWord? horseName,
    Numberz? purchasePrice,
    DateStatus? dateStatus,
    SingleWord? horseNickname,
    List<Prediction>? prediction,
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
      location: location ?? this.location,
      picStatus: picStatus ?? this.picStatus,
      horseName: horseName ?? this.horseName,
      dateStatus: dateStatus ?? this.dateStatus,
      prediction: prediction ?? this.prediction,
      handsValue: handsValue ?? this.handsValue,
      inchesValue: inchesValue ?? this.inchesValue,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      locationName: locationName ?? this.locationName,
      picFlilePath: picFlilePath ?? this.picFlilePath,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      horseNickname: horseNickname ?? this.horseNickname,
      dateOfPurchase: dateOfPurchase ?? this.dateOfPurchase,
      isPurchacedStatus: isPurchacedStatus ?? this.isPurchacedStatus,
      autoCompleteStatus: autoCompleteStatus ?? this.autoCompleteStatus,
    );
  }

  @override
  List<Object?> get props => [
        inchesValue,
        handsValue,
        id,
        error,
        color,
        breed,
        gender,
        picUrl,
        height,
        status,
        location,
        horseName,
        picStatus,
        prediction,
        dateStatus,
        dateOfBirth,
        locationName,
        picFlilePath,
        horseNickname,
        purchasePrice,
        dateOfPurchase,
        isPurchacedStatus,
        autoCompleteStatus,
      ];
}
