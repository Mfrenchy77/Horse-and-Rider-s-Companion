import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_shared_widgets.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/profile_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:intl/intl.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({
    super.key,
    this.rider,
    this.horse,
    this.showRecordActions = true,
  }) : assert((rider == null) != (horse == null), 'Choose one profile.');

  final RiderProfile? rider;
  final HorseProfile? horse;
  final bool showRecordActions;

  static Future<void> openHistory(
    BuildContext context,
    CoachingConnection link,
  ) => showAppGlassDialog<void>(
    context: context,
    builder: (_) => _ConnectionHistory(link: link),
  );

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select((AppCubit c) => c.state.isGuest);
    final profile = context.select((AppCubit c) => c.state.usersProfile);
    final hasConversationsError = context.select(
      (AppCubit c) => c.state.conversationsState == ConversationsState.error,
    );
    final requestActionBusy = context.select(
      (AppCubit c) => c.state.acceptStatus == AcceptStatus.loading,
    );
    final appCubit = context.read<AppCubit>();
    final cubit = context.watch<ConnectionsCubit?>();
    final state = cubit?.state;
    if (isGuest || profile == null || state == null) {
      return const SizedBox.shrink();
    }
    final email = profile.email.toLowerCase();
    final horse = this.horse;
    final rider = this.rider;
    final ownProfile = rider?.email.toLowerCase() == email;
    final horseOwner = horse?.currentOwnerId.toLowerCase() == email;
    final isTrainer = profile.isTrainer ?? false;
    final links = state.email != email
        ? <CoachingConnection>[]
        : state.connections.where((link) {
            if (link.status != 'pending' && link.status != 'accepted') {
              return false;
            }
            if (link.kind == 'transfer' && link.status != 'pending') {
              return false;
            }
            if (horse != null) {
              return link.horseId == horse.id &&
                  link.learner == horse.currentOwnerId.toLowerCase() &&
                  (link.kind == 'transfer'
                      ? horse.transferRequestId == link.id
                      : link.ownershipVersion == horse.ownershipVersion);
            }
            if (ownProfile) return true;
            final viewed = rider!.email.toLowerCase();
            return link.kind == 'rider' &&
                (link.learner == viewed || link.coach == viewed);
          }).toList();
    final linkIds = {for (final link in links) link.id};
    final pendingRequests = ownProfile
        ? appCubit.allPendingConnectionRequests().where((req) {
            final cid = req.connectionId;
            return cid == null || !linkIds.contains(cid);
          }).toList()
        : const <ConnectionRequest>[];
    final pendingConnections = links
        .where((link) => link.status == 'pending' && link.recipient == email)
        .length;
    final incomingRequests = ownProfile
        ? pendingRequests
              .where((req) => req.senderEmail.toLowerCase() != email)
              .length
        : 0;
    final pending = pendingConnections + incomingRequests;
    final requestsError = ownProfile && hasConversationsError;
    final hasProfileRelationships =
        ownProfile &&
        ((rider?.students?.isNotEmpty ?? false) ||
            (rider?.instructors?.isNotEmpty ?? false) ||
            (rider?.studentHorses?.isNotEmpty ?? false));

    final saving = state.actionInProgress;

    final actions = <Widget>[
      if (horse != null &&
          !horse.isArchived &&
          !horseOwner &&
          isTrainer &&
          !links.any((link) => link.kind == 'horse'))
        OutlinedButton(
          onPressed: saving
              ? null
              : () => cubit?.request(coach: profile.email, horseId: horse.id),
          child: const Text('Request to train horse'),
        ),
      if (rider != null &&
          !ownProfile &&
          (rider.isTrainer ?? false) &&
          !links.any((link) => link.learner == email))
        OutlinedButton(
          onPressed: saving
              ? null
              : () =>
                    cubit?.request(learner: profile.email, coach: rider.email),
          child: const Text('Request instructor'),
        ),
      if (rider != null &&
          !ownProfile &&
          isTrainer &&
          !links.any((link) => link.coach == email))
        OutlinedButton(
          onPressed: saving
              ? null
              : () =>
                    cubit?.request(learner: rider.email, coach: profile.email),
          child: const Text('Invite as student'),
        ),
    ];
    if (!ownProfile &&
        actions.isEmpty &&
        links.isEmpty &&
        state.actionFeedback == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ProfileSpotlightTour.isTourActive,
      builder: (context, tourActive, child) => KeyedSubtree(
        key: (ownProfile && tourActive)
            ? ProfileSpotlightTour.connectionsSectionKey
            : null,
        child: child!,
      ),
      child: AppSurfaceCard(
        key: const Key('profileConnectionsSection'),
        padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          AppSectionHeader(
            title: pending == 0
                ? 'Connections and requests'
                : 'Connections and requests ($pending new)',
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Connections could not be loaded.'),
                TextButton(
                  onPressed: cubit!.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          if (requestsError)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Requests could not be loaded.'),
                TextButton(
                  onPressed: appCubit.retryRequests,
                  child: const Text('Retry'),
                ),
              ],
            ),
          if (ownProfile &&
              !state.loading &&
              !state.error &&
              !requestsError &&
              links.isEmpty &&
              pendingRequests.isEmpty)
            Text(
              hasProfileRelationships
                  ? 'No pending requests. Existing students, instructors, '
                        'and student horses appear in your profile lists.'
                  : 'No active connections or pending requests.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
          for (final link in links)
            _connection(context, link, email, saving, cubit!, horse),
          for (final req in pendingRequests)
            _pendingRequest(
              context,
              req,
              email,
              profile.name,
              requestActionBusy,
              appCubit,
            ),
          if (state.actionFeedback != null)
            Semantics(liveRegion: true, child: Text(state.actionFeedback!)),
        ],
      ),
      ),
    );
  }

  Widget _connection(
    BuildContext context,
    CoachingConnection link,
    String email,
    bool saving,
    ConnectionsCubit cubit,
    HorseProfile? horse,
  ) {
    final incoming = link.recipient == email;
    final active = link.status == 'accepted';
    final horseName = link.horseName ?? 'Horse';
    final other = link.otherName(email);
    final requester = link.requesterName;
    final relationship = switch (link.kind) {
      'transfer' => '$horseName ownership transfer',
      'horse' => '$horseName training',
      _ => email == link.coach ? 'Student' : 'Instructor',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        const Divider(),
        Text(
          '$other · $relationship',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          active
              ? 'Accepted'
              : incoming
              ? 'Requested by $requester'
              : 'Awaiting response',
        ),
        if (!active && incoming)
          Text(
            link.kind == 'transfer'
                ? 'Accepting moves this horse and its logbook to your profile.'
                : 'Accepting lets the instructor or trainer add notes '
                      'and update skill progress.',
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (!active && incoming) ...[
              FilledButton(
                onPressed: saving || (horse?.isArchived ?? false)
                    ? null
                    : () => cubit.change(link, 'accept'),
                child: Text(
                  link.kind == 'transfer' ? 'Accept transfer' : 'Accept',
                ),
              ),
              TextButton(
                onPressed: saving ? null : () => cubit.change(link, 'decline'),
                child: const Text('Decline'),
              ),
            ],
            if (!active && !incoming)
              TextButton(
                onPressed: saving ? null : () => cubit.change(link, 'cancel'),
                child: const Text('Cancel request'),
              ),
            if (showRecordActions && active && email == link.coach)
              FilledButton(
                onPressed: saving || (horse?.isArchived ?? false)
                    ? null
                    : () {
                        if (link.kind == 'rider') {
                          RiderLogbookPage.addLessonFor(context, link);
                          return;
                        }
                         showAppGlassDialog<void>(
                           context: context,
                           barrierDismissible: false,
                           builder: (_) => BlocProvider.value(
                             value: cubit,
                             child: _TrainingRecordDialog(link: link),
                           ),
                         );
                      },
                child: Text(
                  link.kind == 'rider'
                      ? 'Add lesson record'
                      : 'Add training record',
                ),
              ),
            if (showRecordActions &&
                active &&
                (email == link.coach || link.kind == 'horse'))
              TextButton(
                onPressed: saving
                    ? null
                    : () => ConnectionPanel.openHistory(context, link),
                child: Text(
                  link.kind == 'rider' ? 'Student logbook' : 'Horse history',
                ),
              ),
            if (active)
              TextButton(
                onPressed: saving ? null : () => cubit.change(link, 'revoke'),
                child: const Text('End connection'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pendingRequest(
    BuildContext context,
    ConnectionRequest req,
    String email,
    String ownName,
    bool busy,
    AppCubit appCubit,
  ) {
    final incoming = req.senderEmail.toLowerCase() != email;
    final otherNames = List<String>.from(req.parties)..remove(ownName);
    final other = otherNames.isNotEmpty
        ? otherNames.join(', ')
        : (incoming ? req.senderName : req.recipientName);
    final roleLabel = switch (req.kind) {
      ConnectionRequestKind.transferHorse =>
        '${req.horseName ?? 'Horse'} ownership transfer',
      ConnectionRequestKind.studentHorse =>
        '${req.horseName ?? 'Horse'} student horse request',
      ConnectionRequestKind.instructor => 'Instructor request',
      ConnectionRequestKind.student => 'Student request',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        const Divider(),
        Text(
          other.isNotEmpty ? '$other · $roleLabel' : roleLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (req.summary.isNotEmpty) Text(req.summary),
        Text(
          incoming ? 'Requested by ${req.senderName}' : 'Awaiting response',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (incoming) ...[
              FilledButton(
                onPressed: busy
                    ? null
                    : () => appCubit.acceptConnectionRequest(req),
                child: Text(
                  req.kind == ConnectionRequestKind.transferHorse
                      ? 'Accept transfer'
                      : 'Accept',
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => appCubit.denyConnectionRequest(req),
                child: const Text('Decline'),
              ),
            ] else
              TextButton(
                onPressed: busy
                    ? null
                    : () => appCubit.denyConnectionRequest(req),
                child: const Text('Cancel request'),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrainingRecordDialog extends StatefulWidget {
  const _TrainingRecordDialog({required this.link});

  final CoachingConnection link;

  @override
  State<_TrainingRecordDialog> createState() => _TrainingRecordDialogState();
}

class _TrainingRecordDialogState extends State<_TrainingRecordDialog> {
  final _recordId = ViewUtils.createId();
  String _notes = '';
  String _highlights = '';
  String _focus = '';
  String _nextSteps = '';
  String _title = '';
  String _videoUrl = '';
  SessionFeel? _feel;
  List<PracticedSkillTag> _practicedSkills = const [];
  bool _takeawaysExpanded = false;
  ({BaseListItem entry, String nextSteps})? _previousNextSteps;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreviousPlan());
  }

  Future<void> _loadPreviousPlan() async {
    try {
      final items = await context.read<ConnectionsCubit>().historyFor(
        widget.link,
      );
      if (!mounted) return;
      final hit = findPreviousNextSteps(items, includeAuthorOnly: false);
      if (hit != null) {
        setState(() => _previousNextSteps = hit);
      }
    } catch (_) {}
  }

  bool get _hasAnyContent =>
      _notes.isNotEmpty ||
      _highlights.isNotEmpty ||
      _focus.isNotEmpty ||
      _nextSteps.isNotEmpty ||
      _title.isNotEmpty ||
      _practicedSkills.isNotEmpty;

  String? _trimmedOrNull(String raw) {
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickSkills() async {
    final picked = await showPracticedSkillsPickerDialog(
      context: context,
      initialSelection: _practicedSkills,
      defaultSubject: widget.link.kind == 'horse'
          ? SkillSubject.horse
          : SkillSubject.rider,
    );
    if (!mounted || picked == null) return;
    setState(() => _practicedSkills = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final video = _trimmedOrNull(_videoUrl);
    if (video != null) {
      final uri = Uri.tryParse(video);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        setState(
          () => _error = 'Enter a valid http:// or https:// video link.',
        );
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cubit = context.read<ConnectionsCubit>();
      final saved = await cubit.recordTraining(
        link: widget.link,
        recordId: _recordId,
        notes: _notes,
        title: _trimmedOrNull(_title),
        feel: _feel,
        highlights: _trimmedOrNull(_highlights),
        focus: _trimmedOrNull(_focus),
        nextSteps: _trimmedOrNull(_nextSteps),
        practicedSkills: _practicedSkills,
        videoUrl: video,
      );
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context);
      } else {
        setState(() {
          _saving = false;
          _error = cubit.state.actionFeedback ?? 'Could not save. Try again.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is ConnectionFailure
            ? error.message
            : 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppGlassDialog(
      title: Text(
        widget.link.kind == 'rider'
            ? 'Add lesson record'
            : 'Add training record',
      ),
      maxWidth: 560,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (_previousNextSteps != null)
            Container(
              key: const Key('trainerPreviousNextStepsBanner'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTokens.accentColor(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    'From last session',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTokens.accentColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _previousNextSteps!.nextSteps,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          TextField(
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Notes'),
            minLines: 3,
            maxLines: 6,
            maxLength: 4000,
            onChanged: (value) => setState(() => _notes = value.trim()),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final feel in SessionFeel.values)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(feel.label),
                  selected: _feel == feel,
                  onSelected: _saving
                      ? null
                      : (sel) => setState(() => _feel = sel ? feel : null),
                ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickSkills,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  _practicedSkills.isEmpty
                      ? 'Tag practiced skills'
                      : 'Edit skills (${_practicedSkills.length})',
                ),
              ),
              for (final tag in _practicedSkills)
                InputChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    tag.levelLabel == null
                        ? tag.skillName
                        : '${tag.skillName} · ${tag.levelLabel}',
                  ),
                  onDeleted: _saving
                      ? null
                      : () => setState(
                          () => _practicedSkills = _practicedSkills
                              .where((s) => s.skillId != tag.skillId)
                              .toList(),
                        ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _takeawaysExpanded = !_takeawaysExpanded),
              icon: Icon(
                _takeawaysExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _takeawaysExpanded
                    ? 'Hide takeaways & video'
                    : 'Add takeaways, next steps, or video (optional)',
              ),
            ),
          ),
          if (_takeawaysExpanded) ...[
            TextField(
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'What went well (optional)',
              ),
              maxLines: 2,
              onChanged: (v) => setState(() => _highlights = v.trim()),
            ),
            TextField(
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'What needs work (optional)',
              ),
              maxLines: 2,
              onChanged: (v) => setState(() => _focus = v.trim()),
            ),
            TextField(
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Plans for next session (optional)',
              ),
              maxLines: 2,
              onChanged: (v) => setState(() => _nextSteps = v.trim()),
            ),
            TextField(
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
              onChanged: (v) => setState(() => _title = v.trim()),
            ),
            TextField(
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Training video link (optional)',
              ),
              keyboardType: TextInputType.url,
              onChanged: (v) => setState(() => _videoUrl = v.trim()),
            ),
          ],
          if (_error != null) Text(_error!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: !_hasAnyContent || _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save record'),
        ),
      ],
    ),
  );
}

class _ConnectionHistory extends StatefulWidget {
  const _ConnectionHistory({required this.link});

  final CoachingConnection link;

  @override
  State<_ConnectionHistory> createState() => _ConnectionHistoryState();
}

class _ConnectionHistoryState extends State<_ConnectionHistory> {
  late Future<List<BaseListItem>> _entries = _load();

  Future<List<BaseListItem>> _load() =>
      context.read<ConnectionsCubit>().historyFor(widget.link);

  Future<void> _editEntry(BaseListItem entry) async {
    if (widget.link.kind == 'rider') {
      await RiderLogbookPage.addLessonFor(
        context,
        widget.link,
        entry: entry,
      );
    } else {
      await RiderLogbookPage.addEntry(
        context,
        horseConnection: widget.link,
        entry: entry,
      );
    }
    if (mounted) {
      setState(() => _entries = _load());
    }
  }

  Future<void> _delete(BaseListItem entry) async {
    final isRiderLink = widget.link.kind == 'rider';
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (context) => AppGlassDialog(
        title: Text(isRiderLink ? 'Delete this lesson?' : 'Delete this entry?'),
        content: const Text('It will be removed from both logbooks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || !(confirmed ?? false)) return;
    try {
      if (isRiderLink) {
        final ok = await context.read<ConnectionsCubit>().deleteLesson(
          link: widget.link,
          entryId: entry.id ?? '',
        );
        if (!ok) throw StateError('delete failed');
      } else {
        final logbookCubit = LogbookCubit(
          connectionRepository:
              context.read<LogbookConnectionRepository?>() ??
              context.read<ConnectionRepository?>(),
          riderProfileRepository:
              context.read<LogbookRiderProfileRepository?>() ??
              context.read<RiderProfileRepository?>(),
        );
        try {
          await logbookCubit.deleteEntry(entry);
        } finally {
          await logbookCubit.close();
        }
      }
      if (mounted) setState(() => _entries = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRiderLink
                  ? 'Could not delete the lesson.'
                  : 'Could not delete the entry.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppGlassDialog(
    title: Text(
      widget.link.kind == 'rider' ? 'Student logbook' : 'Horse history',
    ),
    maxWidth: 620,
    content:
        context.watch<ConnectionsCubit?>()?.state.connections.any(
              (link) =>
                  link.id == widget.link.id &&
                  link.version == widget.link.version &&
                  link.status == 'accepted',
            ) !=
            true
        ? const Text('History unavailable.')
        : SizedBox(
            width: 520,
            child: FutureBuilder<List<BaseListItem>>(
              future: _entries,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: () => setState(() => _entries = _load()),
                    child: const Text('History unavailable. Retry'),
                  );
                }
                final entries = [...?snapshot.data]
                  ..sort(
                    (a, b) => (b.date ?? DateTime(0)).compareTo(
                      a.date ?? DateTime(0),
                    ),
                  );
                if (entries.isEmpty) return const Text('No entries yet.');
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in entries)
                      ListTile(
                        onTap: () async {
                          final editable = entry.isSelected ?? false;
                          final action = await showLogbookEntryDetailDialog(
                            context: context,
                            entry: entry,
                            categoryLabel: entry.riderLogType.label,
                            fallbackTitle:
                                entry.riderLog?.title ?? entry.name ?? 'Entry',
                            riderLabel: entry.extra != null
                                ? 'Rider: ${entry.extra}'
                                : null,
                            attribution: entry.message != null
                                ? 'Recorded by ${entry.message}'
                                : null,
                            canEdit: editable,
                            canDelete: editable,
                          );
                          if (!context.mounted) return;
                          if (action == 'edit') {
                            await _editEntry(entry);
                          } else if (action == 'delete') {
                            await _delete(entry);
                          }
                        },
                        title: Text(
                          entry.riderLog?.title ?? entry.name ?? 'Entry',
                        ),
                        subtitle: Text(
                          [
                            if (entry.riderLog?.title != null &&
                                entry.name != null &&
                                entry.name!.isNotEmpty)
                              entry.name!,
                            if (entry.riderLog?.feel != null)
                              'Feel: ${entry.riderLog!.feel!.label}',
                            if (entry.riderLog != null &&
                                entry.riderLog!.practicedSkills.isNotEmpty)
                              'Skills: ${entry.riderLog!.practicedSkills.map(
                                (s) => s.skillName,
                              ).join(', ')}',
                            if (entry.extra != null) 'Rider: ${entry.extra}',
                            if (entry.message != null)
                              'Recorded by ${entry.message}',
                            if (entry.riderLog?.horse != null)
                              'Horse: ${entry.riderLog!.horse}',
                            if (entry.riderLog?.highlights != null)
                              'Went well: ${entry.riderLog!.highlights}',
                            if (entry.riderLog?.focus != null)
                              'Focus: ${entry.riderLog!.focus}',
                            if (entry.riderLog?.nextSteps != null)
                              'Next: ${entry.riderLog!.nextSteps}',
                            if (entry.date != null)
                              DateFormat.yMMMd().format(entry.date!),
                          ].join('\n'),
                        ),
                        trailing: entry.isSelected ?? false
                            ? PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await _delete(entry);
                                  } else {
                                    await _editEntry(entry);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(
                                      widget.link.kind == 'rider'
                                          ? 'Edit lesson'
                                          : 'Edit entry',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      widget.link.kind == 'rider'
                                          ? 'Delete lesson'
                                          : 'Delete entry',
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                  ],
                );
              },
            ),
          ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
