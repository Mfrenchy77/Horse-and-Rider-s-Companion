// import 'package:flutter/material.dart';

// class NameField extends StatelessWidget {

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       onChanged: (value) {
//         //TODO fix this with the current cubit method
//         // context.read<RegisterBloc>()
//         //.add(RegisterNameChangedEvent(name: value));
//       },
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter your Name';
//         }

//         return null;
//       },
//       decoration: const InputDecoration(
//         labelText: 'Name',
//         hintText: 'Enter your Full Name',
//         prefixIcon: Icon(Icons.person_outline),
//         border: UnderlineInputBorder(),
//       ),
//     );
//   }
// }
