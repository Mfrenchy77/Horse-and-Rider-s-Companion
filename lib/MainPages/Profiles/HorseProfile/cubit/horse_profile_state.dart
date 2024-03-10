part of 'horse_profile_cubit.dart';

enum HorseProfileStatus {
  loading,
  success,
  failure,
}

class HorseProfileState extends Equatable {
  const HorseProfileState({
    this.horseId,
    this.index = 0,
    this.usersProfile,
    this.horseProfile,
    this.ownersProfile,
    this.isError = false,
    this.isGuest = false,
    this.errorMessage = '',
    this.status = HorseProfileStatus.loading,
  });
  final int index;
  final bool isError;
  final bool isGuest;
  final String? horseId;
  final String errorMessage;
  final RiderProfile? usersProfile;
  final HorseProfile? horseProfile;
  final RiderProfile? ownersProfile;
  final HorseProfileStatus status;

  HorseProfileState copyWith({
    int? index,
    bool? isGuest,
    bool? isError,
    String? horseId,
    String? errorMessage,
    HorseProfileStatus? status,
    RiderProfile? usersProfile,
    HorseProfile? horseProfile,
    RiderProfile? ownersProfile,
  }) {
    return HorseProfileState(
      index: index ?? this.index,
      status: status ?? this.status,
      horseId: horseId ?? this.horseId,
      isGuest: isGuest ?? this.isGuest,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      usersProfile: usersProfile ?? this.usersProfile,
      horseProfile: horseProfile ?? this.horseProfile,
      ownersProfile: ownersProfile ?? this.ownersProfile,
    );
  }

  @override
  List<Object?> get props => [
        index,
        status,
        horseId,
        isGuest,
        isError,
        errorMessage,
        usersProfile,
        horseProfile,
        ownersProfile,
      ];
}
