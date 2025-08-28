// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

// Widget that has a text button that takes you to the Registration Page
class LoginLink extends StatelessWidget {
  const LoginLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.read<LoginCubit>().gotoLogin();
      },
      child: const Text(
        'Already have an account? Sign in',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
