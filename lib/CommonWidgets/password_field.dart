// // ignore_for_file: avoid_print

// import 'package:flutter/material.dart';

// enum PasswordState { login, register }

// class PasswordField extends StatefulWidget {
//   const PasswordField({super.key, required this.passwordState});
//   final PasswordState passwordState;

//   @override
//   // ignore: no_logic_in_create_state
//   State<PasswordField> createState() => PasswordFieldState(passwordState);
// }

// class PasswordFieldState extends State<PasswordField> {
//   PasswordFieldState(this.passwordState);
//   final PasswordState passwordState;

//   bool isPasswordVisible = false;
//   @override
//   Widget build(BuildContext context) {
//     return
//         //password
//         TextFormField(
//       onChanged: (value) {
//         //TODO fix this with current cubit method
//         // switch (passwordState) {
//         //   case PasswordState.login:
//         //     return context
//         //         .read<LoginBloc>()
//         //         .add(LoginPasswordChangedEvent(password: value));

//         //   case PasswordState.register:
//         //     return context
//         //         .read<RegisterBloc>()
//         //         .add(RegisterPasswordChangedEvent(password: value));
//         // }
//         // switch (passwordState) {
//         //   case PasswordState.login:
//         //     return context
//         //         .read<LoginBloc>()
//         //         .add(LoginPasswordChangedEvent(password: value));

//         //   case PasswordState.register:
//         //     return context
//         //         .read<RegisterBloc>()
//         //         .add(RegisterPasswordChangedEvent(password: value));
//         // }
//       },
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter some text';
//         }

//         if (value.length < 6) {
//           return 'Password must be at least 6 characters';
//         }
//         return null;
//       },
//       obscureText: !isPasswordVisible,
//       decoration: InputDecoration(
//         labelText: 'Password',
//         hintText: 'Enter your password',
//         prefixIcon: const Icon(Icons.lock_outline_rounded),
//         border: const UnderlineInputBorder(),
//         suffixIcon: IconButton(
//           icon:
//               Icon(isPasswordVisible ?
// Icons.visibility_off : Icons.visibility),
//           onPressed: () {
//             print('show/hide password');
//             setState(() {
//               isPasswordVisible = !isPasswordVisible;
//             });
//           },
//         ),
//       ),
//     );
//   }
// }
