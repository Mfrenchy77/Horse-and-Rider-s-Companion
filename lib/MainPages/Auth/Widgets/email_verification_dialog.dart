import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/navigation_utils.dart';

class EmailVerificationDialog extends StatelessWidget {
  const EmailVerificationDialog({required this.email, super.key});
  static const name = 'EmailVerificationDialog';
  static const path = 'EmailVerificationDialog/:email';
  static const pathParms = 'email';
  final String email;
  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.showEmailVerification && !current.showEmailVerification,
      listener: (context, state) {
        if (ModalRoute.isCurrentOf(context) ?? false) safePop(context);
      },
      child: AppGlassDialog(
        maxWidth: 560,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const MaxWidthBox(
              maxWidth: 500,
              child: Logo(screenName: 'Email Verification Needed'),
            ),
            const SizedBox(height: 20),
            Text(
              email.isEmpty
                  ? 'An email has been sent to your email. '
                      'Please verify your email to continue.'
                  : 'An email has been sent to $email. '
                      'Please verify your email to continue.',
              style: const TextStyle(fontSize: 16),
            ),
            gap(),
            const Text(
              'If you do not see the email, please check your spam folder.',
              style: TextStyle(fontSize: 16),
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
          if (email.isNotEmpty)
            ElevatedButton(
              onPressed: () => context.read<AppCubit>().openEmail(email),
              child: const Text('Open Email'),
            ),
        ],
      ),
    );
  }
}
