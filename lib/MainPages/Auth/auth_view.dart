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
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

// Simple cooldown between SnackBars to avoid rapid spamming.
// ignore: use_late_for_private_fields_and_variables
DateTime? _lastSnackShownAt;
const _snackCooldown = Duration(milliseconds: 1200);

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradients = theme.extension<SurfaceGradients>();
    final isDark = theme.brightness == Brightness.dark;
    final formTheme = isDark
        ? theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              focusedBorder: const _AuthFocusBorder(
                borderSide: BorderSide(
                  color: AppTokens.coralAccent,
                  width: 1.4,
                ),
              ),
              focusedErrorBorder: const _AuthFocusBorder(
                borderSide: BorderSide(color: AppTokens.errorDark, width: 1.4),
              ),
            ),
          )
        : theme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: gradients != null
          ? Colors.transparent
          : ColorConst.backgroundDark,
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
            final now = DateTime.now();
            final canShow =
                _lastSnackShownAt == null ||
                now.difference(_lastSnackShownAt!) >= _snackCooldown;
            if (canShow) {
              _lastSnackShownAt = now;
              debugPrint('Message: ${state.message}');
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      backgroundColor: HorseAndRidersTheme()
                          .getTheme()
                          .primaryColor,
                      content: Text(state.message),
                    ),
                  );
              });
            }
          }

          if (state.isError) {
            final now = DateTime.now();
            final canShow =
                _lastSnackShownAt == null ||
                now.difference(_lastSnackShownAt!) >= _snackCooldown;
            if (canShow) {
              _lastSnackShownAt = now;
              debugPrint('Error: ${state.message}');
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(state.message),
                    ),
                  );
              });
            }
          }
        },
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            final logo = Logo(
              screenName: getScreenName(state.pageStatus),
              forceDark: true,
            );
            final form = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Theme(
                data: formTheme,
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: getView(state: state),
                ),
              ),
            );
            final content = isSmallScreen
                ? Column(children: [logo, form])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: logo),
                      Expanded(child: Center(child: form)),
                    ],
                  );
            return SizedBox.expand(
              child: AppScaffoldBackdrop(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 42, 20, 20),
                  child: Center(
                    child: MaxWidthBox(
                      maxWidth: isSmallScreen ? 510 : 960,
                      child: isDark
                          ? AppSurfaceCard(child: content)
                          : GradientCard(
                              color: ColorConst.cardDark,
                              margin: EdgeInsets.zero,
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: content,
                              ),
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

/// Paints the selection gradient inside the input, above any validation text.
class _AuthFocusBorder extends OutlineInputBorder {
  const _AuthFocusBorder({required super.borderSide})
    : super(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppTokens.radiusMd),
        ),
      );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      Paint()..shader = AppTokens.selectedSurfaceGradient.createShader(rect),
    );
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
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
Widget getView({required LoginState state}) {
  switch (state.pageStatus) {
    case LoginPageStatus.login:
      return loginView();
    case LoginPageStatus.register:
      return registerView();
    case LoginPageStatus.forgot:
      return forgotView();
  }
}
