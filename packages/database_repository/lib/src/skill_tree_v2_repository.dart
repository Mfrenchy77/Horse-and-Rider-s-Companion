// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/curriculum_skill_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_family_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_progress_v2_firestore_mapper.dart';
import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';
import 'package:database_repository/src/models/skill_level.dart';
import 'package:database_repository/src/models/skill_progress_v2.dart';

/// Backend-agnostic store contract for Skill Tree 2.0 data.
abstract class SkillTreeV2Store {
  Future<List<SkillFamily>> fetchFamilies();

  Future<List<CurriculumSkill>> fetchSkills();

  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  });

  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  });

  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  });

  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  });
}

/// Firestore implementation of [SkillTreeV2Store].
class FirestoreSkillTreeV2Store implements SkillTreeV2Store {
  FirestoreSkillTreeV2Store({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _profileCollection(SkillSubject subject) =>
      subject == SkillSubject.rider ? 'Rider_Profile' : 'Horse_Profile';

  @override
  Future<List<SkillFamily>> fetchFamilies() async {
    final snap = await _firestore.collection('SkillFamilies').get();
    final list = snap.docs
        .map((d) => SkillFamilyFirestoreMapper.fromFirestore(d, null))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() async {
    final snap = await _firestore
        .collection('SkillsV2')
        .where('status', isEqualTo: 'active')
        .get();
    final list = snap.docs
        .map((d) => CurriculumSkillFirestoreMapper.fromFirestore(d, null))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    final snap = await _firestore
        .collection(_profileCollection(subject))
        .doc(profileDocId)
        .collection('SkillProgress')
        .get();
    return {
      for (final doc in snap.docs)
        doc.id: SkillProgressV2FirestoreMapper.progressFromFirestore(doc, null),
    };
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    final snap = await _firestore
        .collection(_profileCollection(subject))
        .doc(profileDocId)
        .collection('SkillVerifications')
        .get();
    return {
      for (final doc in snap.docs)
        doc.id: SkillProgressV2FirestoreMapper.verificationFromFirestore(
          doc,
          null,
        ),
    };
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    final snap = await _firestore
        .collection(_profileCollection(subject))
        .doc(profileDocId)
        .collection('SkillVerificationEvents')
        .get();
    final events = snap.docs
        .map((d) => SkillProgressV2FirestoreMapper.eventFromFirestore(d, null))
        .toList()
      ..sort(
        (a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)),
      );
    return events;
  }

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) async {
    final ref = _firestore
        .collection(_profileCollection(subject))
        .doc(profileDocId)
        .collection('SkillProgress')
        .doc(skillId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists && snap.data() != null
          ? SkillProgressV2FirestoreMapper.progressFromMap(
              snap.data()!,
              docId: snap.id,
            )
          : SkillProgressRecord(
              skillId: skillId,
              subject: subject,
              levels: const {},
            );

      final updatedLevels = Map<DifficultyState, LevelProgress>.from(
        current.levels,
      );
      if (state == null || state == LevelState.NO_PROGRESS) {
        updatedLevels.remove(level);
      } else {
        updatedLevels[level] = LevelProgress(
          state: state == LevelState.VERIFIED ? LevelState.PROFICIENT : state,
          updatedAt: DateTime.now().toUtc(),
          updatedByUid: actorUid,
          updatedByName: actorName,
        );
      }

      if (updatedLevels.isEmpty) {
        if (snap.exists) tx.delete(ref);
        return;
      }

      final next = SkillProgressRecord(
        skillId: skillId,
        subject: subject,
        levels: updatedLevels,
        updatedAt: DateTime.now().toUtc(),
      );
      tx.set(ref, SkillProgressV2FirestoreMapper.progressToFirestore(next));
    });
  }
}

/// In-memory / local-fixture implementation of [SkillTreeV2Store] for previewing
/// Skill Tree 2.0 without production `SkillsV2` documents, and for tests.
class InMemorySkillTreeV2Store implements SkillTreeV2Store {
  InMemorySkillTreeV2Store({
    List<SkillFamily> families = const [],
    List<CurriculumSkill> skills = const [],
    Map<String, Map<String, SkillProgressRecord>>? initialProgress,
    Map<String, Map<String, SkillVerificationRecord>>? initialVerifications,
    Map<String, List<VerificationEvent>>? initialEvents,
  })  : _families = List<SkillFamily>.from(families),
        _skills = List<CurriculumSkill>.from(skills),
        _progress = initialProgress ?? {},
        _verifications = initialVerifications ?? {},
        _events = initialEvents ?? {};

