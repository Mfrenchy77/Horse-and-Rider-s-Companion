import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/services.dart';

/// Loads the bundled Skill Tree 2.0 curriculum JSON fixtures from
/// `curriculum/v2/` so the UI can run without production `SkillsV2` documents.
class AssetCurriculumV2Loader {
  const AssetCurriculumV2Loader({this.bundle});

  final AssetBundle? bundle;

  AssetBundle get _effectiveBundle => bundle ?? rootBundle;

  static const String familiesAssetPath = 'curriculum/v2/families.json';
  static const List<String> skillAssetPaths = [
    'curriculum/v2/skills_rider_husbandry.json',
    'curriculum/v2/skills_rider_in_hand.json',
    'curriculum/v2/skills_rider_mounted.json',
    'curriculum/v2/skills_horse_in_hand.json',
    'curriculum/v2/skills_horse_mounted.json',
  ];

  Future<List<SkillFamily>> loadFamilies() async {
    final raw = await _effectiveBundle.loadString(familiesAssetPath);
    final decoded = jsonDecode(raw);
    final list = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['families'] as List<dynamic>? ??
              const [];
    return [
      for (final item in list.whereType<Map<String, dynamic>>())
        SkillFamily.fromMap(item),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<CurriculumSkill>> loadSkills() async {
    final skills = <CurriculumSkill>[];
    for (final path in skillAssetPaths) {
      final raw = await _effectiveBundle.loadString(path);
      final decoded = jsonDecode(raw);
      final list = decoded is List
          ? decoded
          : (decoded as Map<String, dynamic>)['skills'] as List<dynamic>? ??
                const [];
      for (final item in list.whereType<Map<String, dynamic>>()) {
        skills.add(CurriculumSkill.fromMap(item));
      }
    }
    skills.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return skills;
  }

  Future<InMemorySkillTreeV2Store> loadInMemoryStore() async {
    final families = await loadFamilies();
    final skills = await loadSkills();
    return InMemorySkillTreeV2Store(families: families, skills: skills);
  }
}

/// A [SkillTreeV2Store] that reads curriculum metadata from local JSON assets
/// when remote Firestore `SkillFamilies`/`SkillsV2` documents are not yet
/// populated, while delegating progress/verification reads and writes to the
/// primary store.
class HybridCurriculumSkillTreeV2Store implements SkillTreeV2Store {
  HybridCurriculumSkillTreeV2Store({
    required this.primaryStore,
    this.assetLoader = const AssetCurriculumV2Loader(),
  });

  final SkillTreeV2Store primaryStore;
  final AssetCurriculumV2Loader assetLoader;

  @override
  Future<List<SkillFamily>> fetchFamilies() async {
    try {
      final remote = await primaryStore.fetchFamilies();
      if (remote.isNotEmpty) return remote;
    } catch (_) {
      // Fall back to local curriculum fixtures when Firestore V2 collections
      // are unavailable or not yet deployed.
    }
    return assetLoader.loadFamilies();
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() async {
    try {
      final remote = await primaryStore.fetchSkills();
      if (remote.isNotEmpty) return remote;
    } catch (_) {
      // Fall back to local curriculum fixtures when Firestore V2 collections
      // are unavailable or not yet deployed.
    }
    return assetLoader.loadSkills();
  }

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    try {
      return await primaryStore.fetchProgress(
        subject: subject,
        profileDocId: profileDocId,
      );
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    try {
      return await primaryStore.fetchVerifications(
        subject: subject,
        profileDocId: profileDocId,
      );
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) async {
    try {
      return await primaryStore.fetchVerificationEvents(
        subject: subject,
        profileDocId: profileDocId,
      );
    } catch (_) {
      return const [];
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
  }) => primaryStore.setLevelProgress(
    subject: subject,
    profileDocId: profileDocId,
    skillId: skillId,
    level: level,
    state: state,
    actorUid: actorUid,
    actorName: actorName,
  );
}
