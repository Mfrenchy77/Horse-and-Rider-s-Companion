import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/base_list_item_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_level_firestore_mapper.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/horse_profile.dart';
import 'package:database_repository/src/models/skill_level.dart';

/// Firestore persistence mapper for [HorseProfile].
class HorseProfileFirestoreMapper {
  const HorseProfileFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a
  /// [HorseProfile].
  static HorseProfile fromMap(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    for (final key in const ['dateOfBirth', 'lastEditDate', 'dateOfPurchase']) {
      final raw = normalized[key];
      if (raw is Timestamp) {
        normalized[key] = raw.toDate();
      }
    }

    final rawSkillLevels = normalized.remove('skillLevels');
    final rawNotes = normalized.remove('notes');
    final rawInstructors = normalized.remove('instructors');

    final base = HorseProfile.fromMap(normalized);

    List<SkillLevel>? skillLevels;
    if (rawSkillLevels is List) {
      skillLevels = rawSkillLevels
          .map(
            (item) => SkillLevelFirestoreMapper.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    List<BaseListItem>? notes;
    if (rawNotes is List) {
      notes = rawNotes
          .map(
            (item) => BaseListItemFirestoreMapper.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    List<BaseListItem>? instructors;
    if (rawInstructors is List) {
      instructors = rawInstructors
          .map(
            (item) => BaseListItemFirestoreMapper.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    return base.copyWith(
      skillLevels: skillLevels,
      notes: notes,
      instructors: instructors,
    );
  }

  /// Converts a Firestore [DocumentSnapshot] into a [HorseProfile].
  static HorseProfile fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!);
  }

  /// Serializes editable fields of [horseProfile] for Firestore persistence.
  ///
  /// Server-managed fields (`archiveStatus`, `saleListing`,
  /// `transferRequestId`, `ownershipVersion`) are intentionally omitted to
  /// preserve legacy `HorseProfile.toFirestore` behavior.
  static Map<String, Object?> toFirestore(
    HorseProfile horseProfile, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      'id': horseProfile.id,
      'name': horseProfile.name,
      'currentOwnerId': horseProfile.currentOwnerId,
      if (horseProfile.color != null) 'color': horseProfile.color,
      if (horseProfile.breed != null) 'breed': horseProfile.breed,
      if (horseProfile.picUrl != null) 'picUrl': horseProfile.picUrl,
      if (horseProfile.gender != null) 'gender': horseProfile.gender,
      if (horseProfile.height != null) 'height': horseProfile.height,
      if (horseProfile.zipCode != null) 'zipCode': horseProfile.zipCode,
      if (horseProfile.nickname != null) 'nickname': horseProfile.nickname,
      if (horseProfile.cityName != null) 'cityName': horseProfile.cityName,
      if (horseProfile.stateIso != null) 'stateIso': horseProfile.stateIso,
      if (horseProfile.stateName != null) 'stateName': horseProfile.stateName,
      if (horseProfile.countryIso != null)
        'countryIso': horseProfile.countryIso,
      if (horseProfile.lastEditBy != null)
        'lastEditBy': horseProfile.lastEditBy,
      if (horseProfile.countryName != null)
        'countryName': horseProfile.countryName,
      if (horseProfile.dateOfBirth != null)
        'dateOfBirth': horseProfile.dateOfBirth,
      if (horseProfile.locationName != null)
        'locationName': horseProfile.locationName,
      if (horseProfile.lastEditDate != null)
        'lastEditDate': horseProfile.lastEditDate,
      if (horseProfile.purchasePrice != null)
        'purchasePrice': horseProfile.purchasePrice,
      if (horseProfile.dateOfPurchase != null)
        'dateOfPurchase': horseProfile.dateOfPurchase,
      if (horseProfile.currentOwnerName != null)
        'currentOwnerName': horseProfile.currentOwnerName,
      if (horseProfile.notes != null)
        'notes': List<dynamic>.from(
          horseProfile.notes!.map(BaseListItemFirestoreMapper.toFirestore),
        ),
      if (horseProfile.instructors != null)
        'instructors': List<dynamic>.from(
          horseProfile.instructors!.map(
            BaseListItemFirestoreMapper.toFirestore,
          ),
        ),
      if (horseProfile.skillLevels != null)
        'skillLevels': horseProfile.skillLevels!
            .map(SkillLevelFirestoreMapper.toFirestore)
            .toList(),
    };
  }
}
