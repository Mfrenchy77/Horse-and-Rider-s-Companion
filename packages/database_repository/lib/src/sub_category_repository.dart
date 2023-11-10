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
  Stream<DocumentSnapshot> getSubCategory({required SubCategory subCategory}) {
    return _subCategoryDatabaseReference.doc(subCategory.id).snapshots();
  }

  ///get all subCategory For Riders Skill Tree
  Stream<QuerySnapshot> getSubCategoriesForRiderSkillTree() {
    return _subCategoryDatabaseReference
        .where('rider', isEqualTo: true)
        .snapshots();
  }

  ///get all subCategory For Horses Skill Tree
  Stream<QuerySnapshot> getSubCategoriesForHorseSkillTree() {
    return _subCategoryDatabaseReference
        .where('rider', isEqualTo: false)
        .snapshots();
  }

  ///delete [subCategory]
  void deleteSubCategory({required SubCategory? subCategory}) {
    _subCategoryDatabaseReference.doc(subCategory?.id).delete();
  }
}
