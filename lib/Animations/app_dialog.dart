import 'package:flutter/material.dart';

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
  }) : super(
         barrierColor: const Color(0x8C000000),
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );

  final bool reduceMotion;
  late final CurvedAnimation _visibility;
  late final CurvedAnimation _scale;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 230);

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
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic.flipped,
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

    return LayoutBuilder(
      builder: (context, constraints) => SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 20 / constraints.maxHeight),
          end: Offset.zero,
        ).animate(_visibility),
        child: FadeTransition(
          opacity: _visibility,
          child: ScaleTransition(
            scale: Tween<double>(begin: .88, end: 1).animate(_scale),
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
