// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;
import 'package:database_repository/database_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

const int maxDictionaryMediaItems = 8;
const int maxCommunityImagesPerSubmission = 3;
const int maxDictionaryImageBytes = 10 * 1024 * 1024;
const int maxDictionaryImageDimension = 2048;

typedef DictionaryPickedImage = ({String name, Uint8List bytes});
typedef DictionaryMultiImagePicker =
    Future<List<DictionaryPickedImage>> Function();

enum DictionaryImageType {
  illustrative('illustrative', 'Illustrative image'),
  photograph('photograph', 'Educational photograph'),
  diagram('diagram', 'Technical diagram');

  const DictionaryImageType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static DictionaryImageType fromStorageValue(String? raw) {
    for (final value in values) {
      if (value.storageValue == raw) return value;
    }
    return DictionaryImageType.illustrative;
  }
}

class DictionaryMediaItem {
  const DictionaryMediaItem({
    required this.url,
    required this.label,
    this.imageType = DictionaryImageType.illustrative,
    this.explanation = '',
    this.attribution,
  });

  factory DictionaryMediaItem.fromMap(Map<String, dynamic> map) =>
      DictionaryMediaItem(
        url: (map['url'] as String?)?.trim() ?? '',
        label: (map['label'] as String?)?.trim() ?? '',
        imageType: DictionaryImageType.fromStorageValue(
          map['imageType'] as String?,
        ),
        explanation: (map['explanation'] as String?)?.trim() ?? '',
        attribution: ((map['attribution'] as String?)?.trim() ?? '').isNotEmpty
            ? (map['attribution'] as String).trim()
            : null,
      );

  final String url;
  final String label;
  final DictionaryImageType imageType;
  final String explanation;
  final String? attribution;

  Map<String, dynamic> toMap() => {
    'url': url,
    'label': label,
    if (imageType != DictionaryImageType.illustrative)
      'imageType': imageType.storageValue,
    if (explanation.trim().isNotEmpty) 'explanation': explanation.trim(),
    if (attribution != null && attribution!.trim().isNotEmpty)
      'attribution': attribution!.trim(),
  };
}

String _computeSha256Hex(Uint8List bytes) =>
    crypto.sha256.convert(bytes).toString();

Future<String> _hashBytes(Uint8List bytes) {
  if (bytes.length < 64 * 1024) {
    return Future<String>.value(_computeSha256Hex(bytes));
  }
  return compute(_computeSha256Hex, bytes);
}

class ProcessedDictionaryImage {
  const ProcessedDictionaryImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
    required this.sha256,
    required this.originalByteLength,
    required this.wasResized,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
  final String sha256;
  final int originalByteLength;
  final bool wasResized;
}

/// Validates, hashes, and resizes oversized educational images while preserving
/// crisp detail up to `maxDimension` px.
class DictionaryImageProcessor {
  static const int _maxCacheEntries = 16;
  static final Map<String, ProcessedDictionaryImage> _cache = {};

  @visibleForTesting
  static void clearCache() => _cache.clear();

  /// Reads pixel dimensions directly from PNG, JPEG, or WebP headers without
  /// decoding the bitmap into memory.
  static ({int width, int height})? readDimensions(
    Uint8List bytes,
    String contentType,
  ) {
    switch (contentType) {
      case 'image/png':
        return _readPngDimensions(bytes);
      case 'image/jpeg':
        return _readJpegDimensions(bytes);
      case 'image/webp':
        return _readWebpDimensions(bytes);
      default:
        return null;
    }
  }

  static ({int width, int height})? _readPngDimensions(Uint8List bytes) {
    if (bytes.length < 24) return null;
    // IHDR chunk at byte offset 12..15.
    if (bytes[12] != 0x49 ||
        bytes[13] != 0x48 ||
        bytes[14] != 0x44 ||
        bytes[15] != 0x52) {
      return null;
    }
    final data = ByteData.sublistView(bytes, 16, 24);
    final width = data.getUint32(0);
    final height = data.getUint32(4);
    if (width <= 0 || height <= 0) return null;
    return (width: width, height: height);
  }

