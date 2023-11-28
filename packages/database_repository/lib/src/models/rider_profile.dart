// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/skill_level.dart';

///Model for a Rider's Profile
class RiderProfile {
  RiderProfile({
    this.id,
    this.bio,
    this.email,
    this.picUrl,
    this.homeUrl,
    this.zipCode,
    this.lastEditBy,
    this.subscribed,
    this.locationName,
    this.lastEditDate,
    required this.name,
    this.editor = false,
    this.notes = const [],
    this.subscriptionDate,
    this.isTrainer = false,
    this.students = const [],
    this.subscriptionEndDate,
    this.skillLevels = const [],
    this.ownedHorses = const [],
    this.instructors = const [],
    this.messagesList = const [],
    this.studentHorses = const [],
    this.savedProfilesList = const [],
    this.savedResourcesList = const [],
  });

  bool? editor;
  String? bio;
  String? name;
  String? zipCode;
  bool? isTrainer;
  String? homeUrl;
  final String? id;
  String? lastEditBy;
  String? picUrl = '';
  final String? email;
  String? locationName;
  DateTime? lastEditDate;
  List<BaseListItem>? notes;
  bool? subscribed = false;
  List<String>? messagesList;
  DateTime? subscriptionDate;
  List<BaseListItem>? students;
  DateTime? subscriptionEndDate;
  List<SkillLevel>? skillLevels;
  List<BaseListItem>? instructors;
  List<BaseListItem>? ownedHorses;
  List<String>? savedResourcesList;
  List<BaseListItem>? studentHorses;
  List<BaseListItem>? savedProfilesList;

  factory RiderProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return RiderProfile(
      id: data!['id'] as String?,
      bio: data['bio'] as String?,
      name: data['name'] as String?,
      editor: data['editor'] as bool?,
      email: data['email'] as String?,
      picUrl: data['picUrl'] as String?,
      zipCode: data['zipCode'] as String?,
      homeUrl: data['homeUrl'] as String?,
      isTrainer: data['isTrainer'] as bool?,
      subscribed: data['subscribed'] as bool?,
      lastEditBy: data['lastEditBy'] as String?,
      locationName: data['locationName'] as String?,
      subscriptionDate: data['subscriptionDate'] as DateTime?,
      lastEditDate: (data['lastEditDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: data['subscriptionEndDate'] as DateTime?,
      notes: data['notes'] == null
          ? null
          : _convertBaseListItem(
              data['notes'] as List,
            ),
      students: data['students'] == null
          ? null
          : _convertBaseListItem(
              data['students'] as List,
            ),
      skillLevels: data['skillLevels'] == null
          ? null
          : _convertSkillLevel(
              data['skillLevels'] as List,
            ),
      ownedHorses: data['ownedHorses'] == null
          ? null
          : _convertBaseListItem(
              data['ownedHorses'] as List,
            ),
      instructors: data['instructors'] == null
          ? null
          : _convertBaseListItem(
              data['instructors'] as List,
            ),
      studentHorses: data['studentHorses'] == null
          ? null
          : _convertBaseListItem(
              data['studentHorses'] as List,
            ),
      savedProfilesList: data['savedProfilesList'] == null
          ? null
          : _convertBaseListItem(
              data['savedProfilesList'] as List,
            ),
      savedResourcesList: (data['savedResourcesList'] as List?)
          ?.map((e) => e as String)
          .toList(),
      messagesList:
          (data['messagesList'] as List?)?.map((e) => e as String).toList(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      if (bio != null) 'bio': bio,
      if (name != null) 'name': name,
      if (editor != null) 'editor': editor,
      if (picUrl != null) 'picUrl': picUrl,
      if (zipCode != null) 'zipCode': zipCode,
      if (isTrainer != null) 'isTrainer': isTrainer,
      if (email != null) 'email': email?.toLowerCase(),
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (subscribed != null) 'subscribed': subscribed,
      if (locationName != null) 'locationName': locationName,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      if (messagesList != null) 'messagesList': messagesList,
      if (homeUrl != null) 'homeUrl': homeUrl?.toLowerCase(),
      if (savedResourcesList != null) 'savedResourcesList': savedResourcesList,
      if (subscriptionDate != null) 'subscriptionDate': subscriptionDate,
      if (notes != null)
        'notes': List<dynamic>.from(notes!.map((e) => e.toJson())),
      if (subscriptionEndDate != null)
        'subscriptionEndDate': subscriptionEndDate,
      if (studentHorses != null)
        'studentHorses':
            List<dynamic>.from(studentHorses!.map((e) => e.toJson())),
      if (students != null)
        'students': List<dynamic>.from(students!.map((e) => e.toJson())),
      if (savedProfilesList != null)
        'savedProfilesList':
            List<dynamic>.from(savedProfilesList!.map((e) => e.toJson())),
      if (skillLevels != null)
        'skillLevels': List<dynamic>.from(skillLevels!.map((e) => e.toJson())),
      if (ownedHorses != null)
        'ownedHorses': List<dynamic>.from(ownedHorses!.map((e) => e.toJson())),
      if (instructors != null)
        'instructors': List<dynamic>.from(instructors!.map((e) => e.toJson())),
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

List<BaseListItem> _convertBaseListItem(List<dynamic>? itemMap) {
  final baseListItem = <BaseListItem>[];
  if (itemMap != null) {
    for (final item in itemMap) {
      baseListItem.add(BaseListItem.fromJson(item as Map<String, dynamic>));
    }
  }

  return baseListItem;
}

//copyWith method for RiderProfile
extension RiderProfileCopyWith on RiderProfile {
  RiderProfile copyWith({
    String? id,
    String? bio,
    String? name,
    String? email,
    String? picUrl,
    bool? isTrainer,
    String? homeUrl,
    String? zipCode,
    bool? subscribed,
    String? lastEditBy,
    String? locationName,
    DateTime? lastEditDate,
    List<BaseListItem>? notes,
    List<String>? messagesList,
    DateTime? subscriptionDate,
    List<BaseListItem>? students,
    DateTime? subscriptionEndDate,
    List<SkillLevel>? skillLevels,
    List<BaseListItem>? instructors,
    List<BaseListItem>? ownedHorses,
    List<BaseListItem>? studentHorses,
    List<BaseListItem>? savedProfilesList,
    List<String>? savedResourcesList,
  }) {
    return RiderProfile(
      id: id ?? this.id,
      bio: bio ?? this.bio,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      email: email ?? this.email,
      picUrl: picUrl ?? this.picUrl,
      homeUrl: homeUrl ?? this.homeUrl,
      zipCode: zipCode ?? this.zipCode,
      students: students ?? this.students,
      isTrainer: isTrainer ?? this.isTrainer,
      lastEditBy: lastEditBy ?? this.lastEditBy,
      subscribed: subscribed ?? this.subscribed,
      skillLevels: skillLevels ?? this.skillLevels,
      ownedHorses: ownedHorses ?? this.ownedHorses,
      instructors: instructors ?? this.instructors,
      locationName: locationName ?? this.locationName,
      lastEditDate: lastEditDate ?? this.lastEditDate,
      messagesList: messagesList ?? this.messagesList,
      studentHorses: studentHorses ?? this.studentHorses,
      subscriptionDate: subscriptionDate ?? this.subscriptionDate,
      savedProfilesList: savedProfilesList ?? this.savedProfilesList,
      savedResourcesList: savedResourcesList ?? this.savedResourcesList,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }
}
