import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Utilities/app_logger.dart';

void main() {
  late List<LogRecord> records;

  setUp(() {
    records = <LogRecord>[];
    AppLogger.reset();
    AppLogger.configure(isReleaseMode: false, sink: records.add);
  });

  tearDown(AppLogger.reset);

  group('AppLogger', () {
    test('formats level, category, message, and error consistently', () {
      final trace = StackTrace.current;

      AppLogger.info(
        LogCategory.auth,
        'Session initialized',
        error: StateError('stale cache'),
        stackTrace: trace,
      );

      expect(records, hasLength(1));
      final record = records.single;
      expect(record.level, LogLevel.info);
      expect(record.category, LogCategory.auth);
      expect(record.message, 'Session initialized');
      expect(record.stackTrace, trace);
      expect(
        record.formattedMessage,
        '[INFO][auth] Session initialized | error: Bad state: stale cache',
      );
    });

    test('emits debug through error in development mode by default', () {
      AppLogger.configure(isReleaseMode: false);

      AppLogger.debug(LogCategory.app, 'd');
      AppLogger.info(LogCategory.app, 'i');
      AppLogger.warning(LogCategory.app, 'w');
      AppLogger.error(LogCategory.app, 'e');

      expect(records.map((r) => r.level).toList(), [
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
    });

    test('suppresses debug and info in release mode by default', () {
      AppLogger.configure(isReleaseMode: true);

      AppLogger.debug(LogCategory.app, 'd');
      AppLogger.info(LogCategory.app, 'i');
      AppLogger.warning(LogCategory.app, 'w');
      AppLogger.error(LogCategory.app, 'e');

      expect(records.map((r) => r.level).toList(), [
        LogLevel.warning,
        LogLevel.error,
      ]);
    });

    test('honors explicit minLevel override', () {
      AppLogger.configure(isReleaseMode: false, minLevel: LogLevel.error);

      AppLogger.debug(LogCategory.profile, 'd');
      AppLogger.info(LogCategory.profile, 'i');
      AppLogger.warning(LogCategory.profile, 'w');
      AppLogger.error(LogCategory.profile, 'e');

      expect(records.map((r) => r.level).toList(), [LogLevel.error]);
    });

    test('filters by enabledCategories and supports clearing filter', () {
      AppLogger.configure(
        enabledCategories: {LogCategory.dictionary, LogCategory.skillTree},
      );

      AppLogger.info(LogCategory.auth, 'ignored');
      AppLogger.info(LogCategory.dictionary, 'kept-1');
      AppLogger.warning(LogCategory.profile, 'ignored-2');
      AppLogger.error(LogCategory.skillTree, 'kept-2');

      expect(records.map((r) => r.message).toList(), ['kept-1', 'kept-2']);

      AppLogger.configure(clearCategoryFilter: true);
      AppLogger.info(LogCategory.auth, 'restored');
      expect(records.last.message, 'restored');
    });

    test('redacts sensitive data in both message and error fields', () {
      const fakeJwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NSJ9.signatureValue123';
      AppLogger.warning(
        LogCategory.auth,
        'User jane.doe@example.com failed with Bearer secretToken_99 and '
        'jwt $fakeJwt',
        error: 'password="mySecret123", api_key=abc123xyz for bob@test.org',
      );

      expect(records, hasLength(1));
      final record = records.single;
      expect(record.message, isNot(contains('jane.doe@example.com')));
      expect(record.message, isNot(contains('secretToken_99')));
      expect(record.message, isNot(contains(fakeJwt)));
      expect(record.message, contains('[REDACTED_EMAIL]'));
      expect(record.message, contains('Bearer [REDACTED_TOKEN]'));
      expect(record.message, contains('[REDACTED_JWT]'));

      expect(record.error, isNotNull);
      expect(record.error, isNot(contains('mySecret123')));
      expect(record.error, isNot(contains('abc123xyz')));
      expect(record.error, isNot(contains('bob@test.org')));
      expect(record.error, contains('[REDACTED]'));
      expect(record.error, contains('[REDACTED_EMAIL]'));
    });

    test('reset restores defaults cleanly', () {
      AppLogger.configure(
        isReleaseMode: true,
        minLevel: LogLevel.error,
        enabledCategories: {LogCategory.ads},
      );

      AppLogger.reset();

      expect(AppLogger.enabledCategories, isNull);
      // After reset the default sink is installed and no custom list captures.
      AppLogger.info(LogCategory.app, 'post-reset');
      expect(records, isEmpty);
    });
  });
}
