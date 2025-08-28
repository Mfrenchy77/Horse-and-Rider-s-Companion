// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

// Widget that has a text button that takes you to the Registration Page
class RegistrationLink extends StatelessWidget {
  const RegistrationLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.read<LoginCubit>().gotoRegister();
      },
      child: const Text(
        'No Account Yet? Create one',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
