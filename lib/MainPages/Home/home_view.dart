// // ignore_for_file: cast_nullable_to_non_nullable

// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:horseandriderscompanion/CommonWidgets/loading_view.dart';
// import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/ProfileSearchDialog/profile_search_dialog.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/support_message_dialog.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_view.dart';
// import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_view.dart';
// import 'package:horseandriderscompanion/MainPages/Resources/resources_view.dart';
// import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
// import 'package:horseandriderscompanion/Theme/theme.dart';
// import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

// class HomeView extends StatelessWidget {
//   const HomeView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<HomeCubit, HomeState>(
//       listener: (context, state) {
//         final homeCubit = context.read<HomeCubit>();

//         // /// Open the Rider Profile Page
//         //  if (state.homeStatus == HomeStatus.profile) {
//         //   if (state.isForRider) {
//         //     Navigator.of(context).pushNamed(
//         //       RiderProfilePage.routeName,
//         //       arguments: RiderProfilePageArguments(
//         //         isGuest: state.isGuest,
//         //         usersProfile: state.usersProfile,
//         //         viewingProfile: state.viewingProfile,
//         //       ),
//         //     );
//         //   }
//         // }

//         /// Open a Dialog to Show Profile Setup if the user is a not a guest
//         /// and the use profile is null
//         if (state.homeStatus == HomeStatus.profileSetup) {
//           debugPrint('Show Profile Setup Dialog');
//           if (!state.showingProfileSetup) {
//             homeCubit.profileSetupIsShown();
//             showDialog<AlertDialog>(
//               barrierDismissible: false,
//               context: context,
//               builder: (context) =>
//                   EditRiderProfileDialog(riderProfile: null, user: state.user),
//             ).then((value) => homeCubit.resetProfileSetup());
//           }
//         }

//         ///Open a dialog to send a message to support

//         if (state.isSendingMessageToSupport) {
//           SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
//             showDialog<SupportMessageDialog>(
//               context: context,
//               builder: (dialogContext) => const SupportMessageDialog(),
//             ).then((value) => homeCubit.closeMessageToSupport());
//           });
//         }

//         /// Show Search
//         if (state.isSearching) {
//           showDialog<AlertDialog>(
//             context: context,
//             builder: (context) => ProfileSearchDialog(
//               homeContext: context,
//               key: const Key('ProfileSearchDialog'),
//             ),
//           );
//         }

//         /// Show Error Snackbar
//         if (state.errorSnackBar) {
//           SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
//             ScaffoldMessenger.of(context)
//               ..hideCurrentSnackBar()
//               ..showSnackBar(
//                 SnackBar(
//                   content: Text(
//                     state.error,
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   backgroundColor: Colors.red,
//                 ),
//               ).closed.then((value) {
//                 homeCubit.clearSnackBar();
//               });
//           });
//         }

