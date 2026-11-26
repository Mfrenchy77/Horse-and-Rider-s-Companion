// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

const int maxDictionaryMediaItems = 8;
const int maxDictionaryImageBytes = 10 * 1024 * 1024;

/// Validated image payload ready for Firebase Storage upload.
class ValidatedDictionaryImage {
  const ValidatedDictionaryImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

/// Validates PNG, JPEG, and WebP images by extension, magic bytes, and size.
class DictionaryImageValidator {
  static final RegExp _imagePathPattern = RegExp(
    r'\.(png|jpe?g|webp)$',
    caseSensitive: false,
  );

  static ValidatedDictionaryImage validate({
    required Uint8List bytes,
    required String fileName,
  }) {
    if (bytes.isEmpty) {
      throw const FormatException('The selected image file is empty.');
    }
    if (bytes.length > maxDictionaryImageBytes) {
      throw const FormatException('Images must be 10 MB or smaller.');
    }

    final detectedMime = _detectMimeFromBytes(bytes);
    final extMime = _mimeFromFileName(fileName);

    if (extMime == null || detectedMime == null || detectedMime != extMime) {
      throw const FormatException(
        'Only valid PNG, JPEG, and WebP image files with matching extensions '
        'are supported.',
      );
    }
    final contentType = detectedMime;

    final ext = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final base = fileName
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final safeBase = base.isEmpty ? 'image' : base.substring(0, base.length.clamp(0, 48));

    return ValidatedDictionaryImage(
      bytes: bytes,
      fileName: '$safeBase.$ext',
      contentType: contentType,
    );
  }

  static String? _mimeFromFileName(String name) {
    final lower = name.trim().toLowerCase();
    if (!_imagePathPattern.hasMatch(lower)) return null;
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String? _detectMimeFromBytes(Uint8List bytes) {
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    // JPEG: FF D8 FF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }
}

/// Returns true when [rawUrl] is an HTTPS URL pointing to a PNG, JPEG, or WebP
/// image (matching Open Graph selection in `functions/share_preview.js`).
bool isDictionaryImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return false;
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || uri.scheme != 'https') return false;
  return RegExp(
    r'\.(png|jpe?g|webp)$',
    caseSensitive: false,
  ).hasMatch(uri.path);
}

/// Renders Dictionary `media` items: images inline via [SmartImage] with
/// captions and tap-to-zoom preview, and non-image HTTPS links as buttons.
class DictionaryMediaGallery extends StatelessWidget {
  const DictionaryMediaGallery({super.key, required this.media});

  final List<Map<String, dynamic>> media;

  @override
  Widget build(BuildContext context) {
    final images = <Map<String, dynamic>>[];
    final links = <Map<String, dynamic>>[];
    for (final item in media) {
      final url = item['url'] as String?;
      if (isDictionaryImageUrl(url)) {
        images.add(item);
      } else if (url != null && url.startsWith('https://')) {
        links.add(item);
      }
    }

    if (images.isEmpty && links.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (images.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 560 && images.length > 1;
              final itemWidth = twoCol
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < images.length; i++)
                    SizedBox(
                      width: itemWidth,
                      child: _DictionaryImageCard(
                        url: images[i]['url'] as String,
                        caption: (images[i]['label'] as String?) ?? '',
                        index: i,
                      ),
                    ),
                ],
              );
            },
          ),
        if (links.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in links)
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  onPressed: () async {
                    final uri = Uri.tryParse(item['url'] as String);
                    if (uri?.scheme == 'https') {
                      await launchUrl(
                        uri!,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  label: Text((item['label'] as String?) ?? 'Open media'),
                ),
            ],
          ),
      ],
    );
  }
}

class _DictionaryImageCard extends StatelessWidget {
  const _DictionaryImageCard({
    required this.url,
    required this.caption,
    required this.index,
  });

  final String url;
  final String caption;
  final int index;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('dictionaryInlineImage_$index'),
        onTap: () => showAppGlassDialog<void>(
          context: context,
          builder: (ctx) => AppGlassDialog(
            maxWidth: 760,
            title: Text(caption.isEmpty ? 'Dictionary illustration' : caption),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: SmartImage(
                url,
                fit: BoxFit.contain,
                maxLogicalWidth: 720,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minHeight: 140),
              child: SmartImage(
                url,
                fit: BoxFit.contain,
              ),
            ),
            if (caption.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Text(
                  caption,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
