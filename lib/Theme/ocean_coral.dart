import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';

bool isOceanCoralDarkTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark &&
      theme.colorScheme.primary == ColorConst.mainAccentDark;
}

class OceanCoralGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColorConst.mainPrimaryDark,
      ColorConst.backgroundDark,
      ColorConst.mainBackgroundDark,
    ],
    stops: [0, 0.56, 1],
  );

  static const LinearGradient rail = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF365A61),
      ColorConst.mainPrimaryDark,
      ColorConst.backgroundDark,
    ],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF365A61),
      ColorConst.mainPrimaryDark,
      ColorConst.backgroundDark,
    ],
  );
}

/// Applies the gradient surface for the active theme.
///
/// This is intended for "surfaces" like dialogs, cards, and panels.
class OceanCoralSurface extends StatelessWidget {
  const OceanCoralSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradients = theme.extension<SurfaceGradients>();
    if (!isDark && gradients == null) return child;
    final isOceanCoral = isOceanCoralDarkTheme(context);

    final radius = borderRadius ?? const BorderRadius.all(Radius.circular(20));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? AppTokens.cardSurfaceGradient : gradients?.surface,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppTokens.cardBorderDark
              : isOceanCoral
                  ? ColorConst.dividerDarkBlueGrey
                  : theme.colorScheme.outlineVariant,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: isOceanCoral ? Clip.antiAlias : Clip.hardEdge,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// Wrap an [AlertDialog] (or any dialog widget) so its surface matches the
/// Ocean/Coral gradient.
///
/// This works by:
/// - applying a transparent dialog theme locally, so the inner dialog doesn't
///   paint a solid Material background
/// - providing the gradient surface outside.
class OceanCoralDialog extends StatelessWidget {
  const OceanCoralDialog({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.extension<SurfaceGradients>() == null) {
      return child;
    }

    // IMPORTANT:
    // When showDialog() is given a widget that is *not* a Dialog/AlertDialog,
    // it won't apply the usual inset padding / "floating" dialog affordance.
    // Our earlier approach wrapped an AlertDialog with a surface, which made
    // the gradient look like a full-screen panel on web once the AlertDialog's
    // own background was made transparent.
    //
    // By providing an explicit Dialog shell here, we keep dialogs looking like
    // dialogs (inset + centered + constrained), and the gradient becomes the
    // dialog surface.
    return Theme(
      data: theme.copyWith(
        dialogTheme: theme.dialogTheme.copyWith(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: OceanCoralSurface(child: child),
      ),
    );
  }
}

/// Opinionated app dialog used across the UI.
///
/// Why this exists:
/// - AlertDialog internally relies on intrinsic sizing.
/// - When we make the dialog background transparent to show a gradient surface,
///   its sizing can look "off" (especially on web).
///
/// This widget provides a consistent shell:
/// - centered + inset
/// - constrained width
/// - optional scrolling content
/// - Ocean/Coral gradient surface in the active theme
class OceanCoralAppDialog extends StatelessWidget {
  const OceanCoralAppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.maxWidth = 520,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 24,
    ),
    this.scrollable = false,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;
  final EdgeInsets insetPadding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = actions ?? const <Widget>[];

    if (Theme.of(context).extension<SurfaceGradients>() == null) {
      return AlertDialog(
        scrollable: scrollable,
        insetPadding: insetPadding,
        title: title,
        content: maxWidth.isFinite
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: content,
              )
            : content,
        actions: actionWidgets,
      );
    }

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Semantics(
            namesRoute: true,
            child: DefaultTextStyle.merge(
              style: AppTokens.sectionTitleStyle(context),
              textAlign: TextAlign.center,
              child: title!,
            ),
          ),
        if (title != null && content != null)
          const SizedBox(height: AppTokens.spaceMd),
        if (content != null) content!,
      ],
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: OceanCoralSurface(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (scrollable)
                Flexible(child: SingleChildScrollView(child: body))
              else
                body,
              if (actionWidgets.isNotEmpty) ...[
                const SizedBox(height: 16),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 12,
                  overflowSpacing: 8,
                  children: actionWidgets,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
