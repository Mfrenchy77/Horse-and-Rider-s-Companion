import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/base_list_item_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_level_firestore_mapper.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/rider_profile.dart';

/// Firestore persistence mapper for [RiderProfile].
class RiderProfileFirestoreMapper {
  const RiderProfileFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a
  /// [RiderProfile].
  static RiderProfile fromMap(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    for (final key in const [
      'subscriptionDate',
      'lastEditDate',
      'subscriptionEndDate',
    ]) {
      final raw = normalized[key];
      if (raw is Timestamp) {
        normalized[key] = raw.toDate();
      }
    }

    List<BaseListItem>? parseItems(String key) {
      final raw = normalized.remove(key);
      if (raw is! List) return null;
      return raw
          .map(
            (item) => BaseListItemFirestoreMapper.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    final rawSkillLevels = normalized.remove('skillLevels');
    final skillLevels = rawSkillLevels is List
        ? rawSkillLevels
            .map(
              (item) => SkillLevelFirestoreMapper.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList()
        : null;

    final notes = parseItems('notes');
    final students = parseItems('students');
    final ownedHorses = parseItems('ownedHorses');
    final archivedHorses = parseItems('archivedHorses');
    final instructors = parseItems('instructors');
    final studentHorses = parseItems('studentHorses');
    final savedProfilesList = parseItems('savedProfilesList');

    final base = RiderProfile.fromMap(normalized);

    return RiderProfile(
      id: base.id,
      bio: base.bio,
      name: base.name,
      email: base.email,
      editor: base.editor,
      picUrl: base.picUrl,
      zipCode: base.zipCode,
      homeUrl: base.homeUrl,
      cityName: base.cityName,
      stateIso: base.stateIso,
      isTrainer: base.isTrainer,
      subscribed: base.subscribed,
      stateName: base.stateName,
      countryIso: base.countryIso,
      lastEditBy: base.lastEditBy,
      countryName: base.countryName,
      locationName: base.locationName,
      subscriptionDate: base.subscriptionDate,
      lastEditDate: base.lastEditDate,
      subscriptionEndDate: base.subscriptionEndDate,
      notes: notes,
      students: students,
      skillLevels: skillLevels,
      ownedHorses: ownedHorses,
      archivedHorses: archivedHorses,
      ownershipRosterVersion: base.ownershipRosterVersion,
      instructors: instructors,
      messagesList: base.messagesList,
      studentHorses: studentHorses,
      savedProfilesList: savedProfilesList,
      savedResourcesList: base.savedResourcesList,
    );
  }

  /// Converts a Firestore [DocumentSnapshot] into a [RiderProfile].
  static RiderProfile fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!);
  }

  /// Converts a [RiderProfile] into a Firestore-compatible document map,
  /// preserving legacy field names, omitted nulls, and nested serialization.
  static Map<String, dynamic> toFirestore(
    RiderProfile riderProfile, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      'id': riderProfile.id,
      'name': riderProfile.name,
      if (riderProfile.bio != null) 'bio': riderProfile.bio,
      'email': riderProfile.email.toLowerCase(),
      if (riderProfile.editor != null) 'editor': riderProfile.editor,
      if (riderProfile.picUrl != null) 'picUrl': riderProfile.picUrl,
      if (riderProfile.zipCode != null) 'zipCode': riderProfile.zipCode,
      if (riderProfile.cityName != null) 'cityName': riderProfile.cityName,
      if (riderProfile.stateIso != null) 'stateIso': riderProfile.stateIso,
      if (riderProfile.stateName != null) 'stateName': riderProfile.stateName,
      if (riderProfile.isTrainer != null) 'isTrainer': riderProfile.isTrainer,
      if (riderProfile.countryIso != null)
        'countryIso': riderProfile.countryIso,
      if (riderProfile.lastEditBy != null)
        'lastEditBy': riderProfile.lastEditBy,
      if (riderProfile.subscribed != null)
        'subscribed': riderProfile.subscribed,
      if (riderProfile.countryName != null)
        'countryName': riderProfile.countryName,
      if (riderProfile.locationName != null)
        'locationName': riderProfile.locationName,
      if (riderProfile.lastEditDate != null)
        'lastEditDate': riderProfile.lastEditDate,
      if (riderProfile.messagesList != null)
        'messagesList': riderProfile.messagesList,
      if (riderProfile.homeUrl != null)
        'homeUrl': riderProfile.homeUrl?.toLowerCase(),
      if (riderProfile.subscriptionDate != null)
        'subscriptionDate': riderProfile.subscriptionDate,
      if (riderProfile.savedResourcesList != null)
        'savedResourcesList': riderProfile.savedResourcesList,
      if (riderProfile.notes != null)
        'notes': List<dynamic>.from(
          riderProfile.notes!.map(BaseListItemFirestoreMapper.toFirestore),
        ),
      if (riderProfile.subscriptionEndDate != null)
        'subscriptionEndDate': riderProfile.subscriptionEndDate,
      if (riderProfile.studentHorses != null)
        'studentHorses': List<dynamic>.from(
          riderProfile.studentHorses!.map(
            BaseListItemFirestoreMapper.toFirestore,
          ),
        ),
      if (riderProfile.students != null)
        'students': List<dynamic>.from(
          riderProfile.students!.map(BaseListItemFirestoreMapper.toFirestore),
        ),
      if (riderProfile.savedProfilesList != null)
        'savedProfilesList': List<dynamic>.from(
          riderProfile.savedProfilesList!.map(
            BaseListItemFirestoreMapper.toFirestore,
          ),
        ),
      if (riderProfile.skillLevels != null)
        'skillLevels': List<dynamic>.from(
          riderProfile.skillLevels!.map(SkillLevelFirestoreMapper.toJson),
        ),
      if (riderProfile.ownedHorses != null)
        'ownedHorses': List<dynamic>.from(
          riderProfile.ownedHorses!.map(
            BaseListItemFirestoreMapper.toFirestore,
          ),
        ),
      if (riderProfile.ownershipRosterVersion != null)
        'ownershipRosterVersion': riderProfile.ownershipRosterVersion,
      if (riderProfile.archivedHorses != null)
        'archivedHorses': riderProfile.archivedHorses!
            .map(BaseListItemFirestoreMapper.toFirestore)
            .toList(),
      if (riderProfile.instructors != null)
        'instructors': List<dynamic>.from(
          riderProfile.instructors!.map(
            BaseListItemFirestoreMapper.toFirestore,
          ),
        ),
    };
  }
}
