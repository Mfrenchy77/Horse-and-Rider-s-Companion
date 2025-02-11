// import 'package:flutter/material.dart';
// import 'package:horseandriderscompanion/App/app.dart';
// import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
// import 'package:horseandriderscompanion/CommonWidgets/onboarding_dialog.dart';
// import 'package:horseandriderscompanion/Utilities/keys.dart';

// class OnboardingView extends StatefulWidget {
//   const OnboardingView({
//     super.key,
//     required this.cubit,
//     required this.state,
//   });

//   final AppCubit cubit;
//   final AppState state;

//   @override
//   OnboardingViewState createState() => OnboardingViewState();
// }

// class OnboardingViewState extends State<OnboardingView> {
//   @override
//   void initState() {
//     super.initState();
//     if (widget.state.showOnboarding) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _showWelcomeDialog();
//       });
//     }
//   }

//   void _showWelcomeDialog() {
//     showDialog<Dialog>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return onboardingDialog(
//           title: Column(
//             children: [
//               const Text(
//                 'Welcome to',
//                 style: TextStyle(
//                   fontSize: 30,
//                   color: Colors.white,
//                   fontWeight: FontWeight.w100,
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 8),
//                 child: MaxWidthBox(
//                   maxWidth: 500,
//                   child: Image.asset(
//                     'assets/horse_logo_and_text_dark copy.png',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           description:
//               'We will guide you through some of the features of the app.'
//               ' Tap "Next" to continue or "Skip" to proceed to the app.',
//           onNext: () {
//             Navigator.of(context).pop(); // Dismiss the dialog
//             _startShowcase();
//           },
//           skipOnboarding: _skipOnboarding,
//         );
//       },
//     );
//   }

//   // void _showDrawerDialog() {
//   //   showDialog<Dialog>(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (context) {
//   //       return onboardingDialog(
//   //         title: const Text(
//   //           'Drawer',
//   //           style: TextStyle(
//   //             fontSize: 30,
//   //             color: Colors.white,
//   //             fontWeight: FontWeight.w100,
//   //           ),
//   //         ),
//   //         description:
//   //             'This is the drawer. You can access the log book,'
//   //' search for profiles, view messages, and access settings from here.',
//   //         onNext: () {
//   //           Navigator.of(context).pop(); // Dismiss the dialog
//   //           _profileDrawerShowcaseOne();
//   //         },
//   //         skipOnboarding: _skipOnboarding,
//   //       );
//   //     },
//   //   );
//   // }

//   // void _profileDrawerShowcaseOne() {
//   //   WidgetsBinding.instance.addPostFrameCallback((_) {
//   //     ShowCaseWidget.of(context).startShowCase([
//   //       Keys.logoutKey,
//   //       Keys.logBookKey,
//   //     ]);
//   //   });
//   // }

//   void logbookOnboardingDialog() {}

//   // void _startSearchDialogShowcase() {
//   //   WidgetsBinding.instance.addPostFrameCallback((_) {
//   //     ShowCaseWidget.of(context).startShowCase([
//   //       // add the search dialog keys
//   //     ]);
//   //   });
//   // }

//   void _startShowcase() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ShowCaseWidget.of(context).startShowCase([
//         Keys.hamburgerKey,
//         Keys.logoutKey,
//         Keys.logBookKey,
//         Keys.addLogEntryKey,
//         Keys.logSortKey,
//       ]);
//     });
//   }

//   void _logbookShowcase() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ShowCaseWidget.of(context).startShowCase([]);
//     });
//   }

//   void _skipOnboarding() {
//     Navigator.of(context).pop(); // Dismiss the dialog if it's open
//     widget.cubit.completeOnboarding();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }

// //   Widget _onboardingDialog({
// //     required Widget title,
// //     required String description,
// //     required VoidCallback onNext,
// //   }) {
// //     return Dialog(
// //       backgroundColor: Colors.transparent,
// //       child: Container(
// //         padding: const EdgeInsets.all(24),
// //         margin: const EdgeInsets.symmetric(horizontal: 16),
// //         decoration: BoxDecoration(
// //           color: Colors.blue,
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             title,
// //             const SizedBox(height: 16),
// //             Text(
// //               description,
// //               style: const TextStyle(fontSize: 16, color: Colors.white),
// //               textAlign: TextAlign.center,
// //             ),
// //             const SizedBox(height: 24),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 TextButton(
// //                   onPressed: _skipOnboarding,
// //                   child: const Text(
// //                     'Skip',
// //                     style: TextStyle(color: Colors.white60),
// //                   ),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: onNext,
// //                   child: const Text('Next'),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
