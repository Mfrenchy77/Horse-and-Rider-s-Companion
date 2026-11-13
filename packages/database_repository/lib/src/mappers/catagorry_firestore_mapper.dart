import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/catagorry.dart';

/// Firestore persistence mapper for [Catagorry].
class CatagorryFirestoreMapper {
  const CatagorryFirestoreMapper._();

  /// Converts a Firestore [DocumentSnapshot] into a [Catagorry].
  static Catagorry fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    final rawDate = data['lastEditDate'];
    final DateTime lastEditDate;
    if (rawDate is Timestamp) {
      lastEditDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      lastEditDate = rawDate;
    } else if (rawDate is String) {
      lastEditDate = DateTime.parse(rawDate);
    } else if (rawDate is int) {
      lastEditDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      throw ArgumentError('Expected Timestamp or DateTime, got $rawDate');
    }

    return Catagorry.fromMap({
      ...data,
      'id': (data['id'] as String?) ?? snapshot.id,
      'lastEditDate': lastEditDate,
    });
  }

  /// Converts a [Catagorry] into a Firestore-compatible document map.
  static Map<String, Object?> toFirestore(
    Catagorry catagorry, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      'id': catagorry.id,
      'name': catagorry.name,
      'rider': catagorry.rider,
      'position': catagorry.position,
      'lastEditBy': catagorry.lastEditBy,
      'description': catagorry.description,
      'lastEditDate': catagorry.lastEditDate,
    };
  }
}
