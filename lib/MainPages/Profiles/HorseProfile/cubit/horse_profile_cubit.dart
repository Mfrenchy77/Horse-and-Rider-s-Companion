import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';

part 'horse_profile_state.dart';

class HorseProfileCubit extends Cubit<HorseProfileState> {
  HorseProfileCubit() : super(const HorseProfileState());
}
