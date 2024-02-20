import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/skill_level.dart';

///Model for a Rider's Profile
class RiderProfile {
  /// Creates a new instance of [RiderProfile]
  RiderProfile({
    this.bio,
    this.picUrl,
    this.homeUrl,
    this.zipCode,
    this.lastEditBy,
    this.subscribed,
    this.cityName,
    this.stateIso,
    this.stateName,
    this.countryIso,
    this.countryName,
    required this.id,
    this.locationName,
    this.lastEditDate,
    required this.name,
    required this.email,
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

  /// whether the user is an editor
  bool? editor;

  /// the rider's bio
  String? bio;

  /// the rider's name
  String name;

  /// the rider's zip code
  String? zipCode;

  /// whether the user is a trainer
  bool? isTrainer;

  /// the rider's website link
  String? homeUrl;

  /// the rider's id
  final String id;

  /// the last user to edit the profile
  String? lastEditBy;

  /// the rider's profile picture url
  String? picUrl = '';

  /// the rider's email, this as the id
  final String email;

  /// the rider's location name
  String? locationName;

  /// the rider's city name
  String? cityName = '';

  /// the rider's state iso
  String? stateIso = '';

  /// the rider's state name
  String? stateName = '';

  /// the rider's country iso
  String? countryIso = '';

  /// the rider's country name
  String? countryName = '';

  /// the last date the profile was edited
  DateTime? lastEditDate;

  /// List of notes made on the rider's profile
  List<BaseListItem>? notes;

  /// whether the user is subscribed
  bool? subscribed = false;

  /// List of messages sent to the rider
  List<String>? messagesList;

  /// the date the user subscribed
  DateTime? subscriptionDate;

  /// List of students the rider has
  List<BaseListItem>? students;

  /// the date the user's subscription ends
  DateTime? subscriptionEndDate;

  /// List of skill levels the rider has
  List<SkillLevel>? skillLevels;

  /// List of instructors the rider has
  List<BaseListItem>? instructors;

  /// List of horses the rider owns
  List<BaseListItem>? ownedHorses;

  /// List of resources the rider has saved
  List<String>? savedResourcesList;

  /// List of student horses the rider has
  List<BaseListItem>? studentHorses;

  /// List of profiles the rider has saved
  List<BaseListItem>? savedProfilesList;

  /// Creates a new instance of [RiderProfile] from a [DocumentSnapshot]
  // ignore: sort_constructors_first
  factory RiderProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return RiderProfile(
      id: data!['id'] as String,
      bio: data['bio'] as String?,
      name: data['name'] as String,
      email: data['email'] as String,
      editor: data['editor'] as bool?,
      picUrl: data['picUrl'] as String?,
      zipCode: data['zipCode'] as String?,
      homeUrl: data['homeUrl'] as String?,
      cityName: data['cityName'] as String?,
      stateIso: data['stateIso'] as String?,
      isTrainer: data['isTrainer'] as bool?,
      subscribed: data['subscribed'] as bool?,
      stateName: data['stateName'] as String?,
      countryIso: data['countryIso'] as String?,
      lastEditBy: data['lastEditBy'] as String?,
      countryName: data['countryName'] as String?,
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

  /// Converts the [RiderProfile] to a [Map]
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      if (bio != null) 'bio': bio,
      'email': email.toLowerCase(),
      if (editor != null) 'editor': editor,
      if (picUrl != null) 'picUrl': picUrl,
      if (zipCode != null) 'zipCode': zipCode,
      if (cityName != null) 'cityName': cityName,
      if (stateIso != null) 'stateIso': stateIso,
      if (stateName != null) 'stateName': stateName,
      if (isTrainer != null) 'isTrainer': isTrainer,
      if (countryIso != null) 'countryIso': countryIso,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (subscribed != null) 'subscribed': subscribed,
      if (countryName != null) 'countryName': countryName,
      if (locationName != null) 'locationName': locationName,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      if (messagesList != null) 'messagesList': messagesList,
      if (homeUrl != null) 'homeUrl': homeUrl?.toLowerCase(),
      if (subscriptionDate != null) 'subscriptionDate': subscriptionDate,
      if (savedResourcesList != null) 'savedResourcesList': savedResourcesList,
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

  /// Returns a copy of the [RiderProfile] with the specified fields updated
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
    String? cityName,
    String? stateIso,
    String? stateName,
    String? countryIso,
    String? lastEditBy,
    String? countryName,
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
      cityName: cityName ?? this.cityName,
      stateIso: stateIso ?? this.stateIso,
      stateName: stateName ?? this.stateName,
      isTrainer: isTrainer ?? this.isTrainer,
      countryIso: countryIso ?? this.countryIso,
      lastEditBy: lastEditBy ?? this.lastEditBy,
      subscribed: subscribed ?? this.subscribed,
      countryName: countryName ?? this.countryName,
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
