import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/Login/view/forgot_view.dart';
import 'package:horseandriderscompanion/Login/view/login_view.dart';
import 'package:horseandriderscompanion/Login/view/register_view.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen =
        ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        if (state.status.isSubmissionSuccess) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            Navigator.of(context).pushReplacementNamed(HomePage.routeName);
          });
        }
        if (state.showEmailDialog) {
          if (state.mailAppResult != null) {
            showDialog<MailAppPickerDialog>(
              context: context,
              builder: (_) {
                return MailAppPickerDialog(
                  mailApps: state.mailAppResult!.options,
                );
              },
            ).then((value) => context.read<LoginCubit>().clearEmailDialog());
          }
        }
        if (state.isError) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            context
                .read<LoginCubit>()
                .showErrorSnackBar(context, state.errorMessage);
          });
        }
        if (state.pageStatus == LoginPageStatus.login) {
          return loginView(
            context: context,
            state: state,
            isSmallScreen: isSmallScreen,
          );
        } else if (state.pageStatus == LoginPageStatus.register) {
          return registerView(
            state: state,
            context: context,
            isSmallScreen: isSmallScreen,
          );
        } else if (state.pageStatus == LoginPageStatus.forgot) {
          return forgotView(
            context: context,
            state: state,
            isSmallScreen: isSmallScreen,
          );
        } else {
          return const Center(
            child: Logo(
              screenName: 'Loading...',
            ),
          );
        }
      },
    );
  }
}
