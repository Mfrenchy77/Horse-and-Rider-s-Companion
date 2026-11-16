import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/share_helper_stub.dart'
    if (dart.library.js_interop) 'package:horseandriderscompanion/Utilities/share_helper_web.dart';

/// Function signature for platform-native sharing (e.g. Web Share API).
typedef NativeShareHandler = Future<bool> Function({
  required String title,
  required String url,
  String? text,
});

/// Optional test override for [tryNativeWebShare].
NativeShareHandler? debugNativeShareOverride;

/// Default production origin used when [Uri.base] is not HTTP(S) (e.g. tests).
const String kProductionOrigin = 'https://horse-and-riders-compani-d2bd4.web.app';

/// Resolves the active HTTP(S) origin for shareable URLs.
String resolveShareOrigin([Uri? baseUri]) {
  final uri = baseUri ?? Uri.base;
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return uri.origin;
  }
  return kProductionOrigin;
}

/// Builds the canonical shareable URL for a Skill Tree 2.0 skill.
String buildSkillShareUrl(String skillId, {Uri? baseUri}) {
  final origin = resolveShareOrigin(baseUri);
  return '$origin/SkillTree?skillId=${Uri.encodeComponent(skillId)}';
}

/// Builds the canonical shareable URL for a public Horse profile.
String buildHorseShareUrl(String horseId, {Uri? baseUri}) {
  final origin = resolveShareOrigin(baseUri);
  return '$origin/Profile/Horse_Profile/${Uri.encodeComponent(horseId)}';
}

/// Shares [url] via native platform sharing when available, falling back to
/// a frosted-glass Copy Link dialog.
Future<void> shareAppLink(
  BuildContext context, {
  required String title,
  required String dialogTitle,
  required String url,
  String? text,
  String? subtitle,
}) async {
  final nativeHandler = debugNativeShareOverride ?? tryNativeWebShare;
  final shared = await nativeHandler(title: title, url: url, text: text);
  if (shared || !context.mounted) return;

  await showAppGlassDialog<void>(
    context: context,
    builder: (dialogContext) => AppGlassDialog(
      key: const Key('shareLinkDialog'),
      title: Text(dialogTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceSm,
          children: [
            if (subtitle != null && subtitle.isNotEmpty)
              Text(
                subtitle,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(
                  color: Theme.of(dialogContext).dividerColor,
                ),
              ),
              child: SelectableText(
                url,
                key: const Key('shareLinkUrlText'),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          key: const Key('shareCopyLinkButton'),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy Link'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
        ),
      ],
    ),
  );
}
