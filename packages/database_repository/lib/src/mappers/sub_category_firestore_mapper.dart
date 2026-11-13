import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/sub_category.dart';

/// Firestore persistence mapper for [SubCategory].
class SubCategoryFirestoreMapper {
  const SubCategoryFirestoreMapper._();

  /// Converts a Firestore [DocumentSnapshot] into a [SubCategory].
  static SubCategory fromFirestore(
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

    return SubCategory.fromMap({
      ...data,
      'id': (data['id'] as String?) ?? snapshot.id,
      'lastEditDate': lastEditDate,
    });
  }

  /// Converts a [SubCategory] into a Firestore-compatible document map.
  static Map<String, Object?> toFirestore(
    SubCategory subCategory, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      'id': subCategory.id,
      'name': subCategory.name,
      'skills': subCategory.skills,
      'rider': subCategory.isRider,
      'position': subCategory.position,
      'parentId': subCategory.parentId,
      'lastEditBy': subCategory.lastEditBy,
      'description': subCategory.description,
      'lastEditDate': subCategory.lastEditDate,
    };
  }
}
