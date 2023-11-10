import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'rider_profile_viewer_state.dart';

class RiderProfileViewerCubit extends Cubit<RiderProfileViewerState> {
  RiderProfileViewerCubit() : super(RiderProfileViewerInitial());
}
