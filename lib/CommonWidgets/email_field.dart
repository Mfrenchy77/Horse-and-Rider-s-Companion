// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/Presentation/Screens/Login/Bloc/login_bloc.dart';
// import 'package:horseandriderscompanion/Presentation/Screens/Registration/bloc/register_bloc.dart';

// import '../../utils/view_utils.dart';

// enum EmailState { login, register, forgot }

// class EmailField extends StatelessWidget {
//   const EmailField({super.key, required this.emailState});
//   final EmailState emailState;
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       onChanged: ((value) {
//         switch (emailState) {
//           case EmailState.login:
//             return context
//                 .read<LoginBloc>()
//                 .add(LoginEmailChangedEvent(email: value));

//           case EmailState.register:
//             return context
//                 .read<RegisterBloc>()
//                 .add(RegisterEmailChangedEvent(email: value));
//           case EmailState.forgot:
//             return context
//                 .read<RegisterBloc>()
//                 .add(RegisterEmailChangedEvent(email: value));
//         }
//       }),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter some text';
//         }
//         if (!ViewUtils.isEmailValid(value)) {
//           return 'Please enter a valid email';
//         }
//         return null;
//       },
//       decoration: const InputDecoration(
//         labelText: 'Email',
//         hintText: 'Enter your email',
//         prefixIcon: Icon(Icons.email_outlined),
//         border: UnderlineInputBorder(),
//       ),
//     );
//   }
// }
