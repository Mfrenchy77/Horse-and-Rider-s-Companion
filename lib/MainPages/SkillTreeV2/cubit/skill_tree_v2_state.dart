import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';

enum SkillTreeV2ViewMode { browse, summary, matrix }

enum AbilityMatrixFilter { needsReview, verified, allWithActivity }

class SkillTreeV2State extends Equatable {
  const SkillTreeV2State({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.actionMessage,
    this.subject = SkillSubject.rider,
    this.realm = SkillCategory.Husbandry,
    this.viewMode = SkillTreeV2ViewMode.browse,
    this.matrixFilter = AbilityMatrixFilter.needsReview,
    this.resourceSort = SkillTreeV2ResourceSort.helpfulness,
    this.searchQuery = '',
    this.families = const [],
    this.skills = const [],
    this.expandedFamilyIds = const {},
    this.selectedSkillId,
    this.selectedLevel,
    this.progressBySkillId = const {},
    this.verificationsBySkillId = const {},
    this.verificationEvents = const [],
    this.loadedProfileKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? actionMessage;
  final SkillSubject subject;
  final SkillCategory realm;
  final SkillTreeV2ViewMode viewMode;
  final AbilityMatrixFilter matrixFilter;
  final SkillTreeV2ResourceSort resourceSort;
  final String searchQuery;
  final List<SkillFamily> families;
  final List<CurriculumSkill> skills;
  final Set<String> expandedFamilyIds;
  final String? selectedSkillId;
  final DifficultyState? selectedLevel;
  final Map<String, SkillProgressRecord> progressBySkillId;
  final Map<String, SkillVerificationRecord> verificationsBySkillId;
  final List<VerificationEvent> verificationEvents;
  final String? loadedProfileKey;

  List<SkillCategory> get availableRealms => realmsForSubject(subject);

  List<CurriculumSkill> get subjectSkills =>
      skills.where((s) => s.subject == subject).toList();

  List<CurriculumSkill> get activeSubjectSkills => subjectSkills
      .where((s) => s.status == CurriculumSkillStatus.active)
      .toList();

  List<SkillFamily> get realmFamilies =>
      families
          .where((f) => f.subject == subject && f.realm == realm)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<CurriculumSkill> get visibleSkills {
    final trimmed = searchQuery.trim();
    if (trimmed.isNotEmpty) {
      return activeSubjectSkills.where((s) => s.matchesQuery(trimmed)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return activeSubjectSkills.where((s) => s.realm == realm).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  CurriculumSkill? get selectedSkill {
    if (selectedSkillId == null) return null;
    for (final skill in skills) {
      if (skill.id == selectedSkillId) return skill;
    }
    return null;
  }

  DifficultyState? get effectiveSelectedLevel {
    final skill = selectedSkill;
    if (skill == null || skill.availableLevels.isEmpty) return null;
    if (selectedLevel != null &&
        skill.availableLevels.contains(selectedLevel)) {
      return selectedLevel;
    }
    return skill.availableLevels.first;
  }

  SkillTreeV2State copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
    SkillSubject? subject,
    SkillCategory? realm,
    SkillTreeV2ViewMode? viewMode,
    AbilityMatrixFilter? matrixFilter,
    SkillTreeV2ResourceSort? resourceSort,
    String? searchQuery,
    List<SkillFamily>? families,
    List<CurriculumSkill>? skills,
    Set<String>? expandedFamilyIds,
    String? selectedSkillId,
    bool clearSelectedSkill = false,
    DifficultyState? selectedLevel,
    bool clearSelectedLevel = false,
    Map<String, SkillProgressRecord>? progressBySkillId,
    Map<String, SkillVerificationRecord>? verificationsBySkillId,
    List<VerificationEvent>? verificationEvents,
    String? loadedProfileKey,
    bool clearLoadedProfileKey = false,
  }) {
    return SkillTreeV2State(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      subject: subject ?? this.subject,
      realm: realm ?? this.realm,
      viewMode: viewMode ?? this.viewMode,
      matrixFilter: matrixFilter ?? this.matrixFilter,
      resourceSort: resourceSort ?? this.resourceSort,
      searchQuery: searchQuery ?? this.searchQuery,
      families: families ?? this.families,
      skills: skills ?? this.skills,
      expandedFamilyIds: expandedFamilyIds ?? this.expandedFamilyIds,
      selectedSkillId: clearSelectedSkill
          ? null
          : (selectedSkillId ?? this.selectedSkillId),
      selectedLevel: clearSelectedLevel
          ? null
          : (selectedLevel ?? this.selectedLevel),
      progressBySkillId: progressBySkillId ?? this.progressBySkillId,
      verificationsBySkillId:
          verificationsBySkillId ?? this.verificationsBySkillId,
      verificationEvents: verificationEvents ?? this.verificationEvents,
      loadedProfileKey: clearLoadedProfileKey
          ? null
          : (loadedProfileKey ?? this.loadedProfileKey),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSubmitting,
    errorMessage,
    actionMessage,
    subject,
    realm,
    viewMode,
    matrixFilter,
    resourceSort,
    searchQuery,
    families,
    skills,
    expandedFamilyIds,
    selectedSkillId,
    selectedLevel,
    progressBySkillId,
    verificationsBySkillId,
    verificationEvents,
    loadedProfileKey,
  ];
}
