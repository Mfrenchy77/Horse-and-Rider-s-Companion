// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/skill_tree_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/resource_update_skills_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_sync.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/ability_summary_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_draft_dialogs.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_revision_dialogs.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/instructor_ability_matrix_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_tree_v2_header.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/suggest_improvement_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillTreeV2View extends StatefulWidget {
  const SkillTreeV2View({
    super.key,
    this.repository,
    this.enableLocalInstructorPreview = false,
    this.enableCurriculumPublishing = kEnableCurriculumPublishing,
    this.initialSkillId,
    this.initialLevel,
  });

  final SkillTreeV2Repository? repository;
  final bool enableLocalInstructorPreview;
  final bool enableCurriculumPublishing;
  final String? initialSkillId;
  final DifficultyState? initialLevel;

  static InMemorySkillTreeV2Store _previewProgressStore =
      InMemorySkillTreeV2Store();

  @visibleForTesting
  static void resetPreviewStoreForTest() {
    _previewProgressStore = InMemorySkillTreeV2Store();
  }

  @override
  State<SkillTreeV2View> createState() => _SkillTreeV2ViewState();
}

class _SkillTreeV2ViewState extends State<SkillTreeV2View> {
  late final SkillTreeV2Cubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
  double _savedListScrollOffset = 0;
  String? _lastSelectedSkillId;
  String? _pendingInitialSkillId;
  DifficultyState? _pendingInitialLevel;
  bool _suppressNextSubjectSwitch = false;
  bool _mobileShowingDetail = false;
  LocalHistoryEntry? _localHistoryEntry;
  bool _isAdminEditMode = false;
  bool _isPreviewingDraft = true;
  bool _hasUnsavedDraftChanges = false;
  bool _isDraftBusy = false;
  SkillTreeCurriculumDraft? _draft;

  bool _isVerifiedAdmin(AppState appState) =>
      !appState.isGuest && appState.user.emailVerified && appState.isAdmin;

  SkillTreeV2State _effectiveState(SkillTreeV2State publishedState) {
    final draft = _draft;
    if (draft == null || !_isPreviewingDraft) return publishedState;
    return publishedState.copyWith(
      families: draft.families,
      skills: draft.skills,
    );
  }

