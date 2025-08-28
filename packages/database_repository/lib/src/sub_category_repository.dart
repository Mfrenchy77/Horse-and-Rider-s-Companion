import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// SubCategoryRepository
class SubCategoryRepository {
  
  ///Constant for SubCategoryRepository
  // ignore: constant_identifier_names
  static const String SUB_CATEGORIES = 'SubCategories';

  final _subCategoryDatabaseReference = FirebaseFirestore.instance
      .collection(SUB_CATEGORIES)
      .withConverter<SubCategory>(
        fromFirestore: SubCategory.fromFirestore,
        toFirestore: (SubCategory subCategory, options) =>
            subCategory.toFirestore(),
      );

  ///create or upadate [subCategory]
  Future<void> createOrEditSubCategory({required SubCategory subCategory}) {
    return _subCategoryDatabaseReference.doc(subCategory.id).set(subCategory);
  }

  /// get a single [subCategory]
  Stream<SubCategory?> getSubCategory({required SubCategory subCategory}) {
    return _subCategoryDatabaseReference
        .doc(subCategory.id)
        .snapshots()
        .map((snap) => snap.data());
  }

  ///get all subCategory For Riders Skill Tree
  Stream<List<SubCategory>> getSubCategoriesForRiderSkillTree() {
    return _subCategoryDatabaseReference
        .where('rider', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///get all subCategory For Horses Skill Tree
  Stream<List<SubCategory>> getSubCategoriesForHorseSkillTree() {
    return _subCategoryDatabaseReference
        .where('rider', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///delete [subCategory]
  void deleteSubCategory({required SubCategory? subCategory}) {
    _subCategoryDatabaseReference.doc(subCategory?.id).delete();
  }
}