  static ({int width, int height})? _readJpegDimensions(Uint8List bytes) {
    if (bytes.length < 11 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }
    var pos = 2;
    while (pos < bytes.length - 1) {
      if (bytes[pos] != 0xFF) {
        pos++;
        continue;
      }
      while (pos < bytes.length && bytes[pos] == 0xFF) {
        pos++;
      }
      if (pos >= bytes.length) break;
      final marker = bytes[pos++];
      if (marker == 0x00 ||
          marker == 0x01 ||
          (marker >= 0xD0 && marker <= 0xD7)) {
        continue;
      }
      if (marker == 0xD9 || marker == 0xDA) {
        break;
      }
      if (pos + 1 >= bytes.length) break;
      final segmentLength = (bytes[pos] << 8) | bytes[pos + 1];
      if (segmentLength < 2 || pos + segmentLength > bytes.length) break;
      final isSof =
          (marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB) ||
          (marker >= 0xCD && marker <= 0xCF);
      if (isSof && segmentLength >= 7) {
        final height = (bytes[pos + 3] << 8) | bytes[pos + 4];
        final width = (bytes[pos + 5] << 8) | bytes[pos + 6];
        if (width > 0 && height > 0) {
          return (width: width, height: height);
        }
        return null;
      }
      pos += segmentLength;
    }
    return null;
  }

