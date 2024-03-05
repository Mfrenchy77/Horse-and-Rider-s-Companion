part of 'horse_profile_cubit.dart';

class HorseProfileState extends Equatable {
  const HorseProfileState({
    this.horseId,
    this.index = 0,
    this.usersProfile,
    this.horseProfile,
    this.isGuest = false,
  });
  final int index;
  final bool isGuest;
  final String? horseId;
  final RiderProfile? usersProfile;
  final HorseProfile? horseProfile;

  HorseProfileState copyWith({
    int? index,
    bool? isGuest,
    String? horseId,
    RiderProfile? usersProfile,
    HorseProfile? horseProfile,
  }) {
    return HorseProfileState(
      index: index ?? this.index,
      horseId: horseId ?? this.horseId,
      isGuest: isGuest ?? this.isGuest,
      usersProfile: usersProfile ?? this.usersProfile,
      horseProfile: horseProfile ?? this.horseProfile,
    );
  }

  @override
  List<Object> get props => [
        index,
        horseId!,
        isGuest,
        usersProfile!,
        horseProfile!,
      ];
}
