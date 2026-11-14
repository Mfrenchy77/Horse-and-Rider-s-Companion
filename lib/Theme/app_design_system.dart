import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';

/// Centralized design tokens for Horse & Rider's Companion.
class AppTokens {
  const AppTokens._();

  // Typography
  static const String serifFont = 'Georgia';
  static const List<String> serifFallback = ['Times New Roman', 'serif'];

  // Core Midnight-Teal & Coral Palette
  static const Color midnightBase = Color(0xFF0A1D21);
  static const Color midnightMid = Color(0xFF0F262B);
  static const Color midnightDeep = Color(0xFF071518);
  static const Color midnightCardTop = Color(0xFF173339);
  static const Color midnightCardBottom = Color(0xFF0F2429);
  static const Color midnightButtonFill = Color(0xCC163137);
  static const Color midnightButtonBorder = Color(0x4D7EA1A5);
  static const Color midnightInputFill = Color(0xB30D2227);
  static const Color cardBorderDark = Color(0x3D628388);
  static const Color coralAccent = ColorConst.mainAccentDark;
  static const Color coralText = Color(0xFF102429);
  static const Color primaryTextDark = ColorConst.darkForeground;
  static const Color secondaryTextDark = ColorConst.darkMuted;

  // Semantic Status Colors
  static const Color successDark = Color(0xFF5FC29D);
  static const Color warningDark = Color(0xFFE4B66E);
  static const Color errorDark = ColorConst.errorDarkBlueGrey;
  static const Color infoDark = Color(0xFF6AB4C7);

  // Radii & Spacing
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;

  static const double minTouchTarget = 48;
  static const double maxContentWidth = 1320;

  // Glassmorphism Dialog Tokens
  static const double glassBackdropBlurSigma = 24;
  static const Color glassBarrierDark = Color(0x33061215);
  static const Color glassBarrierLight = Color(0x240A2329);
  static const Color glassBorderDark = Color(0x528DC4CE);
  static const Color glassBorderLight = Color(0xA6FFFFFF);

  // Gradients
  static const BoxDecoration midnightBackdrop = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [midnightMid, midnightBase, midnightDeep],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  static const LinearGradient cardSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightCardTop, midnightCardBottom],
  );

  static BoxDecoration atmosphericOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor);
    }
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.75, -0.85),
        radius: 1.15,
        colors: [Color(0x2E2A5961), Colors.transparent],
      ),
    );
  }

  static TextStyle heroTitleStyle(
    BuildContext context, {
    bool compact = false,
  }) {
    final base = Theme.of(context).textTheme.headlineMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: serifFont,
      fontFamilyFallback: serifFallback,
      fontSize: compact ? 26 : 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.12,
      color: primaryTextDark,
      shadows: const [
        Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2)),
      ],
    );
  }

  static TextStyle sectionTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontFamily: serifFont,
      fontFamilyFallback: serifFallback,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: isDark ? primaryTextDark : theme.colorScheme.onSurface,
    );
  }

  static Color primaryTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? primaryTextDark
        : theme.colorScheme.onSurface;
  }

  static Color secondaryTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? secondaryTextDark
        : theme.colorScheme.onSurfaceVariant;
  }

  static Color accentColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? coralAccent
        : theme.colorScheme.primary;
  }
}

/// Atmospheric midnight-teal backdrop for dark-themed pages.
class AppScaffoldBackdrop extends StatelessWidget {
  const AppScaffoldBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return child;
    }
    return DecoratedBox(
      decoration: AppTokens.midnightBackdrop,
      child: DecoratedBox(
        decoration: AppTokens.atmosphericOverlay(context),
        child: child,
      ),
    );
  }
}

