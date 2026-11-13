import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Profile-scoped aliases backed by the centralized [AppTokens] design system.
class ProfileTokens {
  const ProfileTokens._();

  static const String serifFont = AppTokens.serifFont;
  static const List<String> serifFallback = AppTokens.serifFallback;

  static const Color midnightBase = AppTokens.midnightBase;
  static const Color midnightMid = AppTokens.midnightMid;
  static const Color midnightCardTop = AppTokens.midnightCardTop;
  static const Color midnightCardBottom = AppTokens.midnightCardBottom;
  static const Color midnightButtonFill = AppTokens.midnightButtonFill;
  static const Color midnightButtonBorder = AppTokens.midnightButtonBorder;
  static const Color cardBorderDark = AppTokens.cardBorderDark;
  static const Color coralAccent = AppTokens.coralAccent;
  static const Color coralText = AppTokens.coralText;
  static const Color primaryTextDark = AppTokens.primaryTextDark;
  static const Color secondaryTextDark = AppTokens.secondaryTextDark;

  static const double cardRadius = AppTokens.radiusLg;
  static const double buttonRadius = AppTokens.radiusMd;
  static const double horseCardRadius = AppTokens.radiusMd;

  static const BoxDecoration midnightBackdrop = AppTokens.midnightBackdrop;

  static BoxDecoration atmosphericOverlay(BuildContext context) =>
      AppTokens.atmosphericOverlay(context);

  static TextStyle heroNameStyle(
    BuildContext context, {
    bool compact = false,
  }) => AppTokens.heroTitleStyle(context, compact: compact);

  static TextStyle sectionTitleStyle(BuildContext context) =>
      AppTokens.sectionTitleStyle(context);

  static Color secondaryTextColor(BuildContext context) =>
      AppTokens.secondaryTextColor(context);

  static Color accentColor(BuildContext context) =>
      AppTokens.accentColor(context);
}

/// Alias for [AppSurfaceCard] used across Rider Profile widgets.
class ProfileSurfaceCard extends AppSurfaceCard {
  const ProfileSurfaceCard({
    super.key,
    required super.child,
    super.padding,
    super.borderRadius,
  });
}

/// Alias for [AppSectionHeader] used across Rider Profile widgets.
class ProfileSectionHeader extends AppSectionHeader {
  const ProfileSectionHeader({
    super.key,
    required super.title,
    super.actionLabel,
    super.onAction,
    super.showArrow,
  });
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
              color: AppTokens.coralAccent,
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
              ? AppTokens.primaryTextDark.withValues(alpha: 0.92)
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
