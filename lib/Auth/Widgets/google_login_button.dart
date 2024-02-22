// ignore_for_file: prefer_single_quotes, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

///   Widget that has a button that sends you to Google autherization link
class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return Tooltip(
          message: "Login with Google Account",
          child: InkWell(
            onTap: cubit.logInWithGoogle,
            child: Column(
              children: [
                const Text(
                  "Login with Google Account",
                  style: TextStyle(color: Colors.white54),
                ),
                smallGap(),
                Image.asset(
                  'assets/google_icon.png',
                  height: 30,
                  width: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