  static ({int width, int height})? _readWebpDimensions(Uint8List bytes) {
    if (bytes.length < 30 ||
        bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46 ||
        bytes[8] != 0x57 ||
        bytes[9] != 0x45 ||
        bytes[10] != 0x42 ||
        bytes[11] != 0x50) {
      return null;
    }
    final c0 = bytes[12];
    final c1 = bytes[13];
    final c2 = bytes[14];
    final c3 = bytes[15];
    // 'VP8 ' (lossy)
    if (c0 == 0x56 && c1 == 0x50 && c2 == 0x38 && c3 == 0x20) {
      if (bytes[23] != 0x9D || bytes[24] != 0x01 || bytes[25] != 0x2A) {
        return null;
      }
      final width = (bytes[26] | (bytes[27] << 8)) & 0x3FFF;
      final height = (bytes[28] | (bytes[29] << 8)) & 0x3FFF;
      return (width > 0 && height > 0) ? (width: width, height: height) : null;
    }
    // 'VP8L' (lossless)
    if (c0 == 0x56 && c1 == 0x50 && c2 == 0x38 && c3 == 0x4C) {
      if (bytes[20] != 0x2F) return null;
      final bits =
          bytes[21] | (bytes[22] << 8) | (bytes[23] << 16) | (bytes[24] << 24);
      final width = (bits & 0x3FFF) + 1;
      final height = ((bits >> 14) & 0x3FFF) + 1;
      return (width: width, height: height);
    }
    // 'VP8X' (extended)
    if (c0 == 0x56 && c1 == 0x50 && c2 == 0x38 && c3 == 0x58) {
      final width = (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16)) + 1;
      final height = (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16)) + 1;
      return (width: width, height: height);
    }
    return null;
  }

  static void _storeCache(String key, ProcessedDictionaryImage value) {
    _cache.remove(key);
    _cache[key] = value;
    if (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  static Future<ProcessedDictionaryImage> process({
    required Uint8List bytes,
    required String fileName,
    int maxDimension = maxDictionaryImageDimension,
    String? precomputedRawHash,
  }) async {
    final validated = DictionaryImageValidator.validate(
      bytes: bytes,
      fileName: fileName,
    );
    final rawHash =
        precomputedRawHash ?? await _hashBytes(validated.bytes);
    final cacheKey = '$rawHash:$maxDimension';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      var dims = readDimensions(validated.bytes, validated.contentType);
      if (dims == null) {
        final codec = await ui.instantiateImageCodec(validated.bytes);
        final frame = await codec.getNextFrame();
        dims = (width: frame.image.width, height: frame.image.height);
        frame.image.dispose();
        codec.dispose();
      }

      if (dims.width > maxDimension || dims.height > maxDimension) {
        final scale =
            maxDimension /
            (dims.width > dims.height ? dims.width : dims.height);
        final targetWidth = max(1, (dims.width * scale).round());
        final targetHeight = max(1, (dims.height * scale).round());
        final resizedCodec = await ui.instantiateImageCodec(
          validated.bytes,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        final resizedFrame = await resizedCodec.getNextFrame();
        final byteData = await resizedFrame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        resizedFrame.image.dispose();
        resizedCodec.dispose();

        if (byteData != null) {
          final resizedBytes = byteData.buffer.asUint8List();
          final shouldUseResized =
              resizedBytes.isNotEmpty &&
              resizedBytes.length <= maxDictionaryImageBytes &&
              (validated.contentType == 'image/png' ||
                  resizedBytes.length <= validated.bytes.length);
          if (shouldUseResized) {
            final baseName = validated.fileName.replaceAll(
              RegExp(r'\.[^.]+$'),
              '',
            );
            final processed = ProcessedDictionaryImage(
              bytes: resizedBytes,
              fileName: '$baseName.png',
              contentType: 'image/png',
              sha256: await _hashBytes(resizedBytes),
              originalByteLength: validated.bytes.length,
              wasResized: true,
            );
            _storeCache(cacheKey, processed);
            return processed;
          }
        }
      }
    } catch (_) {
      // Minimal stub bytes in unit tests or unsupported decoders fall back to
      // the validated original payload cleanly without failing valid images.
    }

    final fallback = ProcessedDictionaryImage(
      bytes: validated.bytes,
      fileName: validated.fileName,
      contentType: validated.contentType,
      sha256: rawHash,
      originalByteLength: validated.bytes.length,
      wasResized: false,
    );
    _storeCache(cacheKey, fallback);
    return fallback;
  }
}

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
    final safeBase = base.isEmpty
        ? 'image'
        : base.substring(0, base.length.clamp(0, 48));

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

/// Returns the primary published image item attached to [entry], or `null`
/// when [entry] has no valid HTTPS image URL. Reads directly from `entry.data`
/// without issuing additional repository or Firestore requests.
DictionaryMediaItem? firstPublishedDictionaryImage(DictionaryEntry entry) {
  final rawMedia = entry.data['media'];
  if (rawMedia is! List) return null;
  for (final item in rawMedia) {
    if (item is Map && isDictionaryImageUrl(item['url'] as String?)) {
      return DictionaryMediaItem.fromMap(item.cast<String, dynamic>());
    }
  }
  return null;
}

/// Renders Dictionary `media` items: images inline via [SmartImage] with
/// captions, optional educational explanation/attribution, and tap-to-zoom via
/// the shared immersive `PhotoView` viewer, and non-image HTTPS links as buttons.
class DictionaryMediaGallery extends StatelessWidget {
  const DictionaryMediaGallery({super.key, required this.media});

  final List<Map<String, dynamic>> media;

  @override
  Widget build(BuildContext context) {
    final images = <DictionaryMediaItem>[];
    final links = <Map<String, dynamic>>[];
    for (final raw in media) {
      final url = raw['url'] as String?;
      if (isDictionaryImageUrl(url)) {
        images.add(DictionaryMediaItem.fromMap(raw));
      } else if (url != null && url.startsWith('https://')) {
        links.add(raw);
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
                      child: _DictionaryImageCard(item: images[i], index: i),
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
  const _DictionaryImageCard({required this.item, required this.index});

  final DictionaryMediaItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final hasMeta =
        item.label.isNotEmpty ||
        item.explanation.isNotEmpty ||
        item.attribution != null ||
        item.imageType != DictionaryImageType.illustrative;

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('dictionaryInlineImage_$index'),
        onTap: () => showProfilePhoto(
          context,
          item.url,
          heroTag: 'dictionary-gallery-$index-${item.url.hashCode}',
          caption: item.label.isEmpty ? 'Dictionary illustration' : item.label,
          explanation: item.explanation.isEmpty ? null : item.explanation,
          imageTypeLabel: item.imageType.label,
          attribution: item.attribution,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 260,
                    minHeight: 140,
                  ),
                  child: SmartImage(item.url, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.zoom_in, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            if (hasMeta)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    if (item.imageType != DictionaryImageType.illustrative)
                      Text(
                        item.imageType.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTokens.accentColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (item.label.isNotEmpty)
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (item.explanation.isNotEmpty)
                      Text(
                        item.explanation,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                      ),
                    if (item.attribution != null)
                      Text(
                        'Contributed by ${item.attribution}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: secondaryColor),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pending uploaded (or failing) community image in a contributor submission.
class CommunityPendingImage {
  CommunityPendingImage({
    required this.id,
    required this.fileName,
    required this.previewBytes,
    required this.sha256,
    required this.contentType,
    this.rawHash,
    this.uploadedUrl,
    double uploadProgress = 0,
    this.isUploading = false,
    this.errorMessage,
    String initialCaption = '',
    String initialExplanation = '',
  }) : progressNotifier = ValueNotifier<double>(uploadProgress.clamp(0.0, 1.0)),
       captionController = TextEditingController(text: initialCaption),
       explanationController = TextEditingController(text: initialExplanation);

  final String id;
  final String fileName;
  final Uint8List previewBytes;
  final String sha256;
  final String contentType;
  final String? rawHash;
  String? uploadedUrl;
  final ValueNotifier<double> progressNotifier;
  bool isUploading;
  String? errorMessage;
  final TextEditingController captionController;
  final TextEditingController explanationController;

  /// Cached downscaled thumbnail provider (~160px wide) so multi-megapixel
  /// images do not allocate full-resolution GPU textures in the contribution list.
  late final ImageProvider thumbnailProvider = ResizeImage(
    MemoryImage(previewBytes),
    width: 160,
  );

  double get uploadProgress => progressNotifier.value;
  set uploadProgress(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (progressNotifier.value != clamped) {
      progressNotifier.value = clamped;
    }
  }

  bool get isReady =>
      uploadedUrl != null && !isUploading && errorMessage == null;

  Map<String, dynamic> toSubmissionMap() => {
    'id': id,
    'url': uploadedUrl,
    'sha256': sha256,
    'caption': captionController.text.trim(),
    'explanation': explanationController.text.trim(),
    'imageType': DictionaryImageType.illustrative.storageValue,
  };

  void dispose() {
    progressNotifier.dispose();
    captionController.dispose();
    explanationController.dispose();
  }
}

/// Reusable community image picker, client-side processor, duplicate detector,
/// progress tracker, and retry/cleanup section (max 3 images per submission).
class DictionaryImagePickerSection extends StatefulWidget {
  const DictionaryImagePickerSection({
    super.key,
    required this.uid,
    required this.submissionId,
    required this.items,
    required this.onItemsChanged,
    this.mediaStorage,
    this.pickImages,
    this.processImage,
    this.maxImages = maxCommunityImagesPerSubmission,
    this.onBusyChanged,
  });

  final String uid;
  final String submissionId;
  final List<CommunityPendingImage> items;
  final ValueChanged<List<CommunityPendingImage>> onItemsChanged;
  final MediaStorageRepository? mediaStorage;
  final DictionaryMultiImagePicker? pickImages;
  final Future<ProcessedDictionaryImage> Function({
    required Uint8List bytes,
    required String fileName,
  })?
  processImage;
  final int maxImages;
  final ValueChanged<bool>? onBusyChanged;

  @override
  State<DictionaryImagePickerSection> createState() =>
      _DictionaryImagePickerSectionState();
}

class _DictionaryImagePickerSectionState
    extends State<DictionaryImagePickerSection> {
  MediaStorageRepository? _resolvedStorage;
  String? _error;
  String? _notice;
  bool _isPreparing = false;
  String? _preparingStatus;
  bool _lastReportedBusy = false;

  MediaStorageRepository _storage() => _resolvedStorage ??=
      widget.mediaStorage ??
      context.read<MediaStorageRepository?>() ??
      CloudRepository();

  Future<List<DictionaryPickedImage>> _pickFromDevice() async {
    if (widget.pickImages != null) {
      return widget.pickImages!();
    }
    final files = await FilePicker.pickFiles(type: FileType.image);
    final out = <DictionaryPickedImage>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        out.add((name: file.name, bytes: bytes));
      }
    }
    return out;
  }

  void _notifyBusy({List<CommunityPendingImage>? items}) {
    final active = items ?? widget.items;
    final busy = _isPreparing || active.any((item) => item.isUploading);
    if (busy != _lastReportedBusy) {
      _lastReportedBusy = busy;
      widget.onBusyChanged?.call(busy);
    }
  }

  Future<void> _selectAndUpload() async {
    if (_isPreparing || widget.items.length >= widget.maxImages) return;
    setState(() {
      _isPreparing = true;
      _preparingStatus = 'Selecting images…';
      _error = null;
      _notice = null;
    });
    _notifyBusy();

    try {
      final picked = await _pickFromDevice();
      if (!mounted || picked.isEmpty) return;

      final remaining = widget.maxImages - widget.items.length;
      if (picked.length > remaining) {
        setState(() {
          _notice =
              'Only $remaining more ${remaining == 1 ? 'image' : 'images'} can be added '
              '(maximum ${widget.maxImages} per submission).';
        });
      }

      final currentList = List<CommunityPendingImage>.from(widget.items);
      for (final file in picked.take(remaining)) {
        if (!mounted) return;
        setState(() {
          _preparingStatus = 'Preparing ${file.name}…';
        });
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;

        final rawHash = crypto.sha256.convert(file.bytes).toString();
        if (currentList.any(
          (existing) =>
              existing.rawHash == rawHash || existing.sha256 == rawHash,
        )) {
          setState(() {
            _notice = 'Skipped duplicate image "${file.name}".';
          });
          continue;
        }

        ProcessedDictionaryImage processed;
        try {
          if (widget.processImage != null) {
            processed = await widget.processImage!(
              bytes: file.bytes,
              fileName: file.name,
            );
          } else {
            processed = await DictionaryImageProcessor.process(
              bytes: file.bytes,
              fileName: file.name,
              precomputedRawHash: rawHash,
            );
          }
        } on FormatException catch (e) {
          setState(() => _error = e.message);
          continue;
        } catch (e) {
          setState(() => _error = 'Could not prepare image "${file.name}": $e');
          continue;
        }

        if (currentList.any(
          (existing) => existing.sha256 == processed.sha256,
        )) {
          setState(() {
            _notice = 'Skipped duplicate image "${file.name}".';
          });
          continue;
        }

        final id =
            'img_${DateTime.now().microsecondsSinceEpoch}_${currentList.length}';
        final pending = CommunityPendingImage(
          id: id,
          fileName: processed.fileName,
          previewBytes: processed.bytes,
          sha256: processed.sha256,
          contentType: processed.contentType,
          rawHash: rawHash,
          isUploading: true,
        );
        currentList.add(pending);
        widget.onItemsChanged(List<CommunityPendingImage>.from(currentList));
        _notifyBusy(items: currentList);
        await _uploadPending(
          pending,
          processed.bytes,
          currentList: currentList,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
          _preparingStatus = null;
        });
        _notifyBusy();
      }
    }
  }

  String _formatUploadError(Object error) {
    if (error is MediaStorageException) {
      switch (error.code) {
        case 'unauthorized':
          return 'Upload failed (unauthorized): your account could not be '
              'authorized for image upload. Confirm your email is verified and '
              'try again, or contact support if this persists.';
        case 'unauthenticated':
          return 'Upload failed: please sign in again before uploading images.';
        case 'retry-limit-exceeded':
          return 'Upload timed out due to a network issue. Please try again.';
        case 'canceled':
          return 'Upload was canceled. Retry when ready.';
      }
    }
    return 'Upload failed: $error';
  }

  Future<void> _uploadPending(
    CommunityPendingImage pending,
    Uint8List bytes, {
    List<CommunityPendingImage>? currentList,
  }) async {
    final activeList = currentList ?? widget.items;
    setState(() {
      pending
        ..isUploading = true
        ..errorMessage = null
        ..uploadProgress = 0;
    });
    _notifyBusy(items: activeList);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'dictionary_submissions/${widget.uid}/${widget.submissionId}/${timestamp}_${pending.fileName}';
    var lastReported = -1.0;
    var lastEmitMs = 0;

    try {
      final url = await _storage().uploadBytes(
        path: storagePath,
        bytes: bytes,
        contentType: pending.contentType,
        onProgress: (progress) {
          if (!mounted) return;
          final clamped = progress.clamp(0.0, 1.0);
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          if (clamped == 0.0 ||
              clamped == 1.0 ||
              (clamped - lastReported).abs() >= 0.02 ||
              (nowMs - lastEmitMs) >= 60) {
            lastReported = clamped;
            lastEmitMs = nowMs;
            pending.uploadProgress = clamped;
          }
        },
      );
      if (!mounted) return;
      if (url.isEmpty) {
        setState(() {
          pending
            ..isUploading = false
            ..errorMessage = 'Upload did not return a download link.';
        });
      } else {
        setState(() {
          pending
            ..isUploading = false
            ..uploadProgress = 1.0
            ..uploadedUrl = url
            ..errorMessage = null;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.storage,
        'Dictionary image upload failed [contentType=${pending.contentType}, bytes=${bytes.length}]',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        pending
          ..isUploading = false
          ..errorMessage = _formatUploadError(e);
      });
    }
    if (mounted) {
      widget.onItemsChanged(List<CommunityPendingImage>.from(activeList));
      _notifyBusy(items: activeList);
    }
  }

  Future<void> _removeItem(int index) async {
    final removed = widget.items[index];
    final next = List<CommunityPendingImage>.from(widget.items)
      ..removeAt(index);
    widget.onItemsChanged(next);
    _notifyBusy(items: next);
    final url = removed.uploadedUrl;
    removed.dispose();
    if (url != null && url.isNotEmpty) {
      await _storage().deleteByUrl(url).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final atLimit = widget.items.length >= widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Images (${widget.items.length}/${widget.maxImages})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('dictionaryPickCommunityImagesButton'),
              onPressed: (atLimit || _isPreparing) ? null : _selectAndUpload,
              icon: _isPreparing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(
                _isPreparing
                    ? 'Preparing…'
                    : atLimit
                    ? 'Maximum ${widget.maxImages} reached'
                    : 'Choose images',
              ),
            ),
          ],
        ),
        Text(
          'PNG, JPEG, or WebP up to 10 MB each. Large images are automatically '
          'resized while keeping illustration detail sharp.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: secondaryColor),
        ),
        if (_preparingStatus != null)
          Row(
            key: const Key('dictionaryImagePreparingIndicator'),
            spacing: 8,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Expanded(
                child: Text(
                  _preparingStatus!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                ),
              ),
            ],
          ),
        if (_error != null)
          Text(
            _error!,
            key: const Key('dictionaryCommunityImageError'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_notice != null)
          Text(
            _notice!,
            key: const Key('dictionaryCommunityImageNotice'),
            style: TextStyle(color: AppTokens.accentColor(context)),
          ),
        for (var i = 0; i < widget.items.length; i++)
          _PendingImageCard(
            item: widget.items[i],
            index: i,
            onRetry: () =>
                _uploadPending(widget.items[i], widget.items[i].previewBytes),
            onRemove: () => _removeItem(i),
          ),
      ],
    );
  }
}

class _PendingImageCard extends StatelessWidget {
  const _PendingImageCard({
    required this.item,
    required this.index,
    required this.onRetry,
    required this.onRemove,
  });

  final CommunityPendingImage item;
  final int index;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    return RepaintBoundary(
      key: ValueKey(item.id),
      child: Container(
        key: Key('communityPendingImage_$index'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: item.errorMessage != null
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: RepaintBoundary(
                      child: Image(
                        key: Key('communityImageThumbnail_$index'),
                        image: item.thumbnailProvider,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, _, _) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.isUploading)
                        ValueListenableBuilder<double>(
                          valueListenable: item.progressNotifier,
                          builder: (context, progress, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              LinearProgressIndicator(
                                key: Key('communityImageProgress_$index'),
                                value: progress > 0 ? progress : null,
                              ),
                              Text(
                                'Uploading ${(progress * 100).round()}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: secondaryColor),
                              ),
                            ],
                          ),
                        )
                      else if (item.errorMessage != null) ...[
                        Text(
                          item.errorMessage!,
                          key: Key('communityImageUploadError_$index'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                        OutlinedButton.icon(
                          key: Key('dictionaryRetryCommunityImage_${item.id}'),
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry upload'),
                        ),
                      ] else
                        Row(
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppTokens.accentColor(context),
                            ),
                            Text(
                              'Uploaded and ready for review',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: secondaryColor),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('communityImageRemove_$index'),
                  tooltip: 'Remove image',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextFormField(
              key: Key('communityImageCaption_$index'),
              controller: item.captionController,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Short caption (optional)',
                hintText: 'Brief label shown alongside the image',
              ),
            ),
            TextFormField(
              key: Key('communityImageExplanation_$index'),
              controller: item.explanationController,
              maxLength: 600,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Educational explanation (optional)',
                hintText:
                    'Explain what this photo or diagram helps riders and horses understand',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
