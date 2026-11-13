import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/base_list_item.dart';

/// Firestore persistence mapper for [BaseListItem].
class BaseListItemFirestoreMapper {
  const BaseListItemFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a
  /// [BaseListItem].
  static BaseListItem fromMap(Map<String, dynamic> data) {
    final rawDate = data['date'];
    final DateTime? date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      date = null;
    }

    return BaseListItem.fromMap({
      ...data,
      'date': date,
    });
  }

  /// Converts a Firestore [DocumentSnapshot] into a [BaseListItem].
  static BaseListItem fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!);
  }

  /// Converts a [BaseListItem] into a Firestore-compatible document map.
  static Map<String, dynamic> toFirestore(
    BaseListItem item, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      if (item.id != null) 'id': item.id,
      if (item.riderLog != null) 'riderLog': item.riderLog!.toMap(),
      if (item.name != null) 'name': item.name,
      if (item.date != null) 'date': item.date,
      if (item.depth != null) 'depth': item.depth,
      if (item.extra != null) 'extra': item.extra,
      if (item.message != null) 'message': item.message,
      if (item.parentId != null) 'parentId': item.parentId,
      if (item.imageUrl != null) 'imageUrl': item.imageUrl,
      if (item.isSelected != null) 'isSelected': item.isSelected,
      if (item.isCollapsed != null) 'isCollapsed': item.isCollapsed,
    };
  }
}
