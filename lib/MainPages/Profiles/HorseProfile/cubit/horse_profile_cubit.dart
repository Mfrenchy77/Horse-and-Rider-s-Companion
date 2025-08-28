import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'horse_profile_state.dart';

class HorseProfileCubit extends Cubit<HorseProfileState> {
  HorseProfileCubit({
    required String horseId,
    required bool? isGuest,
    required RiderProfile? usersProfile,
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
  StreamSubscription<HorseProfile?>? _horseProfileSubscription;

  Future<void> getHorseProfile(String id) async {
    emit(state.copyWith(status: HorseProfileStatus.loading));
    try {
      debugPrint('getHorseProfile for $id');
      if (state.horseProfile?.id == id) {
        debugPrint('Horse Profile already retrieved');
      } else {
        debugPrint('Horse Profile not retrieved, getting now');
        try {
          _horseProfileSubscription = HorseProfileRepository()
              .getHorseProfile(id: id)
              .listen((horseProfile) {
            debugPrint('Horse Profile Retrieved: ${horseProfile?.name}');
            if (horseProfile != null) {
              if (!_isOwner()) {
                debugPrint('Not Owner');
                RiderProfileRepository()
                    .getRiderProfile(email: horseProfile.currentOwnerId)
                    .first
                    .then((ownerProfile) {
                  debugPrint('Owner Profile Retrieved: ${ownerProfile?.name}');
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
                debugPrint('Owner');
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
        } on FirebaseException catch (e) {
          debugPrint('Failed to get Horse Profile: $e');
          emit(state.copyWith(errorMessage: e.message.toString()));
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
