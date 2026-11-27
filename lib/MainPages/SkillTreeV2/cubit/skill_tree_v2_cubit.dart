import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_sync.dart';

class _ProfileSkillCache {
  const _ProfileSkillCache({
    required this.progressBySkillId,
    required this.verificationsBySkillId,
    required this.verificationEvents,
  });

  final Map<String, SkillProgressRecord> progressBySkillId;
  final Map<String, SkillVerificationRecord> verificationsBySkillId;
  final List<VerificationEvent> verificationEvents;
}

class SkillTreeV2Cubit extends Cubit<SkillTreeV2State> {
  SkillTreeV2Cubit({
    required this.repository,
    SkillSubject initialSubject = SkillSubject.rider,
  }) : super(
         SkillTreeV2State(
           subject: initialSubject,
           realm: realmsForSubject(initialSubject).first,
         ),
       );

  final SkillTreeV2Repository repository;
  final Map<String, _ProfileSkillCache> _profileCache = {};
  final Map<String, Future<void>> _inFlightProfileLoads = {};

  SkillTreeV2Store get store => repository.store;

  InMemorySkillTreeV2Store? get _inMemoryStore {
    final current = repository.store;
    if (current is InMemorySkillTreeV2Store) return current;
    if (current is HybridCurriculumSkillTreeV2Store &&
        current.primaryStore is InMemorySkillTreeV2Store) {
      return current.primaryStore as InMemorySkillTreeV2Store;
    }
    return null;
  }

  bool get isInMemoryStore => _inMemoryStore != null;

