// ignore_for_file: lines_longer_than_80_chars
// import 'package:flutter/material.dart';
// import 'package:horseandriderscompanion/utils/MyConstants/my_const.dart';


// enum SubmitButtonStates { login, register, forget }

// class SubmitButton extends StatelessWidget {
//   const SubmitButton({super.key, required this.buttonStates});
//   final SubmitButtonStates buttonStates;
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: COLOR_CONST.INDICATOR,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: Text(
//             setText(buttonStates),
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//         ),
//         onPressed: () {
//           //TODO fix this with current cubit method

//           // switch (buttonStates) {
//           //   case SubmitButtonStates.login:
//           //     return context
//           //         .read<LoginBloc>()
//           //         .add(const LoginButtonPressedEvent());
//           //   case SubmitButtonStates.register:
//           //     return context
//           //         .read<RegisterBloc>()
//           //         .add(const RegisterButtonPressedEvent());
//           //   case SubmitButtonStates.forget:
//           //     return //implement
//           //         // context.read<LoginBloc>().add(
//           //         //const ForgotButtonPressedEvent())
//           //         ;
//           // }
//         },
//       ),
//     );
//   }

//   String setText(SubmitButtonStates state) {
//     switch (state) {
//       case SubmitButtonStates.login:
//         return 'Login';
//       case SubmitButtonStates.forget:
//         return 'Send Reset Email';
//       case SubmitButtonStates.register:
//         return 'Register';
//     }
//   }
// }
