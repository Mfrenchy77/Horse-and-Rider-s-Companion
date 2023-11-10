// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

//Widget with an icon button that lets you selects saved profiles
class SavedProfilesWidget extends StatelessWidget {
  const SavedProfilesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        //Saved accounts button
        IconButton(
          onPressed: () {
            print('Open saved accounts');
          },
          icon: const Icon(Icons.account_circle),
          color: Colors.black,
        ),
      ],
    );
  }
}
