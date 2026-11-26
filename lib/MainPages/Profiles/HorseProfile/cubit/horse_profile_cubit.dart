import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';

part 'horse_profile_state.dart';

class HorseProfileCubit extends Cubit<HorseProfileState> {
  HorseProfileCubit({
    required String horseId,
    required bool? isGuest,
    required RiderProfile? usersProfile,
    this._horseProfileRepository,
    this._riderProfileRepository,
  }) : super(const HorseProfileState()) {
    emit(
      state.copyWith(
        horseId: horseId,
        isGuest: isGuest,
        usersProfile: usersProfile,
      ),
    );
    getHorseProfile(horseId);
  }
  final HorseProfileStore? _horseProfileRepository;
  final RiderProfileStore? _riderProfileRepository;
  StreamSubscription<HorseProfile?>? _horseProfileSubscription;

  Future<void> getHorseProfile(String id) async {
    emit(state.copyWith(status: HorseProfileStatus.loading));
    try {
      if (state.horseProfile?.id != id) {
        try {
          await _horseProfileSubscription?.cancel();
          final horseRepo = _horseProfileRepository ?? HorseProfileRepository();
          final riderRepo = _riderProfileRepository ?? RiderProfileRepository();
          _horseProfileSubscription = horseRepo.getHorseProfile(id: id).listen((
            horseProfile,
          ) {
            if (isClosed) return;
            if (horseProfile != null) {
              if (!_isOwner()) {
                riderRepo
                    .getRiderProfile(email: horseProfile.currentOwnerId)
                    .first
                    .then((ownerProfile) {
                      if (isClosed) return;
                      emit(
                        state.copyWith(
                          index: 0,
                          horseId: horseProfile.id,
                          horseProfile: horseProfile,
                          ownersProfile: ownerProfile,
                        ),
                      );
                    });
              } else {
                emit(
                  state.copyWith(
                    index: 0,
                    horseId: horseProfile.id,
                    horseProfile: horseProfile,
                  ),
                );
              }
            }
          });
        } on RepositoryException catch (e, stackTrace) {
          AppLogger.error(
            LogCategory.profile,
            'Failed to get horse profile',
            error: e,
            stackTrace: stackTrace,
          );
          emit(state.copyWith(errorMessage: e.message));
        }
      }
    } catch (e) {
      emit(state.copyWith(status: HorseProfileStatus.failure));
    }
  }

  bool _isOwner() {
    return state.horseProfile?.currentOwnerId == state.usersProfile?.email;
  }

  @override
  Future<void> close() {
    _horseProfileSubscription?.cancel();
    return super.close();
  }
}
