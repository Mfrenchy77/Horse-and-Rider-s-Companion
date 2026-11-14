// ignore_for_file: constant_identifier_names

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_filter_bar.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_hero_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/personalized_logbook_backdrop.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
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
    this.previewImage,
  });

  final String name;
  final bool isRider;
  final String? horseId;
  final HorseProfile? horseProfile;
  final BuildContext appContext;
  final List<BaseListItem>? notes;
  final ImageProvider? previewImage;

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
          body: PersonalizedLogbookBackdrop(
            photoUrl: shownHorse?.picUrl,
            imageProvider: widget.previewImage,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          AppTokens.spaceLg,
                          AppTokens.spaceLg,
                          AppTokens.spaceMd,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _header(
                            context,
                            shownHorse,
                            onAddEntry: canAdd
                                ? () => showAppDialog<void>(
                                    context: context,
                                    builder: (_) => AddLogEntryDialog(
                                      usersProfile: rider,
                                      horseProfile: shownHorse,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          0,
                          AppTokens.spaceLg,
                          AppTokens.spaceMd,
                        ),
                        sliver: SliverToBoxAdapter(child: _filters()),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spaceLg,
                            vertical: AppTokens.spaceXs,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: LinearProgressIndicator(
                              color: AppTokens.accentColor(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      if (_history != null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceLg,
                            0,
                            AppTokens.spaceLg,
                            AppTokens.spaceSm,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () =>
                                    setState(() => _historyUid = null),
                                style: TextButton.styleFrom(
                                  foregroundColor: snapshot.hasError
                                      ? Theme.of(context).colorScheme.error
                                      : AppTokens.accentColor(context),
                                ),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text(
                                  snapshot.hasError
                                      ? 'Shared history unavailable. Retry'
                                      : 'Refresh shared history',
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (entries.isEmpty &&
                          snapshot.connectionState != ConnectionState.waiting)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceLg,
                            AppTokens.spaceSm,
                            AppTokens.spaceLg,
                            AppTokens.spaceXl,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: AppEmptyState(
                              icon: HorseAndRiderIcons.horseIcon,
                              title: _query.isEmpty && _category == null
                                  ? 'No Entries in the Log'
                                  : 'No matching entries.',
                              description: _query.isEmpty && _category == null
                                  ? 'Record training sessions, shows, and '
                                        'health care for '
                                        '${shownHorse?.name ?? widget.name}.'
                                  : 'Try clearing your search or selecting '
                                        'another category.',
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          0,
                          AppTokens.spaceLg,
                          AppTokens.spaceXl,
                        ),
                        sliver: SliverList.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) =>
                              _entry(entries[index]),
                        ),
                      ),
                    ],
                  ),
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

  Widget _header(
    BuildContext context,
    HorseProfile? horse, {
    VoidCallback? onAddEntry,
  }) {
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
    return LogbookHeroHeader(
      title: horse?.name ?? widget.name,
      details: details.isNotEmpty ? details : null,
      photoUrl: horse?.picUrl,
      imageProvider: widget.previewImage,
      onAddEntry: onAddEntry,
      fallbackIcon: HorseAndRiderIcons.horseIcon,
    );
  }

  Widget _filters() {
    return LogbookFilterBar<LogTag?>(
      options: [
        const LogbookFilterOption(value: null, label: 'All entries'),
        for (final category in LogTag.values)
          LogbookFilterOption(value: category, label: _categoryLabel(category)),
      ],
      selected: _category,
      onSelected: (category) => setState(() => _category = category),
      newestFirst: _newestFirst,
      onSortChanged: (value) => setState(() => _newestFirst = value),
      onSearchChanged: (value) =>
          setState(() => _query = value.trim().toLowerCase()),
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
          title: Text(heading, style: AppTokens.sectionTitleStyle(context)),
          maxWidth: 540,
          scrollable: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppStatusBadge(
                    label: _categoryLabel(category),
                    icon: Icons.bookmark_outline_rounded,
                    tone: AppStatusTone.coral,
                  ),
                  if (note.date case final date?)
                    Text(
                      DateFormat.yMMMd().format(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                ],
              ),
              Text(
                metadata,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              if (text.isNotEmpty && text != heading)
                SelectableText(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.primaryTextColor(context),
                    height: 1.45,
                  ),
                ),
            ],
          ),
          actions: [
            AppOutlinedButton(
              onPressed: () => Navigator.pop(context),
              label: 'Close',
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
