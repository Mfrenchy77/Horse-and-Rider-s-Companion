import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/adaptive_app_bar_actions.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Administration/cubit/administration_suggestions_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_export_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_revision_dialogs.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/incorporate_suggestion_dialog.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

/// Role-gated Administration section housing the Skill Tree Suggestions inbox.
class AdministrationPage extends StatefulWidget {
  /// Creates an [AdministrationPage].
  const AdministrationPage({
    super.key,
    this.repository,
    this.draftRepository,
    this.skillTreeRepository,
    this.enableCurriculumPublishing = kEnableCurriculumPublishing,
  });

  /// Route name.
  static const String name = 'Administration';

  /// Relative GoRouter path under `/Profile`.
  static const String path = 'Administration';

  /// Optional repository override for widget tests.
  final SkillTreeSuggestionsRepository? repository;

  /// Optional draft/revision repository override for widget tests.
  final SkillTreeDraftRepository? draftRepository;

  /// Optional live Skill Tree repository override for widget tests.
  final SkillTreeV2Repository? skillTreeRepository;

  /// Whether curriculum publishing/recovery/restore actions are enabled.
  final bool enableCurriculumPublishing;

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  late final AdministrationSuggestionsCubit _cubit;
  bool _mobileShowingDetail = false;
  CurriculumPublicationStatus _publicationStatus =
      CurriculumPublicationStatus.idle;
  bool _isRecoveryBusy = false;

  SkillTreeSuggestionsRepository _resolveRepo() {
    if (widget.repository != null) return widget.repository!;
    try {
      return context.read<SkillTreeSuggestionsRepository>();
    } catch (_) {
      return SkillTreeSuggestionsRepository();
    }
  }

  SkillTreeDraftRepository? _resolveDraftRepo() {
    if (widget.draftRepository != null) return widget.draftRepository;
    try {
      return context.read<SkillTreeDraftRepository?>();
    } catch (_) {
      return null;
    }
  }

  SkillTreeV2Repository? _resolveSkillTreeRepo() {
    if (widget.skillTreeRepository != null) return widget.skillTreeRepository;
    try {
      return context.read<SkillTreeV2Repository?>();
    } catch (_) {
      return null;
    }
  }

  void _invalidateSkillTreeCache() {
    final store = _resolveSkillTreeRepo()?.store;
    if (store is FirestoreSkillTreeV2Store) {
      store.invalidateCache();
    } else if (store is HybridCurriculumSkillTreeV2Store) {
      store.invalidateCache();
    }
  }

  Future<void> _loadPublicationStatus() async {
    final appState = context.read<AppCubit>().state;
    if (!appState.isAdmin) return;
    final draftRepo = _resolveDraftRepo();
    if (draftRepo == null) return;
    try {
      final status = await draftRepo.fetchPublicationStatus();
      if (!mounted) return;
      setState(() => _publicationStatus = status);
    } catch (_) {
      // Non-blocking status check for recovery banner.
    }
  }

