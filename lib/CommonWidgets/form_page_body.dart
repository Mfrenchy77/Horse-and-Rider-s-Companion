import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';

/// Scrollable, width-constrained content for a full-page form.
class FormPageBody extends StatelessWidget {
  const FormPageBody({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          gradient: theme.extension<SurfaceGradients>()?.background,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
