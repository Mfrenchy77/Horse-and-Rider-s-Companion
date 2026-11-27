import 'dart:convert';

import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent local cache for published Dictionary entries backed by
/// [SharedPreferences].
///
/// Completely Firebase-free: normalizes any backend-specific date objects into
/// tagged ISO-8601 maps for JSON serialization and degrades gracefully if
/// [SharedPreferences] has not been initialized (e.g. isolated unit tests).
class DictionaryLocalCache {
  const DictionaryLocalCache._();

  static const _storageKey = 'dictionary_catalogue_cache_v1';
  static const _dtTag = '__dt__';

  /// Reads the cached published entries and manifest metadata, or `null` if no
  /// valid local cache exists.
  static Future<DictionaryLocalSnapshot?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final rawEntries = decoded['entries'];
      if (rawEntries is! List<dynamic>) return null;
      final entries = <DictionaryEntry>[];
      for (final item in rawEntries) {
        if (item is! Map) continue;
        final map = _decodeValue(item) as Map<String, dynamic>;
        entries.add(DictionaryEntry(map));
      }
      final published = List<DictionaryEntry>.unmodifiable(
        entries.where((entry) => entry.published),
      );
      if (published.isEmpty) return null;
      return DictionaryLocalSnapshot(
        entries: published,
        version: (decoded['version'] as num?)?.toInt(),
        updatedAtMs: (decoded['updatedAtMs'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Writes published [entries] and their manifest version metadata locally.
  static Future<void> write({
    required List<DictionaryEntry> entries,
    int? version,
    int? updatedAtMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(<String, dynamic>{
        'version': version,
        'updatedAtMs': updatedAtMs,
        'savedAtMs': DateTime.now().millisecondsSinceEpoch,
        'entries': [
          for (final entry in entries)
            if (entry.published && !entry.bundled) _encodeValue(entry.data),
        ],
      });
      await prefs.setString(_storageKey, payload);
    } catch (_) {
      // Ignore storage unavailability in headless tests or restricted contexts.
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // Ignore storage unavailability.
    }
  }

  static dynamic _encodeValue(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return <String, dynamic>{_dtTag: value.toUtc().toIso8601String()};
    }
    if (value is List) {
      return [for (final item in value) _encodeValue(item)];
    }
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _encodeValue(entry.value),
      };
    }
    // Support Firestore Timestamp without importing cloud_firestore.
    try {
      final dt = (value as dynamic).toDate() as DateTime;
      return <String, dynamic>{_dtTag: dt.toUtc().toIso8601String()};
    } catch (_) {
      return value.toString();
    }
  }

  static dynamic _decodeValue(dynamic value) {
    if (value is List) {
      return [for (final item in value) _decodeValue(item)];
    }
    if (value is Map) {
      if (value.length == 1 && value.containsKey(_dtTag)) {
        final rawDt = value[_dtTag];
        if (rawDt is String) {
          return DateTime.tryParse(rawDt) ?? rawDt;
        }
      }
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _decodeValue(entry.value),
      };
    }
    return value;
  }
}

class DictionaryLocalSnapshot {
  const DictionaryLocalSnapshot({
    required this.entries,
    required this.version,
    required this.updatedAtMs,
  });

  final List<DictionaryEntry> entries;
  final int? version;
  final int? updatedAtMs;
}
