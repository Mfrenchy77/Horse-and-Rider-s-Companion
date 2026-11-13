import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';

/// Design tokens for the Rider Profile visual language.
class ProfileTokens {
  const ProfileTokens._();

  static const String serifFont = 'Georgia';
  static const List<String> serifFallback = ['Times New Roman', 'serif'];

  static const Color midnightBase = Color(0xFF0A1D21);
  static const Color midnightMid = Color(0xFF0F262B);
  static const Color midnightCardTop = Color(0xFF173339);
  static const Color midnightCardBottom = Color(0xFF0F2429);
  static const Color midnightButtonFill = Color(0xCC163137);
  static const Color midnightButtonBorder = Color(0x4D7EA1A5);
  static const Color cardBorderDark = Color(0x3D628388);
  static const Color coralAccent = ColorConst.mainAccentDark;
  static const Color coralText = Color(0xFF102429);
  static const Color primaryTextDark = ColorConst.darkForeground;
  static const Color secondaryTextDark = ColorConst.darkMuted;

  static const double cardRadius = 16;
  static const double buttonRadius = 14;
  static const double horseCardRadius = 14;

  static const BoxDecoration midnightBackdrop = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [midnightMid, midnightBase, Color(0xFF071518)],
      stops: [0.0, 0.45, 1.0],
    ),
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

  static TextStyle heroNameStyle(BuildContext context, {bool compact = false}) {
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

/// Reusable dark-teal translucent surface card with subtle border and gradient.
class ProfileSurfaceCard extends StatelessWidget {
  const ProfileSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = ProfileTokens.cardRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (!isDark) {
      return GradientCard(
        margin: EdgeInsets.zero,
        child: Padding(padding: padding, child: child),
      );
    }

    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ProfileTokens.midnightCardTop,
            ProfileTokens.midnightCardBottom,
          ],
        ),
        border: Border.all(color: ProfileTokens.cardBorderDark),
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

/// Section header with a serif title and optional coral "View All" action.
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
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
    final accent = ProfileTokens.accentColor(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ProfileTokens.sectionTitleStyle(context),
          ),
        ),
        if (actionLabel != null && onAction != null)
          Flexible(
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(48, 48),
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

/// Renders basic Markdown (`**bold**`, `*italic*`, `` `code` ``, `# headings`,
/// `- bullets`) cleanly into [TextSpan]s without displaying raw markers.
class MarkdownBioText extends StatelessWidget {
  const MarkdownBioText({
    super.key,
    required this.markdown,
    this.maxLines,
    this.overflow,
    this.style,
  });

  final String markdown;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  static TextSpan buildSpan(String input, TextStyle baseStyle) {
    final lines = input.replaceAll('\r\n', '\n').split('\n');
    final children = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trimRight();
      var lineStyle = baseStyle;

      final headingMatch = RegExp(r'^#{1,3}\s+(.*)$').firstMatch(line);
      if (headingMatch != null) {
        line = headingMatch.group(1) ?? '';
        lineStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
      } else if (RegExp(r'^[-*]\s+').hasMatch(line)) {
        line = '• ${line.replaceFirst(RegExp(r'^[-*]\s+'), '')}';
      }

      children.addAll(_parseInline(line, lineStyle));
      if (i < lines.length - 1) {
        children.add(const TextSpan(text: '\n'));
      }
    }
    return TextSpan(style: baseStyle, children: children);
  }

  static List<InlineSpan> _parseInline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|__[^_]+__|\*[^*]+\*|_[^_]+_|`[^`]+`|\[([^\]]+)\]\([^)]+\))',
    );
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: base),
        );
      }
      final token = match.group(0)!;
      if ((token.startsWith('**') && token.endsWith('**')) ||
          (token.startsWith('__') && token.endsWith('__'))) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if ((token.startsWith('*') && token.endsWith('*')) ||
          (token.startsWith('_') && token.endsWith('_'))) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: base.copyWith(fontFamily: 'monospace'),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: base.copyWith(
              color: ProfileTokens.coralAccent,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? ProfileTokens.primaryTextDark.withValues(alpha: 0.92)
              : null,
          height: 1.5,
        ) ??
        const TextStyle(height: 1.5);
    return Text.rich(
      buildSpan(markdown, effectiveStyle),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
