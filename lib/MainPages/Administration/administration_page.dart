import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Administration/cubit/administration_suggestions_cubit.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

/// Role-gated Administration section housing the Skill Tree Suggestions inbox.
class AdministrationPage extends StatefulWidget {
  /// Creates an [AdministrationPage].
  const AdministrationPage({super.key, this.repository});

  /// Route name.
  static const String name = 'Administration';

  /// Relative GoRouter path under `/Profile`.
  static const String path = 'Administration';

  /// Optional repository override for widget tests.
  final SkillTreeSuggestionsRepository? repository;

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  late final AdministrationSuggestionsCubit _cubit;
  bool _mobileShowingDetail = false;

  SkillTreeSuggestionsRepository _resolveRepo() {
    if (widget.repository != null) return widget.repository!;
    try {
      return context.read<SkillTreeSuggestionsRepository>();
    } catch (_) {
      return SkillTreeSuggestionsRepository();
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = AdministrationSuggestionsCubit(repository: _resolveRepo())
      ..loadInbox();
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
                IconButton(
                  key: const Key('adminRefreshInboxButton'),
                  tooltip: 'Refresh inbox',
                  onPressed: state.isLoading
                      ? null
                      : () => _cubit.loadInbox(
                            statusFilter: state.statusFilter,
                          ),
                  icon: const Icon(Icons.refresh),
                ),
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
    this.onBack,
  });

  final SkillTreeSuggestion suggestion;
  final List<SuggestionAuditEvent> auditEvents;
  final bool loadingAudit;
  final bool isSubmitting;
  final bool isAdmin;
  final String currentUid;
  final Future<bool> Function(SuggestionReviewUpdate update) onSubmitReview;
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
