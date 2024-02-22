// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Auth/cubit/login_cubit.dart';

// Widget that has a text button that takes you to the Forgot Password Page
class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.read<LoginCubit>().gotoforgot();
      },
      child: const Text(
        'Forgot Your Password?',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
