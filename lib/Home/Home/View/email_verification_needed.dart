import 'package:flutter/material.dart';

Widget emailVerificationDialog() {
  return const AlertDialog(
    title: Text('Email Verification Needed'),
    content: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Please verify your email before using the app',
          ),
          SizedBox(height: 20),
          // ElevatedButton(
          //   onPressed: () {
          //     context.read<AppBloc>().add(AppLogoutRequested());
          //     Navigator.pushReplacementNamed(
          //       context,
          //       LoginPage.routeName,
          //     );
          //   },
          //   child: const Text('Logout'),
          // ),
        ],
      ),
    ),
  );
}