  Future<void> _toggleAdminEditMode(SkillTreeV2State publishedState) async {
    if (_isAdminEditMode) {
      setState(() {
        _isAdminEditMode = false;
      });
      return;
    }

    setState(() {
      _isAdminEditMode = true;
      _isPreviewingDraft = true;
      _isDraftBusy = true;
    });

    try {
      final draftRepo = context.read<SkillTreeDraftRepository?>();
      final remoteDraft = await draftRepo?.fetchDraft();
      if (!mounted) return;
      setState(() {
        _draft ??=
            remoteDraft ??
            SkillTreeCurriculumDraft(
              families: List<SkillFamily>.from(publishedState.families),
              skills: List<CurriculumSkill>.from(publishedState.skills),
            );
        _isDraftBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _draft ??= SkillTreeCurriculumDraft(
          families: List<SkillFamily>.from(publishedState.families),
          skills: List<CurriculumSkill>.from(publishedState.skills),
        );
        _isDraftBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded local draft fallback: $e')),
      );
    }
  }

  Future<void> _saveDraft() async {
    final draft = _draft;
    if (draft == null) return;
    final draftRepo = context.read<SkillTreeDraftRepository?>();
    if (draftRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft repository is not configured.')),
      );
      return;
    }

    setState(() => _isDraftBusy = true);
    try {
      final saved = await draftRepo.saveDraft(draft);
      if (!mounted) return;
      setState(() {
        _draft = saved;
        _hasUnsavedDraftChanges = false;
        _isDraftBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Curriculum draft saved (not yet published).'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDraftBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save draft: $e')));
    }
  }

  Future<void> _discardDraft() async {
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard Curriculum Draft?'),
        content: const Text(
          'This will discard all draft curriculum edits and revert to the '
          'published curriculum. User progress is unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _isDraftBusy = true);
    try {
      final draftRepo = context.read<SkillTreeDraftRepository?>();
      await draftRepo?.discardDraft();
      if (!mounted) return;
      setState(() {
        _draft = null;
        _hasUnsavedDraftChanges = false;
        _isAdminEditMode = false;
        _isPreviewingDraft = false;
        _isDraftBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curriculum draft discarded.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDraftBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to discard draft: $e')));
    }
  }

  Future<void> _addOrEditFamily(
    SkillTreeV2State effectiveState, {
    SkillFamily? initial,
  }) async {
    final draft =
        _draft ??
        SkillTreeCurriculumDraft(
          families: List<SkillFamily>.from(effectiveState.families),
          skills: List<CurriculumSkill>.from(effectiveState.skills),
        );
    final result = await showAppGlassDialog<SkillFamily>(
      context: context,
      builder: (_) => EditSkillFamilyDialog(
        initialFamily: initial,
        defaultSubject: effectiveState.subject,
        defaultRealm: effectiveState.realm,
        existingFamilyIds: draft.families.map((f) => f.id).toSet(),
        defaultSortOrder: effectiveState.realmFamilies.length + 1,
      ),
    );
    if (result == null || !mounted) return;

    final updatedFamilies = List<SkillFamily>.from(draft.families);
    final existingIdx = updatedFamilies.indexWhere((f) => f.id == result.id);
    if (existingIdx >= 0) {
      updatedFamilies[existingIdx] = result;
    } else {
      updatedFamilies.add(result);
    }

    setState(() {
      _draft = SkillTreeCurriculumDraft(
        families: updatedFamilies,
        skills: draft.skills,
        updatedByUid: draft.updatedByUid,
        updatedByName: draft.updatedByName,
        updatedAt: draft.updatedAt,
      );
      _hasUnsavedDraftChanges = true;
      _isPreviewingDraft = true;
    });
    if (!effectiveState.expandedFamilyIds.contains(result.id)) {
      _cubit.toggleFamilyExpanded(result.id);
    }
  }

  Future<void> _addOrEditSkill(
    SkillTreeV2State effectiveState, {
    required SkillFamily family,
    CurriculumSkill? initial,
  }) async {
    final draft =
        _draft ??
        SkillTreeCurriculumDraft(
          families: List<SkillFamily>.from(effectiveState.families),
          skills: List<CurriculumSkill>.from(effectiveState.skills),
        );
    final publishedSkill = initial == null
        ? null
        : _cubit.state.skills.where((s) => s.id == initial.id).firstOrNull;
    final familySkillCount = draft.skills
        .where((s) => s.familyId == family.id)
        .length;
    final result = await showAppGlassDialog<CurriculumSkill>(
      context: context,
      builder: (_) => EditCurriculumSkillDialog(
        initialSkill: initial,
        publishedSkill: publishedSkill,
        family: family,
        allSkills: draft.skills,
        existingSkillIds: draft.skills.map((s) => s.id).toSet(),
        defaultSortOrder: familySkillCount + 1,
        initialExpandedLevel: initial == null
            ? null
            : effectiveState.effectiveSelectedLevel,
      ),
    );
    if (result == null || !mounted) return;

    final updatedSkills = List<CurriculumSkill>.from(draft.skills);
    final existingIdx = updatedSkills.indexWhere((s) => s.id == result.id);
    if (existingIdx >= 0) {
      updatedSkills[existingIdx] = result;
    } else {
      updatedSkills.add(result);
    }

    setState(() {
      _draft = SkillTreeCurriculumDraft(
        families: draft.families,
        skills: updatedSkills,
        updatedByUid: draft.updatedByUid,
        updatedByName: draft.updatedByName,
        updatedAt: draft.updatedAt,
      );
      _hasUnsavedDraftChanges = true;
      _isPreviewingDraft = true;
    });
    _cubit.selectSkill(result.id);
  }

  Future<void> _openDraftPreview(SkillTreeV2State publishedState) async {
    final draft = _draft;
    if (draft == null) return;
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => DraftPreviewDialog(
        publishedFamilies: publishedState.families,
        publishedSkills: publishedState.skills,
        draftFamilies: draft.families,
        draftSkills: draft.skills,
        isPreviewingDraft: _isPreviewingDraft,
        onTogglePreview: (value) {
          setState(() {
            _isPreviewingDraft = value;
          });
        },
      ),
    );
  }

  Future<void> _openPublishDialog(SkillTreeV2State publishedState) async {
    final draft = _draft;
    final draftRepo = context.read<SkillTreeDraftRepository?>();
    if (draft == null || draftRepo == null) return;
    final published = await showAppGlassDialog<CurriculumRevisionSummary>(
      context: context,
      builder: (_) => CurriculumPublishDialog(
        publishedFamilies: publishedState.families,
        publishedSkills: publishedState.skills,
        draftFamilies: draft.families,
        draftSkills: draft.skills,
        publishingEnabled: widget.enableCurriculumPublishing,
        onPublish: (notes) async {
          if (_hasUnsavedDraftChanges) {
            await draftRepo.saveDraft(draft);
          }
          return draftRepo.publishDraft(notes: notes);
        },
      ),
    );
    if (published == null || !mounted) return;
    setState(() {
      _draft = null;
      _hasUnsavedDraftChanges = false;
      _isAdminEditMode = false;
      _isPreviewingDraft = false;
    });
    await _cubit.initialize(
      initialSubject: _cubit.state.subject,
      profileDocId: _profileDocIdFor(
        context.read<AppCubit>().state,
        _cubit.state.subject,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Published Curriculum Revision #${published.revisionNumber}.',
        ),
      ),
    );
  }

  Future<void> _openRevisionHistory(SkillTreeV2State publishedState) async {
    final draftRepo = context.read<SkillTreeDraftRepository?>();
    if (draftRepo == null) return;
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => CurriculumRevisionHistoryDialog(
        draftRepository: draftRepo,
        currentFamilies: publishedState.families,
        currentSkills: publishedState.skills,
        publishingEnabled: widget.enableCurriculumPublishing,
        onRestored: (_) {
          _cubit.initialize(
            initialSubject: _cubit.state.subject,
            profileDocId: _profileDocIdFor(
              context.read<AppCubit>().state,
              _cubit.state.subject,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminDraftBanner(
    BuildContext context,
    SkillTreeV2State publishedState,
    SkillTreeV2State effectiveState,
  ) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('skillTreeV2AdminDraftBanner'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceSm,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_outlined, size: 20),
              const SizedBox(width: AppTokens.spaceSm),
              Expanded(
                child: Text(
                  _isPreviewingDraft
                      ? (_hasUnsavedDraftChanges
                            ? 'Admin Draft Mode · Unsaved draft changes'
                            : 'Admin Draft Mode · Previewing draft')
                      : 'Admin Draft Mode · Viewing published curriculum',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isDraftBusy)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceXs,
            children: [
              if (_isAdminEditMode)
                FilledButton.tonalIcon(
                  key: const Key('draftAddFamilyButton'),
                  onPressed: _isDraftBusy
                      ? null
                      : () => _addOrEditFamily(effectiveState),
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('Add Skill Family'),
                ),
              OutlinedButton.icon(
                key: const Key('draftPreviewButton'),
                onPressed: _isDraftBusy
                    ? null
                    : () => _openDraftPreview(publishedState),
                icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                label: Text(
                  _isPreviewingDraft ? 'Preview Changes' : 'Switch to Draft',
                ),
              ),
              FilledButton.icon(
                key: const Key('draftSaveButton'),
                onPressed: _isDraftBusy ? null : _saveDraft,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
              ),
              TextButton.icon(
                key: const Key('draftDiscardButton'),
                onPressed: _isDraftBusy ? null : _discardDraft,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Discard Changes'),
              ),
              OutlinedButton.icon(
                key: const Key('draftRevisionHistoryButton'),
                onPressed: _isDraftBusy
                    ? null
                    : () => _openRevisionHistory(publishedState),
                icon: const Icon(Icons.history_outlined, size: 18),
                label: const Text('Revision History'),
              ),
              if (widget.enableCurriculumPublishing)
                FilledButton.tonalIcon(
                  key: const Key('draftPublishButton'),
                  onPressed: _isDraftBusy
                      ? null
                      : () => _openPublishDialog(publishedState),
                  icon: const Icon(Icons.publish_outlined, size: 18),
                  label: const Text('Publish Curriculum'),
                )
              else
                const Tooltip(
                  message: 'Publishing is currently disabled in production.',
                  child: OutlinedButton(
                    key: Key('draftPublishDisabledButton'),
                    onPressed: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.publish_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Publish (Future Workflow)'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pendingInitialSkillId = widget.initialSkillId;
    _pendingInitialLevel = widget.initialLevel;
    final appState = context.read<AppCubit>().state;
    final initialSubject = appState.isForRider
        ? SkillSubject.rider
        : SkillSubject.horse;
    final repo = widget.repository ?? _resolveDefaultRepository();
    _cubit = SkillTreeV2Cubit(repository: repo, initialSubject: initialSubject)
      ..initialize(
        initialSubject: initialSubject,
        profileDocId: _profileDocIdFor(appState, initialSubject),
      );
    GuestSpotlightTour.skillTreeHooks = GuestSpotlightSkillTreeHooks(
      expandFirstFamily: _expandFirstFamilyForTour,
      ensureSkillSelected: _ensureSkillSelectedForTour,
      showFamilyList: _showFamilyListForTour,
    );
    SkillTreeSpotlightTour.hooks = SkillTreeSpotlightHooks(
      showFamilyList: _showFamilyListForTour,
      expandFirstFamily: _expandFirstFamilyForTour,
      ensureSkillSelected: _ensureSkillSelectedForTour,
      selectSecondLevelIfAvailable: _selectSecondLevelForTour,
      expandGuidance: () {},
    );
  }

  @override
  void didUpdateWidget(covariant SkillTreeV2View oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSkillId != null &&
        (widget.initialSkillId != oldWidget.initialSkillId ||
            widget.initialLevel != oldWidget.initialLevel)) {
      _pendingInitialSkillId = widget.initialSkillId;
      _pendingInitialLevel = widget.initialLevel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyPendingInitialSkillIfReady(
            context.read<AppCubit>(),
            _cubit.state,
          );
        }
      });
    }
  }

  void _applyPendingInitialSkillIfReady(
    AppCubit appCubit,
    SkillTreeV2State state,
  ) {
    if (!mounted ||
        state.isLoading ||
        state.skills.isEmpty ||
        _pendingInitialSkillId == null) {
      return;
    }
    final targetId = _pendingInitialSkillId!;
    final targetLevel = _pendingInitialLevel;
    _pendingInitialSkillId = null;
    _pendingInitialLevel = null;

    final resolved =
        state.skills.where((s) => s.id == targetId).firstOrNull ??
        state.skills.where((s) => s.legacyIds.contains(targetId)).firstOrNull;
    if (resolved == null) return;

    final resolvedLevel =
        targetLevel != null && resolved.availableLevels.contains(targetLevel)
        ? targetLevel
        : resolved.availableLevels.firstOrNull;

    final currentIsForRider = appCubit.state.isForRider;
    final targetIsForRider = resolved.subject == SkillSubject.rider;
    if (currentIsForRider != targetIsForRider) {
      _suppressNextSubjectSwitch = true;
      appCubit.setSkillSubject(isForRider: targetIsForRider);
    }
    _cubit.syncProfile(
      subject: resolved.subject,
      profileDocId: _profileDocIdFor(appCubit.state, resolved.subject),
    );
    _cubit.openSkillInExplore(resolved, level: resolvedLevel);

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    if (!isWide) {
      setState(() => _mobileShowingDetail = true);
      _syncLocalHistoryEntry();
    }
    _resetDetailScrollToTop();
  }

  SkillTreeV2Repository _resolveDefaultRepository() {
    if (Firebase.apps.isEmpty) {
      return SkillTreeV2Repository(
        store: HybridCurriculumSkillTreeV2Store(
          primaryStore: SkillTreeV2View._previewProgressStore,
        ),
      );
    }
    return SkillTreeV2Repository(store: FirestoreSkillTreeV2Store());
  }

  @override
  void dispose() {
    GuestSpotlightTour.skillTreeHooks = null;
    SkillTreeSpotlightTour.hooks = null;
    _localHistoryEntry = null;
    _scrollController.dispose();
    _listScrollController.dispose();
    _detailScrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _expandFirstFamilyForTour() {
    if (!mounted) return;
    final state = _cubit.state;
    final visible = state.visibleSkills;
    for (final family in state.realmFamilies) {
      final hasSkills = visible.any((s) => s.familyId == family.id);
      if (!hasSkills) continue;
      if (!state.expandedFamilyIds.contains(family.id)) {
        _cubit.toggleFamilyExpanded(family.id);
      }
      return;
    }
  }

  void _ensureSkillSelectedForTour() {
    if (!mounted) return;
    final state = _cubit.state;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    if (!isWide && _mobileShowingDetail) return;
    if (isWide && state.selectedSkill != null) return;

    final visible = state.visibleSkills;
    for (final family in state.realmFamilies) {
      final familySkills =
          visible.where((s) => s.familyId == family.id).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (familySkills.isEmpty) continue;
      if (!state.expandedFamilyIds.contains(family.id)) {
        _cubit.toggleFamilyExpanded(family.id);
      }
      final firstSkill = familySkills.first;
      if (isWide) {
        _cubit.selectSkill(firstSkill.id);
      } else {
        _openMobileDetail(firstSkill.id);
      }
      return;
    }
  }

  void _showFamilyListForTour() {
    if (!mounted) return;
    if (_mobileShowingDetail) {
      _returnToBrowsingList();
    }
  }

  void _selectSecondLevelForTour() {
    if (!mounted) return;
    final skill = _cubit.state.selectedSkill;
    if (skill == null || skill.availableLevels.length < 2) return;
    _cubit.selectLevel(skill.availableLevels[1]);
  }

  void _resetDetailScrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_detailScrollController.hasClients) {
        _detailScrollController.jumpTo(0);
      } else if (_mobileShowingDetail && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  bool get _hasInternalBackState =>
      _mobileShowingDetail ||
      _cubit.state.viewMode != SkillTreeV2ViewMode.browse;

  void _syncLocalHistoryEntry() {
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (_hasInternalBackState && _localHistoryEntry == null) {
      final entry = LocalHistoryEntry(onRemove: _onLocalHistoryRemoved);
      _localHistoryEntry = entry;
      route.addLocalHistoryEntry(entry);
    } else if (!_hasInternalBackState && _localHistoryEntry != null) {
      final entry = _localHistoryEntry;
      _localHistoryEntry = null;
      entry?.remove();
    }
  }

  void _onLocalHistoryRemoved() {
    _localHistoryEntry = null;
    if (!mounted) return;
    _stepBackInternally();
  }

  void _stepBackInternally() {
    if (_mobileShowingDetail) {
      _returnToBrowsingList();
      return;
    }
    if (_cubit.state.viewMode == SkillTreeV2ViewMode.matrix) {
      _cubit.setViewMode(SkillTreeV2ViewMode.summary);
      return;
    }
    if (_cubit.state.viewMode != SkillTreeV2ViewMode.browse) {
      _cubit.setViewMode(SkillTreeV2ViewMode.browse);
    }
  }

  void _openMobileDetail(String skillId, {DifficultyState? level}) {
    _savedListScrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0;
    _cubit.selectSkill(skillId, level: level);
    setState(() => _mobileShowingDetail = true);
    _syncLocalHistoryEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _returnToBrowsingList() {
    setState(() => _mobileShowingDetail = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final target = _savedListScrollOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      }
    });
  }

  void _handleAppBarBack(BuildContext context) {
    if (_hasInternalBackState) {
      if (_localHistoryEntry != null) {
        Navigator.of(context).maybePop();
      } else {
        _stepBackInternally();
      }
      return;
    }
    context.read<AppCubit>().changeIndex(0);
  }

  String? _profileDocIdFor(AppState appState, SkillSubject subject) {
    if (subject == SkillSubject.rider) {
      final rider = appState.isViewing
          ? appState.viewingProfile
          : appState.usersProfile;
      return rider?.email;
    }
    return appState.horseProfile?.id;
  }

  CoachingConnection? _activeCoachingLink(
    AppState appState,
    ConnectionsState? connectionState,
    SkillSubject subject,
  ) {
    if (appState.isGuest ||
        connectionState == null ||
        connectionState.email != appState.usersProfile?.email.toLowerCase()) {
      return null;
    }
    if (subject == SkillSubject.rider) {
      final rider = appState.isViewing
          ? appState.viewingProfile
          : appState.usersProfile;
      if (!appState.isViewing || rider == null) return null;
      return connectionState.instructorFor(rider.email);
    }
    final horse = appState.horseProfile;
    if (horse == null || horse.isArchived) return null;
    return connectionState.connections
        .where(
          (link) =>
              link.kind == 'horse' &&
              link.status == 'accepted' &&
              link.coach == connectionState.email &&
              link.horseId == horse.id &&
              link.learner == horse.currentOwnerId.toLowerCase() &&
              link.ownershipVersion == horse.ownershipVersion,
        )
        .firstOrNull;
  }

  Future<void> _handleVerifyLevel({
    required BuildContext context,
    required CurriculumSkill skill,
    required DifficultyState level,
    required bool verified,
    required CoachingConnection? coachingLink,
    required String? profileDocId,
    required AppState appState,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        title: Text(
          verified ? 'Verify Proficient Level' : 'Revoke Verification',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceSm,
          children: [
            Text(
              verified
                  ? 'Verify ${skill.name} '
                        '(${difficultyDisplayLabel(level)}) as Proficient?'
                  : 'Revoke verification for ${skill.name} '
                        '(${difficultyDisplayLabel(level)})? '
                        'The self-assessment record will remain intact.',
            ),
            if (!verified)
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Optional reason',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(verified ? 'Verify' : 'Revoke'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (!(confirmed ?? false) || !context.mounted) return;

    if (coachingLink != null) {
      final connections = context.read<ConnectionsCubit?>();
      if (connections == null) return;
      final result = await connections.submit({
        'action': verified ? 'verifySkillLevel' : 'revokeSkillLevel',
        'id': coachingLink.id,
        'version': coachingLink.version,
        'recordId': ViewUtils.createId(),
        'skillId': skill.id,
        'level': level.name,
        if (!verified && reason.isNotEmpty) 'reason': reason,
      });
      if (!context.mounted) return;
      final ok = result?['verified'] == verified;
      if (ok && profileDocId != null) {
        await _cubit.refreshProfileData(
          subject: skill.subject,
          profileDocId: profileDocId,
        );
        SkillTreeV2Sync.notifyProgressChanged();
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (verified ? 'Level verified.' : 'Verification revoked.')
                : connections.state.actionFeedback ??
                      'Could not update verification.',
          ),
        ),
      );
      return;
    }

    if (widget.enableLocalInstructorPreview &&
        _cubit.store is InMemorySkillTreeV2Store &&
        profileDocId != null) {
      await _cubit.applyLocalVerification(
        skill: skill,
        level: level,
        verified: verified,
        profileDocId: profileDocId,
        coachUid: appState.user.id,
        coachName: appState.usersProfile?.name ?? 'Preview Instructor',
        reason: reason.isEmpty ? null : reason,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final connectionState = context.watch<ConnectionsCubit?>()?.state;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<AppCubit, AppState>(
        listenWhen: (prev, curr) =>
            prev.isForRider != curr.isForRider ||
            prev.isViewing != curr.isViewing ||
            prev.viewingProfile?.email != curr.viewingProfile?.email ||
            prev.usersProfile?.email != curr.usersProfile?.email ||
            prev.horseProfile?.id != curr.horseProfile?.id,
        listener: (context, nextAppState) {
          final nextSubject = nextAppState.isForRider
              ? SkillSubject.rider
              : SkillSubject.horse;
          final nextProfileDocId = _profileDocIdFor(nextAppState, nextSubject);
          if (_suppressNextSubjectSwitch) {
            _suppressNextSubjectSwitch = false;
            _cubit.syncProfile(
              subject: nextSubject,
              profileDocId: nextProfileDocId,
            );
            return;
          }
          setState(() => _mobileShowingDetail = false);
          _cubit.switchProfileContext(
            subject: nextSubject,
            profileDocId: nextProfileDocId,
          );
          _syncLocalHistoryEntry();
        },
        child: BlocConsumer<SkillTreeV2Cubit, SkillTreeV2State>(
          listenWhen: (prev, curr) =>
              (prev.actionMessage != curr.actionMessage &&
                  curr.actionMessage != null) ||
              prev.selectedSkillId != curr.selectedSkillId,
          listener: (context, state) {
            final msg = state.actionMessage;
            if (msg != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
              _cubit.clearActionMessage();
            }
            if (state.selectedSkillId != _lastSelectedSkillId) {
              _lastSelectedSkillId = state.selectedSkillId;
              if (state.selectedSkillId != null) {
                _resetDetailScrollToTop();
              }
            }
          },
          builder: (context, state) {
            final contextSubject = appState.isForRider
                ? SkillSubject.rider
                : SkillSubject.horse;
            final profileDocId = _profileDocIdFor(appState, contextSubject);
            if (!state.isLoading &&
                state.skills.isNotEmpty &&
                _pendingInitialSkillId != null) {
              final appCubitRef = context.read<AppCubit>();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _applyPendingInitialSkillIfReady(appCubitRef, _cubit.state);
                }
              });
            } else if (contextSubject != state.subject) {
              final appCubitRef = context.read<AppCubit>();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _pendingInitialSkillId != null) return;
                final liveSubject = appCubitRef.state.isForRider
                    ? SkillSubject.rider
                    : SkillSubject.horse;
                if (liveSubject != _cubit.state.subject) {
                  _cubit.switchProfileContext(
                    subject: liveSubject,
                    profileDocId: _profileDocIdFor(
                      appCubitRef.state,
                      liveSubject,
                    ),
                  );
                }
              });
            } else {
              _cubit.syncProfile(
                subject: contextSubject,
                profileDocId: profileDocId,
              );
            }

            final isRiderSubject = contextSubject == SkillSubject.rider;
            final rider = appState.isViewing
                ? appState.viewingProfile
                : appState.usersProfile;
            final horse = appState.horseProfile;
            final profileLabel = isRiderSubject ? rider?.name : horse?.name;

            final userEmailLower = appState.usersProfile?.email.toLowerCase();
            final isHorseOwner =
                horse != null &&
                userEmailLower != null &&
                horse.currentOwnerId.toLowerCase() == userEmailLower;
            final canSelfAssess =
                !appState.isGuest &&
                profileDocId != null &&
                profileDocId.isNotEmpty &&
                (isRiderSubject
                    ? !appState.isViewing
                    : isHorseOwner && !horse.isArchived);

            final selfAssessDisabledReason = canSelfAssess
                ? null
                : appState.isGuest
                ? 'Sign in to record self-assessments.'
                : isRiderSubject && appState.isViewing
                ? 'Viewing another rider profile (read-only self-assessment).'
                : !isRiderSubject && horse == null
                ? 'Select or add a horse profile to record Horse progress.'
                : !isRiderSubject && horse != null && horse.isArchived
                ? 'Archived horses are read-only.'
                : !isRiderSubject && !isHorseOwner
                ? 'Only the horse owner can record self-assessments.'
                : 'Select a profile to record progress.';

            final coachingLink = _activeCoachingLink(
              appState,
              connectionState,
              state.subject,
            );
            final canVerify =
                coachingLink != null ||
                (widget.enableLocalInstructorPreview &&
                    _cubit.isInMemoryStore &&
                    profileDocId != null);

            final isWide = MediaQuery.sizeOf(context).width >= 900;
            final isVerifiedAdmin = _isVerifiedAdmin(appState);
            final isAdminEditActive = isVerifiedAdmin && _isAdminEditMode;
            final publishedState = state;
            final effectiveState = _effectiveState(publishedState);
            final isSelectedSkillRetired =
                effectiveState.selectedSkill?.status ==
                CurriculumSkillStatus.retired;
            final effectiveCanSelfAssess =
                canSelfAssess && !isSelectedSkillRetired;
            final effectiveSelfAssessDisabledReason = isSelectedSkillRetired
                ? 'This skill has been retired. Historical progress is preserved.'
                : selfAssessDisabledReason;
            final effectiveCanVerify = canVerify && !isSelectedSkillRetired;
            GuestSpotlightTour.activeDifficultySkillId =
                effectiveState.selectedSkill?.id;
            SkillTreeSpotlightTour.activeSkillId =
                effectiveState.selectedSkill?.id;
            final appCubit = context.read<AppCubit>();
            bool canEditResourceFn(Resource resource) =>
                !appState.isGuest &&
                appState.usersProfile != null &&
                appCubit.canEditResource(resource);
            Future<void> editResourceFn(Resource resource) async {
              final profile = appState.usersProfile;
              if (profile == null) return;
              await showAppGlassDialog<void>(
                context: context,
                builder: (_) => CreateResourcDialog(
                  skills: appState.allSkills,
                  userProfile: profile,
                  resource: resource,
                ),
              );
            }

            Future<void> linkResourceSkillsFn(Resource resource) async {
              await showAppGlassDialog<void>(
                context: context,
                builder: (_) => UpdateResourceSkills(resource: resource),
              );
            }

            final Widget body;
            if (publishedState.isLoading) {
              body = const Center(child: CircularProgressIndicator());
            } else if (publishedState.errorMessage != null) {
              body = Center(child: Text(publishedState.errorMessage!));
            } else {
              final topChrome = <Widget>[
                if (_cubit.isInMemoryStore)
                  Container(
                    key: const Key('skillTreeV2PreviewBanner'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMd,
                      vertical: AppTokens.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science_outlined, size: 18),
                        const SizedBox(width: AppTokens.spaceSm),
                        Expanded(
                          child: Text(
                            'Preview mode: Assessments are stored locally '
                            'for this session and are not saved to your '
                            'account.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isVerifiedAdmin && (_isAdminEditMode || _draft != null))
                  _buildAdminDraftBanner(
                    context,
                    publishedState,
                    effectiveState,
                  ),
                SkillTreeV2Header(
                  state: effectiveState,
                  hasHorseProfile: horse != null,
                  profileLabel: profileLabel,
                  onSelectRealm: (realm) {
                    setState(() => _mobileShowingDetail = false);
                    _cubit.selectRealm(realm);
                    _syncLocalHistoryEntry();
                  },
                  onSelectViewMode: (mode) {
                    setState(() => _mobileShowingDetail = false);
                    _cubit.setViewMode(mode);
                    _syncLocalHistoryEntry();
                  },
                  onSearchChanged: (query) {
                    setState(() => _mobileShowingDetail = false);
                    _cubit.setSearchQuery(query);
                    _syncLocalHistoryEntry();
                  },
                ),
                if (!isRiderSubject &&
                    horse == null &&
                    !appState.isGuest &&
                    appState.usersProfile != null)
                  _buildHorseSelectorBanner(
                    context,
                    userProfile: appState.usersProfile!,
                    onSelectHorse: (horseId) =>
                        appCubit.getHorseProfile(id: horseId),
                  ),
              ];

              if (isWide &&
                  effectiveState.viewMode == SkillTreeV2ViewMode.browse) {
                body = RepaintBoundary(
                  child: Padding(
                    key: const Key('skillTreeV2View'),
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppTokens.spaceMd,
                          children: [
                            ...topChrome,
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: AppTokens.spaceMd,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SingleChildScrollView(
                                      key: const Key('skillTreeV2ListScroll'),
                                      controller: _listScrollController,
                                      child: SkillFamilyListV2(
                                        state: effectiveState,
                                        isAdminEditMode: isAdminEditActive,
                                        onSelectSkill: (skill) =>
                                            _cubit.selectSkill(skill.id),
                                        onToggleFamily:
                                            _cubit.toggleFamilyExpanded,
                                        onEditFamily: (family) =>
                                            _addOrEditFamily(
                                              effectiveState,
                                              initial: family,
                                            ),
                                        onAddSkillToFamily: (family) =>
                                            _addOrEditSkill(
                                              effectiveState,
                                              family: family,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: SingleChildScrollView(
                                      key: const Key('skillTreeV2DetailScroll'),
                                      controller: _detailScrollController,
                                      child: ClipRect(
                                        child: AnimatedSwitcher(
                                          duration: AppTokens.motionDuration(
                                            context,
                                            const Duration(milliseconds: 220),
                                          ),
                                          reverseDuration:
                                              AppTokens.motionDuration(
                                                context,
                                                const Duration(
                                                  milliseconds: 160,
                                                ),
                                              ),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeOutCubic,
                                          layoutBuilder: (current, previous) =>
                                              Stack(
                                                alignment: Alignment.topCenter,
                                                children: [
                                                  ...previous,
                                                  ?current,
                                                ],
                                              ),
                                          transitionBuilder:
                                              (child, animation) {
                                                final slide = Tween<Offset>(
                                                  begin: const Offset(0.03, 0),
                                                  end: Offset.zero,
                                                ).animate(animation);
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: slide,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                          child:
                                              effectiveState.selectedSkill ==
                                                  null
                                              ? const AppSurfaceCard(
                                                  key: ValueKey(
                                                    'desktopDetail_empty',
                                                  ),
                                                  child: Text(
                                                    'Select a skill to see '
                                                    'what you should be able '
                                                    'to demonstrate.',
                                                  ),
                                                )
                                              : KeyedSubtree(
                                                  key: ValueKey(
                                                    'desktopDetail_'
                                                    '${effectiveState.selectedSkill!.id}',
                                                  ),
                                                  child: SkillDetailV2Panel(
                                                    state: effectiveState,
                                                    skill: effectiveState
                                                        .selectedSkill!,
                                                    allResources:
                                                        appState.resources,
                                                    canSelfAssess:
                                                        effectiveCanSelfAssess,
                                                    selfAssessDisabledReason:
                                                        effectiveSelfAssessDisabledReason,
                                                    canVerify:
                                                        effectiveCanVerify,
                                                    isAdminEditMode:
                                                        isAdminEditActive,
                                                    onEditSkill: () {
                                                      final selected =
                                                          effectiveState
                                                              .selectedSkill!;
                                                      final family =
                                                          effectiveState
                                                              .families
                                                              .firstWhere(
                                                                (f) =>
                                                                    f.id ==
                                                                    selected
                                                                        .familyId,
                                                              );
                                                      _addOrEditSkill(
                                                        effectiveState,
                                                        family: family,
                                                        initial: selected,
                                                      );
                                                    },
                                                    canEditResource:
                                                        canEditResourceFn,
                                                    onEditResource:
                                                        editResourceFn,
                                                    onLinkResourceSkills:
                                                        linkResourceSkillsFn,
                                                    onSelectLevel:
                                                        _cubit.selectLevel,
                                                    onSelfAssess: (level, nextState) {
                                                      if (profileDocId ==
                                                          null) {
                                                        return;
                                                      }
                                                      _cubit.setSelfAssessment(
                                                        skillId: effectiveState
                                                            .selectedSkill!
                                                            .id,
                                                        level: level,
                                                        levelState: nextState,
                                                        profileDocId:
                                                            profileDocId,
                                                        actorUid:
                                                            appState.user.id,
                                                        actorName: appState
                                                            .usersProfile
                                                            ?.name,
                                                      );
                                                    },
                                                    onVerifyLevel:
                                                        (
                                                          level, {
                                                          required verified,
                                                        }) => _handleVerifyLevel(
                                                          context: context,
                                                          skill: effectiveState
                                                              .selectedSkill!,
                                                          level: level,
                                                          verified: verified,
                                                          coachingLink:
                                                              coachingLink,
                                                          profileDocId:
                                                              profileDocId,
                                                          appState: appState,
                                                        ),
                                                    onSelectRelatedSkill:
                                                        (id) => _cubit
                                                            .selectSkill(id),
                                                    onChangeResourceSort:
                                                        _cubit.setResourceSort,
                                                    onSuggestForSkill: () async {
                                                      final created = await showSuggestImprovementDialog(
                                                        context,
                                                        subject: effectiveState
                                                            .subject,
                                                        realm: effectiveState
                                                            .selectedSkill!
                                                            .realm,
                                                        familyId: effectiveState
                                                            .selectedSkill!
                                                            .familyId,
                                                        targetSkill:
                                                            effectiveState
                                                                .selectedSkill,
                                                        targetLevel: effectiveState
                                                            .effectiveSelectedLevel,
                                                      );
                                                      if (created != null &&
                                                          context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Suggestion submitted '
                                                              'for review. Thank you!',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                body = RepaintBoundary(
                  child: SingleChildScrollView(
                    key: const Key('skillTreeV2View'),
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppTokens.spaceMd,
                          children: [
                            ...topChrome,
                            if (effectiveState.viewMode ==
                                SkillTreeV2ViewMode.summary)
                              AbilitySummaryV2View(
                                state: effectiveState,
                                profileLabel: profileLabel,
                                canVerify: canVerify,
                                onBrowseRealm: (realm) {
                                  setState(() => _mobileShowingDetail = false);
                                  _cubit.selectRealm(realm);
                                  _syncLocalHistoryEntry();
                                },
                                onExploreSkills: () {
                                  setState(() => _mobileShowingDetail = false);
                                  _cubit.setViewMode(
                                    SkillTreeV2ViewMode.browse,
                                  );
                                  _syncLocalHistoryEntry();
                                },
                                onSelectSkill: (skill, level) {
                                  _cubit.openSkillInExplore(
                                    skill,
                                    level: level,
                                  );
                                  if (!isWide) {
                                    _openMobileDetail(skill.id, level: level);
                                  } else {
                                    _syncLocalHistoryEntry();
                                  }
                                },
                                onOpenReviewVerifications: canVerify
                                    ? () {
                                        setState(
                                          () => _mobileShowingDetail = false,
                                        );
                                        _cubit.setViewMode(
                                          SkillTreeV2ViewMode.matrix,
                                        );
                                        _syncLocalHistoryEntry();
                                      }
                                    : null,
                              )
                            else if (effectiveState.viewMode ==
                                    SkillTreeV2ViewMode.matrix &&
                                canVerify)
                              InstructorAbilityMatrixV2View(
                                state: effectiveState,
                                canVerify: canVerify,
                                onBackToMySkills: () {
                                  setState(() => _mobileShowingDetail = false);
                                  _cubit.setViewMode(
                                    SkillTreeV2ViewMode.summary,
                                  );
                                  _syncLocalHistoryEntry();
                                },
                                onChangeFilter: _cubit.setMatrixFilter,
                                onSelectCell: (skill, level) {
                                  if (!isWide) {
                                    _openMobileDetail(skill.id, level: level);
                                  } else {
                                    _cubit.selectSkill(skill.id, level: level);
                                    _syncLocalHistoryEntry();
                                  }
                                },
                                onVerifyCell:
                                    (skill, level, {required verified}) =>
                                        _handleVerifyLevel(
                                          context: context,
                                          skill: skill,
                                          level: level,
                                          verified: verified,
                                          coachingLink: coachingLink,
                                          profileDocId: profileDocId,
                                          appState: appState,
                                        ),
                              )
                            else
                              ClipRect(
                                child: AnimatedSwitcher(
                                  duration: AppTokens.motionDuration(
                                    context,
                                    const Duration(milliseconds: 230),
                                  ),
                                  reverseDuration: AppTokens.motionDuration(
                                    context,
                                    const Duration(milliseconds: 200),
                                  ),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeOutCubic,
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: Alignment.topCenter,
                                    children: [...previous, ?current],
                                  ),
                                  transitionBuilder: (child, animation) {
                                    final isDetail = child.key
                                        .toString()
                                        .contains('mobileDetail_');
                                    final slide = Tween<Offset>(
                                      begin: Offset(isDetail ? 0.22 : -0.10, 0),
                                      end: Offset.zero,
                                    ).animate(animation);
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: slide,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child:
                                      _mobileShowingDetail &&
                                          effectiveState.selectedSkill != null
                                      ? KeyedSubtree(
                                          key: ValueKey(
                                            'mobileDetail_'
                                            '${effectiveState.selectedSkill!.id}',
                                          ),
                                          child: SkillDetailV2Panel(
                                            state: effectiveState,
                                            skill:
                                                effectiveState.selectedSkill!,
                                            allResources: appState.resources,
                                            canSelfAssess:
                                                effectiveCanSelfAssess,
                                            selfAssessDisabledReason:
                                                effectiveSelfAssessDisabledReason,
                                            canVerify: effectiveCanVerify,
                                            isAdminEditMode: isAdminEditActive,
                                            onEditSkill: () {
                                              final selected =
                                                  effectiveState.selectedSkill!;
                                              final family = effectiveState
                                                  .families
                                                  .firstWhere(
                                                    (f) =>
                                                        f.id ==
                                                        selected.familyId,
                                                  );
                                              _addOrEditSkill(
                                                effectiveState,
                                                family: family,
                                                initial: selected,
                                              );
                                            },
                                            canEditResource: canEditResourceFn,
                                            onEditResource: editResourceFn,
                                            onLinkResourceSkills:
                                                linkResourceSkillsFn,
                                            onBack: () =>
                                                _handleAppBarBack(context),
                                            onSelectLevel: _cubit.selectLevel,
                                            onSelfAssess: (level, nextState) {
                                              if (profileDocId == null) return;
                                              _cubit.setSelfAssessment(
                                                skillId: effectiveState
                                                    .selectedSkill!
                                                    .id,
                                                level: level,
                                                levelState: nextState,
                                                profileDocId: profileDocId,
                                                actorUid: appState.user.id,
                                                actorName:
                                                    appState.usersProfile?.name,
                                              );
                                            },
                                            onVerifyLevel:
                                                (
                                                  level, {
                                                  required verified,
                                                }) => _handleVerifyLevel(
                                                  context: context,
                                                  skill: effectiveState
                                                      .selectedSkill!,
                                                  level: level,
                                                  verified: verified,
                                                  coachingLink: coachingLink,
                                                  profileDocId: profileDocId,
                                                  appState: appState,
                                                ),
                                            onSelectRelatedSkill: (id) =>
                                                _cubit.selectSkill(id),
                                            onChangeResourceSort:
                                                _cubit.setResourceSort,
                                            onSuggestForSkill: () async {
                                              final created =
                                                  await showSuggestImprovementDialog(
                                                    context,
                                                    subject:
                                                        effectiveState.subject,
                                                    realm: effectiveState
                                                        .selectedSkill!
                                                        .realm,
                                                    familyId: effectiveState
                                                        .selectedSkill!
                                                        .familyId,
                                                    targetSkill: effectiveState
                                                        .selectedSkill,
                                                    targetLevel: effectiveState
                                                        .effectiveSelectedLevel,
                                                  );
                                              if (created != null &&
                                                  context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Suggestion submitted '
                                                      'for review. Thank you!',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        )
                                      : KeyedSubtree(
                                          key: const ValueKey(
                                            'mobileFamilyList',
                                          ),
                                          child: SkillFamilyListV2(
                                            state: effectiveState,
                                            isAdminEditMode: isAdminEditActive,
                                            onSelectSkill: (skill) =>
                                                _openMobileDetail(skill.id),
                                            onToggleFamily:
                                                _cubit.toggleFamilyExpanded,
                                            onEditFamily: (family) =>
                                                _addOrEditFamily(
                                                  effectiveState,
                                                  initial: family,
                                                ),
                                            onAddSkillToFamily: (family) =>
                                                _addOrEditSkill(
                                                  effectiveState,
                                                  family: family,
                                                ),
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            }

            return Scaffold(
              appBar: ThemedAppBar(
                leading: BackButton(
                  key: const Key('skillTreeV2AppBarBackButton'),
                  onPressed: () => _handleAppBarBack(context),
                ),
                title: const Text('Skill Tree'),
                actions: [
                  ValueListenableBuilder<bool>(
                    valueListenable: SkillTreeSpotlightTour.isTourActive,
                    builder: (context, tourActive, child) => KeyedSubtree(
                      key: tourActive
                          ? SkillTreeSpotlightTour.overflowMenuKey
                          : null,
                      child: child!,
                    ),
                    child: PopupMenuButton<String>(
                      key: const Key('skillTreeV2AppBarOverflowMenu'),
                    tooltip: 'More options',
                    onSelected: (value) async {
                      if (value == 'share_skill' &&
                          effectiveState.selectedSkill != null) {
                        final skill = effectiveState.selectedSkill!;
                        await shareAppLink(
                          context,
                          title: "${skill.name} — Horse & Rider's Companion",
                          dialogTitle: 'Share Skill',
                          url: buildSkillShareUrl(skill.id),
                        );
                      } else if (value == 'suggest') {
                        final created = await showSuggestImprovementDialog(
                          context,
                          subject: effectiveState.subject,
                          realm: effectiveState.realm,
                        );
                        if (created != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Suggestion submitted for review. Thank you!',
                              ),
                            ),
                          );
                        }
                      } else if (value == 'my_suggestions') {
                        await showMySuggestionsDialog(context);
                      } else if (value == 'admin_edit_draft' &&
                          isVerifiedAdmin) {
                        await _toggleAdminEditMode(publishedState);
                      }
                    },
                    itemBuilder: (context) => [
                      if (effectiveState.selectedSkill != null)
                        const PopupMenuItem<String>(
                          key: Key('skillTreeV2MenuShareSkill'),
                          value: 'share_skill',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share_outlined, size: 18),
                              SizedBox(width: AppTokens.spaceSm),
                              Flexible(child: Text('Share Skill')),
                            ],
                          ),
                        ),
                      if (!(_mobileShowingDetail &&
                          effectiveState.selectedSkill != null))
                        const PopupMenuItem<String>(
                          key: Key('skillTreeV2MenuSuggestImprovement'),
                          value: 'suggest',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 18),
                              SizedBox(width: AppTokens.spaceSm),
                              Flexible(child: Text('Suggest an Improvement')),
                            ],
                          ),
                        ),
                      if (!appState.isGuest && appState.user.emailVerified)
                        const PopupMenuItem<String>(
                          key: Key('skillTreeV2MenuMySuggestions'),
                          value: 'my_suggestions',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_edu_outlined, size: 18),
                              SizedBox(width: AppTokens.spaceSm),
                              Flexible(child: Text('My Suggestions')),
                            ],
                          ),
                        ),
                      if (isVerifiedAdmin)
                        PopupMenuItem<String>(
                          key: const Key('skillTreeV2MenuAdminEditDraft'),
                          value: 'admin_edit_draft',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAdminEditMode
                                    ? Icons.edit_off_outlined
                                    : Icons.edit_note_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: AppTokens.spaceSm),
                              Flexible(
                                child: Text(
                                  _isAdminEditMode
                                      ? 'Exit Curriculum Draft Mode'
                                      : 'Edit Curriculum (Draft)',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  ),
                ],
              ),
              body: AppScaffoldBackdrop(child: body),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorseSelectorBanner(
    BuildContext context, {
    required RiderProfile userProfile,
    required void Function(String horseId) onSelectHorse,
  }) {
    final theme = Theme.of(context);
    final horsesById = <String, BaseListItem>{};
    for (final item in <BaseListItem>[
      ...?userProfile.ownedHorses,
      ...?userProfile.studentHorses,
    ]) {
      final id = item.id?.trim() ?? '';
      if (id.isNotEmpty) {
        horsesById.putIfAbsent(id, () => item);
      }
    }
    final horses = horsesById.values.toList();

    return AppSurfaceCard(
      key: const Key('skillTreeHorseSelectorCard'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  horses.isEmpty
                      ? 'Add a horse profile to track Horse skills'
                      : 'Select a horse to track Horse skills',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppOutlinedButton(
                key: const Key('skillTreeAddHorseButton'),
                icon: Icons.add,
                label: 'Add Horse',
                onPressed: () {
                  showAppGlassDialog<void>(
                    context: context,
                    builder: (_) => AddHorseDialog(
                      editProfile: false,
                      userProfile: userProfile,
                      horseProfile: null,
                    ),
                  );
                },
              ),
            ],
          ),
          if (horses.isEmpty) ...[
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              'You can browse all Horse skills now, or add a horse to record progress and training milestones.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppTokens.spaceSm),
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceXs,
              children: horses
                  .map(
                    (horseItem) => ActionChip(
                      key: Key('skillTreeSelectHorse_${horseItem.id}'),
                      avatar: const Icon(Icons.pets_outlined, size: 16),
                      label: Text(horseItem.name ?? 'Horse'),
                      onPressed: () => onSelectHorse(horseItem.id!),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