//         /// Show Regular SnackBar
//         if (state.snackBar) {
//           SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
//             ScaffoldMessenger.of(context)
//               ..hideCurrentSnackBar()
//               ..showSnackBar(
//                 SnackBar(
//                   backgroundColor:
//                       HorseAndRidersTheme().getTheme().colorScheme.primary,
//                   content: Text(
//                     state.message,
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ).closed.then(
//                     (value) => homeCubit.clearSnackBar(),
//                   );
//           });
//         }

//         /// Show Message SnackBar
//         if (state.messageSnackBar) {
//           SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
//             ScaffoldMessenger.of(context)
//               ..hideCurrentSnackBar()
//               ..showSnackBar(
//                 SnackBar(
//                   action: SnackBarAction(
//                     label: 'Open Messages',
//                     onPressed: () => context
//                         .read<HomeCubit>()
//                         .openMessages(context: context),
//                   ),
//                   backgroundColor:
//                       HorseAndRidersTheme().getTheme().colorScheme.primary,
//                   content: Text(
//                     state.message,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ).closed.then(
//                     (value) => homeCubit.clearSnackBar(),
//                   );
//           });
//         }
//       },
//       child: BlocBuilder<HomeCubit, HomeState>(
//         builder: (context, state) {
//           final homeCubit = context.read<HomeCubit>();

//           return SizedBox(
//             height: MediaQuery.of(context).size.height,
//             width: MediaQuery.of(context).size.width,
//             child: Column(
//               children: [
//                 Expanded(
//                   child: AdaptiveScaffold(
//                     internalAnimations: false,
//                     smallBreakpoint: const WidthPlatformBreakpoint(end: 800),
//                     mediumBreakpoint: const WidthPlatformBreakpoint(
//                       begin: 800,
//                       end: 1200,
//                     ),
//                     largeBreakpoint: const WidthPlatformBreakpoint(begin: 1200),
//                     leadingUnextendedNavRail: state.index == 0
//                         ? const Image(
//                             color: Colors.white,
//                             fit: BoxFit.contain,
//                             image: AssetImage('assets/horse_logo.png'),
//                             height: 40,
//                           )
//                         : Visibility(
//                             visible: state.index != 0 || state.isViewing,
//                             child: IconButton(
//                               icon: Icon(
//                                 Icons.arrow_back,
//                                 color: HorseAndRidersTheme()
//                                     .getTheme()
//                                     .appBarTheme
//                                     .iconTheme
//                                     ?.color,
//                               ),
//                               onPressed: () => homeCubit.backPressed(context),
//                             ),
//                           ),
//                     leadingExtendedNavRail: state.index == 0
//                         ? const Image(
//                             color: Colors.white,
//                             fit: BoxFit.contain,
//                             image: AssetImage('assets/horse_logo.png'),
//                             height: 40,
//                           )
//                         : Visibility(
//                             visible: state.index != 0 || state.isViewing,
//                             child: IconButton(
//                               icon: Icon(
//                                 Icons.arrow_back,
//                                 color: HorseAndRidersTheme()
//                                     .getTheme()
//                                     .appBarTheme
//                                     .iconTheme
//                                     ?.color,
//                               ),
//                               onPressed: () => homeCubit.backPressed(context),
//                             ),
//                           ),
//                     useDrawer: false,
//                     destinations:
//                         _buildDestinations(isForRider: state.isForRider),
//                     selectedIndex: state.index,
//                     onSelectedIndexChange: (int newIndex) {
//                       if (newIndex == 0) {
//                         homeCubit.profileNavigationSelected();
//                       } else if (newIndex == 1) {
//                         homeCubit.navigateToTrainingPathList();
//                       } else if (newIndex == 2) {
//                         homeCubit.resourcesNavigationSelected();
//                       }
//                     },
//                     body: (_) => AdaptiveLayout(
//                       internalAnimations: false,
//                       body: SlotLayout(
//                         config: <Breakpoint, SlotLayoutConfig>{
//                           Breakpoints.standard: SlotLayout.from(
//                             key: const Key('mainView'),
//                             builder: (_) => _mainView(
//                               context: context,
//                               state: state,
//                               homeCubit: homeCubit,
//                             ),
//                           ),
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//                 _bannerAd(),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /// Determines the main view to display based on the current [HomeStatus].
// ///
// /// This method uses the state's home status to decide which view to
// ///  render, handling different cases like showing the profile, skill tree,
// ///  resources, or loading views, among others. It simplifies the
// ///  decision-making process by utilizing a switch statement.
// ///
// // ///
// // class MainView extends StatelessWidget {
// //   const MainView({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocListener<HomeCubit, HomeState>(
// //       listener: (context, state) {
// //         //TODO: implement listener
// //         if (state.homeStatus == HomeStatus.profile) {
// //           if (state.isForRider) {
// //             Navigator.of(context).pushNamed(
// //               RiderProfilePage.routeName,
// //               arguments: RiderProfilePageArguments(
// //                 isGuest: state.isGuest,
// //                 usersProfile: state.usersProfile,
// //                 viewingProfile: state.viewingProfile,
// //               ),
// //             );
// //           }
// //         }
// //       },
// //       child: Placeholder(),
// //     );
// //   }
// // }

// Widget _mainView({
//   required BuildContext context,
//   required HomeState state,
//   required HomeCubit homeCubit,
// }) {
//   switch (state.homeStatus) {
//     case HomeStatus.profile:
//       return state.isForRider
//           ? RiderProfileView(
//               user: state.user,
//               isGuest: state.isGuest,
//               usersProfile: state.usersProfile,
//               viewingProfile: state.viewingProfile,
//               key: const Key('RiderProfilePage'),
//             )
//           : horseProfileView(
//               context: context,
//               state: state,
//               homeCubit: homeCubit,
//             );
//     case HomeStatus.ridersLog:
//       return logViewDialog(
//         context: context,
//         name: state.viewingProfile?.name ?? state.usersProfile!.name,
//         notes: state.viewingProfile?.notes ?? state.usersProfile!.notes,
//         isRider: true,
//       );
//     case HomeStatus.horseLog:
//       return logViewDialog(
//         context: context,
//         name: state.horseProfile?.name ?? 'Horse',
//         notes: state.horseProfile?.notes,
//         isRider: false,
//       );
//     case HomeStatus.skillTree:
//       return skillTreeView(
//         context: context,
//         homeCubit: homeCubit,
//         state: state,
//       );
//     case HomeStatus.resource:
//       return resourcesView(
//         context: context,
//         homeCubit: homeCubit,
//         state: state,
//       );
//     case HomeStatus.loading:
//       return loadingView();
//     case HomeStatus.profileSetup:
//       return RiderProfileView(
//         user: state.user,
//         isGuest: state.isGuest,
//         usersProfile: state.usersProfile,
//         viewingProfile: state.viewingProfile,
//         key: const Key('RiderProfilePage'),
//       );
//   }
// }

// // Define your destinations for NavigationRail and BottomNavigationBar
// List<NavigationDestination> _buildDestinations({required bool isForRider}) {
//   return [
//     NavigationDestination(
//       selectedIcon: isForRider
//           ? const Icon(Icons.person)
//           : const Icon(HorseAndRiderIcons.horseIconCircle),
//       icon: isForRider
//           ? const Icon(Icons.person_outline)
//           : const Icon(HorseAndRiderIcons.horseIcon),
//       label: isForRider ? 'Profile' : 'Horse Profile',
//     ),
//     NavigationDestination(
//       selectedIcon: isForRider
//           ? const Icon(HorseAndRiderIcons.riderSkillIcon)
//           : const Icon(HorseAndRiderIcons.horseSkillIcon),
//       icon: isForRider
//           ? const Icon(HorseAndRiderIcons.riderSkillIcon)
//           : const Icon(HorseAndRiderIcons.horseSkillIcon),
//       label: 'Skill Tree',
//     ),
//     const NavigationDestination(
//       selectedIcon: Icon(HorseAndRiderIcons.resourcesIcon),
//       icon: Icon(HorseAndRiderIcons.resourcesIcon),
//       label: 'Resources',
//     ),
//   ];
// }

// Widget _bannerAd() {
//   return BlocBuilder<HomeCubit, HomeState>(
//     buildWhen: (previous, current) =>
//         previous.isBannerAdReady != current.isBannerAdReady ||
//         previous.bannerAd != current.bannerAd,
//     builder: (context, state) {
//       if (state.isBannerAdReady) {
//         return Visibility(
//           visible: state.isBannerAdReady,
//           child: Container(
//             color: HorseAndRidersTheme().getTheme().primaryColor,
//             width: double.infinity,
//             height: state.bannerAd?.size.height.toDouble(),
//             alignment: Alignment.center,
//             child: AdWidget(ad: state.bannerAd!),
//           ),
//         );
//       } else {
//         return const SizedBox();
//       }
//     },
//   );
// }
