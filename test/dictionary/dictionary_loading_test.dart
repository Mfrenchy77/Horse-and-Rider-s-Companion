import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

// Firestore seals its references; these doubles only stub SDK calls in tests.
// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Document extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'undeployed Dictionary rules deny the manifest but guests get the bundle',
    () async {
      final db = _Firestore();
      final collection = _Collection();
      final manifest = _Document();
      when(() => db.collection('DictionaryPublic')).thenReturn(collection);
      when(() => collection.doc('catalogue')).thenReturn(manifest);
      when(
        () => manifest.get(const GetOptions(source: Source.server)),
      ).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );

      when(
        () => manifest.get(const GetOptions(source: Source.cache)),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      final entries = await DictionaryRepository(firestore: db).load();
      expect(entries, hasLength(28));
      expect(
        entries.every((entry) => entry.bundled && entry.published),
        isTrue,
      );
      expect(DictionaryRepository.resolve(entries, 'lope')?.id, 'canter');
      expect(DictionaryRepository.resolve(entries, 'jog')?.id, 'trot');
      expect(
        DictionaryRepository.resolve(entries, 'green broke')?.id,
        'green-broke',
      );
      verifyNever(() => db.collection('DictionaryEntries'));
    },
  );

  test(
    'a genuine connection error is not treated as an uninitialized glossary',
    () async {
      final db = _Firestore();
      final collection = _Collection();
      final manifest = _Document();
      when(() => db.collection('DictionaryPublic')).thenReturn(collection);
      when(() => collection.doc('catalogue')).thenReturn(manifest);
      final offline = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Offline',
      );
      when(
        () => manifest.get(const GetOptions(source: Source.server)),
      ).thenThrow(offline);
      await expectLater(
        DictionaryRepository(firestore: db).load(),
        throwsA(same(offline)),
      );
    },
  );

  test(
    'an existing but uninitialized manifest still uses published starters',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('DictionaryPublic').doc('catalogue').set({
        'initialized': false,
      });
      await db.collection('DictionaryEntries').doc('private').set({
        'status': 'draft',
        'definition': 'Private unfinished definition.',
      });
      final entries = await DictionaryRepository(firestore: db).load();
      expect(entries, hasLength(28));
      expect(
        entries.every((entry) => entry.bundled && entry.published),
        isTrue,
      );
    },
  );

  test(
    'a known publication does not revert to starters on later denial',
    () async {
      final db = _Firestore();
      final collection = _Collection();
      final manifest = _Document();
      final cachedDb = FakeFirebaseFirestore();
      final cachedRef = cachedDb
          .collection('DictionaryPublic')
          .doc('catalogue');
      await cachedRef.set({'initialized': true});
      final cached = await cachedRef.get();
      final denied = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      when(() => db.collection('DictionaryPublic')).thenReturn(collection);
      when(() => collection.doc('catalogue')).thenReturn(manifest);
      when(
        () => manifest.get(const GetOptions(source: Source.server)),
      ).thenThrow(denied);
      when(
        () => manifest.get(const GetOptions(source: Source.cache)),
      ).thenAnswer((_) async => cached);
      await expectLater(
        DictionaryRepository(firestore: db).load(),
        throwsA(same(denied)),
      );
    },
  );

  test(
    'published-query denial propagates after initialization is confirmed',
    () async {
      final db = _Firestore();
      final publicCollection = _Collection();
      final entriesCollection = _Collection();
      final manifest = _Document();
      final realDb = FakeFirebaseFirestore();
      final realManifest = realDb
          .collection('DictionaryPublic')
          .doc('catalogue');
      await realManifest.set({'initialized': true});
      final snapshot = await realManifest.get();
      when(
        () => db.collection('DictionaryPublic'),
      ).thenReturn(publicCollection);
      when(() => publicCollection.doc('catalogue')).thenReturn(manifest);
      when(
        () => manifest.get(const GetOptions(source: Source.server)),
      ).thenAnswer((_) async => snapshot);
      when(
        () => db.collection('DictionaryEntries'),
      ).thenReturn(entriesCollection);
      final denied = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      when(
        () => entriesCollection.where('status', isEqualTo: 'published'),
      ).thenThrow(denied);
      await expectLater(
        DictionaryRepository(firestore: db).load(),
        throwsA(same(denied)),
      );
    },
  );
}