  Future<void> _resumeInterruptedPublication() async {
    final draftRepo = _resolveDraftRepo();
    if (draftRepo == null) return;
    setState(() => _isRecoveryBusy = true);
    try {
      final revision = await draftRepo.publishDraft(
        resumeFailedPublication: true,
      );
      _invalidateSkillTreeCache();
      await _loadPublicationStatus();
      if (!mounted) return;
      setState(() => _isRecoveryBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resumed and completed Curriculum Revision '
            '#${revision.revisionNumber}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecoveryBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resume publication: $e')),
      );
    }
  }

  Future<void> _discardInterruptedPublication() async {
    final draftRepo = _resolveDraftRepo();
    if (draftRepo == null) return;
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        title: const Text('Discard Unpublished Changes?'),
        content: const Text(
          'This clears the interrupted publication attempt. The live Skill '
          'Tree and your saved curriculum draft remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDiscardInterruptedPublicationButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard Unpublished Changes'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _isRecoveryBusy = true);
    try {
      await draftRepo.discardFailedPublication();
      await _loadPublicationStatus();
      if (!mounted) return;
      setState(() => _isRecoveryBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interrupted publication attempt discarded.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecoveryBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not discard publication: $e')),
      );
    }
  }

  Future<({List<SkillFamily> families, List<CurriculumSkill> skills})>
  _loadLiveCurriculum() async {
    final skillTreeRepo = _resolveSkillTreeRepo();
    if (skillTreeRepo == null) {
      return (
        families: const <SkillFamily>[],
        skills: const <CurriculumSkill>[],
      );
    }
    try {
      final results = await Future.wait([
        skillTreeRepo.fetchFamilies(),
        skillTreeRepo.fetchSkills(),
      ]);
      return (
        families: results[0] as List<SkillFamily>,
        skills: results[1] as List<CurriculumSkill>,
      );
    } catch (_) {
      return (
        families: const <SkillFamily>[],
        skills: const <CurriculumSkill>[],
      );
    }
  }

  Future<void> _openRevisionHistory() async {
    final draftRepo = _resolveDraftRepo();
    if (draftRepo == null) return;
    final live = await _loadLiveCurriculum();
    if (!mounted) return;
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => CurriculumRevisionHistoryDialog(
        draftRepository: draftRepo,
        currentFamilies: live.families,
        currentSkills: live.skills,
        publishingEnabled: widget.enableCurriculumPublishing,
        onRestored: (_) {
          _invalidateSkillTreeCache();
          _loadPublicationStatus();
        },
      ),
    );
  }

  Future<void> _openDownloadCurriculum() async {
    final live = await _loadLiveCurriculum();
    if (!mounted) return;
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => CurriculumExportDialog(
        families: live.families,
        skills: live.skills,
      ),
    );
  }

  Future<void> _incorporateSelected(
    SkillTreeSuggestion suggestion,
  ) async {
    final draftRepo = _resolveDraftRepo();
    if (draftRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Curriculum draft service is not available.'),
        ),
      );
      return;
    }
    final live = await _loadLiveCurriculum();
    if (!mounted) return;
    final result = await showAppGlassDialog<IncorporateSuggestionResult>(
      context: context,
      builder: (_) => IncorporateSuggestionDialog(
        suggestion: suggestion,
        draftRepository: draftRepo,
        publishedFamilies: live.families,
        publishedSkills: live.skills,
      ),
    );
    if (result == null || !mounted) return;

    if (result.markIncorporated || result.grantPublicCredit) {
      await _cubit.submitReview(
        SuggestionReviewUpdate(
          suggestionId: suggestion.id,
          status: result.markIncorporated
              ? SuggestionStatus.incorporated
              : null,
          grantPublicCredit: result.grantPublicCredit ? true : null,
          privateNote: result.draftSaved
              ? 'Incorporated into curriculum draft.'
              : null,
        ),
      );
    } else if (result.draftSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saved suggestion changes to curriculum draft (not yet published).',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = AdministrationSuggestionsCubit(repository: _resolveRepo())
      ..loadInbox();
    _loadPublicationStatus();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    if (!appState.canAccessAdministration) {
      return Scaffold(
        appBar: ThemedAppBar(title: const Text('Administration')),
        body: const AppScaffoldBackdrop(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.spaceLg),
              child: Text(
                'Administrator or moderator privileges are required to view '
                'this section.',
              ),
            ),
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AdministrationSuggestionsCubit,
          AdministrationSuggestionsState>(
        listenWhen: (prev, curr) =>
            prev.actionMessage != curr.actionMessage &&
            curr.actionMessage != null,
        listener: (context, state) {
          final msg = state.actionMessage;
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
            _cubit.clearActionMessage();
          }
        },
        builder: (context, state) {
          final isWide =
              MediaQuery.sizeOf(context).width >=
              StringConstants.splitScreenBreakpoint;

          return Scaffold(
            key: const Key('administrationPage'),
            appBar: ThemedAppBar(
              title: Text(
                appState.isAdmin
                    ? 'Administration · Suggestions Inbox'
                    : 'Moderation · Suggestions Inbox',
              ),
              actions: [
                AdaptiveAppBarActions(actions: [
                  if (appState.isAdmin) ...[
                    AdaptiveAppBarAction(
                      key: const Key('adminDownloadCurriculumButton'),
                      label: 'Download Curriculum',
                      onPressed: _openDownloadCurriculum,
                      icon: Icons.download_outlined,
                    ),
                    AdaptiveAppBarAction(
                      key: const Key('adminRevisionHistoryButton'),
                      label: 'Curriculum Revision History',
                      onPressed: _openRevisionHistory,
                      icon: Icons.history_outlined,
                    ),
                    AdaptiveAppBarAction(
                      label: 'Dictionary review',
                      onPressed: () => context.push('/DictionaryReview'),
                      icon: Icons.menu_book_outlined,
                    ),
                  ],
                  AdaptiveAppBarAction(
                    key: const Key('adminRefreshInboxButton'),
                    label: 'Refresh inbox',
                    priority: 2,
                    onPressed: state.isLoading ? null : () {
                      _cubit.loadInbox(statusFilter: state.statusFilter);
                      _loadPublicationStatus();
                    },
                    icon: Icons.refresh,
                  ),
                ]),
              ],
            ),
            body: AppScaffoldBackdrop(
              child: MaxWidthBox(
                maxWidth: 1200,
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppTokens.spaceMd,
                    children: [
                      if (appState.isAdmin &&
                          _publicationStatus.needsAttention)
                        CurriculumPublicationRecoveryBanner(
                          status: _publicationStatus,
                          publishingEnabled: widget.enableCurriculumPublishing,
                          isBusy: _isRecoveryBusy,
                          onResume: _resumeInterruptedPublication,
                          onDiscard: _discardInterruptedPublication,
                        ),
                      _StatusFilterBar(
                        selected: state.statusFilter,
                        onSelect: (status) {
                          setState(() => _mobileShowingDetail = false);
                          _cubit.loadInbox(statusFilter: status);
                        },
                      ),
                      if (state.errorMessage != null)
                        AppSurfaceCard(
                          child: Text(
                            state.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      Expanded(
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: AppTokens.spaceMd,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _SuggestionsListPane(
                                      suggestions: state.suggestions,
                                      selectedId: state.selectedSuggestion?.id,
                                      onSelect: _cubit.selectSuggestion,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: state.selectedSuggestion == null
                                        ? const AppSurfaceCard(
                                            child: Center(
                                              child: Text(
                                                'Select a suggestion '
                                                'to review.',
                                              ),
                                            ),
                                          )
                                        : _SuggestionDetailPane(
                                            suggestion:
                                                state.selectedSuggestion!,
                                            auditEvents: state.auditEvents,
                                            loadingAudit: state.loadingAudit,
                                            isSubmitting: state.isSubmitting,
                                            isAdmin: appState.isAdmin,
                                            currentUid: appState.user.id,
                                            onIncorporateIntoDraft:
                                                appState.isAdmin
                                                ? () => _incorporateSelected(
                                                    state.selectedSuggestion!,
                                                  )
                                                : null,
                                            onSubmitReview:
                                                _cubit.submitReview,
                                          ),
                                  ),
                                ],
                              )
                            : _mobileShowingDetail &&
                                  state.selectedSuggestion != null
                            ? _SuggestionDetailPane(
                                suggestion: state.selectedSuggestion!,
                                auditEvents: state.auditEvents,
                                loadingAudit: state.loadingAudit,
                                isSubmitting: state.isSubmitting,
                                isAdmin: appState.isAdmin,
                                currentUid: appState.user.id,
                                onIncorporateIntoDraft: appState.isAdmin
                                    ? () => _incorporateSelected(
                                        state.selectedSuggestion!,
                                      )
                                    : null,
                                onBack: () => setState(
                                  () => _mobileShowingDetail = false,
                                ),
                                onSubmitReview: _cubit.submitReview,
                              )
                            : _SuggestionsListPane(
                                suggestions: state.suggestions,
                                selectedId: state.selectedSuggestion?.id,
                                onSelect: (s) {
                                  _cubit.selectSuggestion(s);
                                  setState(() => _mobileShowingDetail = true);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onSelect});

  final SuggestionStatus? selected;
  final ValueChanged<SuggestionStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppTokens.spaceXs,
        children: [
          FilterChip(
            key: const Key('adminFilter_all'),
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelect(null),
          ),
          for (final status in SuggestionStatus.values)
            FilterChip(
              key: Key('adminFilter_${status.value}'),
              label: Text(status.label),
              selected: selected == status,
              onSelected: (_) => onSelect(status),
            ),
        ],
      ),
    );
  }
}

class _SuggestionsListPane extends StatelessWidget {
  const _SuggestionsListPane({
    required this.suggestions,
    required this.selectedId,
    required this.onSelect,
  });

  final List<SkillTreeSuggestion> suggestions;
  final String? selectedId;
  final ValueChanged<SkillTreeSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (suggestions.isEmpty) {
      return const AppSurfaceCard(
        child: Center(
          child: Text('No Skill Tree suggestions match this filter.'),
        ),
      );
    }

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          final isSelected = item.id == selectedId;
          return AppSelectionHighlight(
            selected: isSelected,
            child: ListTile(
              key: Key('adminSuggestionTile_${item.id}'),
              selected: isSelected,
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.contributionCategory.label} · '
                '${item.subject} · ${item.submitterName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Chip(
                label: Text(
                  item.status.label,
                  style: theme.textTheme.labelSmall,
                ),
                visualDensity: VisualDensity.compact,
              ),
              onTap: () => onSelect(item),
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionDetailPane extends StatefulWidget {
  const _SuggestionDetailPane({
    required this.suggestion,
    required this.auditEvents,
    required this.loadingAudit,
    required this.isSubmitting,
    required this.isAdmin,
    required this.currentUid,
    required this.onSubmitReview,
    this.onIncorporateIntoDraft,
    this.onBack,
  });

  final SkillTreeSuggestion suggestion;
  final List<SuggestionAuditEvent> auditEvents;
  final bool loadingAudit;
  final bool isSubmitting;
  final bool isAdmin;
  final String currentUid;
  final Future<bool> Function(SuggestionReviewUpdate update) onSubmitReview;
  final VoidCallback? onIncorporateIntoDraft;
  final VoidCallback? onBack;

  @override
  State<_SuggestionDetailPane> createState() => _SuggestionDetailPaneState();
}

class _SuggestionDetailPaneState extends State<_SuggestionDetailPane> {
  late SuggestionStatus _selectedStatus;
  final _publicNoteController = TextEditingController();
  final _privateNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromSuggestion();
  }

  @override
  void didUpdateWidget(covariant _SuggestionDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestion.id != widget.suggestion.id ||
        oldWidget.suggestion.status != widget.suggestion.status) {
      _syncFromSuggestion();
    }
  }

  void _syncFromSuggestion() {
    _selectedStatus = widget.suggestion.status;
    _publicNoteController.text = widget.suggestion.publicResolutionNote ?? '';
    _privateNoteController.clear();
  }

  @override
  void dispose() {
    _publicNoteController.dispose();
    _privateNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveReview({
    String? assignUid,
    bool includeAssign = false,
  }) async {
    final publicText = _publicNoteController.text.trim();
    final privateText = _privateNoteController.text.trim();
    final statusChanged = _selectedStatus != widget.suggestion.status;
    final publicChanged =
        publicText != (widget.suggestion.publicResolutionNote ?? '');

    final ok = await widget.onSubmitReview(
      SuggestionReviewUpdate(
        suggestionId: widget.suggestion.id,
        status: statusChanged ? _selectedStatus : null,
        assignedToUid: assignUid,
        includeAssignedToUid: includeAssign,
        publicResolutionNote: publicText.isEmpty ? null : publicText,
        includePublicResolutionNote: publicChanged,
        privateNote: privateText.isEmpty ? null : privateText,
      ),
    );
    if (ok && mounted) {
      _privateNoteController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.suggestion;
    final availableStatuses = SuggestionStatus.values
        .where((st) => widget.isAdmin || !st.isAdminOnly || st == s.status)
        .toList();

    return AppSurfaceCard(
      key: Key('adminSuggestionDetail_${s.id}'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceMd,
          children: [
            if (widget.onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to inbox'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(s.status.label)),
              ],
            ),
            Wrap(
              spacing: AppTokens.spaceXs,
              runSpacing: AppTokens.spaceXs,
              children: [
                Chip(label: Text(s.contributionCategory.label)),
                Chip(label: Text('Subject: ${s.subject}')),
                Chip(label: Text('Category: ${s.realm}')),
                if (s.targetSkillName != null)
                  Chip(label: Text('Skill: ${s.targetSkillName}')),
                if (s.targetLevel != null)
                  Chip(label: Text('Level: ${s.targetLevel}')),
                if (widget.isAdmin)
                  Chip(
                    label: Text(
                      s.creditConsent
                          ? (s.creditGranted
                                ? 'Contributor credit: Granted'
                                : 'Contributor credit: Opted in')
                          : 'Contributor credit: Not requested',
                    ),
                  ),
              ],
            ),
            Text(
              'Submitted by ${s.submitterName} (${s.submitterEmail})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
            Text(s.description, style: theme.textTheme.bodyMedium),
            if (s.rationale != null && s.rationale!.isNotEmpty) ...[
              Text(
                'Rationale',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(s.rationale!, style: theme.textTheme.bodySmall),
            ],
            if (s.proposedAlias != null && s.proposedAlias!.isNotEmpty)
              Text(
                'Proposed alias/term: ${s.proposedAlias}',
                style: theme.textTheme.bodySmall,
              ),
            const Divider(),
            Text(
              'Staff Review',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!widget.isAdmin)
              Text(
                'Moderator permissions: you can triage, assign, add private '
                'notes, and request clarification. Only administrators can '
                'approve, decline, or publish.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
            DropdownButtonFormField<SuggestionStatus>(
              key: const Key('adminStatusDropdown'),
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Review Status',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final st in availableStatuses)
                  DropdownMenuItem(value: st, child: Text(st.label)),
              ],
              onChanged: widget.isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
            ),
            TextField(
              key: const Key('adminPublicNoteField'),
              controller: _publicNoteController,
              enabled: !widget.isSubmitting,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Public Resolution / Clarification Note',
                hintText: 'Visible to the submitter',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              key: const Key('adminPrivateNoteField'),
              controller: _privateNoteController,
              enabled: !widget.isSubmitting,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Private Staff Note (Admin/Moderator only)',
                hintText: 'Stored in private AuditEvents',
                border: OutlineInputBorder(),
              ),
            ),
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceSm,
              children: [
                if (widget.isAdmin && widget.onIncorporateIntoDraft != null)
                  FilledButton.tonalIcon(
                    key: const Key('adminIncorporateIntoDraftButton'),
                    onPressed: widget.isSubmitting
                        ? null
                        : widget.onIncorporateIntoDraft,
                    icon: const Icon(Icons.playlist_add_outlined),
                    label: const Text('Incorporate into Draft'),
                  ),
                FilledButton.icon(
                  key: const Key('adminSaveReviewButton'),
                  onPressed: widget.isSubmitting ? null : _saveReview,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Review'),
                ),
                OutlinedButton.icon(
                  key: const Key('adminAssignToMeButton'),
                  onPressed: widget.isSubmitting
                      ? null
                      : () => _saveReview(
                            assignUid: s.assignedToUid == widget.currentUid
                                ? null
                                : widget.currentUid,
                            includeAssign: true,
                          ),
                  icon: const Icon(Icons.person_pin_outlined),
                  label: Text(
                    s.assignedToUid == widget.currentUid
                        ? 'Unassign Me'
                        : 'Assign to Me',
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              'Audit History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.loadingAudit)
              const LinearProgressIndicator()
            else if (widget.auditEvents.isEmpty)
              const Text('No audit events recorded yet.')
            else
              for (final event in widget.auditEvents)
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        '${event.type} · ${event.actorName} '
                        '(${event.actorRole})',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (event.fromStatus != null || event.toStatus != null)
                        Text(
                          '${event.fromStatus?.label ?? '—'} → '
                          '${event.toStatus?.label ?? '—'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (event.privateNote != null &&
                          event.privateNote!.isNotEmpty)
                        Text(
                          'Private note: ${event.privateNote}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (event.publicNote != null &&
                          event.publicNote!.isNotEmpty)
                        Text(
                          'Public note: ${event.publicNote}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
