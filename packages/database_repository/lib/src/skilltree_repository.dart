// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// Repository for Accessing Elements of the SkillTree
class SkillTreeRepository {
// /* ****
//                   ****   Categories   ****

// **** */
//   /// Constant Reference for Categories in the database
//   static const String CATEGORIES = 'Categories';

//   final _categoryDatabaseReference = FirebaseFirestore.instance
//       .collection(CATEGORIES)
//       .withConverter<Catagorry>(
//         fromFirestore: Catagorry.fromFirestore,
//         toFirestore: (Catagorry catagorry, options) => catagorry.toFirestore(),
//       );

//   ///create or upadate [catagory]
//   Future<void> createOrEditCategory({required Catagorry catagory}) {
//     return _categoryDatabaseReference.doc(catagory.id).set(catagory);
//   }

//   /// get a single [categorry]
//   Stream<DocumentSnapshot> getCategory({required Catagorry categorry}) {
//     return _categoryDatabaseReference.doc(categorry.id).snapshots();
//   }

//   ///get all category For Riders Skill Tree
//   Stream<QuerySnapshot> getCatagoriesForRiderSkillTree() {
//     return _categoryDatabaseReference
//         .where('rider', isEqualTo: true)
//         .snapshots();
//   }

//   ///get all category For Horses Skill Tree
//   Stream<QuerySnapshot> getCatagoriesForHorseSkillTree() {
//     return _categoryDatabaseReference
//         .where('rider', isEqualTo: false)
//         .snapshots();
//   }

//   ///delete Category at [catagorry]
//   void deleteCategory({required Catagorry? catagorry}) {
//     _categoryDatabaseReference.doc(catagorry?.id).delete();
//   }

// /* ****
//                   ****   SubCategor   ****

// **** */

//   ///Constant for Accessing the SubCategories on the Skill Tree
//   static const String SUB_CATEGORIES = 'SubCategories';

//   final _subCategoryDatabaseReference = FirebaseFirestore.instance
//       .collection(SUB_CATEGORIES)
//       .withConverter<SubCategory>(
//         fromFirestore: SubCategory.fromFirestore,
//         toFirestore: (SubCategory subCategory, options) =>
//             subCategory.toFirestore(),
//       );

//   ///create or upadate [subCategory]
//   Future<void> createOrEditSubCategory({required SubCategory subCategory}) {
//     return _subCategoryDatabaseReference.doc(subCategory.id).set(subCategory);
//   }

//   /// get a single [subCategory]
//   Stream<DocumentSnapshot> getSubCategory({required SubCategory subCategory}) {
//     return _subCategoryDatabaseReference.doc(subCategory.id).snapshots();
//   }

//   ///get all subCategory For Riders Skill Tree
//   Stream<QuerySnapshot> getSubCategoriesForRiderSkillTree() {
//     return _subCategoryDatabaseReference
//         .where('rider', isEqualTo: true)
//         .snapshots();
//   }

//   ///get all subCategory For Horses Skill Tree
//   Stream<QuerySnapshot> getSubCategoriesForHorseSkillTree() {
//     return _subCategoryDatabaseReference
//         .where('rider', isEqualTo: false)
//         .snapshots();
//   }

//   ///delete [subCategory]
//   void deleteSubCategory({required SubCategory? subCategory}) {
//     _subCategoryDatabaseReference.doc(subCategory?.id).delete();
//   }

/* ****
                  ****   TrainingPaths   ****

**** */

  /// Constant for Accessing the Training Paths in the Database
  static const String TRAINING_PATHS = 'TrainingPaths';

  final _trainingPathDatabaseReference = FirebaseFirestore.instance
      .collection(TRAINING_PATHS)
      .withConverter<TrainingPath>(
        fromFirestore: TrainingPath.fromFirestore,
        toFirestore: (TrainingPath trainingPath, options) =>
            trainingPath.toFirestore(),
      );

  /// Create or update a TrainingPath
  Future<void> createOrEditTrainingPath({required TrainingPath trainingPath}) {
    return _trainingPathDatabaseReference
        .doc(trainingPath.id)
        .set(trainingPath);
  }

  /// Retrieve a TrainingPath by its ID
  Stream<DocumentSnapshot> getTrainingPathById({required String id}) {
    return _trainingPathDatabaseReference.doc(id).snapshots();
  }

  /// Retrieve all TrainingPaths
  Stream<QuerySnapshot> getAllTrainingPaths() {
    return _trainingPathDatabaseReference.snapshots();
  }

  /// Delete a TrainingPath
  void deleteTrainingPath({required TrainingPath? trainingPath}) {
    _trainingPathDatabaseReference.doc(trainingPath?.id).delete();
  }

/* ****
                  ****   Skills   ****

**** */
  /// Constant for Accessing the Skills on the Skill Tree
  static const String SKILLS = 'Skills';

  final _skillDatabaseReference =
      FirebaseFirestore.instance.collection(SKILLS).withConverter<Skill>(
            fromFirestore: Skill.fromFirestore,
            toFirestore: (Skill skill, options) => skill.toFirestore(),
          );

  /// create or update [skill]
  Future<void> createOrEditSkill({required Skill skill}) {
    return _skillDatabaseReference.doc(skill.id).set(skill);
  }

  /// Retreive Skill from Category [id]
  Stream<QuerySnapshot> getSkillsFromCategory({required String id}) {
    return _skillDatabaseReference
        .where('categoryId', isEqualTo: id)
        .snapshots();
  }

  /// Retreive all Skills
  Stream<QuerySnapshot> getSkills() {
    return _skillDatabaseReference.snapshots();
  }

  ///  Retreives all Skills for Rider SKill Tree
  Stream<QuerySnapshot> getSkillsForRiderSkillTree() {
    return _skillDatabaseReference.where('rider', isEqualTo: true).snapshots();
  }

  ///  Retreives all Skills for Horse SKill Tree
  Stream<QuerySnapshot> getSkillsForHorseSkillTree() {
    return _skillDatabaseReference.where('rider', isEqualTo: false).snapshots();
  }

  /// delete Skill
  void deleteSkill({required Skill? skill}) {
    _skillDatabaseReference.doc(skill?.id).delete();
  }

// /* ****
//                   ****   Levels   ****

// **** */

//   ///constant to reuse
//   static const String LEVELS = 'Levels';

//   final _levelsDatabaseReference =
//       FirebaseFirestore.instance.collection(LEVELS).withConverter<Level>(
//             fromFirestore: Level.fromFirestore,
//             toFirestore: (Level level, options) => level.toFirestore(),
//           );

//   ///   Create or update [level]
//   Future<void> createOrEditLevel({required Level level}) {
//     return _levelsDatabaseReference.doc(level.id).set(level);
//   }

//   ///   Retrieve a single Level
//   Stream<DocumentSnapshot> getLevel({required String id}) {
//     return _levelsDatabaseReference.doc(id).snapshots();
//   }

//   ///   Retrieve all Levels
//   Stream<QuerySnapshot> getLevelsForRiderSkillTree() {
//     return _levelsDatabaseReference.where('rider', isEqualTo: true).snapshots();
//   }

//   ///   Retrieve all Levels
//   Stream<QuerySnapshot> getLevelsForHorseSkillTree() {
//     return _levelsDatabaseReference
//         .where('rider', isEqualTo: false)
//         .snapshots();
//   }

//   /// Delete a Level
//   void deleteLevel({required Level? level}) {
//     _levelsDatabaseReference.doc(level?.id).delete();
//   }
}
