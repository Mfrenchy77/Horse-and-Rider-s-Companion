import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';

class GuestLoginButton extends StatelessWidget {
  const GuestLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        smallGap(),
        const Divider(
          indent: 100,
          endIndent: 100,
          color: Colors.black,
          thickness: 1,
        ),
        Tooltip(
          message: 'Create Account/Login',
          child: MaxWidthBox(
            maxWidth: 200,
            child: FilledButton(
              onPressed: () {
                context.goNamed(AuthPage.name);
              },
              child: const Text(
                'Create Account/Login',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