  final List<SkillFamily> _families;
  final List<CurriculumSkill> _skills;
  final Map<String, Map<String, SkillProgressRecord>> _progress;
  final Map<String, Map<String, SkillVerificationRecord>> _verifications;
  final Map<String, List<VerificationEvent>> _events;

  String _key(SkillSubject subject, String profileDocId) =>
      '${subject.name}:$profileDocId';

  @override
  Future<List<SkillFamily>> fetchFamilies() async =>
      List<SkillFamily>.from(_families);

  @override
  Future<List<CurriculumSkill>> fetchSkills() async =>
      List<CurriculumSkill>.from(_skills);

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    return Map<String, SkillProgressRecord>.from(
      _progress[_key(subject, profileDocId)] ?? const {},
    );
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    return Map<String, SkillVerificationRecord>.from(
      _verifications[_key(subject, profileDocId)] ?? const {},
    );
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    return List<VerificationEvent>.from(
      _events[_key(subject, profileDocId)] ?? const [],
    );
  }

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) async {
    final k = _key(subject, profileDocId);
    final bySkill = _progress.putIfAbsent(k, () => {});
    final existing = bySkill[skillId];
    final nextLevels = Map<DifficultyState, LevelProgress>.from(
      existing?.levels ?? const {},
    );

    if (state == null || state == LevelState.NO_PROGRESS) {
      nextLevels.remove(level);
    } else {
      nextLevels[level] = LevelProgress(
        state: state == LevelState.VERIFIED ? LevelState.PROFICIENT : state,
        updatedAt: DateTime.now().toUtc(),
        updatedByUid: actorUid,
        updatedByName: actorName,
      );
    }

    if (nextLevels.isEmpty) {
      bySkill.remove(skillId);
    } else {
      bySkill[skillId] = SkillProgressRecord(
        skillId: skillId,
        subject: subject,
        levels: nextLevels,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  /// Helper for local preview & tests to simulate backend verification/revocation.
  void applyVerificationLocally({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required String skillName,
    required DifficultyState level,
    required bool verified,
    required String coachUid,
    required String coachName,
    String? reason,
  }) {
    final k = _key(subject, profileDocId);
    final bySkill = _verifications.putIfAbsent(k, () => {});
    final existing = bySkill[skillId];
    final nextLevels = Map<DifficultyState, LevelVerification>.from(
      existing?.levels ?? const {},
    );
    final prev = nextLevels[level];
    final now = DateTime.now().toUtc();

    if (verified) {
      nextLevels[level] = LevelVerification(
        verifiedByName: coachName,
        verifiedAt: now,
      );
    } else {
      nextLevels.remove(level);
    }
    bySkill[skillId] = SkillVerificationRecord(
      skillId: skillId,
      levels: nextLevels,
      updatedAt: now,
    );

    final events = _events.putIfAbsent(k, () => []);
    events.insert(
      0,
      VerificationEvent(
        id: 'local-evt-${events.length + 1}',
        type: verified
            ? VerificationEventType.verified
            : VerificationEventType.revoked,
        skillId: skillId,
        skillName: skillName,
        level: level,
        actorUid: coachUid,
        actorName: coachName,
        connectionId: 'local-preview',
        previousVerifiedByUid: prev?.verifiedByUid,
        previousVerifiedAt: prev?.verifiedAt,
        reason: reason,
        at: now,
      ),
    );
  }
}

/// Repository facade for Skill Tree 2.0.
class SkillTreeV2Repository {
  SkillTreeV2Repository({required this.store});

  final SkillTreeV2Store store;

  Future<List<SkillFamily>> fetchFamilies() => store.fetchFamilies();

  Future<List<CurriculumSkill>> fetchSkills() => store.fetchSkills();

  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) =>
      store.fetchProgress(subject: subject, profileDocId: profileDocId);

  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) =>
      store.fetchVerifications(subject: subject, profileDocId: profileDocId);

  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) =>
      store.fetchVerificationEvents(
        subject: subject,
        profileDocId: profileDocId,
      );

  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) =>
      store.setLevelProgress(
        subject: subject,
        profileDocId: profileDocId,
        skillId: skillId,
        level: level,
        state: state,
        actorUid: actorUid,
        actorName: actorName,
      );
}
