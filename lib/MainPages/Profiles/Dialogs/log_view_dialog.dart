// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_filter_bar.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_hero_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_shared_widgets.dart';
import 'package:horseandriderscompanion/CommonWidgets/personalized_logbook_backdrop.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

sealed class _HorseTimelineItem {
  const _HorseTimelineItem();
}

class _HorseMonthItem extends _HorseTimelineItem {
  const _HorseMonthItem(this.date);
  final DateTime date;
}

class _HorseEntryItem extends _HorseTimelineItem {
  const _HorseEntryItem(this.note);
  final BaseListItem note;
}

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

  LogbookConnectionRepository? _connectionRepo(BuildContext context) =>
      context.read<LogbookConnectionRepository?>() ??
      context.read<ConnectionRepository?>();

  LogbookRiderProfileRepository? _riderRepo(BuildContext context) =>
      context.read<LogbookRiderProfileRepository?>() ??
      context.read<RiderProfileRepository?>();

  Future<List<BaseListItem>>? _historyFor(
    BuildContext context,
    AppState state,
  ) {
    final uid = state.isGuest ? null : state.user.id;
    if (_historyUid != uid) {
      _historyUid = uid;
      _history = uid == null || uid.isEmpty || widget.horseId == null
          ? null
          : _connectionRepo(context)?.history({
              'action': 'horseHistory',
              'horseId': widget.horseId,
            });
    }
    return _history;
  }

  CoachingConnection? _acceptedTrainerLink(
    ConnectionsState? connections,
    RiderProfile? rider,
    HorseProfile? horse,
  ) {
    if (connections == null ||
        rider == null ||
        horse == null ||
        horse.isArchived) {
      return null;
    }
    final lowerEmail = rider.email.toLowerCase();
    return connections.connections
        .where(
          (link) =>
              link.kind == 'horse' &&
              link.status == 'accepted' &&
              link.horseId == horse.id &&
              link.coach == lowerEmail &&
              link.learner == horse.currentOwnerId.toLowerCase() &&
              link.ownershipVersion == horse.ownershipVersion,
        )
        .firstOrNull;
  }

  Future<void> _addHorseEntry({
    required HorseProfile shownHorse,
    required CoachingConnection? trainerLink,
    required List<BaseListItem> allEntries,
    BaseListItem? entry,
  }) async {
    final saved = await RiderLogbookPage.addEntry(
      context,
      initialHorse: shownHorse,
      horseConnection: trainerLink,
      knownEntries: allEntries,
      entry: entry,
    );
    if ((saved ?? false) && mounted) {
      setState(() => _historyUid = null);
    }
  }

  Future<void> _deleteHorseEntry(BaseListItem note) async {
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        title: const Text('Delete this entry?'),
        content: const Text('A shared entry is removed from both logbooks.'),
        actions: [
          AppOutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Cancel',
          ),
          AppDestructiveButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            label: 'Delete',
          ),
        ],
      ),
    );
    if (!mounted || !(confirmed ?? false)) return;
    final cubit = LogbookCubit(
      connectionRepository: _connectionRepo(context),
      riderProfileRepository: _riderRepo(context),
    );
    try {
      await cubit.deleteEntry(note);
      if (mounted) {
        setState(() => _historyUid = null);
      }
    } catch (error) {
      if (!mounted) return;
      final msg = error is ConnectionFailure
          ? error.message
          : 'Could not delete the entry.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      await cubit.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final connections = context.watch<ConnectionsCubit?>()?.state;
    final horse = state.horseProfile;
    final rider = state.usersProfile;
    final currentHorse = widget.horseId != null && horse?.id == widget.horseId
        ? horse
        : null;
    final notes = [
      ...?(currentHorse == null ? widget.notes : currentHorse.notes)?.where(
        (note) => !(note.riderLog?.authorOnly ?? false),
      ),
      if (!state.isGuest &&
          rider != null &&
          currentHorse?.currentOwnerId.toLowerCase() ==
              rider.email.toLowerCase())
        ...?rider.notes?.where(
          (note) =>
              note.riderLog?.horseId == widget.horseId &&
              !(note.riderLog?.authorOnly ?? false),
        ),
    ];

    return FutureBuilder<List<BaseListItem>>(
      future: _historyFor(context, state),
      builder: (context, snapshot) {
        final shared =
            snapshot.connectionState == ConnectionState.done && !state.isGuest
            ? (snapshot.data ?? const <BaseListItem>[])
                  .where((note) => !(note.riderLog?.authorOnly ?? false))
                  .toList()
            : const <BaseListItem>[];
        final ids = shared.map((note) => note.id).toSet();
        final allEntries = [
          ...notes.where((note) => !ids.contains(note.id)),
          ...shared,
        ];
        final entries = allEntries.where(_matches).toList()
          ..sort(_compareDates);

        final shownHorse = currentHorse ?? widget.horseProfile;
        final trainerLink = _acceptedTrainerLink(
          connections,
          rider,
          shownHorse,
        );
        final isOwner =
            rider != null &&
            shownHorse != null &&
            rider.email.toLowerCase() ==
                shownHorse.currentOwnerId.toLowerCase();
        final isListedTrainer =
            rider != null &&
            shownHorse != null &&
            (rider.studentHorses?.any((h) => h.id == shownHorse.id) ?? false) &&
            (shownHorse.instructors?.any(
                  (i) => i.id?.toLowerCase() == rider.email.toLowerCase(),
                ) ??
                false);
        final canAdd =
            !state.isGuest &&
            shownHorse != null &&
            !shownHorse.isArchived &&
            (isOwner || trainerLink != null || isListedTrainer);

        final nextStepsHit = findPreviousNextSteps(
          allEntries,
          includeAuthorOnly: false,
        );
        final recentSkills = recentPracticedSkills(
          allEntries,
          includeAuthorOnly: false,
        );
        final showUpNext =
            _query.isEmpty &&
            _category == null &&
            (nextStepsHit != null || recentSkills.isNotEmpty);

        final listItems = <_HorseTimelineItem>[];
        String? lastMonth;
        for (final entry in entries) {
          final month = monthGroupKey(entry.date);
          if (month != null && month != lastMonth) {
            lastMonth = month;
            listItems.add(_HorseMonthItem(entry.date!));
          }
          listItems.add(_HorseEntryItem(entry));
        }

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
                                ? () => _addHorseEntry(
                                    shownHorse: shownHorse,
                                    trainerLink: trainerLink,
                                    allEntries: allEntries,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (showUpNext)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceLg,
                            0,
                            AppTokens.spaceLg,
                            AppTokens.spaceMd,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: LogbookUpNextCard(
                              nextStepsHit: nextStepsHit,
                              recentSkills: recentSkills,
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
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];
                            if (item is _HorseMonthItem) {
                              return LogbookMonthHeader(date: item.date);
                            }
                            return _entry(
                              (item as _HorseEntryItem).note,
                              rider: rider,
                              shownHorse: shownHorse,
                              trainerLink: trainerLink,
                              allEntries: allEntries,
                              sharedIds: ids,
                            );
                          },
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
    if (note.riderLog?.authorOnly ?? false) return false;
    final category = _entryCategory(note);
    final info = note.riderLog;
    return (_category == null || category == _category) &&
        [
          note.name,
          note.message,
          note.extra,
          info?.title,
          info?.instructor,
          info?.feel?.label,
          info?.highlights,
          info?.focus,
          info?.nextSteps,
          ...?info?.practicedSkills.map((s) => s.skillName),
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

  Widget _entry(
    BaseListItem note, {
    required RiderProfile? rider,
    required HorseProfile? shownHorse,
    required CoachingConnection? trainerLink,
    required List<BaseListItem> allEntries,
    required Set<String?> sharedIds,
  }) {
    final category = _entryCategory(note);
    final info = note.riderLog;
    final title = info?.title?.trim();
    final text = note.name?.trim() ?? '';
    final heading = (title?.isNotEmpty ?? false)
        ? title!
        : text.isNotEmpty
        ? text
        : (info != null && info.practicedSkills.isNotEmpty)
        ? info.practicedSkills.map((s) => s.skillName).join(', ')
        : _categoryLabel(category);
    final author = note.message ?? note.parentId ?? '';
    final riderLabel = (note.extra?.isNotEmpty ?? false)
        ? 'Rider: ${note.extra}'
        : null;
    final attribution = switch (info?.authorRole) {
      'instructor' || 'trainer' => 'Added by ${info!.authorRole} $author',
      _ => null,
    };
    final metadata = [
      _categoryLabel(category),
      if (note.date case final date?) DateFormat.yMMMd().format(date),
      ?riderLabel,
      ?attribution,
    ].join(' · ');

    final isFromShared = sharedIds.contains(note.id);
    final isOwnRiderNote =
        rider != null &&
        !isFromShared &&
        (rider.notes?.any((n) => n.id == note.id) ?? false) &&
        note.canEditRiderLog(rider.email);
    final canEditShared =
        rider != null &&
        isFromShared &&
        (note.isSelected ?? false) &&
        note.canEditRiderLog(rider.email);
    final canEdit = isOwnRiderNote || canEditShared;
    final canDelete = canEdit && _connectionRepo(context) != null;

    return LogbookEntryCard(
      title: heading,
      metadata: metadata,
      preview: buildLogbookCardPreview(note, heading),
      footer: buildLogbookEntryFooter(context, note),
      icon: switch (category) {
        LogTag.Show => Icons.emoji_events_outlined,
        LogTag.Training => Icons.school_outlined,
        LogTag.Health => Icons.health_and_safety_outlined,
        LogTag.Edit => Icons.history,
        LogTag.Other => Icons.notes,
      },
      trailing: category == LogTag.Show && info?.placing != null
          ? LogbookPlacingBadge(placing: info!.placing!)
          : null,
      onTap: () async {
        final action = await showLogbookEntryDetailDialog(
          context: context,
          entry: note,
          categoryLabel: _categoryLabel(category),
          fallbackTitle: heading,
          riderLabel: riderLabel,
          attribution: attribution,
          canEdit: canEdit,
          canDelete: canDelete,
        );
        if (!mounted) return;
        if (action == 'edit' && shownHorse != null) {
          await _addHorseEntry(
            shownHorse: shownHorse,
            trainerLink: trainerLink,
            allEntries: allEntries,
            entry: note,
          );
        } else if (action == 'delete') {
          await _deleteHorseEntry(note);
        }
      },
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
