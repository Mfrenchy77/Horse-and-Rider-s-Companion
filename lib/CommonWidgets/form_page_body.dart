import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Scrollable, width-constrained content for a full-page form.
class FormPageBody extends StatelessWidget {
  const FormPageBody({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppScaffoldBackdrop(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
