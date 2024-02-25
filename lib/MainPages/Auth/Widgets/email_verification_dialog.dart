import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
import 'package:responsive_framework/responsive_framework.dart';

class EmailVerificationDialog extends StatelessWidget {
  const EmailVerificationDialog({
    required this.email,
    super.key,
  });
  final String email;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorConst.backgroundDark,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const MaxWidthBox(
            maxWidth: 500,
            child: Logo(
              screenName: 'Email Verification Needed',
              forceDark: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Please verify your email $email \nbefore using the app',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          gap(),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
