part of 'transfer_horse_cubit.dart';

enum TransferHorseStatus {
  error,
  initial,
  sending,
  success,
  searching,
}

class TransferHorseState extends Equatable {
  const TransferHorseState({
    this.userProfile,
    this.message = '',
    this.horseProfile,
    this.transferProfile,
    this.isError = false,
    this.isMessage = false,
    this.isTransferable = false,
    this.email = const Email.pure(),
    this.status = TransferHorseStatus.initial,
  });

  /// Email of the user to transfer the horse to
  final Email email;

  /// Is there an error
  final bool isError;

  /// Is there a message
  final bool isMessage;

  /// Error message and success message
  final String message;

  /// If the Email is valid
  final bool isTransferable;

  /// User profile
  final RiderProfile? userProfile;

  /// Status of the transfer
  final TransferHorseStatus status;

  /// Horse profile being transferred
  final HorseProfile? horseProfile;

  /// The profile of the user to transfer the horse to
  final RiderProfile? transferProfile;

  TransferHorseState copyWith({
    Email? email,
    bool? isError,
    String? message,
    bool? isMessage,
    bool? isTransferable,
    RiderProfile? userProfile,
    HorseProfile? horseProfile,
    TransferHorseStatus? status,
    RiderProfile? transferProfile,
  }) {
    return TransferHorseState(
      email: email ?? this.email,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      message: message ?? this.message,
      isMessage: isMessage ?? this.isMessage,
      userProfile: userProfile ?? this.userProfile,
      horseProfile: horseProfile ?? this.horseProfile,
      isTransferable: isTransferable ?? this.isTransferable,
      transferProfile: transferProfile ?? this.transferProfile,
    );
  }

  @override
  List<Object?> get props => [
        email,
        status,
        isError,
        message,
        isMessage,
        userProfile,
        horseProfile,
        isTransferable,
        transferProfile,
      ];
}
