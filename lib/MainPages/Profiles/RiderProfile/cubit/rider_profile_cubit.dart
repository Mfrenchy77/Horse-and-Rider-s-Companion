// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:bloc/bloc.dart';
// import 'package:database_repository/database_repository.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart';

// part 'rider_profile_state.dart';

// class RiderProfileCubit extends Cubit<RiderProfileState> {
//   RiderProfileCubit() : super(const RiderProfileState());

//   /// Dertermins if the userprofile is authorized by the owner of the profile
//   /// viewing profile is null, they are authorized
//   /// if the userprofile is on the viewing profile instructor
//   ///  list they are authorized
//   ///
//   bool isAuthorized() {
//     final viewingProfile = state.viewingProfile;
//     final usersProfile = state.usersProfile;
//     if (viewingProfile == null) {
//       return true;
//     }
//     if (usersProfile == null) {
//       return false;
//     }
//     return viewingProfile.instructors
//             ?.any((element) => element.id == usersProfile.id) ??
//         false;
//   }
// }
