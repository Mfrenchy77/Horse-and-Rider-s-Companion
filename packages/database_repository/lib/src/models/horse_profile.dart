import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/skill_level.dart';

///Model of a Horse Profile
class HorseProfile {
  /// Creates a new instance of [HorseProfile]
  HorseProfile({
    this.notes,
    this.color,
    this.breed,
    this.gender,
    this.picUrl,
    this.height,
    this.zipCode,
    this.nickname,
    this.cityName,
    this.stateIso,
    this.stateName,
    this.countryIso,
    this.lastEditBy,
    this.countryName,
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

  /// the horse's id
  final String id;

  /// the horse's name
  final String name;

  /// the horse's breed
  String? breed = '';

  /// the horse's color
  String? color = '';

  /// the horse's gender
  String? gender = '';

  /// the horse's height
  String? height = '';

  /// the horse's profile picture url
  String? picUrl = '';

  /// the horse's location zip code
  String? zipCode = '';

  /// the horse's location city name
  String? cityName = '';

  /// the horse's location state iso
  String? stateIso = '';

  /// the horse's location state name
  String? locationName;

  /// the horse's current owner id
  String currentOwnerId;

  /// the horse's date of birth
  DateTime? dateOfBirth;

  /// the horse's nickname
  String? nickname = '';

  /// the horse's purchase price
  int? purchasePrice = 0;

  /// the horse's location state name
  String? stateName = '';

  /// the last date the profile was edited
  DateTime? lastEditDate;

  /// the horse's location country iso
  String? countryIso = '';

  /// the last user to edit the profile
  String? lastEditBy = '';

  /// the horse's location country name
  String? countryName = '';

  /// the horse's date of purchase
  DateTime? dateOfPurchase;

  /// the horse's current owner name
  String? currentOwnerName;

  /// the horse's skill levels
  List<BaseListItem>? notes = [];

  /// List of skill levels the horse has
  List<SkillLevel>? skillLevels = [];

  /// List of instructors the horse has
  List<BaseListItem>? instructors = [];

  ///Converts a [DocumentSnapshot] to a [HorseProfile]
  // ignore: sort_constructors_first
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
      zipCode: data['zipCode'] as String?,
      cityName: data['cityName'] as String?,
      nickname: data['nickname'] as String?,
      stateIso: data['stateIso'] as String?,
      stateName: data['stateName'] as String?,
      countryIso: data['countryIso'] as String?,
      lastEditBy: data['lastEditBy'] as String?,
      countryName: data['countryName'] as String?,
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

  ///Converts a [HorseProfile] to a [Map<String, dynamic>]
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
      if (zipCode != null) 'zipCode': zipCode,
      if (nickname != null) 'nickname': nickname,
      if (cityName != null) 'cityName': cityName,
      if (stateIso != null) 'stateIso': stateIso,
      if (stateName != null) 'stateName': stateName,
      if (countryIso != null) 'countryIso': countryIso,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (countryName != null) 'countryName': countryName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (locationName != null) 'locationName': locationName,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (dateOfPurchase != null) 'dateOfPurchase': dateOfPurchase,
      if (currentOwnerName != null) 'currentOwnerName': currentOwnerName,
      if (notes != null)
        'notes': List<dynamic>.from(notes!.map((e) => e.toJson())),
      if (instructors != null)
        'instructors': List<dynamic>.from(instructors!.map((e) => e.toJson())),
      if (skillLevels != null)
        'skillLevels': skillLevels?.map((e) => e.toFirestore()).toList(),
    };
  }

  ///Creates a copy of the [HorseProfile] with the specified fields replaced
  HorseProfile copyWith({
    String? id,
    String? name,
    String? breed,
    String? color,
    String? gender,
    String? height,
    String? picUrl,
    String? cityName,
    String? zipCode,
    String? stateIso,
    String? nickname,
    String? stateName,
    int? purchasePrice,
    String? lastEditBy,
    String? countryIso,
    String? countryName,
    String? locationName,
    DateTime? dateOfBirth,
    DateTime? lastEditDate,
    String? currentOwnerId,
    DateTime? dateOfPurchase,
    String? currentOwnerName,
    List<BaseListItem>? notes,
    List<SkillLevel>? skillLevels,
    List<BaseListItem>? instructors,
  }) {
    return HorseProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      picUrl: picUrl ?? this.picUrl,
      zipCode: zipCode ?? this.zipCode,
      cityName: cityName ?? this.cityName,
      nickname: nickname ?? this.nickname,
      stateIso: stateIso ?? this.stateIso,
      stateName: stateName ?? this.stateName,
      countryIso: countryIso ?? this.countryIso,
      lastEditBy: lastEditBy ?? this.lastEditBy,
      countryName: countryName ?? this.countryName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      skillLevels: skillLevels ?? this.skillLevels,
      instructors: instructors ?? this.instructors,
      lastEditDate: lastEditDate ?? this.lastEditDate,
      locationName: locationName ?? this.locationName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentOwnerId: currentOwnerId ?? this.currentOwnerId,
      dateOfPurchase: dateOfPurchase ?? this.dateOfPurchase,
      currentOwnerName: currentOwnerName ?? this.currentOwnerName,
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

List<BaseListItem> _baseListItem(List<dynamic>? itemMap) {
  final baseListItem = <BaseListItem>[];

  if (itemMap != null) {
    for (final note in itemMap) {
      baseListItem.add(BaseListItem.fromJson(note as Map<String, dynamic>));
    }
  }
  return baseListItem;
}
