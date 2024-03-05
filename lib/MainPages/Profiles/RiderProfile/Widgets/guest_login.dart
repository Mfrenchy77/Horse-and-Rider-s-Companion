import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GuestLoginButton extends StatelessWidget {
  const GuestLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Column(
          children: [
            smallGap(),
            Visibility(
              visible: state.isGuest,
              child: const Divider(
                indent: 100,
                endIndent: 100,
                color: Colors.black,
                thickness: 1,
              ),
            ),
            Visibility(
              visible: state.isGuest,
              child: Tooltip(
                message: 'Create Account/Login',
                child: MaxWidthBox(
                  maxWidth: 200,
                  child: FilledButton(
                    onPressed: cubit.logOutRequested,
                    child: const Text('Create Account/Login'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
