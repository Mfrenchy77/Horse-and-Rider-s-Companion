// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';

// part 'navigation_state.dart';

// class NavigationCubit extends Cubit<NavigationState> {
//   NavigationCubit({
//     required int index,
//     required bool isGuest,
//     required bool isViewing,
//     required bool isForRider,
//   })  : _index = index,
//         _isGuest = isGuest,
//         _isViewing = isViewing,
//         _isForRider = isForRider,
//         super(const NavigationState()) {
//     emit(
//       state.copyWith(
//         index: _index,
//         isGuest: _isGuest,
//         isViewing: _isViewing,
//         isForRider: _isForRider,
//       ),
//     );
//   }

//   final int _index;
//   final bool _isGuest;
//   final bool _isViewing;
//   final bool _isForRider;

//   void changePage(int index) {
//     emit(state.copyWith(index: index));
//   }

//   void backPressed() {
//     if (state.index == 2) {
//       emit(state.copyWith(index: 1));
//     } else if (state.index == 1) {
//       emit(state.copyWith(index: 0));
//     } else {
//       emit(state.copyWith(index: 0));
//     }
//   }
// }
