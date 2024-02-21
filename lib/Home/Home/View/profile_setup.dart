import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';

/// This is the page that is shown when the user has registered but not
/// completed their profile setup their rider profile is not set up yet
Widget profileSetup({
  required HomeState state,
  required BuildContext context,
  required HomeCubit homeCubit,
}) {
  final nameController = TextEditingController(text: state.user?.name ?? '');
  return Scaffold(
    body: AlertDialog(
      title: const Text('Finish Profile Setup'),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              state.user?.name.isEmpty ?? false
                  ? 'You have not finished setting up your profile yet'
                  : "Welcome ${state.user?.name} to Horse & Rider's Companion,"
                      ' verify your name to complete your profile',
            ),
            gap(),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Enter your full name',
              ),
            ),
            gap(),
            FilledButton(
              onPressed: () {
                homeCubit.createRiderProfile(
                  user: state.user,
                  name: nameController.text,
                );
              },
              child: const Text('Complete Profile'),
            ),
          ],
        ),
      ),
    ),
  );
}
