// ignore_for_file: sort_constructors_first, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';

///  Model of category
class Catagorry {
  Catagorry({
    required this.id,
    required this.name,
    required this.rider,
    required this.position,
    required this.lastEditBy,
    required this.description,
    required this.lastEditDate,
  });

  final String id;
  final String name;
  final bool rider;
  final int position;
  final String lastEditBy;
  final String description;
  final DateTime lastEditDate;

  factory Catagorry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Catagorry(
      id: data!['id'] as String,
      name: data['name'] as String,
      rider: data['rider'] as bool,
      position: data['position'] as int,
      lastEditBy: data['lastEditBy'] as String,
      description: data['description'] as String,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'name': name,
      'rider': rider,
      'position': position,
      'lastEditBy': lastEditBy,
      'description': description,
      'lastEditDate': lastEditDate,
    };
  }
}
