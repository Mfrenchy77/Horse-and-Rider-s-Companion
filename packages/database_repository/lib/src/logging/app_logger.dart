import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity levels supported by [AppLogger].
enum LogLevel {
  /// Fine-grained diagnostic events useful during active development.
  debug(severity: 0, label: 'DEBUG', developerLevel: 500),

  /// High-level operational milestones in the application lifecycle.
  info(severity: 1, label: 'INFO', developerLevel: 800),

  /// Recoverable anomalies or unexpected fallback paths.
  warning(severity: 2, label: 'WARN', developerLevel: 900),

  /// Failures that prevented an operation from succeeding.
  error(severity: 3, label: 'ERROR', developerLevel: 1000);

  const LogLevel({
    required this.severity,
    required this.label,
    required this.developerLevel,
  });

  /// Numeric ordering used to compare minimum log thresholds.
  final int severity;

  /// Short uppercase tag used in formatted log output.
  final String label;

  /// Equivalent `dart:developer` log level value.
  final int developerLevel;
}

/// Functional areas used to tag and filter [AppLogger] records.
enum LogCategory {
  /// Application startup, lifecycle, and root cubit coordination.
  app('app'),

  /// Authentication and session flows.
  auth('auth'),

  /// Routing and navigation state.
  navigation('navigation'),

  /// Repository and backend data persistence operations.
  database('database'),

  /// Media upload and storage operations.
  storage('storage'),

  /// Skill Tree 2.0 and legacy skill tree workflows.
  skillTree('skill_tree'),

  /// Equestrian Dictionary loading, matching, and submissions.
  dictionary('dictionary'),

  /// Educational resources, comments, and ratings.
  resources('resources'),

  /// Rider and horse profile management and search.
  profile('profile'),

  /// User preferences and application settings.
  settings('settings'),

  /// BLoC and Cubit observer events.
  bloc('bloc'),

  /// Mobile and web advertising initialization.
  ads('ads'),

  /// Shared UI widgets and dialogs.
  ui('ui');

  const LogCategory(this.tag);

  /// Short lowercase tag printed in formatted log lines.
  final String tag;
}

/// Immutable structured log entry emitted by [AppLogger].
class LogRecord {
  /// Creates a structured log entry.
  const LogRecord({
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  /// Severity level of the entry.
  final LogLevel level;

  /// Functional domain category of the entry.
  final LogCategory category;

  /// Sanitized log message text.
  final String message;

  /// Timestamp captured when the log call occurred.
  final DateTime timestamp;

  /// Optional sanitized string description of an associated error.
  final String? error;

  /// Optional stack trace associated with a warning or error.
  final StackTrace? stackTrace;

  /// Canonical single-line summary formatted for readable console output.
  String get formattedMessage {
    final buffer = StringBuffer('[${level.label}][${category.tag}] $message');
    if (error != null && error!.isNotEmpty) {
      buffer.write(' | error: $error');
    }
    return buffer.toString();
  }
}

/// Callback invoked for each accepted [LogRecord].
typedef LogSink = void Function(LogRecord record);

/// Centralized, dependency-free logger with environment thresholds and PII
/// redaction.
class AppLogger {
  AppLogger._();

  static final RegExp _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\b',
  );

  static final RegExp _bearerPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static final RegExp _secretFieldPattern = RegExp(
    r'''((?:password|passwd|pwd|secret|id_?token|access_?token|refresh_?token|api_?key|authorization|token)\s*[:=]\s*)(?:"[^"]*"|'[^']*'|[^\s,;}\]]+)''',
    caseSensitive: false,
  );

  static final RegExp _emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b',
  );

  static bool? _releaseModeOverride;
  static LogLevel? _minLevelOverride;
  static Set<LogCategory>? _enabledCategories;
  static LogSink _sink = _defaultSink;

  /// Whether logging currently behaves as a release build.
  static bool get isReleaseMode => _releaseModeOverride ?? kReleaseMode;

  /// Effective minimum severity required for a log record to be emitted.
  static LogLevel get minLevel =>
      _minLevelOverride ?? (isReleaseMode ? LogLevel.warning : LogLevel.debug);

  /// Optional category allowlist. When `null`, all categories are enabled.
  static Set<LogCategory>? get enabledCategories => _enabledCategories == null
      ? null
      : Set<LogCategory>.unmodifiable(_enabledCategories!);

  /// Updates logger configuration such as minimum severity, category filters,
  /// custom sink, or simulated release mode for testing.
  static void configure({
    bool? isReleaseMode,
    LogLevel? minLevel,
    Set<LogCategory>? enabledCategories,
    bool clearCategoryFilter = false,
    LogSink? sink,
  }) {
    if (isReleaseMode != null) {
      _releaseModeOverride = isReleaseMode;
    }
    if (minLevel != null) {
      _minLevelOverride = minLevel;
    }
    if (clearCategoryFilter) {
      _enabledCategories = null;
    } else if (enabledCategories != null) {
      _enabledCategories = Set<LogCategory>.from(enabledCategories);
    }
    if (sink != null) {
      _sink = sink;
    }
  }

  /// Restores default configuration (`kReleaseMode` threshold, all categories,
  /// and standard `dart:developer` sink).
  static void reset() {
    _releaseModeOverride = null;
    _minLevelOverride = null;
    _enabledCategories = null;
    _sink = _defaultSink;
  }

  /// Redacts emails, JWTs, bearer tokens, and common secret key-value pairs
  /// from [input].
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(_jwtPattern, '[REDACTED_JWT]')
        .replaceAll(_bearerPattern, 'Bearer [REDACTED_TOKEN]')
        .replaceAllMapped(
          _secretFieldPattern,
          (match) => '${match.group(1)}[REDACTED]',
        )
        .replaceAll(_emailPattern, '[REDACTED_EMAIL]');
  }

  /// Emits a [LogLevel.debug] record when allowed by current filters.
  static void debug(
    LogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.debug,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Emits a [LogLevel.info] record when allowed by current filters.
  static void info(
    LogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.info,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Emits a [LogLevel.warning] record when allowed by current filters.
  static void warning(
    LogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.warning,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Emits a [LogLevel.error] record when allowed by current filters.
  static void error(
    LogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.error,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a message at [level] for [category] if active filters allow it.
  static void log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.severity < minLevel.severity) return;
    final categories = _enabledCategories;
    if (categories != null && !categories.contains(category)) return;

    final sanitizedMessage = sanitize(message);
    final sanitizedError = error == null ? null : sanitize(error.toString());

    final record = LogRecord(
      level: level,
      category: category,
      message: sanitizedMessage,
      timestamp: DateTime.now(),
      error: sanitizedError,
      stackTrace: stackTrace,
    );

    _sink(record);
  }

  static void _defaultSink(LogRecord record) {
    developer.log(
      record.formattedMessage,
      time: record.timestamp,
      level: record.level.developerLevel,
      name: 'hrc.${record.category.tag}',
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
