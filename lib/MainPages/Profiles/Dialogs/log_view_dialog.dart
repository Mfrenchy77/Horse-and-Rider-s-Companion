// ignore_for_file: constant_identifier_names

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

/// Horse logbook, including notes and shared entries for this horse.
class LogViewDialog extends StatefulWidget {
  const LogViewDialog({
    super.key,
    required this.name,
    required this.notes,
    required this.isRider,
    required this.appContext,
    this.horseId,
    this.horseProfile,
  });

  final String name;
  final bool isRider;
  final String? horseId;
  final HorseProfile? horseProfile;
  final BuildContext appContext;
  final List<BaseListItem>? notes;

  @override
  LogViewDialogState createState() => LogViewDialogState();
}

class LogViewDialogState extends State<LogViewDialog> {
  LogTag? _category;
  bool _newestFirst = true;
  String _query = '';

  String? _historyUid;
  Future<List<BaseListItem>>? _history;

  Future<List<BaseListItem>>? _historyFor(
    BuildContext context,
    AppState state,
  ) {
    final uid = state.isGuest ? null : state.user.id;
    if (_historyUid != uid) {
      _historyUid = uid;
      _history = uid == null || uid.isEmpty || widget.horseId == null
          ? null
          : (context.read<LogbookConnectionRepository?>() ??
                    context.read<ConnectionRepository?>())
                ?.history({
                  'action': 'horseHistory',
                  'horseId': widget.horseId,
                });
    }
    return _history;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final horse = state.horseProfile;
    final rider = state.usersProfile;
    final currentHorse = widget.horseId != null && horse?.id == widget.horseId
        ? horse
        : null;
    final notes = [
      ...?(currentHorse == null ? widget.notes : currentHorse.notes),
      if (!state.isGuest &&
          rider != null &&
          currentHorse?.currentOwnerId.toLowerCase() ==
              rider.email.toLowerCase())
        ...?rider.notes?.where(
          (note) => note.riderLog?.horseId == widget.horseId,
        ),
    ];

    return FutureBuilder<List<BaseListItem>>(
      future: _historyFor(context, state),
      builder: (context, snapshot) {
        final shared =
            snapshot.connectionState == ConnectionState.done && !state.isGuest
            ? snapshot.data ?? const <BaseListItem>[]
            : const <BaseListItem>[];
        final ids = shared.map((note) => note.id).toSet();
        final entries = [
          ...notes.where((note) => !ids.contains(note.id)),
          ...shared,
        ].where(_matches).toList()..sort(_compareDates);
        final shownHorse = currentHorse ?? widget.horseProfile;
        final canAdd =
            rider != null &&
            !state.isGuest &&
            shownHorse != null &&
            !shownHorse.isArchived &&
            rider.email.toLowerCase() ==
                shownHorse.currentOwnerId.toLowerCase();
        return Scaffold(
          appBar: ThemedAppBar(title: const Text('Horse logbook')),
          floatingActionButton: canAdd
              ? FloatingActionButton(
                  tooltip: 'Add entry',
                  onPressed: () => showAppDialog<void>(
                    context: context,
                    builder: (_) => AddLogEntryDialog(
                      usersProfile: rider,
                      horseProfile: shownHorse,
                    ),
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: _header(context, shownHorse),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(child: _filters()),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(),
                      ),
                    if (_history != null)
                      SliverToBoxAdapter(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _historyUid = null),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(
                            snapshot.hasError
                                ? 'Shared history unavailable. Retry'
                                : 'Refresh shared history',
                          ),
                        ),
                      ),
                    if (entries.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _query.isEmpty && _category == null
                                ? 'No Entries in the Log'
                                : 'No matching entries.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      sliver: SliverList.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) => _entry(entries[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _matches(BaseListItem note) {
    final category = _entryCategory(note);
    return (_category == null || category == _category) &&
        [
          note.name,
          note.message,
          note.extra,
          note.riderLog?.title,
          _categoryLabel(category),
        ].whereType<String>().any(
          (value) => value.toLowerCase().contains(_query),
        );
  }

  int _compareDates(BaseListItem a, BaseListItem b) {
    final first = a.date;
    final second = b.date;
    if (first == null) return second == null ? 0 : 1;
    if (second == null) return -1;
    return _newestFirst ? second.compareTo(first) : first.compareTo(second);
  }

  Widget _header(BuildContext context, HorseProfile? horse) {
    final theme = Theme.of(context);
    final details =
        [
              horse?.breed,
              horse?.gender,
              if (horse?.isArchived ?? false) 'Archived',
            ]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .join(' · ');
    return GradientCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 64,
                child: SmartImage(
                  horse?.picUrl,
                  width: 64,
                  height: 64,
                  fallback: ColoredBox(
                    color: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      HorseAndRiderIcons.horseIcon,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    horse?.name ?? widget.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (details.isNotEmpty) Text(details),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    final search = TextField(
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        labelText: 'Search entries',
        border: OutlineInputBorder(),
      ),
    );
    final sort = DropdownButton<bool>(
      value: _newestFirst,
      onChanged: (value) {
        if (value != null) setState(() => _newestFirst = value);
      },
      items: const [
        DropdownMenuItem(value: true, child: Text('Newest first')),
        DropdownMenuItem(value: false, child: Text('Oldest first')),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final category in [null, ...LogTag.values])
              ChoiceChip(
                label: Text(
                  category == null ? 'All entries' : _categoryLabel(category),
                ),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 420
              ? Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 12),
                    sort,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [search, sort],
                ),
        ),
      ],
    );
  }

  Widget _entry(BaseListItem note) {
    final category = _entryCategory(note);
    final title = note.riderLog?.title?.trim();
    final text = note.name?.trim() ?? '';
    final heading = (title?.isNotEmpty ?? false)
        ? title!
        : text.isEmpty
        ? _categoryLabel(category)
        : text;
    final author = note.message ?? note.parentId ?? '';
    final metadata = [
      _categoryLabel(category),
      if (note.date case final date?) DateFormat.yMMMd().format(date),
      if (note.extra?.isNotEmpty ?? false) 'Rider: ${note.extra}',
      if (note.riderLog?.authorRole case 'instructor' || 'trainer')
        'Added by ${note.riderLog!.authorRole} $author',
    ].join(' · ');
    return LogbookEntryCard(
      title: heading,
      metadata: metadata,
      preview: heading != text && text.isNotEmpty ? text : null,
      icon: switch (category) {
        LogTag.Show => Icons.emoji_events_outlined,
        LogTag.Training => Icons.school_outlined,
        LogTag.Health => Icons.health_and_safety_outlined,
        LogTag.Edit => Icons.history,
        LogTag.Other => Icons.notes,
      },
      onTap: () => showAppDialog<void>(
        context: context,
        builder: (context) => OceanCoralAppDialog(
          title: Text(heading),
          scrollable: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(metadata),
              if (text.isNotEmpty && text != heading) Text(text),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

LogTag _entryCategory(BaseListItem note) => switch (note.riderLog?.type) {
  RiderLogType.lesson || RiderLogType.training => LogTag.Training,
  RiderLogType.care => LogTag.Health,
  RiderLogType.show => LogTag.Show,
  _ => convertStringToLogTag(note.imageUrl),
};

String _categoryLabel(LogTag tag) => switch (tag) {
  LogTag.Show => 'Show',
  LogTag.Training => 'Training',
  LogTag.Health => 'Health',
  LogTag.Other => 'Other',
  LogTag.Edit => 'Activity',
};

/// Enum representing the different log tags
enum LogTag { Show, Training, Health, Other, Edit }

LogTag convertStringToLogTag(String? tag) {
  switch (tag) {
    case 'LogTag.Show':
      return LogTag.Show;
    case 'LogTag.Training':
      return LogTag.Training;
    case 'LogTag.Health':
      return LogTag.Health;
    case 'LogTag.Other':
      return LogTag.Other;
    case 'LogTag.Edit':
      return LogTag.Edit;
    default:
      return LogTag.Other;
  }
}
