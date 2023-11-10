// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/skill_level.dart';

///Model of a Horse Profile
class HorseProfile {
  HorseProfile({
    this.notes,
    this.color,
    this.breed,
    this.gender,
    this.picUrl,
    this.height,
    this.nickname,
    this.location,
    this.lastEditBy,
    this.dateOfBirth,
    this.skillLevels,
    required this.id,
    this.instructors,
    this.locationName,
    this.lastEditDate,
    this.purchasePrice,
    required this.name,
    this.dateOfPurchase,
    this.currentOwnerId = '',
    this.currentOwnerName = '',
  });

  final String id;
  final String name;
  String? breed = '';
  String? color = '';
  GeoPoint? location;
  String? gender = '';
  String? height = '';
  String? picUrl = '';
  String? locationName;
  DateTime? dateOfBirth;
  String? nickname = '';
  int? purchasePrice = 0;
  DateTime? lastEditDate;
  String? lastEditBy = '';
  DateTime? dateOfPurchase;
  String currentOwnerId;
  String? currentOwnerName;
  List<BaseListItem>? notes = [];
  List<SkillLevel>? skillLevels = [];
  List<BaseListItem>? instructors = [];

  factory HorseProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return HorseProfile(
      id: data!['id'] as String,
      name: data['name'] as String,
      breed: data['breed'] as String?,
      color: data['color'] as String?,
      picUrl: data['picUrl'] as String?,
      gender: data['gender'] as String?,
      height: data['height'] as String?,
      nickname: data['nickname'] as String?,
      location: data['location'] as GeoPoint?,
      lastEditBy: data['lastEditBy'] as String?,
      purchasePrice: data['purchasePrice'] as int?,
      locationName: data['locationName'] as String?,
      currentOwnerId: data['currentOwnerId'] as String,
      currentOwnerName: data['currentOwnerName'] as String,
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      dateOfPurchase: (data['dateOfPurchase'] as Timestamp).toDate(),
      skillLevels: data['skillLevels'] == null
          ? null
          : _convertSkillLevel(data['skillLevels'] as List),
      notes:
          data['notes'] == null ? null : _baseListItem(data['notes'] as List),
      instructors: data['instructors'] == null
          ? null
          : _baseListItem(data['instructors'] as List),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'name': name,
      'currentOwnerId': currentOwnerId,
      if (color != null) 'color': color,
      if (breed != null) 'breed': breed,
      if (picUrl != null) 'picUrl': picUrl,
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (nickname != null) 'nickname': nickname,
      if (location != null) 'location': location,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (locationName != null) 'locationName': locationName,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      if (currentOwnerName != null) 'currentOwnerName': currentOwnerName,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (dateOfPurchase != null) 'dateOfPurchase': dateOfPurchase,
      if (notes != null)
        'notes': List<dynamic>.from(notes!.map((e) => e.toJson())),
      if (instructors != null)
        'instructors': List<dynamic>.from(instructors!.map((e) => e.toJson())),
      if (skillLevels != null)
        'skillLevels': skillLevels?.map((e) => e.toFirestore()).toList(),
    };
  }
}

List<SkillLevel> _convertSkillLevel(List<dynamic>? skillLevelMap) {
  final skillLevels = <SkillLevel>[];

  if (skillLevelMap != null) {
    for (final skillLevel in skillLevelMap) {
      skillLevels.add(SkillLevel.fromJson(skillLevel as Map<String, dynamic>));
    }
  }
  return skillLevels;
}

List<BaseListItem> _baseListItem(List<dynamic>? itemMap) {
  final baseListItem = <BaseListItem>[];

  if (itemMap != null) {
    for (final note in itemMap) {
      baseListItem.add(BaseListItem.fromJson(note as Map<String, dynamic>));
    }
  }
  return baseListItem;
}
