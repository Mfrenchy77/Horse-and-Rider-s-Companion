// part of 'navigation_cubit.dart';

// class NavigationState extends Equatable {
//   const NavigationState({
//     this.index = 0,
//     this.isGuest = false,
//     this.isViewing = false,
//     this.isForRider = false,
//   });

//   /// The index of the current page:
//   /// 0 = Profile(Horse/Rider)
//   /// 1 = SkillTree
//   /// 2 = Resourses
//   final int index;

//   /// whether the user is a guest or not
//   final bool isGuest;

//   /// whether the user is viewing a profile or not
//   final bool isViewing;

//   /// whether the user is viewing a horse profile or not
//   final bool isForRider;

//   NavigationState copyWith({
//     int? index,
//     bool? isGuest,
//     bool? isViewing,
//     bool? isForRider,
//   }) {
//     return NavigationState(
//       index: index ?? this.index,
//       isGuest: isGuest ?? this.isGuest,
//       isViewing: isViewing ?? this.isViewing,
//       isForRider: isForRider ?? this.isForRider,
//     );
//   }

//   @override
//   List<Object> get props => [
//         index,
//         isGuest,
//         isViewing,
//         isForRider,
//       ];
// }