/// Rounded dark translucent surface card with subtle border and gradient.
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceLg),
    this.borderRadius = AppTokens.radiusLg,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) {
      return GradientCard(
        margin: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: AppTokens.cardSurfaceGradient,
        border: Border.all(color: borderColor ?? AppTokens.cardBorderDark),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded dark gradient surface for dialogs and bottom sheets.
class AppDialogSurface extends StatelessWidget {
  const AppDialogSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceLg),
    this.borderRadius = AppTokens.radiusXl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: padding,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Controls how translucent vs. frosted an [AppGlassSurface] appears.
enum AppGlassDensity {
  /// Balanced translucency for compact dialogs and confirmation prompts.
  standard,

  /// Higher-opacity frosting for dense forms over bright photographic pages.
  frosted,
}

/// Translucent frosted-glass surface for floating dialogs.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceXl),
    this.borderRadius = AppTokens.radiusXl,
    this.customBorderRadius,
    this.density = AppGlassDensity.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final AppGlassDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = customBorderRadius ?? BorderRadius.circular(borderRadius);
    final isFrosted = density == AppGlassDensity.frosted;
    final topAlpha = isDark
        ? (isFrosted ? 0.91 : 0.80)
        : (isFrosted ? 0.94 : 0.86);
    final bottomAlpha = isDark
        ? (isFrosted ? 0.87 : 0.72)
        : (isFrosted ? 0.90 : 0.78);
    final gradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTokens.midnightCardTop.withValues(alpha: topAlpha),
              AppTokens.midnightCardBottom.withValues(alpha: bottomAlpha),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withValues(alpha: topAlpha),
              theme.colorScheme.surfaceContainerLow.withValues(
                alpha: bottomAlpha,
              ),
            ],
          );
    final borderColor = isDark
        ? AppTokens.glassBorderDark
        : AppTokens.glassBorderLight;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.36)
        : const Color(0xFF0A242B).withValues(alpha: 0.16);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.38],
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating frosted-glass dialog shell supporting light and dark themes.
class AppGlassDialog extends StatelessWidget {
  const AppGlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.maxWidth = 520,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 24,
    ),
    this.padding = const EdgeInsets.all(AppTokens.spaceXl),
    this.scrollable = true,
    this.density = AppGlassDensity.standard,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final AppGlassDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionWidgets = actions ?? const <Widget>[];
    final bodyStyle =
        theme.textTheme.bodyMedium?.copyWith(
          color: AppTokens.primaryTextColor(context),
        ) ??
        const TextStyle();

    Widget? contentWidget;
    if (content != null) {
      final styledContent = DefaultTextStyle.merge(
        style: bodyStyle,
        child: content!,
      );
      contentWidget = scrollable
          ? Flexible(child: SingleChildScrollView(child: styledContent))
          : Flexible(child: styledContent);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AppGlassSurface(
          padding: padding,
          density: density,
          child: Column(
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
              if (title != null && contentWidget != null)
                const SizedBox(height: AppTokens.spaceMd),
              ?contentWidget,
              if (actionWidgets.isNotEmpty) ...[
                const SizedBox(height: AppTokens.spaceLg),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 8,
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

/// Serif section heading with an optional coral trailing action link.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.showArrow = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accentColor(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTokens.sectionTitleStyle(context),
          ),
        ),
        if (actionLabel != null && onAction != null)
          Flexible(
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(
                  AppTokens.minTouchTarget,
                  AppTokens.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      actionLabel!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: accent),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Primary coral filled button with dark high-contrast ink.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final style = FilledButton.styleFrom(
      backgroundColor: AppTokens.accentColor(context),
      foregroundColor: isDark
          ? AppTokens.coralText
          : theme.colorScheme.onPrimary,
      minimumSize: const Size(AppTokens.minTouchTarget, 50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

/// Secondary translucent dark-teal outlined button.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppTokens.primaryTextColor(context),
      backgroundColor: isDark
          ? AppTokens.midnightButtonFill
          : theme.colorScheme.surface.withValues(alpha: 0.7),
      side: BorderSide(
        color: isDark
            ? AppTokens.midnightButtonBorder
            : theme.colorScheme.outline,
      ),
      minimumSize: const Size(AppTokens.minTouchTarget, 50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
    );
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

/// Clearly differentiated destructive action button (distinct from coral
/// primary).
class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final onError = Theme.of(context).colorScheme.onError;
    if (outlined) {
      final style = OutlinedButton.styleFrom(
        foregroundColor: errorColor,
        side: BorderSide(color: errorColor.withValues(alpha: 0.75)),
        minimumSize: const Size(AppTokens.minTouchTarget, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      );
      return icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 18),
              label: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            );
    }
    final style = FilledButton.styleFrom(
      backgroundColor: errorColor,
      foregroundColor: onError,
      minimumSize: const Size(AppTokens.minTouchTarget, 50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
    );
    return icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

enum AppStatusTone { neutral, coral, success, warning, error, info }

/// Color-independent status badge pairing an icon and label.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final IconData? icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (tone) {
      AppStatusTone.coral => AppTokens.accentColor(context),
      AppStatusTone.success =>
        isDark ? AppTokens.successDark : const Color(0xFF2E7D32),
      AppStatusTone.warning =>
        isDark ? AppTokens.warningDark : const Color(0xFFED6C02),
      AppStatusTone.error => theme.colorScheme.error,
      AppStatusTone.info =>
        isDark ? AppTokens.infoDark : theme.colorScheme.primary,
      AppStatusTone.neutral => AppTokens.secondaryTextColor(context),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark ? AppTokens.primaryTextDark : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable dark radial + bottom-fade vignette overlay for photography.
class AppImageVignette extends StatelessWidget {
  const AppImageVignette({super.key, this.bottomColor});

  final Color? bottomColor;

  @override
  Widget build(BuildContext context) {
    final fade = bottomColor ?? AppTokens.midnightBase;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.05,
                colors: [Colors.transparent, Color(0x73051013)],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x28051013),
                  Colors.transparent,
                  fade.withValues(alpha: 0.72),
                  fade,
                ],
                stops: const [0.0, 0.28, 0.74, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent dark-teal placeholder for missing or loading photographs.
class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({super.key, this.logoSize = 44});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? const Color(0xFF153137)
          : theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Image.asset(
          'assets/horse_logo.png',
          width: logoSize,
          height: logoSize,
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Centered loading indicator styled with the coral accent.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTokens.accentColor(context)),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTokens.secondaryTextColor(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent empty-state card with serif title and optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppTokens.accentColor(context)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTokens.sectionTitleStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTokens.secondaryTextColor(context),
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            AppPrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Consistent error-state card with optional retry action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AppSurfaceCard(
      borderColor: errorColor.withValues(alpha: 0.55),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 38, color: errorColor),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTokens.sectionTitleStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTokens.secondaryTextColor(context)),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppOutlinedButton(
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline feedback banner for success, info, warning, or error messages.
class AppFeedbackBanner extends StatelessWidget {
  const AppFeedbackBanner({
    super.key,
    required this.message,
    this.tone = AppStatusTone.success,
    this.icon,
  });

  final String message;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (tone) {
      AppStatusTone.success =>
        isDark ? AppTokens.successDark : const Color(0xFF2E7D32),
      AppStatusTone.warning =>
        isDark ? AppTokens.warningDark : const Color(0xFFED6C02),
      AppStatusTone.error => theme.colorScheme.error,
      AppStatusTone.coral => AppTokens.accentColor(context),
      AppStatusTone.info =>
        isDark ? AppTokens.infoDark : theme.colorScheme.primary,
      AppStatusTone.neutral => AppTokens.secondaryTextColor(context),
    };
    final effectiveIcon =
        icon ??
        switch (tone) {
          AppStatusTone.success => Icons.check_circle_outline,
          AppStatusTone.warning => Icons.warning_amber_rounded,
          AppStatusTone.error => Icons.error_outline,
          _ => Icons.info_outline,
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(effectiveIcon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.primaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
