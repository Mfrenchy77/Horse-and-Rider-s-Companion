// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/Home/Home/bloc/home_cubit.dart';

// class ResourcesSortDialog extends StatelessWidget {
//   const ResourcesSortDialog({super.key, required this.buildContext});
//   final BuildContext buildContext;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         title: const Text('Sort Resources'),
//       ),
//       body: AlertDialog(
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextButton(
//               onPressed: () {
//                 debugPrint('New Clicked');
//                 Navigator.of(context).pop();
//               },
//               child: const Text('New'),
//             ),
//             TextButton(
//               onPressed: () {
//                 debugPrint('Saved Clicked');
//                 buildContext.read<HomeCubit>().sortBySaved();
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Saved'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
