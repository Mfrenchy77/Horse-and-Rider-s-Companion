import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/forgot_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/login_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/register_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: ColorConst.backgroundDark,
      body: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            debugPrint('Success Pop?');
            context.goNamed(ProfilePage.name);
            // if (state.mailAppResult != null) {
            //   showDialog<MailAppPickerDialog>(
            //     context: context,
            //     builder: (_) {
            //       return MailAppPickerDialog(
            //         mailApps: state.mailAppResult!.options,
            //       );
            //     },
            //   ).then((value) => cubit.clearEmailDialog());
            // }
          }
          if (state.isMessage) {
            debugPrint('Message: ${state.errorMessage}');
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor:
                        HorseAndRidersTheme().getTheme().primaryColor,
                    content: Text(state.errorMessage),
                  ),
                );
            });
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
                );
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
  }
}
