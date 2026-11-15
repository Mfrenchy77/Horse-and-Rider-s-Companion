import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';

/// State for the Administration Skill Tree Suggestions inbox.
class AdministrationSuggestionsState extends Equatable {
  /// Creates an [AdministrationSuggestionsState].
  const AdministrationSuggestionsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.loadingAudit = false,
    this.suggestions = const [],
    this.selectedSuggestion,
    this.auditEvents = const [],
    this.statusFilter,
    this.errorMessage,
    this.actionMessage,
  });

  final bool isLoading;
  final bool isSubmitting;
  final bool loadingAudit;
  final List<SkillTreeSuggestion> suggestions;
  final SkillTreeSuggestion? selectedSuggestion;
  final List<SuggestionAuditEvent> auditEvents;
  final SuggestionStatus? statusFilter;
  final String? errorMessage;
  final String? actionMessage;

  /// Returns a copy with the specified fields updated.
  AdministrationSuggestionsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? loadingAudit,
    List<SkillTreeSuggestion>? suggestions,
    SkillTreeSuggestion? selectedSuggestion,
    bool clearSelected = false,
    List<SuggestionAuditEvent>? auditEvents,
    SuggestionStatus? statusFilter,
    bool clearStatusFilter = false,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return AdministrationSuggestionsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      loadingAudit: loadingAudit ?? this.loadingAudit,
      suggestions: suggestions ?? this.suggestions,
      selectedSuggestion: clearSelected
          ? null
          : (selectedSuggestion ?? this.selectedSuggestion),
      auditEvents: auditEvents ?? this.auditEvents,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        loadingAudit,
        suggestions,
        selectedSuggestion,
        auditEvents,
        statusFilter,
        errorMessage,
        actionMessage,
      ];
}

/// Cubit managing the staff Skill Tree Suggestions inbox and audit history.
class AdministrationSuggestionsCubit
    extends Cubit<AdministrationSuggestionsState> {
  /// Creates an [AdministrationSuggestionsCubit].
  AdministrationSuggestionsCubit({
    required this._repository,
  }) : super(const AdministrationSuggestionsState());

  final SkillTreeSuggestionsRepository _repository;

  /// Loads inbox suggestions, optionally filtered by [statusFilter].
  Future<void> loadInbox({SuggestionStatus? statusFilter}) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        statusFilter: statusFilter,
        clearStatusFilter: statusFilter == null,
      ),
    );
    try {
      final items = await _repository.fetchInboxSuggestions(
        statusFilter: statusFilter,
      );
      var selected = state.selectedSuggestion;
      if (selected != null) {
        selected = items.where((s) => s.id == selected!.id).firstOrNull;
      }
      selected ??= items.firstOrNull;
      emit(
        state.copyWith(
          isLoading: false,
          suggestions: items,
          selectedSuggestion: selected,
          clearSelected: selected == null,
          auditEvents: selected == null ? const [] : state.auditEvents,
        ),
      );
      if (selected != null) {
        await _loadAuditEvents(selected.id);
      }
    } on SkillTreeSuggestionException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load suggestions inbox.',
        ),
      );
    }
  }

  /// Selects [suggestion] and loads its private audit events.
  Future<void> selectSuggestion(SkillTreeSuggestion suggestion) async {
    emit(state.copyWith(selectedSuggestion: suggestion, clearError: true));
    await _loadAuditEvents(suggestion.id);
  }

  Future<void> _loadAuditEvents(String suggestionId) async {
    emit(state.copyWith(loadingAudit: true));
    try {
      final events = await _repository.fetchAuditEvents(suggestionId);
      emit(state.copyWith(loadingAudit: false, auditEvents: events));
    } catch (_) {
      emit(state.copyWith(loadingAudit: false, auditEvents: const []));
    }
  }

  /// Submits a staff review update for the currently selected suggestion.
  Future<bool> submitReview(SuggestionReviewUpdate update) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearActionMessage: true,
      ),
    );
    try {
      final updated = await _repository.reviewSuggestion(update);
      final updatedList = [
        for (final item in state.suggestions)
          if (item.id == updated.id) updated else item,
      ];
      final filteredList = state.statusFilter == null
          ? updatedList
          : updatedList.where((s) => s.status == state.statusFilter).toList();
      final events = await _repository.fetchAuditEvents(updated.id);
      emit(
        state.copyWith(
          isSubmitting: false,
          suggestions: filteredList,
          selectedSuggestion: updated,
          auditEvents: events,
          actionMessage: 'Review saved.',
        ),
      );
      return true;
    } on SkillTreeSuggestionException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Could not save review update.',
        ),
      );
      return false;
    }
  }

  /// Clears any transient feedback message.
  void clearActionMessage() {
    emit(state.copyWith(clearActionMessage: true));
  }
}
