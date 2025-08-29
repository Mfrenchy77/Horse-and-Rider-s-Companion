import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
import 'package:horseandriderscompanion/Utilities/navigation_utils.dart';

class EmailVerificationDialog extends StatelessWidget {
  const EmailVerificationDialog({
    required this.email,
    super.key,
  });
  static const name = 'EmailVerificationDialog';
  static const path = 'EmailVerificationDialog/:email';
  static const pathParms = 'email';
  final String email;
  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listener: (context, state) {
        if (!state.showEmailVerification) {
          if (context.mounted) context.pushReplacementNamed(ProfilePage.name);
        }
      },
      child: AlertDialog(
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
              email.isEmpty
                  ? 'An email has been sent to your email. '
                      'Please verify your email to continue.'
                  : 'An email has been sent to $email. '
                      'Please verify your email to continue.',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            gap(),
            const Text(
              'If you do not see the email, please check your spam folder.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // close dialog safely
              safePop(context);
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => context.read<AppCubit>().resendEmailVerification(),
            child: const Text('Resend Email'),
          ),
          Visibility(
            visible: email.isNotEmpty,
            child: ElevatedButton(
              onPressed: () => context.read<AppCubit>().openEmail(email),
              child: const Text('Open Email'),
            ),
          ),
        ],
      ),
    );
  }
}
