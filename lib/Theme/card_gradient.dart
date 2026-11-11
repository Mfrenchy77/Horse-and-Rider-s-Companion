import 'package:flutter/material.dart';

@immutable
class CardGradientTheme extends ThemeExtension<CardGradientTheme> {
  const CardGradientTheme({required this.gradient});

  factory CardGradientTheme.fromTheme(ThemeData theme) {
    final base = theme.colorScheme.surface;
    return CardGradientTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            theme.primaryColor.withValues(
              alpha: theme.brightness == Brightness.dark ? .32 : .04,
            ),
            base,
          ),
          Color.alphaBlend(
            theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? .04 : .01,
            ),
            base,
          ),
        ],
      ),
    );
  }

  final LinearGradient gradient;

  @override
  CardGradientTheme copyWith({LinearGradient? gradient}) =>
      CardGradientTheme(gradient: gradient ?? this.gradient);

  @override
  CardGradientTheme lerp(CardGradientTheme? other, double t) => other == null
      ? this
      : CardGradientTheme(
          gradient: LinearGradient.lerp(gradient, other.gradient, t)!,
        );
}

/// Standard content card. Explicit colors retain their semantic meaning.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.margin,
    this.elevation,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.extension<CardGradientTheme>() ??
        CardGradientTheme.fromTheme(theme);
    return Card(
      margin: margin,
      elevation: elevation,
      color: color,
      // Avoid anti-aliased clipping here. On some web GPU backends that
      // produces an unsupported Skia coverage shader when rendering profile
      // cards. The card's Material still supplies the rounded visual surface.
      clipBehavior: Clip.none,
      child: color != null
          ? child
          : Ink(
              decoration: BoxDecoration(gradient: style.gradient),
              child: child,
            ),
    );
  }
}
