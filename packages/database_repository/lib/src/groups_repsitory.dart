// // ignore_for_file: constant_identifier_names

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:database_repository/database_repository.dart';

// ///   Interface for Firebase and Horse and Rider's Companion
// class GroupsRespository {
//   ///Constant for Groups
//   static const String GROUPS = 'Groups';

//   final _groupDatabaseReference =
//       FirebaseFirestore.instance.collection(GROUPS).withConverter(
//             fromFirestore: Group.fromFirestore,
//             toFirestore: (Group group, options) => group.toFirestore(),
//           );

//   ///   create or update [group]
//   Future<void> createOrUpdateGroup({required Group group}) {
//     return _groupDatabaseReference.doc(group.id).set(group);
//   }

//   ///   Retrieves a List of Groups for a User
//   Stream<QuerySnapshot> getGroups({required String userEmail}) {
//     return _groupDatabaseReference
//         .where('partiesIds', arrayContains: userEmail)
//         .snapshots();
//   }

//   ///   Delete a group
//   void deleteGroup({required Group group}) {
//     _groupDatabaseReference.doc(group.id).delete();
//   }
// }
