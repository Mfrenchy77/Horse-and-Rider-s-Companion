// ignore_for_file: prefer_single_quotes, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';

///   Widget that has a button that sends you to Google autherization link
class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return Column(
          children: [
            const Text(
              "Login with Google Account",
              style: TextStyle(color: Colors.white54),
            ),
            IconButton(
              onPressed: () => context.read<LoginCubit>().logInWithGoogle(),
              icon: Image.asset(
                'assets/google_icon.png',
                height: 30,
                width: 30,
              ),
            ),
          ],
        );
      },
    );
  }
}
