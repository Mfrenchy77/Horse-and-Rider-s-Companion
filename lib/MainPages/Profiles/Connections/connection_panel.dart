import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({super.key, this.rider, this.horse})
    : assert((rider == null) != (horse == null), 'Choose one profile.');

  final RiderProfile? rider;
  final HorseProfile? horse;

  static Future<void> openHistory(
    BuildContext context,
    CoachingConnection link,
  ) => showAppDialog<void>(
    context: context,
    builder: (_) => _ConnectionHistory(link: link),
  );

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select((AppCubit c) => c.state.isGuest);
    final profile = context.select((AppCubit c) => c.state.usersProfile);
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
    final pending = links
        .where((link) => link.status == 'pending' && link.recipient == email)
        .length;

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

    return GradientCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text(
              pending == 0
                  ? 'Connections and requests'
                  : 'Connections and requests ($pending new)',
              style: Theme.of(context).textTheme.titleMedium,
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
            if (ownProfile && !state.loading && !state.error && links.isEmpty)
              const Text('No active connections or pending requests.'),
            for (final link in links)
              _connection(context, link, email, saving, cubit!, horse),
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
            if (active && email == link.coach)
              FilledButton(
                onPressed: saving || (horse?.isArchived ?? false)
                    ? null
                    : () {
                        if (link.kind == 'rider') {
                          RiderLogbookPage.addLessonFor(context, link);
                          return;
                        }
                        final skills = cubit.skillsFor(link);
                        showAppDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              _TrainingRecordDialog(skills: skills, link: link),
                        );
                      },
                child: Text(
                  link.kind == 'rider'
                      ? 'Add lesson record'
                      : 'Add training record',
                ),
              ),
            if (active && (email == link.coach || link.kind == 'horse'))
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
}

class _TrainingRecordDialog extends StatefulWidget {
  const _TrainingRecordDialog({required this.skills, required this.link});

  final List<Skill> skills;
  final CoachingConnection link;

  @override
  State<_TrainingRecordDialog> createState() => _TrainingRecordDialogState();
}

class _TrainingRecordDialogState extends State<_TrainingRecordDialog> {
  final _recordId = ViewUtils.createId();
  String _notes = '';
  String? _skillId;
  String _level = 'LEARNING';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ConnectionsCubit>().recordTraining(
        link: widget.link,
        recordId: _recordId,
        notes: _notes,
        skillId: _skillId,
        level: _level,
      );
      if (mounted) Navigator.pop(context);
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
    child: OceanCoralAppDialog(
      scrollable: true,
      title: Text(
        widget.link.kind == 'rider'
            ? 'Add lesson record'
            : 'Add training record',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Notes'),
            minLines: 3,
            maxLines: 6,
            maxLength: 4000,
            onChanged: (value) => setState(() => _notes = value.trim()),
          ),
          if (widget.skills.isNotEmpty)
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Skill progress (optional)',
              ),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _skillId = value),
              items: [
                const DropdownMenuItem<String>(child: Text('No skill update')),
                for (final skill in widget.skills)
                  DropdownMenuItem(
                    value: skill.id,
                    child: Text(
                      skill.skillName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          if (_skillId != null)
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Progress'),
              items: const [
                DropdownMenuItem(value: 'LEARNING', child: Text('Learning')),
                DropdownMenuItem(
                  value: 'PROFICIENT',
                  child: Text('Proficient'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _level = value!),
            ),
          if (_error != null) Text(_error!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _notes.isEmpty || _saving ? null : _save,
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

  Future<void> _delete(BaseListItem entry) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => OceanCoralAppDialog(
        title: const Text('Delete this lesson?'),
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
      final ok = await context.read<ConnectionsCubit>().deleteLesson(
        link: widget.link,
        entryId: entry.id ?? '',
      );
      if (!ok) throw StateError('delete failed');
      if (mounted) setState(() => _entries = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the lesson.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => OceanCoralAppDialog(
    scrollable: true,
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
                        title: Text(
                          entry.riderLog?.title ?? entry.name ?? 'Entry',
                        ),
                        subtitle: Text(
                          [
                            if (entry.riderLog?.title != null &&
                                entry.name != null)
                              entry.name!,
                            if (entry.extra != null) 'Rider: ${entry.extra}',
                            if (entry.message != null)
                              'Recorded by ${entry.message}',
                            if (entry.riderLog?.horse != null)
                              'Horse: ${entry.riderLog!.horse}',
                            if (entry.riderLog?.focus != null)
                              'Focus: ${entry.riderLog!.focus}',
                            if (entry.riderLog?.nextSteps != null)
                              'Next: ${entry.riderLog!.nextSteps}',
                            if (entry.date != null)
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(entry.date!),
                          ].join('\n'),
                        ),
                        trailing: entry.isSelected ?? false
                            ? PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await _delete(entry);
                                  } else {
                                    await RiderLogbookPage.addLessonFor(
                                      context,
                                      widget.link,
                                      entry: entry,
                                    );
                                    if (mounted) {
                                      setState(() => _entries = _load());
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit lesson'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete lesson'),
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
