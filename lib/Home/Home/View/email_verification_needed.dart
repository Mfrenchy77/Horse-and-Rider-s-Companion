import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';

Widget emailVerificationDialog() {
  return const AlertDialog(
    title: Text('Email Verification Needed'),
    content: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Logo(screenName: 'Email Verification Needed'),
          SizedBox(height: 20),
          Text(
            'Please verify your email before using the app',
          ),

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
