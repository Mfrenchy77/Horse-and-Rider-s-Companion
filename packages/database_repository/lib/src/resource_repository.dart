// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

///  Crud interface for Firebase and Resources
class ResourcesRepository {
  static const String RESOURCES = 'Resources';

  final _resourceDatabaseReference =
      FirebaseFirestore.instance.collection(RESOURCES).withConverter(
            fromFirestore: Resource.fromFirestore,
            toFirestore: (Resource resource, options) => resource.toFirestore(),
          );

  ///create or update [resource]
  Future<void> createOrUpdateResource({required Resource resource}) {
    return _resourceDatabaseReference.doc(resource.id).set(resource);
  }

///   Update Resources Rating
  Future<void> editResourceRating({
    required Resource resource,
    required BaseListItem userWhoRated,
  }) {
    return _resourceDatabaseReference
        .doc(resource.id)
        .collection('usersWhoRated')
        .withConverter(
          fromFirestore: BaseListItem.fromFirestore,
          toFirestore: (BaseListItem baseListItem, options) =>
              baseListItem.toFirestore(),
        )
        .doc(userWhoRated.id)
        .set(userWhoRated);
  }

  ///get resources
  Stream<QuerySnapshot> getResources() {
    return _resourceDatabaseReference.snapshots();
  }

  /// delete [resource]
  void deleteResource({required Resource resource}) {
    _resourceDatabaseReference.doc(resource.id).delete();
  }
}
