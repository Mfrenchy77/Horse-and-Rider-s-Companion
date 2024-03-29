// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/catagorry.dart';

///   Crud Iterface for Firebase and Category gives the
///   option to specify wether the databse id for Rider
///   or horse
class CatagorryRepository {
  static const String CATEGORIES = 'Categories';

  final _categoryDatabaseReference = FirebaseFirestore.instance
      .collection(CATEGORIES)
      .withConverter<Catagorry>(
        fromFirestore: Catagorry.fromFirestore,
        toFirestore: (Catagorry catagorry, options) => catagorry.toFirestore(),
      );

  ///create or upadate [catagory]
  Future<void> createOrEditCategory({required Catagorry catagory}) {
    return _categoryDatabaseReference.doc(catagory.id).set(catagory);
  }

  /// get a single [categorry]
  Stream<DocumentSnapshot> getCategory({required Catagorry categorry}) {
    return _categoryDatabaseReference.doc(categorry.id).snapshots();
  }

  ///get all category For Riders Skill Tree
  Stream<QuerySnapshot> getCatagoriesForRiderSkillTree() {
    return _categoryDatabaseReference
        .where('rider', isEqualTo: true)
        .snapshots();
  }

  ///get all category For Horses Skill Tree
  Stream<QuerySnapshot> getCatagoriesForHorseSkillTree() {
    return _categoryDatabaseReference
        .where('rider', isEqualTo: false)
        .snapshots();
  }

  ///delete Category at [catagorry]
  void deleteCategory({required Catagorry? catagorry}) {
    _categoryDatabaseReference.doc(catagorry?.id).delete();
  }
}
