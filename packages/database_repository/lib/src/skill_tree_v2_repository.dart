// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/logging/app_logger.dart';
import 'package:database_repository/src/mappers/curriculum_skill_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_family_firestore_mapper.dart';
import 'package:database_repository/src/mappers/skill_progress_v2_firestore_mapper.dart';
import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';
import 'package:database_repository/src/models/skill_level.dart';
import 'package:database_repository/src/models/skill_progress_v2.dart';
import 'package:database_repository/src/repository_exception.dart';
import 'package:database_repository/src/rider_profile_repository.dart';

/// Thrown when an active versioned curriculum snapshot is incomplete or
/// corrupt and cannot be safely served.
class CurriculumLoadException implements Exception {
  CurriculumLoadException(this.message, {this.revisionId});

  final String message;
  final String? revisionId;

  @override
  String toString() => message;
}

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
  FirestoreSkillTreeV2Store({
    FirebaseFirestore? firestore,
    this.verificationEventLimit = 20,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _publicCollection = 'SkillTreeCurriculumPublic';
  static const _publicActiveDocId = 'active';
  static const _revisionsCollection = 'SkillTreeCurriculumRevisions';
  static const _chunksSubcollection = 'Chunks';

  final FirebaseFirestore _firestore;
  final int verificationEventLimit;
  final Duration cacheTtl;
  _AtomicCurriculumSnapshot? _cachedSnapshot;
  _AtomicCurriculumSnapshot? _lastVerifiedSnapshot;
  DateTime? _cachedAt;
  Future<_AtomicCurriculumSnapshot?>? _inFlightSnapshot;

  /// Clears the active in-memory snapshot cache so subsequent reads re-check
  /// `SkillTreeCurriculumPublic/active` while keeping `_lastVerifiedSnapshot`
  /// as a safe fallback if a newly activated revision is temporarily corrupt.
  void invalidateCache() {
    _cachedSnapshot = null;
    _cachedAt = null;
    _inFlightSnapshot = null;
  }

  String _profileCollection(SkillSubject subject) =>
      subject == SkillSubject.rider ? 'Rider_Profile' : 'Horse_Profile';

  /// Resolves the canonical Firestore profile document ID.
  ///
  /// `Rider_Profile` documents are keyed by [RiderProfileRepository.profileDocIdForEmail],
  /// while callers may pass the rider's raw email or an already-encoded doc ID.
  static String resolveProfileDocId(SkillSubject subject, String profileDocId) {
    final trimmed = profileDocId.trim();
    if (subject == SkillSubject.rider && trimmed.contains('@')) {
      return RiderProfileRepository.profileDocIdForEmail(trimmed);
    }
    return trimmed;
  }

  Future<_AtomicCurriculumSnapshot?> _loadAtomicSnapshot() {
    final cached = _cachedSnapshot;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheTtl) {
      return Future.value(cached);
    }
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
    for (var attempt = 0; attempt < 2; attempt++) {
      final DocumentSnapshot<Map<String, dynamic>> activeSnap;
      try {
        activeSnap = await _firestore
            .collection(_publicCollection)
            .doc(_publicActiveDocId)
            .get();
      } catch (_) {
        if (_lastVerifiedSnapshot != null) return _lastVerifiedSnapshot;
        rethrow;
      }

      // Pre-versioned environment: active pointer does not exist yet.
      if (!activeSnap.exists) return null;

      final activeData = activeSnap.data();
      final activeRevisionId = activeData?['activeRevisionId'] as String? ?? '';
      final expectedChunkCount =
          (activeData?['chunkCount'] as num?)?.toInt() ?? 0;
      final expectedFamilyCount =
          (activeData?['familyCount'] as num?)?.toInt() ?? 0;
      final expectedSkillCount =
          (activeData?['skillCount'] as num?)?.toInt() ?? 0;

      if (activeRevisionId.isEmpty || expectedChunkCount <= 0) {
        if (_lastVerifiedSnapshot != null) return _lastVerifiedSnapshot;
        throw CurriculumLoadException(
          'Active curriculum pointer is invalid or incomplete.',
          revisionId: activeRevisionId,
        );
      }

        final cached = _cachedSnapshot;
        if (cached != null && cached.revisionId == activeRevisionId) {
          _cachedAt = DateTime.now();
          return cached;
        }

      try {
        final chunksSnap = await _firestore
            .collection(_revisionsCollection)
            .doc(activeRevisionId)
            .collection(_chunksSubcollection)
            .orderBy('index')
            .get();

        // Detect revision switching mid-read: re-check active pointer.
        final recheckSnap = await _firestore
            .collection(_publicCollection)
            .doc(_publicActiveDocId)
            .get();
        final recheckId =
            recheckSnap.data()?['activeRevisionId'] as String? ?? '';
        if (recheckId.isNotEmpty && recheckId != activeRevisionId) {
          if (attempt == 0) continue;
          if (_lastVerifiedSnapshot != null) return _lastVerifiedSnapshot;
          throw CurriculumLoadException(
            'Active curriculum revision changed while loading.',
            revisionId: recheckId,
          );
        }

        if (chunksSnap.docs.length != expectedChunkCount) {
          throw CurriculumLoadException(
            'Active curriculum revision "$activeRevisionId" is missing chunks.',
            revisionId: activeRevisionId,
          );
        }

        final buffer = StringBuffer();
        for (var i = 0; i < expectedChunkCount; i++) {
          final data = chunksSnap.docs[i].data();
          final index = (data['index'] as num?)?.toInt();
          final payload = data['payload'] as String?;
          if (index != i || payload == null || payload.isEmpty) {
            throw CurriculumLoadException(
              'Active curriculum revision "$activeRevisionId" has corrupt chunk '
              'data.',
              revisionId: activeRevisionId,
            );
          }
          buffer.write(payload);
        }

        final decoded = jsonDecode(buffer.toString());
        if (decoded is! Map<String, dynamic>) {
          throw CurriculumLoadException(
            'Active curriculum revision "$activeRevisionId" could not be decoded.',
            revisionId: activeRevisionId,
          );
        }

        final rawFamilies = decoded['families'];
        final rawSkills = decoded['skills'];
        if (rawFamilies is! List || rawSkills is! List) {
          throw CurriculumLoadException(
            'Active curriculum revision "$activeRevisionId" is malformed.',
            revisionId: activeRevisionId,
          );
        }

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
          throw CurriculumLoadException(
            'Active curriculum revision "$activeRevisionId" family count '
            'mismatch.',
            revisionId: activeRevisionId,
          );
        }
        if (expectedSkillCount > 0 && allSkills.length != expectedSkillCount) {
          throw CurriculumLoadException(
            'Active curriculum revision "$activeRevisionId" skill count mismatch.',
            revisionId: activeRevisionId,
          );
        }

        final visibleSkills = allSkills
            .where(
              (s) =>
                  s.status == CurriculumSkillStatus.active ||
                  s.status == CurriculumSkillStatus.retired,
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (families.isEmpty || visibleSkills.isEmpty) {
          throw CurriculumLoadException(
            'Active curriculum revision "$activeRevisionId" contains no visible '
            'curriculum entries.',
            revisionId: activeRevisionId,
          );
        }

        final snapshot = _AtomicCurriculumSnapshot(
          revisionId: activeRevisionId,
          families: List<SkillFamily>.unmodifiable(families),
          skills: List<CurriculumSkill>.unmodifiable(visibleSkills),
        );
        _cachedSnapshot = snapshot;
        _cachedAt = DateTime.now();
        _lastVerifiedSnapshot = snapshot;
        return snapshot;
      } catch (err) {
        if (attempt == 0 && err is! CurriculumLoadException) {
          // Transient permission/network hiccup during revision flip: retry once.
          continue;
        }
        if (_lastVerifiedSnapshot != null) return _lastVerifiedSnapshot;
        if (err is CurriculumLoadException) rethrow;
        throw CurriculumLoadException(
          'Failed to load active curriculum revision "$activeRevisionId": $err',
          revisionId: activeRevisionId,
        );
      }
    }
    if (_lastVerifiedSnapshot != null) return _lastVerifiedSnapshot;
    throw CurriculumLoadException('Unable to load verified curriculum revision.');
  }

  @override
  Future<List<SkillFamily>> fetchFamilies() async {
    final atomic = await _loadAtomicSnapshot();
    if (atomic != null) {
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
    if (atomic != null) {
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
    final resolvedDocId = resolveProfileDocId(subject, profileDocId);
    try {
      final snap = await _firestore
          .collection(_profileCollection(subject))
          .doc(resolvedDocId)
          .collection('SkillProgress')
          .get();
      return {
        for (final doc in snap.docs)
          doc.id: SkillProgressV2FirestoreMapper.progressFromFirestore(doc, null),
      };
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.skillTree,
        'Failed to fetch SkillProgress (${e.code}) [subject=${subject.toWireString()}]',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    final resolvedDocId = resolveProfileDocId(subject, profileDocId);
    try {
      final snap = await _firestore
          .collection(_profileCollection(subject))
          .doc(resolvedDocId)
          .collection('SkillVerifications')
          .get();
      return {
        for (final doc in snap.docs)
          doc.id: SkillProgressV2FirestoreMapper.verificationFromFirestore(
            doc,
            null,
          ),
      };
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.skillTree,
        'Failed to fetch SkillVerifications (${e.code}) [subject=${subject.toWireString()}]',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    final resolvedDocId = resolveProfileDocId(subject, profileDocId);
    try {
      final snap = await _firestore
          .collection(_profileCollection(subject))
          .doc(resolvedDocId)
          .collection('SkillVerificationEvents')
          .orderBy('at', descending: true)
          .limit(verificationEventLimit)
          .get();
      final events = snap.docs
          .map((d) => SkillProgressV2FirestoreMapper.eventFromFirestore(d, null))
          .toList()
        ..sort(
          (a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)),
        );
      return events;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.skillTree,
        'Failed to fetch SkillVerificationEvents (${e.code}) [subject=${subject.toWireString()}]',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException.fromFirebase(e);
    }
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
    final resolvedDocId = resolveProfileDocId(subject, profileDocId);
    final ref = _firestore
        .collection(_profileCollection(subject))
        .doc(resolvedDocId)
        .collection('SkillProgress')
        .doc(skillId);

    try {
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
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.skillTree,
        'Failed to save SkillProgress (${e.code}) [subject=${subject.toWireString()}, skillId=$skillId, level=${difficultyToKey(level)}]',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException.fromFirebase(e);
    }
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
