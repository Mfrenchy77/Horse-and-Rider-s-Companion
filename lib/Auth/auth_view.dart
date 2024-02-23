import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/Auth/Widgets/email_verification_dialog.dart';
import 'package:horseandriderscompanion/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/Auth/forgot_view.dart';
import 'package:horseandriderscompanion/Auth/login_view.dart';
import 'package:horseandriderscompanion/Auth/register_view.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/utils/MyConstants/COLOR_CONST.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:responsive_framework/max_width_box.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen =
        ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);
    return Scaffold(
      backgroundColor: ColorConst.backgroundDark,
      body: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status.isSubmissionSuccess) {
            debugPrint('Success Login, go to HomePage');
            Navigator.pushReplacementNamed(context, HomePage.routeName);
          }
          final cubit = context.read<LoginCubit>();
          if (state.pageStatus == LoginPageStatus.awitingEmailVerification) {
            context.read<LoginCubit>().checkEmailVerificationStatus();
            showDialog<AlertDialog>(
              context: context,
              builder: (_) => EmailVerificationDialog(email: state.email.value),
            );
            if (state.mailAppResult != null) {
              showDialog<MailAppPickerDialog>(
                context: context,
                builder: (_) {
                  return MailAppPickerDialog(
                    mailApps: state.mailAppResult!.options,
                  );
                },
              ).then((value) => cubit.clearEmailDialog());
            }
          }

          if (state.isError) {
            debugPrint('Error: ${state.errorMessage}');
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.errorMessage),
                  ),
                ).closed.then((_) => cubit.clearError());
            });
          }
        },
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            return isSmallScreen
                ? SingleChildScrollView(
                    child: Center(
                      child: MaxWidthBox(
                        maxWidth: 550,
                        child: Card(
                          color: ColorConst.cardDark,
                          margin: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 42,
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Logo(
                                  screenName: getScreenName(state.pageStatus),
                                  forceDark: true,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 300),
                                      child: Form(
                                        child: getView(state: state),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Center(
                      child: MaxWidthBox(
                        maxWidth: 1000,
                        child: Card(
                          color: ColorConst.cardDark,
                          margin: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 42,
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Logo(
                                    screenName: getScreenName(state.pageStatus),
                                    forceDark: true,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 300),
                                        child: Form(
                                          child: getView(state: state),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }
}

/// Returns the screen name for the page status
String getScreenName(LoginPageStatus pageStatus) {
  switch (pageStatus) {
    case LoginPageStatus.login:
      return 'Login';
    case LoginPageStatus.register:
      return 'Register';
    case LoginPageStatus.forgot:
      return 'Forgot Password';
    case LoginPageStatus.awitingEmailVerification:
      return 'Email Verification';
  }
}

/// Returns the view for the page status
Widget getView({
  required LoginState state,
}) {
  switch (state.pageStatus) {
    case LoginPageStatus.login:
      return loginView();
    case LoginPageStatus.register:
      return registerView();
    case LoginPageStatus.forgot:
      return forgotView();
    case LoginPageStatus.awitingEmailVerification:
      return loginView();
  }
}