import 'package:cache/cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CacheClient cache;
  setUp(() => cache = CacheClient());

  test('missing keys return null', () {
    expect(cache.read<String>(key: 'missing'), isNull);
    expect(cache.remove<String>(key: 'missing'), isNull);
  });
  test('writes and overwrites values', () {
    cache.write(key: 'key', value: 'first');
    expect(cache.read<String>(key: 'key'), 'first');
    cache.write(key: 'key', value: 42);
    expect(cache.read<int>(key: 'key'), 42);
    expect(cache.read<String>(key: 'key'), isNull);
  });
  test('removal returns the value and removes only that key', () {
    cache
      ..write(key: 'a', value: 'A')
      ..write(key: 'b', value: 'B');
    expect(cache.remove<String>(key: 'a'), 'A');
    expect(cache.read<String>(key: 'a'), isNull);
    expect(cache.read<String>(key: 'b'), 'B');
  });
  test('instances do not share data', () {
    cache.write(key: 'key', value: 'private');
    expect(CacheClient().read<String>(key: 'key'), isNull);
  });
}
