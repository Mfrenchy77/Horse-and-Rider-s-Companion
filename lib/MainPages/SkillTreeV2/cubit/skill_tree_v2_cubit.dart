import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';

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

  SkillTreeV2Store get store => repository.store;

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
      final families = await repository.fetchFamilies();
      final skills = await repository.fetchSkills();
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
      await syncProfile(subject: subject, profileDocId: profileDocId);
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load Skill Tree 2.0 curriculum.',
        ),
      );
    }
  }

  Future<void> syncProfile({
    required SkillSubject subject,
    required String? profileDocId,
  }) async {
    final key = profileDocId == null || profileDocId.isEmpty
        ? '${subject.name}:none'
        : '${subject.name}:$profileDocId';
    if (key == state.loadedProfileKey) return;
    await _loadProfileData(subject: subject, profileDocId: profileDocId);
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

    try {
      final progress = await repository.fetchProgress(
        subject: subject,
        profileDocId: trimmed,
      );
      final verifications = await repository.fetchVerifications(
        subject: subject,
        profileDocId: trimmed,
      );
      final events = await repository.fetchVerificationEvents(
        subject: subject,
        profileDocId: trimmed,
      );
      emit(
        state.copyWith(
          progressBySkillId: progress,
          verificationsBySkillId: verifications,
          verificationEvents: events,
          loadedProfileKey: '${subject.name}:$trimmed',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          progressBySkillId: const {},
          verificationsBySkillId: const {},
          verificationEvents: const [],
          loadedProfileKey: '${subject.name}:$trimmed',
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
    final nextRealm = realmsForSubject(subject).first;
    final nextSkill = _firstSkillFor(state.skills, subject, nextRealm);
    emit(
      state.copyWith(
        subject: subject,
        realm: nextRealm,
        searchQuery: '',
        expandedFamilyIds: const {},
        selectedSkillId: nextSkill?.id,
        selectedLevel: nextSkill?.availableLevels.firstOrNull,
        clearSelectedSkill: nextSkill == null,
        clearSelectedLevel: nextSkill == null,
        clearActionMessage: true,
      ),
    );
    await _loadProfileData(subject: subject, profileDocId: profileDocId);
  }

  void selectRealm(SkillCategory realm) {
    if (!state.availableRealms.contains(realm)) return;
    final nextSkill = _firstSkillFor(state.skills, state.subject, realm);
    emit(
      state.copyWith(
        realm: realm,
        viewMode: SkillTreeV2ViewMode.browse,
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
        ? state.subjectSkills.where((s) => s.realm == state.realm).toList()
        : state.subjectSkills.where((s) => s.matchesQuery(trimmed)).toList();
    final keepSelected = filtered.any((s) => s.id == state.selectedSkillId);
    final nextSkill = keepSelected
        ? state.selectedSkill
        : filtered.firstOrNull;
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
    final nextLevel =
        (level != null && skill.availableLevels.contains(level))
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
      await _loadProfileData(
        subject: state.subject,
        profileDocId: profileDocId,
      );
      final label = switch (levelState) {
        LevelState.LEARNING => 'Marked as Learning.',
        LevelState.PROFICIENT => 'Marked as Proficient.',
        _ => 'Self-assessment cleared.',
      };
      emit(state.copyWith(isSubmitting: false, actionMessage: label));
      return true;
    } catch (e) {
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
    final inMemory = repository.store;
    if (inMemory is! InMemorySkillTreeV2Store) return false;
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
        actionMessage: verified
            ? 'Level verified.'
            : 'Verification revoked.',
      ),
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
            .where((s) => s.subject == subject && s.realm == realm)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return matching.firstOrNull;
  }
}