  Future<void> initialize({
    SkillSubject? initialSubject,
    String? profileDocId,
  }) async {
    final subject = initialSubject ?? state.subject;
    final defaultRealm = realmsForSubject(subject).first;
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        subject: subject,
        realm: defaultRealm,
      ),
    );
    try {
      final curriculumFuture = Future.wait<Object>([
        repository.fetchFamilies(),
        repository.fetchSkills(),
      ]);
      final profileFuture = syncProfile(
        subject: subject,
        profileDocId: profileDocId,
      );
      final curriculum = await curriculumFuture;
      if (isClosed) return;
      final families = curriculum[0] as List<SkillFamily>;
      final skills = curriculum[1] as List<CurriculumSkill>;
      final firstSkill = _firstSkillFor(skills, subject, defaultRealm);
      emit(
        state.copyWith(
          isLoading: false,
          families: families,
          skills: skills,
          selectedSkillId: firstSkill?.id,
          selectedLevel: firstSkill?.availableLevels.firstOrNull,
        ),
      );
      await profileFuture;
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load the Skill Tree.',
        ),
      );
    }
  }

  Future<void> syncProfile({
    required SkillSubject subject,
    required String? profileDocId,
  }) async {
    final trimmed = profileDocId?.trim();
    final key = (trimmed == null || trimmed.isEmpty)
        ? '${subject.name}:none'
        : '${subject.name}:$trimmed';
    if (key == state.loadedProfileKey) return;
    final cached = _profileCache[key];
    if (cached != null) {
      emit(
        state.copyWith(
          progressBySkillId: cached.progressBySkillId,
          verificationsBySkillId: cached.verificationsBySkillId,
          verificationEvents: cached.verificationEvents,
          loadedProfileKey: key,
        ),
      );
      return;
    }
    final existing = _inFlightProfileLoads[key];
    if (existing != null) return existing;
    final future = _loadProfileData(subject: subject, profileDocId: trimmed)
        .whenComplete(() {
          _inFlightProfileLoads.remove(key);
        });
    _inFlightProfileLoads[key] = future;
    return future;
  }

  Future<void> refreshProfileData({
    required SkillSubject subject,
    required String? profileDocId,
  }) => _loadProfileData(subject: subject, profileDocId: profileDocId);

  Future<void> _loadProfileData({
    required SkillSubject subject,
    required String? profileDocId,
  }) async {
    final trimmed = profileDocId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      emit(
        state.copyWith(
          progressBySkillId: const {},
          verificationsBySkillId: const {},
          verificationEvents: const [],
          loadedProfileKey: '${subject.name}:none',
        ),
      );
      return;
    }

    final key = '${subject.name}:$trimmed';
    try {
      final results = await Future.wait<Object>([
        repository.fetchProgress(subject: subject, profileDocId: trimmed),
        repository.fetchVerifications(subject: subject, profileDocId: trimmed),
        repository.fetchVerificationEvents(
          subject: subject,
          profileDocId: trimmed,
        ),
      ]);
      final progress = results[0] as Map<String, SkillProgressRecord>;
      final verifications = results[1] as Map<String, SkillVerificationRecord>;
      final events = results[2] as List<VerificationEvent>;
      _profileCache[key] = _ProfileSkillCache(
        progressBySkillId: progress,
        verificationsBySkillId: verifications,
        verificationEvents: events,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          progressBySkillId: progress,
          verificationsBySkillId: verifications,
          verificationEvents: events,
          loadedProfileKey: key,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          progressBySkillId: const {},
          verificationsBySkillId: const {},
          verificationEvents: const [],
          loadedProfileKey: key,
        ),
      );
    }
  }

  Future<void> selectSubject(
    SkillSubject subject, {
    String? profileDocId,
  }) async {
    if (subject == state.subject) {
      await syncProfile(subject: subject, profileDocId: profileDocId);
      return;
    }
    await switchProfileContext(subject: subject, profileDocId: profileDocId);
  }

  Future<void> switchProfileContext({
    required SkillSubject subject,
    required String? profileDocId,
  }) async {
    final nextRealm = realmsForSubject(subject).first;
    final nextSkill = _firstSkillFor(state.skills, subject, nextRealm);
    emit(
      state.copyWith(
        subject: subject,
        realm: nextRealm,
        viewMode: SkillTreeV2ViewMode.browse,
        searchQuery: '',
        expandedFamilyIds: const {},
        selectedSkillId: nextSkill?.id,
        selectedLevel: nextSkill?.availableLevels.firstOrNull,
        clearSelectedSkill: nextSkill == null,
        clearSelectedLevel: nextSkill == null,
        clearActionMessage: true,
      ),
    );
    await syncProfile(subject: subject, profileDocId: profileDocId);
  }

  void selectRealm(SkillCategory realm) {
    if (!state.availableRealms.contains(realm)) return;
    final nextSkill = _firstSkillFor(state.skills, state.subject, realm);
    emit(
      state.copyWith(
        realm: realm,
        viewMode: SkillTreeV2ViewMode.browse,
        searchQuery: '',
        expandedFamilyIds: const {},
        selectedSkillId: nextSkill?.id,
        selectedLevel: nextSkill?.availableLevels.firstOrNull,
        clearSelectedSkill: nextSkill == null,
        clearSelectedLevel: nextSkill == null,
        clearActionMessage: true,
      ),
    );
  }

  void toggleFamilyExpanded(String familyId) {
    final next = Set<String>.from(state.expandedFamilyIds);
    if (!next.add(familyId)) {
      next.remove(familyId);
    }
    emit(state.copyWith(expandedFamilyIds: next));
  }

  void setViewMode(SkillTreeV2ViewMode mode) {
    emit(state.copyWith(viewMode: mode, clearActionMessage: true));
  }

  /// Clears any active skill selection (e.g., when navigating to an unknown
  /// skill URL so a stale previously selected skill does not remain open).
  void clearSelection() {
    if (state.selectedSkillId == null && state.selectedLevel == null) return;
    emit(
      state.copyWith(
        clearSelectedSkill: true,
        clearSelectedLevel: true,
        clearActionMessage: true,
      ),
    );
  }

  void openSkillInExplore(CurriculumSkill skill, {DifficultyState? level}) {
    emit(
      state.copyWith(
        subject: skill.subject,
        realm: skill.realm,
        viewMode: SkillTreeV2ViewMode.browse,
        searchQuery: '',
        expandedFamilyIds: {skill.familyId},
        selectedSkillId: skill.id,
        selectedLevel: level ?? skill.availableLevels.firstOrNull,
        clearActionMessage: true,
      ),
    );
  }

  void setMatrixFilter(AbilityMatrixFilter filter) {
    emit(state.copyWith(matrixFilter: filter));
  }

  void setResourceSort(SkillTreeV2ResourceSort sort) {
    emit(state.copyWith(resourceSort: sort));
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    final filtered = trimmed.isEmpty
        ? state.activeSubjectSkills
              .where((s) => s.realm == state.realm)
              .toList()
        : state.activeSubjectSkills
              .where((s) => s.matchesQuery(trimmed))
              .toList();
    final keepSelected = filtered.any((s) => s.id == state.selectedSkillId);
    final nextSkill = keepSelected ? state.selectedSkill : filtered.firstOrNull;
    emit(
      state.copyWith(
        searchQuery: query,
        selectedSkillId: nextSkill?.id,
        selectedLevel: nextSkill?.availableLevels.firstOrNull,
        clearSelectedSkill: nextSkill == null,
        clearSelectedLevel: nextSkill == null,
      ),
    );
  }

  void selectSkill(String? skillId, {DifficultyState? level}) {
    if (skillId == null) {
      emit(state.copyWith(clearSelectedSkill: true, clearSelectedLevel: true));
      return;
    }
    final skill = state.skills.where((s) => s.id == skillId).firstOrNull;
    if (skill == null) return;
    final nextLevel = (level != null && skill.availableLevels.contains(level))
        ? level
        : skill.availableLevels.firstOrNull;
    emit(
      state.copyWith(
        subject: skill.subject,
        realm: skill.realm,
        viewMode: SkillTreeV2ViewMode.browse,
        selectedSkillId: skill.id,
        selectedLevel: nextLevel,
        clearActionMessage: true,
      ),
    );
  }

  void selectLevel(DifficultyState level) {
    final skill = state.selectedSkill;
    if (skill == null || !skill.availableLevels.contains(level)) return;
    emit(state.copyWith(selectedLevel: level));
  }

  Future<bool> setSelfAssessment({
    required String skillId,
    required DifficultyState level,
    required LevelState? levelState,
    required String profileDocId,
    required String actorUid,
    String? actorName,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearActionMessage: true));
    try {
      await repository.setLevelProgress(
        subject: state.subject,
        profileDocId: profileDocId,
        skillId: skillId,
        level: level,
        state: levelState,
        actorUid: actorUid,
        actorName: actorName,
      );
      final updatedProgress = Map<String, SkillProgressRecord>.from(
        state.progressBySkillId,
      );
      final existing = updatedProgress[skillId];
      final nextLevels = Map<DifficultyState, LevelProgress>.from(
        existing?.levels ?? const {},
      );
      final now = DateTime.now().toUtc();
      if (levelState == null || levelState == LevelState.NO_PROGRESS) {
        nextLevels.remove(level);
      } else {
        nextLevels[level] = LevelProgress(
          state: levelState == LevelState.VERIFIED
              ? LevelState.PROFICIENT
              : levelState,
          updatedAt: now,
          updatedByUid: actorUid,
          updatedByName: actorName,
        );
      }
      if (nextLevels.isEmpty) {
        updatedProgress.remove(skillId);
      } else {
        updatedProgress[skillId] = SkillProgressRecord(
          skillId: skillId,
          subject: state.subject,
          levels: nextLevels,
          updatedAt: now,
        );
      }
      final trimmedProfile = profileDocId.trim();
      final cacheKey = '${state.subject.name}:$trimmedProfile';
      _profileCache[cacheKey] = _ProfileSkillCache(
        progressBySkillId: updatedProgress,
        verificationsBySkillId: state.verificationsBySkillId,
        verificationEvents: state.verificationEvents,
      );
      final label = switch (levelState) {
        LevelState.LEARNING => 'Marked as Learning.',
        LevelState.PROFICIENT => 'Marked as Proficient.',
        _ => 'Self-assessment cleared.',
      };
      if (isClosed) return true;
      emit(
        state.copyWith(
          isSubmitting: false,
          progressBySkillId: updatedProgress,
          loadedProfileKey: cacheKey,
          actionMessage: label,
        ),
      );
      SkillTreeV2Sync.notifyProgressChanged(
        subject: state.subject,
        profileDocId: trimmedProfile,
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSubmitting: false,
          actionMessage: 'Could not save assessment. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> applyLocalVerification({
    required CurriculumSkill skill,
    required DifficultyState level,
    required bool verified,
    required String profileDocId,
    required String coachUid,
    required String coachName,
    String? reason,
  }) async {
    final inMemory = _inMemoryStore;
    if (inMemory == null) return false;
    emit(state.copyWith(isSubmitting: true, clearActionMessage: true));
    inMemory.applyVerificationLocally(
      subject: skill.subject,
      profileDocId: profileDocId,
      skillId: skill.id,
      skillName: skill.name,
      level: level,
      verified: verified,
      coachUid: coachUid,
      coachName: coachName,
      reason: reason,
    );
    await _loadProfileData(subject: skill.subject, profileDocId: profileDocId);
    emit(
      state.copyWith(
        isSubmitting: false,
        actionMessage: verified ? 'Level verified.' : 'Verification revoked.',
      ),
    );
    SkillTreeV2Sync.notifyProgressChanged(
      subject: skill.subject,
      profileDocId: profileDocId,
    );
    return true;
  }

  void clearActionMessage() {
    if (state.actionMessage != null) {
      emit(state.copyWith(clearActionMessage: true));
    }
  }

  CurriculumSkill? _firstSkillFor(
    List<CurriculumSkill> skills,
    SkillSubject subject,
    SkillCategory realm,
  ) {
    final matching =
        skills
            .where(
              (s) =>
                  s.status == CurriculumSkillStatus.active &&
                  s.subject == subject &&
                  s.realm == realm,
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return matching.firstOrNull;
  }
}
