import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Opens an app dialog while preserving Material's barrier and focus behavior.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    _AppDialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      useGlassBackdrop: false,
      blurSigma: 0,
      barrierColor: const Color(0x8C000000),
    ),
  );
}

/// Opens a frosted-glass dialog that blurs the underlying page behind it.
Future<T?> showAppGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  double blurSigma = AppTokens.glassBackdropBlurSigma,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return navigator.push(
    _AppDialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      useGlassBackdrop: true,
      blurSigma: blurSigma,
      barrierColor: isDark
          ? AppTokens.glassBarrierDark
          : AppTokens.glassBarrierLight,
    ),
  );
}

class _AppDialogRoute<T> extends DialogRoute<T> {
  _AppDialogRoute({
    required super.context,
    required super.builder,
    required super.barrierDismissible,
    required super.themes,
    required this.reduceMotion,
    required this.useGlassBackdrop,
    required this.blurSigma,
    required Color super.barrierColor,
  }) : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  final bool reduceMotion;
  final bool useGlassBackdrop;
  final double blurSigma;
  late final CurvedAnimation _visibility;
  late final CurvedAnimation _scale;

  @override
  Duration get transitionDuration => reduceMotion
      ? Duration.zero
      : Duration(milliseconds: useGlassBackdrop ? 300 : 340);

  @override
  Duration get reverseTransitionDuration => reduceMotion
      ? Duration.zero
      : Duration(milliseconds: useGlassBackdrop ? 220 : 230);

  @override
  Curve get barrierCurve => Curves.linear;

  @override
  void install() {
    super.install();
    // The route value falls from 1 to 0 on exit. Flip the exit curve
    // so elapsed dismissal time still follows easeInCubic.
    _visibility = CurvedAnimation(
      parent: animation!,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic.flipped,
    );
    _scale = CurvedAnimation(
      parent: animation!,
      curve: useGlassBackdrop ? Curves.easeOutCubic : Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic.flipped,
    );
  }

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    if (!useGlassBackdrop || blurSigma <= 0) return barrier;

    return AnimatedBuilder(
      animation: animation!,
      builder: (context, child) {
        final t = reduceMotion ? 1.0 : _visibility.value.clamp(0.0, 1.0);
        final sigma = blurSigma * t;
        if (sigma <= 0.01) return child!;
        final filter = ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        );
        // Two passes keep each sigma <= 30 so WebGL/CanvasKit does not clamp
        // or skip the blur while dramatically defocusing underlying text.
        return ClipRect(
          child: BackdropFilter(
            filter: filter,
            child: BackdropFilter(filter: filter, child: child),
          ),
        );
      },
      child: barrier,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion) return child;

    final slideOffset = useGlassBackdrop ? 16.0 : 20.0;
    final scaleBegin = useGlassBackdrop ? 0.94 : 0.88;

    return LayoutBuilder(
      builder: (context, constraints) => SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, slideOffset / constraints.maxHeight),
          end: Offset.zero,
        ).animate(_visibility),
        child: FadeTransition(
          opacity: _visibility,
          child: ScaleTransition(
            scale: Tween<double>(begin: scaleBegin, end: 1).animate(_scale),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _visibility.dispose();
    _scale.dispose();
    super.dispose();
  }
}
