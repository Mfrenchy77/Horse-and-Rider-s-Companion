// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/curriculum_skill_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_family_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_progress_v2_firestore_mapper.dart';
import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';
import 'package:database_repository/src/models/skill_level.dart';
import 'package:database_repository/src/models/skill_progress_v2.dart';

class _AtomicCurriculumSnapshot {
  const _AtomicCurriculumSnapshot({
    required this.revisionId,
    required this.families,
    required this.skills,
  });

  final String revisionId;
  final List<SkillFamily> families;
  final List<CurriculumSkill> skills;
}

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
///
/// Prefers the atomic versioned curriculum pointer at
/// `SkillTreeCurriculumPublic/active` →
/// `SkillTreeCurriculumRevisions/{activeRevisionId}/Chunks/*`, verifying full
/// chunk completeness before exposing data so readers never observe a
/// partially published revision. Falls back cleanly to `SkillFamilies` /
/// `SkillsV2` when no active pointer exists yet or if verification fails.
class FirestoreSkillTreeV2Store implements SkillTreeV2Store {
  FirestoreSkillTreeV2Store({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _publicCollection = 'SkillTreeCurriculumPublic';
  static const _publicActiveDocId = 'active';
  static const _revisionsCollection = 'SkillTreeCurriculumRevisions';
  static const _chunksSubcollection = 'Chunks';

  final FirebaseFirestore _firestore;
  _AtomicCurriculumSnapshot? _cachedSnapshot;
  Future<_AtomicCurriculumSnapshot?>? _inFlightSnapshot;

  /// Clears the in-memory atomic snapshot cache so subsequent reads re-check
  /// `SkillTreeCurriculumPublic/active`.
  void invalidateCache() {
    _cachedSnapshot = null;
    _inFlightSnapshot = null;
  }

  String _profileCollection(SkillSubject subject) =>
      subject == SkillSubject.rider ? 'Rider_Profile' : 'Horse_Profile';

  Future<_AtomicCurriculumSnapshot?> _loadAtomicSnapshot() {
    final existing = _inFlightSnapshot;
    if (existing != null) return existing;
    final future = _fetchAndVerifyAtomicSnapshot();
    _inFlightSnapshot = future;
    future.whenComplete(() {
      if (identical(_inFlightSnapshot, future)) {
        _inFlightSnapshot = null;
      }
    });
    return future;
  }

  Future<_AtomicCurriculumSnapshot?> _fetchAndVerifyAtomicSnapshot() async {
    try {
      final activeSnap = await _firestore
          .collection(_publicCollection)
          .doc(_publicActiveDocId)
          .get();
      final activeData = activeSnap.data();
      if (!activeSnap.exists || activeData == null) return null;

      final activeRevisionId = activeData['activeRevisionId'] as String? ?? '';
      final expectedChunkCount = (activeData['chunkCount'] as num?)?.toInt() ?? 0;
      final expectedFamilyCount =
          (activeData['familyCount'] as num?)?.toInt() ?? 0;
      final expectedSkillCount =
          (activeData['skillCount'] as num?)?.toInt() ?? 0;
      if (activeRevisionId.isEmpty || expectedChunkCount <= 0) return null;

      final cached = _cachedSnapshot;
      if (cached != null && cached.revisionId == activeRevisionId) {
        return cached;
      }

      final chunksSnap = await _firestore
          .collection(_revisionsCollection)
          .doc(activeRevisionId)
          .collection(_chunksSubcollection)
          .orderBy('index')
          .get();

      if (chunksSnap.docs.length != expectedChunkCount) {
        return null;
      }

      final buffer = StringBuffer();
      for (var i = 0; i < expectedChunkCount; i++) {
        final data = chunksSnap.docs[i].data();
        final index = (data['index'] as num?)?.toInt();
        final payload = data['payload'] as String?;
        if (index != i || payload == null || payload.isEmpty) {
          return null;
        }
        buffer.write(payload);
      }

      final decoded = jsonDecode(buffer.toString());
      if (decoded is! Map<String, dynamic>) return null;

      final rawFamilies = decoded['families'];
      final rawSkills = decoded['skills'];
      if (rawFamilies is! List || rawSkills is! List) return null;

      final families = rawFamilies
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SkillFamily.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final allSkills = rawSkills
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => CurriculumSkill.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (expectedFamilyCount > 0 && families.length != expectedFamilyCount) {
        return null;
      }
      if (expectedSkillCount > 0 && allSkills.length != expectedSkillCount) {
        return null;
      }

      final visibleSkills = allSkills
          .where(
            (s) =>
                s.status == CurriculumSkillStatus.active ||
                s.status == CurriculumSkillStatus.retired,
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final snapshot = _AtomicCurriculumSnapshot(
        revisionId: activeRevisionId,
        families: List<SkillFamily>.unmodifiable(families),
        skills: List<CurriculumSkill>.unmodifiable(visibleSkills),
      );
      _cachedSnapshot = snapshot;
      return snapshot;
    } catch (_) {
      // Never return a partially loaded snapshot; let caller fall back cleanly.
      return null;
    }
  }

  @override
  Future<List<SkillFamily>> fetchFamilies() async {
    final atomic = await _loadAtomicSnapshot();
    if (atomic != null && atomic.families.isNotEmpty) {
      return List<SkillFamily>.from(atomic.families);
    }
    final snap = await _firestore.collection('SkillFamilies').get();
    final list = snap.docs
        .map((d) => SkillFamilyFirestoreMapper.fromFirestore(d, null))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() async {
    final atomic = await _loadAtomicSnapshot();
    if (atomic != null && atomic.skills.isNotEmpty) {
      return List<CurriculumSkill>.from(atomic.skills);
    }
    final snap = await _firestore
        .collection('SkillsV2')
        .where('status', whereIn: ['active', 'retired'])
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
